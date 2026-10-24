import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala_api/api.dart';

/// The Indonesian message a screen shows for a failure that carries only the
/// API error [code], as a screen derives it from the caught failure.
String messageOfCode(String code) => errorMessageFor(ApiFailure(code: code));

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

/// An invitation that is still valid. Created 18 Okt 2026, valid until
/// 25 Okt 2026.
TenantInvitation makeTenantInvitation({
  DateTime? createdAt,
  DateTime? expiresAt,
  bool expired = false,
  String? url = 'https://niscala.example/undangan/abc123',
}) => TenantInvitation(
  createdAt: createdAt ?? DateTime.utc(2026, 10, 18, 12),
  expiresAt: expiresAt ?? DateTime.utc(2026, 10, 25, 12),
  expired: expired,
  url: url,
);

/// A [Tenant] with sensible defaults: not activated, with a valid invitation,
/// in room 08 on a monthly lease from 1 Jan 2026 to 31 Des 2026.
///
/// Without [invitation] a not activated tenant gets [makeTenantInvitation]
/// and an active tenant gets none. Set [withoutInvitation] to force none.
Tenant makeTenant({
  String id = 't1',
  String name = 'Budi Santoso',
  String phone = '081255204471',
  String? email,
  String? occupation = 'Karyawan swasta',
  TenantAccountStatus accountStatus = TenantAccountStatus.notActivated,
  TenantInvitation? invitation,
  bool withoutInvitation = false,
  List<EmergencyContact> emergencyContacts = const [],
  String roomId = 'r1',
  String roomNumber = '08',
  BillingCycle billingCycle = BillingCycle.monthly,
  DateTime? startDate,
  DateTime? endDate,
  bool noEndDate = false,
  DateTime? nextBillDate,
  bool noNextBillDate = false,
  int gracePeriodDays = 0,
  int rent = 750000,
}) => Tenant(
  id: id,
  name: name,
  phone: phone,
  email: email,
  occupation: occupation,
  accountStatus: accountStatus,
  invitation: withoutInvitation
      ? null
      : invitation ??
            (accountStatus == TenantAccountStatus.notActivated
                ? makeTenantInvitation()
                : null),
  emergencyContacts: emergencyContacts,
  room: RoomRef(id: roomId, number: roomNumber),
  lease: Lease(
    billingCycle: billingCycle,
    startDate: startDate ?? DateTime.utc(2026, 1, 1),
    endDate: noEndDate ? null : endDate ?? DateTime.utc(2026, 12, 31),
    nextBillDate: noNextBillDate
        ? null
        : nextBillDate ?? DateTime.utc(2026, 11, 1),
    gracePeriodDays: gracePeriodDays,
    rent: rent,
  ),
);

/// A [TenantSummary] with sensible defaults: active, monthly, ending
/// 31 Des 2026.
TenantSummary makeTenantSummary({
  String id = 't1',
  String name = 'Budi Santoso',
  String roomId = 'r1',
  String roomNumber = '08',
  TenantAccountStatus accountStatus = TenantAccountStatus.active,
  BillingCycle billingCycle = BillingCycle.monthly,
  DateTime? leaseEndDate,
  bool noEndDate = false,
  DateTime? invitationExpiresAt,
}) => TenantSummary(
  id: id,
  name: name,
  room: RoomRef(id: roomId, number: roomNumber),
  accountStatus: accountStatus,
  billingCycle: billingCycle,
  leaseEndDate: noEndDate ? null : leaseEndDate ?? DateTime.utc(2026, 12, 31),
  invitationExpiresAt: invitationExpiresAt,
);

/// A [TenantRepository] that keeps the tenants in memory and records its
/// calls.
///
/// [tenants] belong to the property `p1`; [otherProperties] maps other
/// property ids to their tenants. [list] returns summaries; [create] adds a
/// not activated tenant to the property only when the call succeeds, with the
/// invitation url `https://niscala.example/undangan/<id>` (none when
/// [createWithoutInvitation] is set). Script failures and gates per method
/// with the `*Script` fields. Every call is also appended to [calls] in order,
/// as `list:<propertyId>`, `get:<id>` or `create:<propertyId>`.
class FakeTenantRepository implements TenantRepository {
  FakeTenantRepository({
    List<Tenant>? tenants,
    Map<String, List<Tenant>>? otherProperties,
  }) : _byProperty = {'p1': tenants ?? [], ...?otherProperties};

