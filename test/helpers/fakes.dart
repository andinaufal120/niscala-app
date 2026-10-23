import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala_api/api.dart';

/// A [SessionStore] that keeps the session in memory.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this.stored]);

  StoredSession? stored;

  @override
  Future<StoredSession?> read() async => stored;

  @override
  Future<void> write(StoredSession session) async => stored = session;

  @override
  Future<void> clear() async => stored = null;
}

/// A [SessionStore] whose [read] never completes, to hold the app in its
/// loading state.
class NeverReadySessionStore implements SessionStore {
  @override
  Future<StoredSession?> read() => Completer<StoredSession?>().future;

  @override
  Future<void> write(StoredSession session) async {}

  @override
  Future<void> clear() async {}
}

StoredSession storedSession({
  UserRole role = UserRole.owner,
  bool emailVerified = true,
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) => StoredSession(
  accessToken: accessToken,
  refreshToken: refreshToken,
  role: role,
  emailVerified: emailVerified,
);

AuthSession authSessionFor(
  UserRole role, {
  bool emailVerified = true,
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) => AuthSession(
  accessToken: accessToken,
  refreshToken: refreshToken,
  expiresIn: 900,
  tokenType: AuthSessionTokenTypeEnum.bearer,
  account: Account(
    email: 'budi@example.com',
    emailVerified: emailVerified,
    googleEmail: null,
    hasPassword: true,
    id: 'account-1',
    name: 'Budi',
    role: role,
  ),
);

AuthTokens authTokens({
  String accessToken = 'access-2',
  String refreshToken = 'refresh-2',
}) => AuthTokens(
  accessToken: accessToken,
  refreshToken: refreshToken,
  expiresIn: 900,
  tokenType: AuthTokensTokenTypeEnum.bearer,
);

/// A refresh function that always fails, for tests that must not refresh.
Future<AuthTokens> failingRefresh(String refreshToken) =>
    Future<AuthTokens>.error(Exception('refresh must not be called'));

/// An [AuthRepository] that records its calls and answers from fields.
///
/// Set a `*Failure` field to make that method throw. Set [gate] to hold every
/// call of login, register, send and confirm in flight until it completes, and
/// [accountGate] to do the same for [getMyAccount].
class FakeAuthRepository implements AuthRepository {
  final logins = <({String email, String password})>[];
  final registrations = <({String name, String email, String password})>[];
  final confirmations = <String>[];
  var accountLoads = 0;
  var verificationRequests = 0;

  AuthSession loginResult = authSessionFor(UserRole.owner);
  AuthSession registerResult = authSessionFor(
    UserRole.owner,
    emailVerified: false,
  );
  Account accountResult = authSessionFor(
    UserRole.owner,
    emailVerified: false,
  ).account;
  DateTime resendAvailableAt = DateTime.utc(2026, 10, 18, 12);
  Account confirmResult = authSessionFor(UserRole.owner).account;

  ApiFailure? loginFailure;
  ApiFailure? registerFailure;
  ApiFailure? accountFailure;
  ApiFailure? sendFailure;
  ApiFailure? confirmFailure;

  Completer<void>? gate;
  Completer<void>? accountGate;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    logins.add((email: email, password: password));
    await gate?.future;
    if (loginFailure != null) throw loginFailure!;
    return loginResult;
  }

  @override
  Future<AuthSession> registerOwner({
    required String name,
    required String email,
    required String password,
  }) async {
    registrations.add((name: name, email: email, password: password));
    await gate?.future;
    if (registerFailure != null) throw registerFailure!;
    return registerResult;
  }

  @override
  Future<Account> getMyAccount() async {
    accountLoads++;
    await accountGate?.future;
    if (accountFailure != null) throw accountFailure!;
    return accountResult;
  }

  @override
  Future<DateTime> sendEmailVerification() async {
    verificationRequests++;
    await gate?.future;
    if (sendFailure != null) throw sendFailure!;
    return resendAvailableAt;
  }

  @override
  Future<Account> confirmEmail(String code) async {
    confirmations.add(code);
    await gate?.future;
    if (confirmFailure != null) throw confirmFailure!;
    return confirmResult;
  }
}

/// Scripts the outcome of one repository method.
///
/// Each call first takes the next entry of [queue] (null means success), and
/// falls back to [always] when the queue is empty. While [gate] is set, every
/// call is held in flight until it completes.
class CallScript {
  final queue = <ApiFailure?>[];
  ApiFailure? always;
  Completer<void>? gate;

  /// Waits for the gate, then returns the failure to throw, if any.
  Future<ApiFailure?> next() async {
    final failure = queue.isNotEmpty ? queue.removeAt(0) : always;
    await gate?.future;
    return failure;
  }
}

/// A [Property] with sensible defaults; vacant rooms are derived.
Property makeProperty({
  String id = 'p1',
  String name = 'Kos Melati',
  String address = 'Jl. Melati 1, Bandung',
  BankAccount? bankAccount,
  int roomCount = 10,
  int occupiedRoomCount = 4,
  List<ManagerRef> managers = const [],
  bool editable = true,
}) => Property(
  id: id,
  name: name,
  address: address,
  bankAccount: bankAccount,
  roomCount: roomCount,
  occupiedRoomCount: occupiedRoomCount,
  vacantRoomCount: roomCount - occupiedRoomCount,
  managers: managers,
  editable: editable,
);

/// A [PropertyRepository] that keeps the properties in memory and records its
/// calls.
///
/// [list] returns summaries of [properties]; [create], [update] and [delete]
/// change [properties] only when the call succeeds. Script failures and gates
/// per method with the `*Script` fields. Every call is also appended to
/// [calls] in order, as `list`, `get:<id>`, `create`, `update:<id>`,
/// `delete:<id>` or `reauthenticate`.
class FakePropertyRepository implements PropertyRepository {
  FakePropertyRepository({List<Property>? properties})
    : properties = properties ?? [];

  final List<Property> properties;

  final calls = <String>[];
  final created = <PropertyInput>[];
  final updated = <({String id, PropertyInput input})>[];
  final deleted = <String>[];
  final reauthentications = <String>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final createScript = CallScript();
  final updateScript = CallScript();
  final deleteScript = CallScript();
  final reauthScript = CallScript();

  var _nextId = 1;

  int get listCalls => calls.where((c) => c == 'list').length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;

  @override
  Future<List<PropertySummary>> list() async {
    calls.add('list');
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final p in properties)
        PropertySummary(
          id: p.id,
          name: p.name,
          address: p.address,
          roomCount: p.roomCount,
          occupiedRoomCount: p.occupiedRoomCount,
          managers: p.managers,
          editable: p.editable,
        ),
    ];
  }

  @override
  Future<Property> get(String id) async {
    calls.add('get:$id');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return properties.firstWhere((p) => p.id == id);
  }

  @override
  Future<Property> create(PropertyInput input) async {
    calls.add('create');
    created.add(input);
    final failure = await createScript.next();
    if (failure != null) throw failure;
    final property = makeProperty(
      id: 'new-${_nextId++}',
      name: input.name,
      address: input.address,
      bankAccount: input.bankAccount,
      roomCount: 0,
      occupiedRoomCount: 0,
    );
    properties.add(property);
    return property;
  }

  @override
  Future<Property> update(String id, PropertyInput input) async {
    calls.add('update:$id');
    updated.add((id: id, input: input));
    final failure = await updateScript.next();
    if (failure != null) throw failure;
    final index = properties.indexWhere((p) => p.id == id);
    final old = properties[index];
    return properties[index] = makeProperty(
      id: id,
      name: input.name,
      address: input.address,
      bankAccount: input.bankAccount,
      roomCount: old.roomCount,
      occupiedRoomCount: old.occupiedRoomCount,
      managers: old.managers,
      editable: old.editable,
    );
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    deleted.add(id);
    final failure = await deleteScript.next();
    if (failure != null) throw failure;
    properties.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    calls.add('reauthenticate');
    reauthentications.add(password);
    final failure = await reauthScript.next();
    if (failure != null) throw failure;
  }
}