  final Map<String, List<Tenant>> _byProperty;

  /// The tenants of property `p1`.
  List<Tenant> get tenants => _byProperty['p1']!;

  /// Whether [create] returns a tenant without an invitation.
  bool createWithoutInvitation = false;

  final calls = <String>[];
  final created = <({String propertyId, NewTenantInput input})>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final createScript = CallScript();

  var _nextId = 1;

  int get listCalls => calls.where((c) => c.startsWith('list:')).length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;

  @override
  Future<List<TenantSummary>> list(String propertyId) async {
    calls.add('list:$propertyId');
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final t in _byProperty[propertyId] ?? <Tenant>[])
        TenantSummary(
          id: t.id,
          name: t.name,
          room: t.room,
          accountStatus: t.accountStatus,
          billingCycle: t.lease.billingCycle,
          leaseEndDate: t.lease.endDate,
          invitationExpiresAt: t.invitation?.expiresAt,
        ),
    ];
  }

  @override
  Future<Tenant> get(String tenantId) async {
    calls.add('get:$tenantId');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return _byProperty.values
        .expand((list) => list)
        .firstWhere(
          (t) => t.id == tenantId,
          orElse: () => throw const ApiFailure(code: 'TENANT_NOT_FOUND'),
        );
  }

  @override
  Future<Tenant> create(String propertyId, NewTenantInput input) async {
    calls.add('create:$propertyId');
    created.add((propertyId: propertyId, input: input));
    final failure = await createScript.next();
    if (failure != null) throw failure;
    final id = 'new-${_nextId++}';
    final lease = input.lease ?? LeaseInput();
    final tenant = Tenant(
      id: id,
      name: input.name,
      phone: input.phone,
      occupation: input.occupation,
      accountStatus: TenantAccountStatus.notActivated,
      emergencyContacts: input.emergencyContacts,
      room: RoomRef(id: input.roomId, number: input.roomId),
      invitation: createWithoutInvitation
          ? null
          : makeTenantInvitation(url: 'https://niscala.example/undangan/$id'),
      lease: Lease(
        billingCycle: lease.billingCycle,
        startDate: lease.startDate,
        endDate: lease.endDate,
        gracePeriodDays: lease.gracePeriodDays,
        rent: lease.rent ?? 0,
      ),
    );
    (_byProperty[propertyId] ??= []).add(tenant);
    return tenant;
  }
}

/// An [InvitationPreview] with sensible defaults: a valid tenant invitation
/// from Siti Pemilik for room 08 of Kos Melati, whose contacts are complete.
InvitationPreview makeInvitationPreview({
  InvitationLinkStatus status = InvitationLinkStatus.valid,
  InvitationRole role = InvitationRole.tenant,
  String name = 'Budi Santoso',
  String inviterName = 'Siti Pemilik',
  List<InvitationProperty>? properties,
  String? roomNumber = '08',
  bool emergencyContactsRequired = false,
}) => InvitationPreview(
  emergencyContactsRequired: emergencyContactsRequired,
  expiresAt: DateTime.utc(2026, 10, 25, 12),
  inviterName: inviterName,
  name: name,
  properties:
      properties ??
      [
        InvitationProperty(
          address: 'Jl. Melati 1, Bandung',
          name: 'Kos Melati',
        ),
      ],
  role: role,
  roomNumber: roomNumber,
  status: status,
);

/// An [InvitationRepository] that records its calls and answers from fields.
///
/// Set [previewFailure] or [activateFailure] to make that method throw. Set
/// [previewGate] or [activateGate] to hold that method in flight until it
/// completes.
class FakeInvitationRepository implements InvitationRepository {
  final previews = <String>[];
  final activations =
      <
        ({
          String token,
          String name,
          String email,
          String password,
          List<EmergencyContact>? emergencyContacts,
        })
      >[];