/// A [RoomLease] with sensible defaults.
RoomLease makeRoomLease({
  String tenantId = 't1',
  String tenantName = 'Budi Santoso',
  String tenantPhone = '081234567890',
  int rent = 750000,
  DateTime? startDate,
  DateTime? endDate,
}) => RoomLease(
  tenantId: tenantId,
  tenantName: tenantName,
  tenantPhone: tenantPhone,
  rent: rent,
  startDate: startDate,
  endDate: endDate,
);

/// A [Room] with sensible defaults. Without [occupancy] the room is occupied
/// exactly when it has a [lease].
Room makeRoom({
  String id = 'r1',
  String propertyId = 'p1',
  String number = '08',
  int baseRate = 800000,
  Occupancy? occupancy,
  RoomLease? lease,
  num? lengthM,
  num? widthM,
  List<String> facilities = const [],
  bool editable = true,
}) => Room(
  id: id,
  propertyId: propertyId,
  number: number,
  baseRate: baseRate,
  occupancy:
      occupancy ?? (lease == null ? Occupancy.vacant : Occupancy.occupied),
  lease: lease,
  lengthM: lengthM,
  widthM: widthM,
  facilities: facilities,
  editable: editable,
);

/// A [RoomSummary] with sensible defaults, see [makeRoom].
RoomSummary makeRoomSummary({
  String id = 'r1',
  String number = '08',
  int baseRate = 800000,
  Occupancy? occupancy,
  RoomLeaseSummary? lease,
  num? lengthM,
  num? widthM,
  List<String> facilities = const [],
  bool editable = true,
}) => RoomSummary(
  id: id,
  number: number,
  baseRate: baseRate,
  occupancy:
      occupancy ?? (lease == null ? Occupancy.vacant : Occupancy.occupied),
  lease: lease,
  lengthM: lengthM,
  widthM: widthM,
  facilities: facilities,
  editable: editable,
);