  InvitationPreview previewResult = makeInvitationPreview();
  AuthSession activateResult = authSessionFor(
    UserRole.tenant,
    emailVerified: false,
  );

  ApiFailure? previewFailure;
  ApiFailure? activateFailure;

  Completer<void>? previewGate;
  Completer<void>? activateGate;

  @override
  Future<InvitationPreview> preview(String token) async {
    previews.add(token);
    await previewGate?.future;
    if (previewFailure != null) throw previewFailure!;
    return previewResult;
  }

  @override
  Future<AuthSession> activateWithPassword({
    required String token,
    required String name,
    required String email,
    required String password,
    List<EmergencyContact>? emergencyContacts,
  }) async {
    activations.add((
      token: token,
      name: name,
      email: email,
      password: password,
      emergencyContacts: emergencyContacts,
    ));
    await activateGate?.future;
    if (activateFailure != null) throw activateFailure!;
    return activateResult;
  }
}

/// A [ComplaintClassification] with sensible defaults. Without
/// [classifiedByName] it is an AI result.
ComplaintClassification makeComplaintClassification({
  String category = 'Pipa dan air',
  ComplaintUrgency urgency = ComplaintUrgency.medium,
  String? suggestedAction = 'Panggil tukang ledeng.',
  String? classifiedByName,
}) => ComplaintClassification(
  category: category,
  urgency: urgency,
  suggestedAction: suggestedAction,
  classifiedByName: classifiedByName,
);

/// A [Complaint] with sensible defaults: new, from Budi Santoso in room 08 of
/// Kos Melati, sent 18 Okt 2026 at 12:00 UTC.
///
/// It has no classification and no classification state unless given.
Complaint makeComplaint({
  String id = 'c1',
  String description = 'Keran air di kamar mandi bocor sejak kemarin.',
  ComplaintStatus status = ComplaintStatus.new_,
  ComplaintClassification? classification,
  ComplaintClassificationState? classificationState,
  bool classificationWithheld = false,
  DateTime? createdAt,
  String tenantName = 'Budi Santoso',
  String roomNumber = '08',
  String propertyName = 'Kos Melati',
  List<ComplaintStatusChange> statusChanges = const [],
}) => Complaint(
  id: id,
  description: description,
  status: status,
  classification: classification,
  classificationState: classificationState,
  classificationWithheld: classificationWithheld,
  createdAt: createdAt ?? DateTime.utc(2026, 10, 18, 12),
  hasPhoto: false,
  property: PropertyRef(id: 'p1', name: propertyName),
  room: RoomRef(id: 'r1', number: roomNumber),
  statusChanges: statusChanges,
  tenantName: tenantName,
);

/// A [ComplaintRepository] that keeps the complaints in memory and records its
/// calls.
///
/// [list] returns summaries of [complaints] in their order; [get] returns the
/// complaint with the id or fails with `COMPLAINT_NOT_FOUND`. [submit] saves a
/// new complaint (status new, classification state `classifying`, or
/// [submitState] when set) only when the call succeeds, and appends it to
/// [complaints]. Script failures and gates per method with the `*Script`
/// fields. Every call is also appended to [calls] in order, as `list`,
/// `get:<id>` or `submit`.
class FakeComplaintRepository implements ComplaintRepository {
  FakeComplaintRepository({List<Complaint>? complaints})
    : complaints = complaints ?? [];

  final List<Complaint> complaints;

  final calls = <String>[];
  final submitted = <String>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final submitScript = CallScript();

  /// The classification state of a complaint saved by [submit]. Null means
  /// classified: [submitClassification] is returned instead.
  ComplaintClassificationState? submitState =
      ComplaintClassificationState.classifying;
  ComplaintClassification? submitClassification;

  var _nextId = 1;

  int get listCalls => calls.where((c) => c == 'list').length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;
  int get submitCalls => calls.where((c) => c == 'submit').length;

  @override
  Future<List<ComplaintSummary>> list() async {
    calls.add('list');
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final c in complaints)
        ComplaintSummary(
          id: c.id,
          description: c.description,
          status: c.status,
          classification: c.classification,
          classificationState: c.classificationState,
          classificationWithheld: c.classificationWithheld,
          createdAt: c.createdAt,
          hasPhoto: c.hasPhoto,
          property: c.property,
          room: c.room,
          tenantName: c.tenantName,
        ),
    ];
  }

  @override
  Future<Complaint> get(String complaintId) async {
    calls.add('get:$complaintId');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return complaints.firstWhere(
      (c) => c.id == complaintId,
      orElse: () => throw const ApiFailure(code: 'COMPLAINT_NOT_FOUND'),
    );
  }

  @override
  Future<Complaint> submit(String description) async {
    calls.add('submit');
    submitted.add(description);
    final failure = await submitScript.next();
    if (failure != null) throw failure;
    final complaint = makeComplaint(
      id: 'new-${_nextId++}',
      description: description,
      classification: submitState == null ? submitClassification : null,
      classificationState: submitState,
    );
    complaints.add(complaint);
    return complaint;
  }
}

/// A valid 1 x 1 PNG image.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// A [BankAccount] of the owner Siti Pemilik at BCA.
BankAccount makeBankAccount() => BankAccount(
  bankName: 'BCA',
  accountNumber: '1234567890',
  accountHolderName: 'Siti Pemilik',
);

/// A [RentBill] with sensible defaults: an unpaid bill of Budi Santoso in room
/// 08 of Kos Melati for November 2026, due 5 Nov 2026.
///
/// Without [canUploadReceipt] the bill can be uploaded to when it is unpaid or
/// rejected and the property has a bank account, whether or not it is in the
/// current period ([isCurrent]). Without
/// [hasReceipt] only a bill awaiting verification has a receipt. The default
/// bank account is BCA 1234567890 of Siti Pemilik; set [withoutBankAccount] for
/// none.
RentBill makeRentBill({
  String id = 'b1',
  String tenantName = 'Budi Santoso',
  String roomNumber = '08',
  String propertyName = 'Kos Melati',
  int amount = 800000,
  DateTime? periodStart,
  DateTime? periodEnd,
  DateTime? dueDate,
  PaymentStatus status = PaymentStatus.unpaid,
  String? rejectionReason,
  bool? hasReceipt,
  int daysOverdue = 0,
  bool isCurrent = true,
  bool? canUploadReceipt,
  BankAccount? bankAccount,
  bool withoutBankAccount = false,
}) {
  final account = withoutBankAccount ? null : bankAccount ?? makeBankAccount();
  final open =
      status == PaymentStatus.unpaid || status == PaymentStatus.rejected;
  return RentBill(
    id: id,
    amount: amount,
    daysOverdue: daysOverdue,
    dueDate: dueDate ?? DateTime.utc(2026, 11, 5),
    periodStart: periodStart ?? DateTime.utc(2026, 11, 1),
    periodEnd: periodEnd ?? DateTime.utc(2026, 11, 30),
    bankAccount: account,
    payment: Payment(
      status: status,
      hasReceipt: hasReceipt ?? status == PaymentStatus.awaitingVerification,
      rejectionReason: rejectionReason,
    ),
    property: PropertyRef(id: 'p1', name: propertyName),
    room: RoomRef(id: 'r1', number: roomNumber),
    tenant: TenantRef(id: 't1', name: tenantName),
    isCurrent: isCurrent,
    canUploadReceipt: canUploadReceipt ?? (account != null && open),
  );
}

/// The list entry of [bill].
RentBillSummary rentBillSummaryOf(RentBill bill) => RentBillSummary(
  id: bill.id,
  amount: bill.amount,
  daysOverdue: bill.daysOverdue,
  dueDate: bill.dueDate,
  periodStart: bill.periodStart,
  periodEnd: bill.periodEnd,
  payment: bill.payment,
  property: bill.property,
  room: bill.room,
  tenant: bill.tenant,
  isCurrent: bill.isCurrent,
  canUploadReceipt: bill.canUploadReceipt,
);