/// A [RoomRepository] that keeps the rooms in memory and records its calls.
///
/// [list] returns summaries of the [rooms] of the property; [create],
/// [update] and [delete] change [rooms] only when the call succeeds. Script
/// failures and gates per method with the `*Script` fields. Every call is also
/// appended to [calls] in order, as `list:<propertyId>`, `get:<id>`,
/// `create:<propertyId>`, `update:<id>`, `delete:<id>` or
/// `suggestions:<propertyId>`.
class FakeRoomRepository implements RoomRepository {
  FakeRoomRepository({List<Room>? rooms, List<String>? suggestions})
    : rooms = rooms ?? [],
      suggestions = suggestions ?? [];

  final List<Room> rooms;

  /// The tags [facilitySuggestions] returns.
  List<String> suggestions;

  final calls = <String>[];
  final created = <({String propertyId, RoomInput input})>[];
  final updated = <({String id, RoomInput input})>[];
  final deleted = <String>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final createScript = CallScript();
  final updateScript = CallScript();
  final deleteScript = CallScript();
  final suggestionsScript = CallScript();

  var _nextId = 1;

  int get listCalls => calls.where((c) => c.startsWith('list:')).length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;

  @override
  Future<List<RoomSummary>> list(String propertyId) async {
    calls.add('list:$propertyId');
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final r in rooms)
        if (r.propertyId == propertyId)
          makeRoomSummary(
            id: r.id,
            number: r.number,
            baseRate: r.baseRate,
            occupancy: r.occupancy,
            lease: r.lease == null
                ? null
                : RoomLeaseSummary(
                    tenantName: r.lease!.tenantName,
                    endDate: r.lease!.endDate,
                  ),
            lengthM: r.lengthM,
            widthM: r.widthM,
            facilities: r.facilities,
            editable: r.editable,
          ),
    ];
  }

  @override
  Future<Room> get(String roomId) async {
    calls.add('get:$roomId');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw const ApiFailure(code: 'ROOM_NOT_FOUND'),
    );
  }

  @override
  Future<Room> create(String propertyId, RoomInput input) async {
    calls.add('create:$propertyId');
    created.add((propertyId: propertyId, input: input));
    final failure = await createScript.next();
    if (failure != null) throw failure;
    final room = makeRoom(
      id: 'new-${_nextId++}',
      propertyId: propertyId,
      number: input.number,
      baseRate: input.baseRate,
      lengthM: input.lengthM,
      widthM: input.widthM,
      facilities: input.facilities,
    );
    rooms.add(room);
    return room;
  }

  @override
  Future<Room> update(String roomId, RoomInput input) async {
    calls.add('update:$roomId');
    updated.add((id: roomId, input: input));
    final failure = await updateScript.next();
    if (failure != null) throw failure;
    final index = rooms.indexWhere((r) => r.id == roomId);
    final old = rooms[index];
    return rooms[index] = makeRoom(
      id: roomId,
      propertyId: old.propertyId,
      number: input.number,
      baseRate: input.baseRate,
      occupancy: old.occupancy,
      lease: old.lease,
      lengthM: input.lengthM,
      widthM: input.widthM,
      facilities: input.facilities,
      editable: old.editable,
    );
  }

  @override
  Future<void> delete(String roomId) async {
    calls.add('delete:$roomId');
    deleted.add(roomId);
    final failure = await deleteScript.next();
    if (failure != null) throw failure;
    rooms.removeWhere((r) => r.id == roomId);
  }

  @override
  Future<List<String>> facilitySuggestions(String propertyId) async {
    calls.add('suggestions:$propertyId');
    final failure = await suggestionsScript.next();
    if (failure != null) throw failure;
    return List.of(suggestions);
  }
}

/// The whole app with a fake session store and no network.
Widget buildTestApp({
  SessionStore? store,
  Future<AuthTokens> Function(String refreshToken)? refresh,
  Future<void> Function()? logout,
  AuthRepository? auth,
  PropertyRepository? properties,
  RoomRepository? rooms,
}) {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(store ?? InMemorySessionStore()),
      refreshTokensProvider.overrideWithValue(refresh ?? failingRefresh),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      propertyRepositoryProvider.overrideWithValue(
        properties ?? FakePropertyRepository(),
      ),
      roomRepositoryProvider.overrideWithValue(rooms ?? FakeRoomRepository()),
      if (logout != null) logoutProvider.overrideWithValue(logout),
    ],
    child: const NiscalaApp(),
  );
}

/// Matches any Material button (the base type is abstract, so `byType` cannot).
Finder anyButton() =>
    find.byWidgetPredicate((widget) => widget is ButtonStyleButton);

/// Wraps [child] in a themed [MaterialApp] without any provider.
Widget themedApp(Widget child) => MaterialApp(theme: buildTheme(), home: child);