/// A [RentBillSummary] with the same defaults as [makeRentBill].
RentBillSummary makeRentBillSummary({
  String id = 'b1',
  int amount = 800000,
  PaymentStatus status = PaymentStatus.unpaid,
  String? rejectionReason,
  int daysOverdue = 0,
  bool isCurrent = true,
  bool? canUploadReceipt,
}) => rentBillSummaryOf(
  makeRentBill(
    id: id,
    amount: amount,
    status: status,
    rejectionReason: rejectionReason,
    daysOverdue: daysOverdue,
    isCurrent: isCurrent,
    canUploadReceipt: canUploadReceipt,
  ),
);

/// A [RentBillRepository] that keeps the bills in memory and records its calls.
///
/// [list] returns summaries of the [bills] whose status is asked for, in their
/// order. [get] returns the bill or fails with `RENT_BILL_NOT_FOUND`.
/// [uploadReceipt] turns a bill into one awaiting verification, with a
/// receipt and no upload action, only when the call succeeds. [receiptBytes]
/// returns the entry of [receipts] or fails with `RECEIPT_NOT_FOUND`. Script
/// failures and gates per method with the `*Script` fields. Every call is also
/// appended to [calls] in order, as `list`, `get:<id>`, `upload:<id>` or
/// `receipt:<id>`.
class FakeRentBillRepository implements RentBillRepository {
  FakeRentBillRepository({
    List<RentBill>? bills,
    Map<String, Uint8List>? receipts,
  }) : bills = bills ?? [],
       receipts = receipts ?? {};

  final List<RentBill> bills;
  final Map<String, Uint8List> receipts;

  final calls = <String>[];
  final listedStatuses = <List<PaymentStatus>>[];
  final uploaded = <({String id, ReceiptFile file})>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final uploadScript = CallScript();
  final receiptScript = CallScript();

  int get listCalls => calls.where((c) => c == 'list').length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;
  int get uploadCalls => calls.where((c) => c.startsWith('upload:')).length;
  int get receiptCalls => calls.where((c) => c.startsWith('receipt:')).length;

  @override
  Future<List<RentBillSummary>> list({
    required List<PaymentStatus> statuses,
  }) async {
    calls.add('list');
    listedStatuses.add(List.of(statuses));
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final b in bills)
        if (statuses.contains(b.payment.status)) rentBillSummaryOf(b),
    ];
  }

  @override
  Future<RentBill> get(String id) async {
    calls.add('get:$id');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return bills.firstWhere(
      (b) => b.id == id,
      orElse: () => throw const ApiFailure(code: 'RENT_BILL_NOT_FOUND'),
    );
  }

  @override
  Future<RentBill> uploadReceipt(String id, ReceiptFile file) async {
    calls.add('upload:$id');
    uploaded.add((id: id, file: file));
    final failure = await uploadScript.next();
    if (failure != null) throw failure;
    final index = bills.indexWhere((b) => b.id == id);
    if (index < 0) throw const ApiFailure(code: 'RENT_BILL_NOT_FOUND');
    final old = bills[index];
    receipts[id] = file.bytes;
    return bills[index] = RentBill(
      id: old.id,
      amount: old.amount,
      daysOverdue: old.daysOverdue,
      dueDate: old.dueDate,
      periodStart: old.periodStart,
      periodEnd: old.periodEnd,
      bankAccount: old.bankAccount,
      payment: Payment(
        status: PaymentStatus.awaitingVerification,
        hasReceipt: true,
      ),
      property: old.property,
      room: old.room,
      tenant: old.tenant,
      isCurrent: old.isCurrent,
      canUploadReceipt: false,
    );
  }

  @override
  Future<Uint8List> receiptBytes(String id) async {
    calls.add('receipt:$id');
    final failure = await receiptScript.next();
    if (failure != null) throw failure;
    return receipts[id] ?? (throw const ApiFailure(code: 'RECEIPT_NOT_FOUND'));
  }
}

/// A [ReceiptPicker] that records the sources asked for.
///
/// Each [pick] first takes the next entry of [queue] (null means cancelled),
/// and falls back to [always] when the queue is empty. While [gate] is set,
/// every call is held until it completes. While [failure] is set, every call
/// throws it, as the device picker does when access is denied.
class FakeReceiptPicker implements ReceiptPicker {
  final requested = <ReceiptSource>[];
  final queue = <ReceiptFile?>[];
  ReceiptFile? always;
  Completer<void>? gate;
  Object? failure;

  @override
  Future<ReceiptFile?> pick(ReceiptSource source) async {
    requested.add(source);
    final file = queue.isNotEmpty ? queue.removeAt(0) : always;
    await gate?.future;
    if (failure != null) throw failure!;
    return file;
  }
}

/// A [CurrentLease] with sensible defaults: room 08 of Kos Melati on a
/// monthly lease of Rp750.000 from 1 Jan 2026 to 31 Des 2026, 3,5 x 4 m, with
/// the facilities ac and kasur.
///
/// Set [noStartDate], [noEndDate], [noDimensions] to leave those out.
CurrentLease makeCurrentLease({
  String propertyName = 'Kos Melati',
  String address = 'Jl. Melati 1, Bandung',
  String roomNumber = '08',
  BillingCycle billingCycle = BillingCycle.monthly,
  int rent = 750000,
  DateTime? startDate,
  DateTime? endDate,
  bool noStartDate = false,
  bool noEndDate = false,
  num? lengthM = 3.5,
  num? widthM = 4,
  bool noDimensions = false,
  List<String> facilities = const ['ac', 'kasur'],
}) => CurrentLease(
  billingCycle: billingCycle,
  property: CurrentLeaseProperty(
    id: 'p1',
    name: propertyName,
    address: address,
  ),
  rent: rent,
  room: CurrentLeaseRoom(
    id: 'r1',
    number: roomNumber,
    lengthM: noDimensions ? null : lengthM,
    widthM: noDimensions ? null : widthM,
    facilities: facilities,
  ),
  startDate: noStartDate ? null : startDate ?? DateTime.utc(2026, 1, 1),
  endDate: noEndDate ? null : endDate ?? DateTime.utc(2026, 12, 31),
);

/// A [LeaseRepository] that answers with [lease] (null means no lease) and
/// records its calls. Script failures and a gate with [script].
class FakeLeaseRepository implements LeaseRepository {
  FakeLeaseRepository({this.lease});

  CurrentLease? lease;

  final script = CallScript();

  var calls = 0;

  @override
  Future<CurrentLease?> myLease() async {
    calls++;
    final failure = await script.next();
    if (failure != null) throw failure;
    return lease;
  }
}

/// The whole app with a fake session store and no network.
///
/// Without [invitationSharer] sharing does nothing.
Widget buildTestApp({
  SessionStore? store,
  Future<AuthTokens> Function(String refreshToken)? refresh,
  Future<void> Function()? logout,
  AuthRepository? auth,
  InvitationRepository? invitations,
  PropertyRepository? properties,
  RoomRepository? rooms,
  TenantRepository? tenants,
  ComplaintRepository? complaints,
  RentBillRepository? rentBills,
  LeaseRepository? leases,
  ReceiptPicker? receiptPicker,
  Future<void> Function(String text)? invitationSharer,
}) {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(store ?? InMemorySessionStore()),
      refreshTokensProvider.overrideWithValue(refresh ?? failingRefresh),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      invitationRepositoryProvider.overrideWithValue(
        invitations ?? FakeInvitationRepository(),
      ),
      propertyRepositoryProvider.overrideWithValue(
        properties ?? FakePropertyRepository(),
      ),
      roomRepositoryProvider.overrideWithValue(rooms ?? FakeRoomRepository()),
      tenantRepositoryProvider.overrideWithValue(
        tenants ?? FakeTenantRepository(),
      ),
      complaintRepositoryProvider.overrideWithValue(
        complaints ?? FakeComplaintRepository(),
      ),
      rentBillRepositoryProvider.overrideWithValue(
        rentBills ?? FakeRentBillRepository(),
      ),
      leaseRepositoryProvider.overrideWithValue(
        leases ?? FakeLeaseRepository(),
      ),
      receiptPickerProvider.overrideWithValue(
        receiptPicker ?? FakeReceiptPicker(),
      ),
      invitationSharerProvider.overrideWithValue(
        invitationSharer ?? (text) async {},
      ),
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
