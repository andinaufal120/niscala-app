import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/api/health_repository.dart';
import 'package:niscala/core/push/push_messaging.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/dashboard/data/dashboard_repository.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/features/user_accounts/data/user_account_repository.dart';
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

  /// The email of every [requestPasswordReset] call, in order.
  final passwordResetRequests = <String>[];

  /// The token of every [previewPasswordReset] call, in order.
  final passwordResetPreviews = <String>[];

  /// The arguments of every [resetPassword] call, in order.
  final passwordResets = <({String token, String newPassword})>[];

  /// The email that [previewPasswordReset] returns.
  String passwordResetPreviewEmail = 'budi@example.com';

  ApiFailure? requestPasswordResetFailure;
  ApiFailure? previewPasswordResetFailure;
  ApiFailure? resetPasswordFailure;

  /// Holds [requestPasswordReset], [previewPasswordReset] or [resetPassword]
  /// in flight until it completes.
  Completer<void>? requestPasswordResetGate;
  Completer<void>? previewPasswordResetGate;
  Completer<void>? resetPasswordGate;

  @override
  Future<void> requestPasswordReset(String email) async {
    passwordResetRequests.add(email);
    await requestPasswordResetGate?.future;
    if (requestPasswordResetFailure != null) throw requestPasswordResetFailure!;
  }

  @override
  Future<String> previewPasswordReset(String token) async {
    passwordResetPreviews.add(token);
    await previewPasswordResetGate?.future;
    if (previewPasswordResetFailure != null) {
      throw previewPasswordResetFailure!;
    }
    return passwordResetPreviewEmail;
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    passwordResets.add((token: token, newPassword: newPassword));
    await resetPasswordGate?.future;
    if (resetPasswordFailure != null) throw resetPasswordFailure!;
  }

  /// The token of every [confirmEmailChange] call, in order.
  final emailChangeConfirmations = <String>[];

  ApiFailure? confirmEmailChangeFailure;

  /// Holds [confirmEmailChange] in flight until it completes.
  Completer<void>? confirmEmailChangeGate;

  @override
  Future<void> confirmEmailChange(String token) async {
    emailChangeConfirmations.add(token);
    await confirmEmailChangeGate?.future;
    if (confirmEmailChangeFailure != null) throw confirmEmailChangeFailure!;
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
/// as `list:<propertyId>`, `get:<id>`, `create:<propertyId>`, `update:<id>`,
/// `delete:<id>` or `regenerate:<id>`. [delete] removes the tenant from its
/// property only when the call succeeds, and fails with `TENANT_NOT_FOUND` for
/// an unknown id.
///
/// [update] replaces name, phone, occupation, emergency contacts and the lease
/// of a tenant only when the call succeeds; the room, the account status, the
/// email, the invitation and the next bill date stay as they were.
/// [regenerateInvitation] gives the tenant a new valid invitation with the url
/// `https://niscala.example/undangan/<id>-<n>`, where n counts the
/// regenerations, only when the call succeeds. [update] and
/// [regenerateInvitation] fail with `TENANT_NOT_FOUND` for an unknown id.
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
  final updated = <({String id, TenantInput input})>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final createScript = CallScript();
  final updateScript = CallScript();
  final regenerateScript = CallScript();
  final deleteScript = CallScript();

  /// The ids of every [delete] call, in order, whether it succeeded or not.
  final deleted = <String>[];

  var _nextId = 1;
  var _regenerations = 0;

  int get listCalls => calls.where((c) => c.startsWith('list:')).length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;
  int get updateCalls => calls.where((c) => c.startsWith('update:')).length;
  int get deleteCalls => calls.where((c) => c.startsWith('delete:')).length;

  @override
  Future<void> delete(String tenantId) async {
    calls.add('delete:$tenantId');
    deleted.add(tenantId);
    final failure = await deleteScript.next();
    if (failure != null) throw failure;
    for (final list in _byProperty.values) {
      final index = list.indexWhere((t) => t.id == tenantId);
      if (index >= 0) {
        list.removeAt(index);
        return;
      }
    }
    throw const ApiFailure(code: 'TENANT_NOT_FOUND');
  }

  int get regenerateCalls =>
      calls.where((c) => c.startsWith('regenerate:')).length;

  /// Replaces the tenant with the id by [change] of it, or fails with
  /// `TENANT_NOT_FOUND`.
  Tenant _change(String tenantId, Tenant Function(Tenant old) change) {
    for (final list in _byProperty.values) {
      final index = list.indexWhere((t) => t.id == tenantId);
      if (index >= 0) return list[index] = change(list[index]);
    }
    throw const ApiFailure(code: 'TENANT_NOT_FOUND');
  }

  @override
  Future<Tenant> update(String tenantId, TenantInput input) async {
    calls.add('update:$tenantId');
    updated.add((id: tenantId, input: input));
    final failure = await updateScript.next();
    if (failure != null) throw failure;
    return _change(tenantId, (old) {
      final lease = input.lease ?? LeaseInput();
      return Tenant(
        id: old.id,
        name: input.name,
        phone: input.phone,
        email: old.email,
        occupation: input.occupation,
        accountStatus: old.accountStatus,
        invitation: old.invitation,
        emergencyContacts: input.emergencyContacts,
        room: old.room,
        lease: Lease(
          billingCycle: lease.billingCycle,
          startDate: lease.startDate,
          endDate: lease.endDate,
          nextBillDate: old.lease.nextBillDate,
          gracePeriodDays: lease.gracePeriodDays,
          rent: lease.rent ?? old.lease.rent,
        ),
      );
    });
  }

  @override
  Future<TenantInvitation> regenerateInvitation(String tenantId) async {
    calls.add('regenerate:$tenantId');
    final failure = await regenerateScript.next();
    if (failure != null) throw failure;
    final invitation = makeTenantInvitation(
      url: 'https://niscala.example/undangan/$tenantId-${++_regenerations}',
    );
    _change(
      tenantId,
      (old) => Tenant(
        id: old.id,
        name: old.name,
        phone: old.phone,
        email: old.email,
        occupation: old.occupation,
        accountStatus: old.accountStatus,
        invitation: invitation,
        emergencyContacts: old.emergencyContacts,
        room: old.room,
        lease: old.lease,
      ),
    );
    return invitation;
  }

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

/// A [ManagerProperty] with sensible defaults: Kos Melati.
ManagerProperty makeManagerProperty({
  String id = 'p1',
  String name = 'Kos Melati',
  String address = 'Jl. Melati 1, Bandung',
}) => ManagerProperty(id: id, name: name, address: address);

/// The properties of the Owner as a manager lists them: `p1` Kos Melati, `p2`
/// Kos Mawar and `p3` Kos Anggrek.
List<ManagerProperty> makeManagerCatalog() => [
  makeManagerProperty(),
  makeManagerProperty(
    id: 'p2',
    name: 'Kos Mawar',
    address: 'Jl. Mawar 2, Bandung',
  ),
  makeManagerProperty(
    id: 'p3',
    name: 'Kos Anggrek',
    address: 'Jl. Anggrek 3, Bandung',
  ),
];

/// A manager invitation that is still valid. Created 18 Okt 2026, valid until
/// 25 Okt 2026. An expired invitation has no link unless [url] is given.
ManagerInvitation makeManagerInvitation({
  DateTime? createdAt,
  DateTime? expiresAt,
  bool expired = false,
  String? url,
  bool withoutUrl = false,
}) => ManagerInvitation(
  createdAt: createdAt ?? DateTime.utc(2026, 10, 18, 12),
  expiresAt: expiresAt ?? DateTime.utc(2026, 10, 25, 12),
  expired: expired,
  url: withoutUrl || (expired && url == null)
      ? null
      : url ?? 'https://niscala.example/undangan/abc123',
);

/// A [Manager] with sensible defaults: not activated, no email, assigned to
/// Kos Melati, with a valid invitation.
///
/// Without [invitation] a not activated manager gets [makeManagerInvitation]
/// and an active one gets none. Set [withoutInvitation] to force none.
Manager makeManager({
  String id = 'm1',
  String name = 'Rina Putri',
  String? nickname,
  String phone = '081255204471',
  String? email,
  ManagerAccountStatus accountStatus = ManagerAccountStatus.notActivated,
  ManagerInvitation? invitation,
  bool withoutInvitation = false,
  List<ManagerProperty>? properties,
}) => Manager(
  id: id,
  name: name,
  nickname: nickname,
  phone: phone,
  email: email,
  accountStatus: accountStatus,
  invitation: withoutInvitation
      ? null
      : invitation ??
            (accountStatus == ManagerAccountStatus.notActivated
                ? makeManagerInvitation()
                : null),
  properties: properties ?? [makeManagerProperty()],
);

/// The list entry of [manager].
ManagerSummary managerSummaryOf(Manager manager) => ManagerSummary(
  id: manager.id,
  name: manager.name,
  nickname: manager.nickname,
  phone: manager.phone,
  email: manager.email,
  accountStatus: manager.accountStatus,
  properties: manager.properties,
);

/// A [ManagerRepository] that keeps the managers in memory and records its
/// calls.
///
/// [list] returns summaries of the [managers] assigned to the property (all of
/// them without a property). [create] adds a not activated manager only when
/// the call succeeds, with the invitation url
/// `https://niscala.example/undangan/<id>` (none when
/// [createWithoutInvitation] is set); its properties come from [catalog].
/// [update] replaces name, nickname, phone and properties of a manager.
/// [delete] removes it. [regenerateInvitation] fails with
/// `MANAGER_ALREADY_ACTIVE` for an active manager and otherwise gives the
/// manager a new valid invitation with the url
/// `https://niscala.example/undangan/<id>-<n>`, where n counts the
/// regenerations. [get], [update], [delete] and [regenerateInvitation] fail
/// with `MANAGER_NOT_FOUND` for an unknown id. Script failures and gates per
/// method with the `*Script` fields. Every call is also appended to [calls] in
/// order, as `list:<propertyId>` (empty without a property), `get:<id>`,
/// `create`, `update:<id>`, `delete:<id>` or `regenerate:<id>`.
class FakeManagerRepository implements ManagerRepository {
  FakeManagerRepository({
    List<Manager>? managers,
    List<ManagerProperty>? catalog,
  }) : managers = managers ?? [],
       catalog = catalog ?? makeManagerCatalog();

  final List<Manager> managers;
  final List<ManagerProperty> catalog;

  /// Whether [create] returns a manager without an invitation.
  bool createWithoutInvitation = false;

  final calls = <String>[];
  final created = <ManagerInput>[];
  final updated = <({String id, ManagerInput input})>[];
  final deleted = <String>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final createScript = CallScript();
  final updateScript = CallScript();
  final deleteScript = CallScript();
  final regenerateScript = CallScript();

  var _nextId = 1;
  var _regenerations = 0;

  int get listCalls => calls.where((c) => c.startsWith('list:')).length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;
  int get regenerateCalls =>
      calls.where((c) => c.startsWith('regenerate:')).length;

  int _indexOf(String id) {
    final index = managers.indexWhere((m) => m.id == id);
    if (index < 0) throw const ApiFailure(code: 'MANAGER_NOT_FOUND');
    return index;
  }

  List<ManagerProperty> _propertiesOf(List<String> ids) => [
    for (final id in ids)
      catalog.firstWhere(
        (p) => p.id == id,
        orElse: () => makeManagerProperty(id: id, name: id, address: ''),
      ),
  ];

  @override
  Future<List<ManagerSummary>> list({String? propertyId}) async {
    calls.add('list:${propertyId ?? ''}');
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final m in managers)
        if (propertyId == null || m.properties.any((p) => p.id == propertyId))
          managerSummaryOf(m),
    ];
  }

  @override
  Future<Manager> get(String managerId) async {
    calls.add('get:$managerId');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return managers[_indexOf(managerId)];
  }

  @override
  Future<Manager> create(ManagerInput input) async {
    calls.add('create');
    created.add(input);
    final failure = await createScript.next();
    if (failure != null) throw failure;
    final id = 'new-${_nextId++}';
    final manager = Manager(
      id: id,
      name: input.name,
      nickname: input.nickname,
      phone: input.phone,
      accountStatus: ManagerAccountStatus.notActivated,
      invitation: createWithoutInvitation
          ? null
          : makeManagerInvitation(url: 'https://niscala.example/undangan/$id'),
      properties: _propertiesOf(input.propertyIds),
    );
    managers.add(manager);
    return manager;
  }

  @override
  Future<Manager> update(String managerId, ManagerInput input) async {
    calls.add('update:$managerId');
    updated.add((id: managerId, input: input));
    final failure = await updateScript.next();
    if (failure != null) throw failure;
    final index = _indexOf(managerId);
    final old = managers[index];
    return managers[index] = Manager(
      id: old.id,
      name: input.name,
      nickname: input.nickname,
      phone: input.phone,
      email: old.email,
      accountStatus: old.accountStatus,
      invitation: old.invitation,
      properties: _propertiesOf(input.propertyIds),
    );
  }

  @override
  Future<void> delete(String managerId) async {
    calls.add('delete:$managerId');
    deleted.add(managerId);
    final failure = await deleteScript.next();
    if (failure != null) throw failure;
    managers.removeAt(_indexOf(managerId));
  }

  @override
  Future<ManagerInvitation> regenerateInvitation(String managerId) async {
    calls.add('regenerate:$managerId');
    final failure = await regenerateScript.next();
    if (failure != null) throw failure;
    final index = _indexOf(managerId);
    final old = managers[index];
    if (old.accountStatus == ManagerAccountStatus.active) {
      throw const ApiFailure(code: 'MANAGER_ALREADY_ACTIVE');
    }
    final invitation = makeManagerInvitation(
      url: 'https://niscala.example/undangan/$managerId-${++_regenerations}',
    );
    managers[index] = Manager(
      id: old.id,
      name: old.name,
      nickname: old.nickname,
      phone: old.phone,
      email: old.email,
      accountStatus: old.accountStatus,
      invitation: invitation,
      properties: old.properties,
    );
    return invitation;
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

/// An [InvitationAcceptancePreview] with sensible defaults: Andi Pengguna,
/// a Manager, may accept a valid Manager invitation from Siti Pemilik.
///
/// Without [canAccept] the invitation can be accepted exactly when it is valid
/// and there is no [blocker].
InvitationAcceptancePreview makeAcceptancePreview({
  InvitationPreview? invitation,
  String accountName = 'Andi Pengguna',
  String accountEmail = 'andi@example.com',
  UserRole accountRole = UserRole.manager,
  InvitationBlocker? blocker,
  ActiveLeaseSummary? activeLease,
  bool? canAccept,
}) {
  final shown =
      invitation ??
      makeInvitationPreview(role: InvitationRole.manager, roomNumber: null);
  return InvitationAcceptancePreview(
    invitation: shown,
    accountName: accountName,
    accountEmail: accountEmail,
    accountRole: accountRole,
    blocker: blocker,
    activeLease: activeLease,
    canAccept:
        canAccept ??
        (shown.status == InvitationLinkStatus.valid && blocker == null),
  );
}

/// An [InvitationRepository] that records its calls and answers from fields.
///
/// Set [previewFailure], [activateFailure], [previewAcceptanceFailure] or
/// [acceptFailure] to make that method throw. Set [previewGate],
/// [activateGate], [previewAcceptanceGate] or [acceptGate] to hold that method
/// in flight until it completes.
class FakeInvitationRepository implements InvitationRepository {
  final acceptancePreviews = <String>[];
  final acceptances = <String>[];

  InvitationAcceptancePreview previewAcceptanceResult = makeAcceptancePreview();
  ApiFailure? previewAcceptanceFailure;
  ApiFailure? acceptFailure;
  Completer<void>? previewAcceptanceGate;
  Completer<void>? acceptGate;

  @override
  Future<InvitationAcceptancePreview> previewAcceptance(String token) async {
    acceptancePreviews.add(token);
    await previewAcceptanceGate?.future;
    if (previewAcceptanceFailure != null) throw previewAcceptanceFailure!;
    return previewAcceptanceResult;
  }

  @override
  Future<void> accept(String token) async {
    acceptances.add(token);
    await acceptGate?.future;
    if (acceptFailure != null) throw acceptFailure!;
  }

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
/// [classifiedByName] it is an AI result. [originalAiClassification] is the AI
/// result that a manual classification replaced.
ComplaintClassification makeComplaintClassification({
  String category = 'Pipa dan air',
  ComplaintUrgency urgency = ComplaintUrgency.medium,
  String? suggestedAction = 'Panggil tukang ledeng.',
  String? classifiedByName,
  AiComplaintClassification? originalAiClassification,
}) => ComplaintClassification(
  category: category,
  urgency: urgency,
  suggestedAction: suggestedAction,
  classifiedByName: classifiedByName,
  originalAiClassification: originalAiClassification,
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
/// `get:<id>`, `submit` or `status:<id>`.
///
/// [changeStatus] moves the complaint to the asked status only when the call
/// succeeds, and appends a status change at [statusChangedAt] carrying the
/// handling note. Every call is recorded in [statusChanged] as given, before
/// the script is consulted.
///
/// [categories] returns [categoryList] and is recorded as `categories` in
/// [calls]. [classify] records the call in [classified] as given, then, when it
/// succeeds, sets a manual classification by [classifierName] with no suggested
/// action and no classification state, and keeps the AI result it replaces as
/// the original AI classification. Asking for the values the complaint already
/// has changes nothing, as the API does. It is recorded as `classify:<id>`.
class FakeComplaintRepository implements ComplaintRepository {
  FakeComplaintRepository({List<Complaint>? complaints})
    : complaints = complaints ?? [];

  final List<Complaint> complaints;

  final calls = <String>[];
  final submitted = <String>[];
  final statusChanged =
      <({String id, ComplaintStatus status, String? handlingNote})>[];
  final classified =
      <({String id, String category, ComplaintUrgency urgency})>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final submitScript = CallScript();
  final changeStatusScript = CallScript();
  final categoriesScript = CallScript();
  final classifyScript = CallScript();

  /// The categories that [categories] returns.
  List<String> categoryList = ['Pipa dan air', 'Listrik', 'Furnitur'];

  /// The name of the management user that [classify] records as its author.
  String classifierName = 'Siti Pemilik';

  /// The time of the status change that [changeStatus] records.
  static final statusChangedAt = DateTime.utc(2026, 10, 20, 8);

  /// The classification state of a complaint saved by [submit]. Null means
  /// classified: [submitClassification] is returned instead.
  ComplaintClassificationState? submitState =
      ComplaintClassificationState.classifying;
  ComplaintClassification? submitClassification;

  var _nextId = 1;

  int get listCalls => calls.where((c) => c == 'list').length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;
  int get submitCalls => calls.where((c) => c == 'submit').length;
  int get statusCalls => calls.where((c) => c.startsWith('status:')).length;
  int get categoriesCalls => calls.where((c) => c == 'categories').length;
  int get classifyCalls => calls.where((c) => c.startsWith('classify:')).length;

  @override
  Future<List<String>> categories() async {
    calls.add('categories');
    final failure = await categoriesScript.next();
    if (failure != null) throw failure;
    return List.of(categoryList);
  }

  @override
  Future<Complaint> classify(
    String complaintId, {
    required String category,
    required ComplaintUrgency urgency,
  }) async {
    calls.add('classify:$complaintId');
    classified.add((id: complaintId, category: category, urgency: urgency));
    final failure = await classifyScript.next();
    if (failure != null) throw failure;
    final index = complaints.indexWhere((c) => c.id == complaintId);
    if (index < 0) throw const ApiFailure(code: 'COMPLAINT_NOT_FOUND');
    final old = complaints[index];
    final current = old.classification;
    if (current != null &&
        current.category == category &&
        current.urgency == urgency) {
      return old;
    }
    final original =
        current?.originalAiClassification ??
        (current != null && current.classifiedByName == null
            ? AiComplaintClassification(
                category: current.category,
                suggestedAction: current.suggestedAction ?? '',
                urgency: current.urgency,
              )
            : null);
    return complaints[index] = Complaint(
      id: old.id,
      description: old.description,
      status: old.status,
      classification: ComplaintClassification(
        category: category,
        urgency: urgency,
        classifiedByName: classifierName,
        originalAiClassification: original,
      ),
      classificationState: null,
      classificationWithheld: false,
      createdAt: old.createdAt,
      hasPhoto: old.hasPhoto,
      property: old.property,
      room: old.room,
      statusChanges: old.statusChanges,
      tenantName: old.tenantName,
    );
  }

  @override
  Future<Complaint> changeStatus(
    String complaintId,
    ComplaintStatus status, {
    String? handlingNote,
  }) async {
    calls.add('status:$complaintId');
    statusChanged.add((
      id: complaintId,
      status: status,
      handlingNote: handlingNote,
    ));
    final failure = await changeStatusScript.next();
    if (failure != null) throw failure;
    final index = complaints.indexWhere((c) => c.id == complaintId);
    if (index < 0) throw const ApiFailure(code: 'COMPLAINT_NOT_FOUND');
    final old = complaints[index];
    return complaints[index] = Complaint(
      id: old.id,
      description: old.description,
      status: status,
      classification: old.classification,
      classificationState: old.classificationState,
      classificationWithheld: old.classificationWithheld,
      createdAt: old.createdAt,
      hasPhoto: old.hasPhoto,
      property: old.property,
      room: old.room,
      statusChanges: [
        ...old.statusChanges,
        ComplaintStatusChange(
          status: status,
          changedAt: statusChangedAt,
          handlingNote: handlingNote,
        ),
      ],
      tenantName: old.tenantName,
    );
  }

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
/// none. The bill belongs to tenant `t1` in room `r1` of property `p1` unless
/// given. [statusChanges] is oldest first.
RentBill makeRentBill({
  String id = 'b1',
  String propertyId = 'p1',
  String tenantId = 't1',
  String roomId = 'r1',
  String tenantName = 'Budi Santoso',
  String roomNumber = '08',
  String propertyName = 'Kos Melati',
  PaymentMethod? method,
  DateTime? paidOn,
  List<PaymentStatusChange> statusChanges = const [],
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
      method: method,
      paidOn: paidOn,
    ),
    property: PropertyRef(id: propertyId, name: propertyName),
    room: RoomRef(id: roomId, number: roomNumber),
    tenant: TenantRef(id: tenantId, name: tenantName),
    statusChanges: statusChanges,
    isCurrent: isCurrent,
    canUploadReceipt: canUploadReceipt ?? (account != null && open),
  );
}

/// A [PaymentStatusChange] with sensible defaults: a manual change to
/// [status] by Siti Pemilik on 6 Nov 2026 at 03:00 UTC.
PaymentStatusChange makePaymentStatusChange({
  PaymentStatus status = PaymentStatus.paid,
  DateTime? changedAt,
  String? actorName = 'Siti Pemilik',
  bool manual = true,
  PaymentMethod? method,
  String? reason,
}) => PaymentStatusChange(
  status: status,
  changedAt: changedAt ?? DateTime.utc(2026, 11, 6, 3),
  actorName: actorName,
  manual: manual,
  method: method,
  reason: reason,
);

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

/// A [PaymentOverviewItem] with sensible defaults: Budi Santoso (tenant `t1`)
/// in room 08. Without [bill] the tenant has no bill on the date.
PaymentOverviewItem makeOverviewItem({
  String tenantId = 't1',
  String tenantName = 'Budi Santoso',
  String roomId = 'r1',
  String roomNumber = '08',
  RentBillSummary? bill,
}) => PaymentOverviewItem(
  tenant: TenantRef(id: tenantId, name: tenantName),
  room: RoomRef(id: roomId, number: roomNumber),
  bill: bill,
);

/// A [PaymentPattern] with sensible defaults: Budi Santoso (tenant `t1`) in room
/// 08, on time for 5 of 6 counted bills, 1 day late on average, no arrears, not
/// at risk, without a summary and with the summary not withheld.
PaymentPattern makePaymentPattern({
  String tenantId = 't1',
  String tenantName = 'Budi Santoso',
  String roomId = 'r1',
  String roomNumber = '08',
  int onTimeCount = 5,
  int countedBillCount = 6,
  int averageDaysLate = 1,
  int arrears = 0,
  bool atRisk = false,
  String? summary,
  bool summaryWithheld = false,
}) => PaymentPattern(
  tenant: TenantRef(id: tenantId, name: tenantName),
  room: RoomRef(id: roomId, number: roomNumber),
  onTimeCount: onTimeCount,
  countedBillCount: countedBillCount,
  averageDaysLate: averageDaysLate,
  arrears: arrears,
  atRisk: atRisk,
  summary: summary,
  summaryWithheld: summaryWithheld,
);

/// The key under which [FakeManagementRentBillRepository.itemsOnDate] holds the
/// items of [propertyId] on the calendar day [date].
String overviewKey(String propertyId, DateTime date) =>
    '$propertyId@${date.year}-${date.month}-${date.day}';

/// A [ManagementRentBillRepository] that answers from memory and records its
/// calls.
///
/// [overview] returns the entry of [items] for the property, or the entry of
/// [itemsOnDate] (see [overviewKey]) when the call asks for a date that has
/// one, and fails with `PROPERTY_NOT_FOUND` for a property in neither. The
/// returned overview carries the asked date, or today. [list] returns summaries
/// of the [bills] that match the property, the tenant and the statuses asked
/// for (all of them when not asked), in their order. Script failures and gates
/// per method with the `*Script` fields. Every call is also appended to
/// [calls] in order, as `overview:<propertyId>`, `bills:<propertyId>:<tenantId>`,
/// `verify:<id>`, `reject:<id>` or `cash:<id>`.
///
/// [recordCashPayment] changes the bill in [bills] only when the call
/// succeeds, after the scripted outcome: a bill that is not in [bills] fails
/// with `RENT_BILL_NOT_FOUND` (404), and a bill that is neither unpaid nor
/// rejected fails with `RENT_BILL_NOT_PAYABLE` (409). It makes the bill paid in
/// cash on the calendar day of the date received, without a receipt, appends a
/// status change made by [reviewerName] at [reviewedAt] and replaces the bill
/// in the overview entries, as the review methods do.
///
/// [verifyReceipt] and [rejectReceipt] change the bill in [bills] only when the
/// call succeeds, after the scripted outcome: a bill that is not in [bills]
/// fails with `RENT_BILL_NOT_FOUND` (404), and a bill whose status is not
/// awaiting verification fails with `RENT_BILL_NOT_AWAITING_VERIFICATION`
/// (409). Verifying makes the bill paid by transfer on the calendar day of
/// [reviewedAt]; rejecting makes it rejected with the given reason and keeps
/// its receipt. Both append a status change made by [reviewerName] at
/// [reviewedAt], and replace the bill of the same id in the entries of
/// [items] and [itemsOnDate]. The list passed as `bills` can be shared with a
/// `FakeRentBillRepository`, so that both see the change.
///
/// [changePaymentStatus] is recorded as `change:<id>` in [calls] and in
/// [statusChangeRequests], then validates like the backend, in this order,
/// after the scripted outcome: a bill that is not in [bills] fails with
/// `RENT_BILL_NOT_FOUND` (404); a blank reason with `REASON_REQUIRED` (422,
/// field `reason`); the status the bill already has with `STATUS_UNCHANGED`
/// (422, field `status`); awaiting verification as the target with
/// `VALIDATION_FAILED` (422, field `status`); a paid target without a method or
/// without a date received with `VALIDATION_FAILED` (422, field `method` or
/// `receivedOn`); a date received after today with `RECEIVED_ON_IN_FUTURE`
/// (422, field `receivedOn`). On success the bill takes the new status: paid
/// carries the method and the calendar day received and no rejection reason,
/// rejected carries the reason as its rejection reason, unpaid carries neither.
/// A status change made by [reviewerName] at [reviewedAt], carrying the reason
/// (and the method for paid), is appended, and the bill is replaced in the
/// overview entries as the review methods do.
///
/// [paymentPatterns] returns the entry of [patterns] for the property, in
/// order, and fails with `PROPERTY_NOT_FOUND` for a property without one. It is
/// recorded as `patterns:<propertyId>` in [calls] and scripted with
/// [patternsScript].
class FakeManagementRentBillRepository implements ManagementRentBillRepository {
  FakeManagementRentBillRepository({
    Map<String, List<PaymentOverviewItem>>? items,
    Map<String, List<PaymentOverviewItem>>? itemsOnDate,
    List<RentBill>? bills,
    Map<String, List<PaymentPattern>>? patterns,
  }) : items = items ?? {},
       itemsOnDate = itemsOnDate ?? {},
       bills = bills ?? [],
       patterns = patterns ?? {};

  final Map<String, List<PaymentOverviewItem>> items;
  final Map<String, List<PaymentOverviewItem>> itemsOnDate;
  final List<RentBill> bills;
  final Map<String, List<PaymentPattern>> patterns;

  final calls = <String>[];

  final patternsScript = CallScript();

  int get patternCalls => calls.where((c) => c.startsWith('patterns:')).length;

  @override
  Future<List<PaymentPattern>> paymentPatterns(String propertyId) async {
    calls.add('patterns:$propertyId');
    final failure = await patternsScript.next();
    if (failure != null) throw failure;
    final found = patterns[propertyId];
    if (found == null) throw const ApiFailure(code: 'PROPERTY_NOT_FOUND');
    return List.of(found);
  }

  /// The date of every [overview] call, in order; null when it asked for none.
  final overviewDates = <DateTime?>[];

  /// The arguments of every [list] call, in order.
  final listed =
      <
        ({String? propertyId, String? tenantId, List<PaymentStatus>? statuses})
      >[];

  final overviewScript = CallScript();
  final listScript = CallScript();
  final verifyScript = CallScript();
  final rejectScript = CallScript();
  final cashScript = CallScript();
  final changeScript = CallScript();

  /// The arguments of every [changePaymentStatus] call, in order, whether it
  /// succeeded or not.
  final statusChangeRequests =
      <
        ({
          String id,
          PaymentStatus status,
          String reason,
          PaymentMethod? method,
          DateTime? receivedOn,
        })
      >[];

  int get changeCalls => calls.where((c) => c.startsWith('change:')).length;

  /// The time and the person of every successful verification, rejection, cash
  /// payment or manual status change.
  DateTime reviewedAt = DateTime.utc(2026, 11, 7, 12);
  String reviewerName = 'Siti Pemilik';

  /// The ids of every [verifyReceipt] call, in order, whether it succeeded or
  /// not.
  final verified = <String>[];

  /// The arguments of every [rejectReceipt] call, in order.
  final rejected = <({String id, String reason})>[];

  /// The arguments of every [recordCashPayment] call, in order, whether it
  /// succeeded or not.
  final cashPayments = <({String id, DateTime receivedOn})>[];

  int get cashCalls => calls.where((c) => c.startsWith('cash:')).length;

  /// How many [list] calls asked for exactly the payable statuses.
  int get payableListCalls => listed
      .where(
        (call) =>
            call.statuses != null &&
            call.statuses!.length == 2 &&
            call.statuses!.contains(PaymentStatus.unpaid) &&
            call.statuses!.contains(PaymentStatus.rejected),
      )
      .length;

  /// How many [list] calls asked for exactly the bills awaiting verification.
  int get verificationListCalls => listed
      .where(
        (call) =>
            call.statuses != null &&
            call.statuses!.length == 1 &&
            call.statuses!.single == PaymentStatus.awaitingVerification,
      )
      .length;

  /// How many [list] calls asked for the bills of the tenant.
  int tenantListCalls(String tenantId) =>
      listed.where((call) => call.tenantId == tenantId).length;

  int get overviewCalls => calls.where((c) => c.startsWith('overview:')).length;
  int get listCalls => calls.where((c) => c.startsWith('bills:')).length;
  int get verifyCalls => calls.where((c) => c.startsWith('verify:')).length;
  int get rejectCalls => calls.where((c) => c.startsWith('reject:')).length;

  /// Replaces the bill with the id by the result of [change], in [bills] and
  /// in the overview entries, after checking it awaits verification.
  RentBill _review(
    String id,
    Payment Function(RentBill old) payment,
    PaymentStatusChange change, {
    Set<PaymentStatus> from = const {PaymentStatus.awaitingVerification},
    String conflictCode = 'RENT_BILL_NOT_AWAITING_VERIFICATION',
  }) {
    final index = bills.indexWhere((b) => b.id == id);
    if (index < 0) {
      throw const ApiFailure(code: 'RENT_BILL_NOT_FOUND', statusCode: 404);
    }
    final old = bills[index];
    if (!from.contains(old.payment.status)) {
      throw ApiFailure(code: conflictCode, statusCode: 409);
    }
    final updated = RentBill(
      id: old.id,
      amount: old.amount,
      daysOverdue: old.daysOverdue,
      dueDate: old.dueDate,
      periodStart: old.periodStart,
      periodEnd: old.periodEnd,
      bankAccount: old.bankAccount,
      payment: payment(old),
      property: old.property,
      room: old.room,
      tenant: old.tenant,
      statusChanges: [...old.statusChanges, change],
      isCurrent: old.isCurrent,
      canUploadReceipt:
          (change.status == PaymentStatus.rejected ||
              change.status == PaymentStatus.unpaid) &&
          old.bankAccount != null,
    );
    bills[index] = updated;
    for (final entries in [...items.values, ...itemsOnDate.values]) {
      for (var i = 0; i < entries.length; i++) {
        final item = entries[i];
        if (item.bill?.id == id) {
          entries[i] = PaymentOverviewItem(
            tenant: item.tenant,
            room: item.room,
            bill: rentBillSummaryOf(updated),
          );
        }
      }
    }
    return updated;
  }

  @override
  Future<RentBill> verifyReceipt(String billId) async {
    calls.add('verify:$billId');
    verified.add(billId);
    final failure = await verifyScript.next();
    if (failure != null) throw failure;
    return _review(
      billId,
      (old) => Payment(
        status: PaymentStatus.paid,
        hasReceipt: old.payment.hasReceipt,
        method: PaymentMethod.transfer,
        paidOn: DateTime.utc(reviewedAt.year, reviewedAt.month, reviewedAt.day),
      ),
      PaymentStatusChange(
        status: PaymentStatus.paid,
        changedAt: reviewedAt,
        actorName: reviewerName,
        manual: true,
        method: PaymentMethod.transfer,
      ),
    );
  }

  @override
  Future<RentBill> rejectReceipt(String billId, String reason) async {
    calls.add('reject:$billId');
    rejected.add((id: billId, reason: reason));
    final failure = await rejectScript.next();
    if (failure != null) throw failure;
    return _review(
      billId,
      (old) => Payment(
        status: PaymentStatus.rejected,
        hasReceipt: old.payment.hasReceipt,
        rejectionReason: reason,
      ),
      PaymentStatusChange(
        status: PaymentStatus.rejected,
        changedAt: reviewedAt,
        actorName: reviewerName,
        manual: true,
        reason: reason,
      ),
    );
  }

  @override
  Future<RentBill> recordCashPayment(String billId, DateTime receivedOn) async {
    calls.add('cash:$billId');
    cashPayments.add((id: billId, receivedOn: receivedOn));
    final failure = await cashScript.next();
    if (failure != null) throw failure;
    return _review(
      billId,
      (old) => Payment(
        status: PaymentStatus.paid,
        hasReceipt: false,
        method: PaymentMethod.cash,
        paidOn: DateTime.utc(receivedOn.year, receivedOn.month, receivedOn.day),
      ),
      PaymentStatusChange(
        status: PaymentStatus.paid,
        changedAt: reviewedAt,
        actorName: reviewerName,
        manual: true,
        method: PaymentMethod.cash,
      ),
      from: const {PaymentStatus.unpaid, PaymentStatus.rejected},
      conflictCode: 'RENT_BILL_NOT_PAYABLE',
    );
  }

  @override
  Future<RentBill> changePaymentStatus(
    String billId, {
    required PaymentStatus status,
    required String reason,
    PaymentMethod? method,
    DateTime? receivedOn,
  }) async {
    calls.add('change:$billId');
    statusChangeRequests.add((
      id: billId,
      status: status,
      reason: reason,
      method: method,
      receivedOn: receivedOn,
    ));
    final failure = await changeScript.next();
    if (failure != null) throw failure;
    final old = bills.firstWhere(
      (b) => b.id == billId,
      orElse: () =>
          throw const ApiFailure(code: 'RENT_BILL_NOT_FOUND', statusCode: 404),
    );
    ApiFailure invalid(String field) =>
        ApiFailure(code: 'VALIDATION_FAILED', field: field, statusCode: 422);
    if (reason.trim().isEmpty) {
      throw const ApiFailure(
        code: 'REASON_REQUIRED',
        field: 'reason',
        statusCode: 422,
      );
    }
    if (status == old.payment.status) {
      throw const ApiFailure(
        code: 'STATUS_UNCHANGED',
        field: 'status',
        statusCode: 422,
      );
    }
    if (status == PaymentStatus.awaitingVerification) throw invalid('status');
    final paid = status == PaymentStatus.paid;
    if (paid && method == null) throw invalid('method');
    if (paid && receivedOn == null) throw invalid('receivedOn');
    DateTime? paidOn;
    if (paid) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(receivedOn!.year, receivedOn.month, receivedOn.day);
      if (day.isAfter(today)) {
        throw const ApiFailure(
          code: 'RECEIVED_ON_IN_FUTURE',
          field: 'receivedOn',
          statusCode: 422,
        );
      }
      paidOn = DateTime.utc(day.year, day.month, day.day);
    }
    return _review(
      billId,
      (old) => Payment(
        status: status,
        hasReceipt: old.payment.hasReceipt,
        rejectionReason: status == PaymentStatus.rejected ? reason : null,
        method: paid ? method : null,
        paidOn: paidOn,
      ),
      PaymentStatusChange(
        status: status,
        changedAt: reviewedAt,
        actorName: reviewerName,
        manual: true,
        method: paid ? method : null,
        reason: reason,
      ),
      from: PaymentStatus.values.toSet(),
    );
  }

  @override
  Future<PaymentOverview> overview(String propertyId, {DateTime? date}) async {
    calls.add('overview:$propertyId');
    overviewDates.add(date);
    final failure = await overviewScript.next();
    if (failure != null) throw failure;
    final onDate = date == null
        ? null
        : itemsOnDate[overviewKey(propertyId, date)];
    final found = onDate ?? items[propertyId];
    if (found == null) throw const ApiFailure(code: 'PROPERTY_NOT_FOUND');
    return PaymentOverview(date: date ?? DateTime.now(), items: List.of(found));
  }

  @override
  Future<List<RentBillSummary>> list({
    String? propertyId,
    String? tenantId,
    List<PaymentStatus>? statuses,
  }) async {
    calls.add('bills:${propertyId ?? ''}:${tenantId ?? ''}');
    listed.add((
      propertyId: propertyId,
      tenantId: tenantId,
      statuses: statuses == null ? null : List.of(statuses),
    ));
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final b in bills)
        if ((propertyId == null || b.property.id == propertyId) &&
            (tenantId == null || b.tenant.id == tenantId) &&
            (statuses == null ||
                statuses.isEmpty ||
                statuses.contains(b.payment.status)))
          rentBillSummaryOf(b),
    ];
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

/// An [Account] with sensible defaults: Andi Pengguna, an owner who signs in
/// with a password.
Account makeAccount({
  String id = 'account-1',
  String name = 'Andi Pengguna',
  String email = 'andi@example.com',
  UserRole role = UserRole.owner,
  bool emailVerified = true,
  String? googleEmail,
  bool hasPassword = true,
}) => Account(
  id: id,
  name: name,
  email: email,
  emailVerified: emailVerified,
  googleEmail: googleEmail,
  hasPassword: hasPassword,
  role: role,
);

/// A [Session] of another Android device unless given, last active 18 Okt 2026
/// at 12:00 UTC.
Session makeSession({
  String id = 's1',
  String deviceName = 'Galaxy A54',
  String platform = 'Android',
  LoginMethod loginMethod = LoginMethod.password,
  DateTime? lastActiveAt,
  bool isCurrent = false,
}) => Session(
  id: id,
  deviceName: deviceName,
  platform: platform,
  loginMethod: loginMethod,
  lastActiveAt: lastActiveAt ?? DateTime.utc(2026, 10, 18, 12),
  isCurrent: isCurrent,
);

/// An [AccountRepository] that keeps the sessions in memory and records its
/// calls.
///
/// Without [devices] the account has only its current session, Pixel 8.
/// [sessions] returns [devices] in their order. [endSession] and
/// [endOtherSessions] change [devices] only when the call succeeds;
/// [endSession] fails with `SESSION_NOT_FOUND` for an unknown id and with
/// `SESSION_IS_CURRENT` for the current session. Script failures and gates per
/// method with the `*Script` fields. Every call is also appended to [calls] in
/// order, as `me`, `sessions`, `end:<id>`, `endOthers` or `changePassword`.
///
/// [changePassword] records the passwords it receives in [passwordChanges] and
/// returns whether the account has other devices, unless [hasOtherSessions]
/// says otherwise. It does not check the current password: script
/// `changePasswordScript` to fail it.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({Account? account, List<Session>? devices})
    : account = account ?? makeAccount(),
      devices =
          devices ??
          [
            makeSession(
              id: 'current',
              deviceName: 'Pixel 8',
              loginMethod: LoginMethod.google,
              isCurrent: true,
            ),
          ];

  Account account;
  final List<Session> devices;

  final calls = <String>[];

  final meScript = CallScript();
  final sessionsScript = CallScript();
  final endScript = CallScript();
  final endOthersScript = CallScript();
  final changePasswordScript = CallScript();

  /// The passwords of every [changePassword] call, in order.
  final passwordChanges = <({String currentPassword, String newPassword})>[];

  /// What [changePassword] returns. Null means: whether [devices] holds a
  /// device other than the current one.
  bool? hasOtherSessions;

  int get changePasswordCalls =>
      calls.where((c) => c == 'changePassword').length;

  int get meCalls => calls.where((c) => c == 'me').length;
  int get sessionsCalls => calls.where((c) => c == 'sessions').length;
  int get endCalls => calls.where((c) => c.startsWith('end:')).length;
  int get endOthersCalls => calls.where((c) => c == 'endOthers').length;

  @override
  Future<Account> me() async {
    calls.add('me');
    final failure = await meScript.next();
    if (failure != null) throw failure;
    return account;
  }

  @override
  Future<List<Session>> sessions() async {
    calls.add('sessions');
    final failure = await sessionsScript.next();
    if (failure != null) throw failure;
    return List.of(devices);
  }

  @override
  Future<void> endSession(String id) async {
    calls.add('end:$id');
    final failure = await endScript.next();
    if (failure != null) throw failure;
    final index = devices.indexWhere((s) => s.id == id);
    if (index < 0) {
      throw const ApiFailure(code: 'SESSION_NOT_FOUND', statusCode: 404);
    }
    if (devices[index].isCurrent) {
      throw const ApiFailure(code: 'SESSION_IS_CURRENT', statusCode: 409);
    }
    devices.removeAt(index);
  }

  @override
  Future<void> endOtherSessions() async {
    calls.add('endOthers');
    final failure = await endOthersScript.next();
    if (failure != null) throw failure;
    devices.removeWhere((s) => !s.isCurrent);
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls.add('changePassword');
    passwordChanges.add((
      currentPassword: currentPassword,
      newPassword: newPassword,
    ));
    final failure = await changePasswordScript.next();
    if (failure != null) throw failure;
    return hasOtherSessions ?? devices.any((s) => !s.isCurrent);
  }
}

/// An [OccupancyRoom] with sensible defaults: room 08, occupied.
OccupancyRoom makeOccupancyRoom({
  String id = 'r1',
  String number = '08',
  Occupancy occupancy = Occupancy.occupied,
}) => OccupancyRoom(id: id, number: number, occupancy: occupancy);

/// A [PropertyOccupancy] whose figures are exactly the ones given, whether or
/// not they agree with [rooms]: the dashboard shows what the API returns.
PropertyOccupancy makePropertyOccupancy({
  String id = 'p1',
  String name = 'Kos Melati',
  int occupiedRoomCount = 1,
  int vacantRoomCount = 1,
  int? roomCount,
  int occupancyPercentage = 50,
  List<OccupancyRoom>? rooms,
}) => PropertyOccupancy(
  id: id,
  name: name,
  occupiedRoomCount: occupiedRoomCount,
  vacantRoomCount: vacantRoomCount,
  roomCount: roomCount ?? occupiedRoomCount + vacantRoomCount,
  occupancyPercentage: occupancyPercentage,
  rooms:
      rooms ??
      [
        makeOccupancyRoom(id: 'r1', number: '01'),
        makeOccupancyRoom(id: 'r2', number: '02', occupancy: Occupancy.vacant),
      ],
);

/// An [OccupancySummary] whose figures are exactly the ones given.
OccupancySummary makeOccupancySummary({
  int propertyCount = 1,
  int occupiedRoomCount = 1,
  int vacantRoomCount = 1,
  int? roomCount,
  int occupancyPercentage = 50,
}) => OccupancySummary(
  propertyCount: propertyCount,
  occupiedRoomCount: occupiedRoomCount,
  vacantRoomCount: vacantRoomCount,
  roomCount: roomCount ?? occupiedRoomCount + vacantRoomCount,
  occupancyPercentage: occupancyPercentage,
);

/// An [OccupancyDashboard]. Without [summary] it is the plain figures of one
/// property per entry of [items]; without [items] the dashboard is empty.
OccupancyDashboard makeOccupancyDashboard({
  List<PropertyOccupancy>? items,
  OccupancySummary? summary,
}) => OccupancyDashboard(
  items: items ?? const [],
  summary:
      summary ??
      makeOccupancySummary(
        propertyCount: (items ?? const []).length,
        occupiedRoomCount: 0,
        vacantRoomCount: 0,
        occupancyPercentage: 0,
      ),
);

/// A [DashboardRepository] that answers with [dashboard] (empty by default)
/// and records its calls. Script failures and a gate with [script].
class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({OccupancyDashboard? dashboard})
    : dashboard = dashboard ?? makeOccupancyDashboard();

  OccupancyDashboard dashboard;

  final script = CallScript();

  var calls = 0;

  @override
  Future<OccupancyDashboard> occupancyDashboard() async {
    calls++;
    final failure = await script.next();
    if (failure != null) throw failure;
    return dashboard;
  }
}

/// A [UserAccountSummary] with sensible defaults: Budi Santoso, an active
/// tenant.
UserAccountSummary makeUserAccountSummary({
  String id = 'u1',
  String name = 'Budi Santoso',
  String email = 'budi@example.com',
  UserRole role = UserRole.tenant,
  UserAccountStatus status = UserAccountStatus.active,
}) => UserAccountSummary(
  id: id,
  name: name,
  email: email,
  role: role,
  status: status,
);

/// A [UserAccount] with sensible defaults: Budi Santoso, an active tenant with
/// a password, registered on 18 Okt 2026 and last signed in on 19 Okt 2026
/// (both at 12:00 UTC), with no pending email, properties or tenancy.
///
/// Set [neverLoggedIn] to leave out the last login.
UserAccount makeUserAccount({
  String id = 'u1',
  String name = 'Budi Santoso',
  String email = 'budi@example.com',
  UserRole role = UserRole.tenant,
  UserAccountStatus status = UserAccountStatus.active,
  int activeLeaseCount = 0,
  DateTime? registeredAt,
  DateTime? lastLoginAt,
  bool neverLoggedIn = false,
  List<LoginMethod> loginMethods = const [LoginMethod.password],
  String? pendingEmail,
  DateTime? pendingEmailExpiresAt,
  List<AccountPropertyRef> properties = const [],
  AccountTenancy? tenancy,
}) => UserAccount(
  id: id,
  name: name,
  email: email,
  role: role,
  status: status,
  activeLeaseCount: activeLeaseCount,
  registeredAt: registeredAt ?? DateTime.utc(2026, 10, 18, 12),
  lastLoginAt: neverLoggedIn
      ? null
      : lastLoginAt ?? DateTime.utc(2026, 10, 19, 12),
  loginMethods: loginMethods,
  pendingEmail: pendingEmail,
  pendingEmailExpiresAt: pendingEmailExpiresAt,
  properties: properties,
  tenancy: tenancy,
);

/// A [UserAccountRepository] that keeps the accounts in memory and records its
/// calls.
///
/// [list] filters like the API: [email] matches any part of the email without
/// regard to case, [role] matches the role, and deleted accounts are left out
/// unless [includeDeleted] is set. It returns summaries in the order of
/// [accounts]. [get] returns the account with the id or fails with
/// `USER_ACCOUNT_NOT_FOUND`. Script failures and gates per method with the
/// `*Script` fields. Every call is appended to [calls] in order, as `list`,
/// `get:<id>` or `update:<id>`, every [list] call to [listed] as given and
/// every [update] call to [updated] as given, whether it succeeded or not.
///
/// [update] changes the account only when the call succeeds, like the API: it
/// fails with `USER_ACCOUNT_NOT_FOUND` for an unknown id and with
/// `USER_ACCOUNT_DELETED` for a deleted account. The name and the email are
/// trimmed and the email is lowercased. A different email does not replace the
/// current one: it becomes the pending email, valid until [pendingExpiresAt].
/// The current email cancels a pending email.
///
/// [delete] is recorded as `delete:<id>` in [calls] and its id in [deleted],
/// whether it succeeded or not. After the scripted outcome it fails with
/// `USER_ACCOUNT_NOT_FOUND` (404) for an unknown id and with
/// `USER_ACCOUNT_DELETED` (409) for a deleted account. Otherwise it marks the
/// account deleted and keeps the rest of it, as the API does.
class FakeUserAccountRepository implements UserAccountRepository {
  FakeUserAccountRepository({List<UserAccount>? accounts})
    : accounts = accounts ?? [];

  final List<UserAccount> accounts;

  /// When the link of a pending email change that [update] starts expires.
  static final pendingExpiresAt = DateTime.utc(2026, 11, 10, 12);

  final calls = <String>[];
  final listed = <({String? email, UserRole? role, bool includeDeleted})>[];
  final updated = <({String id, UserAccountInput input})>[];
  final deleted = <String>[];

  final listScript = CallScript();
  final getScript = CallScript();
  final updateScript = CallScript();
  final deleteScript = CallScript();

  int get listCalls => calls.where((c) => c == 'list').length;
  int get getCalls => calls.where((c) => c.startsWith('get:')).length;
  int get updateCalls => calls.where((c) => c.startsWith('update:')).length;
  int get deleteCalls => calls.where((c) => c.startsWith('delete:')).length;

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
    deleted.add(id);
    final failure = await deleteScript.next();
    if (failure != null) throw failure;
    final index = accounts.indexWhere((a) => a.id == id);
    if (index < 0) {
      throw const ApiFailure(code: 'USER_ACCOUNT_NOT_FOUND', statusCode: 404);
    }
    final old = accounts[index];
    if (old.status == UserAccountStatus.deleted) {
      throw const ApiFailure(code: 'USER_ACCOUNT_DELETED', statusCode: 409);
    }
    accounts[index] = makeUserAccount(
      id: old.id,
      name: old.name,
      email: old.email,
      role: old.role,
      status: UserAccountStatus.deleted,
      activeLeaseCount: old.activeLeaseCount,
      registeredAt: old.registeredAt,
      lastLoginAt: old.lastLoginAt,
      neverLoggedIn: old.lastLoginAt == null,
      loginMethods: old.loginMethods,
      pendingEmail: old.pendingEmail,
      pendingEmailExpiresAt: old.pendingEmailExpiresAt,
      properties: old.properties,
      tenancy: old.tenancy,
    );
  }

  @override
  Future<UserAccount> update(String id, UserAccountInput input) async {
    calls.add('update:$id');
    updated.add((id: id, input: input));
    final failure = await updateScript.next();
    if (failure != null) throw failure;
    final index = accounts.indexWhere((a) => a.id == id);
    if (index < 0) {
      throw const ApiFailure(code: 'USER_ACCOUNT_NOT_FOUND', statusCode: 404);
    }
    final old = accounts[index];
    if (old.status == UserAccountStatus.deleted) {
      throw const ApiFailure(code: 'USER_ACCOUNT_DELETED', statusCode: 409);
    }
    final email = input.email.trim().toLowerCase();
    final changesEmail = email != old.email.toLowerCase();
    return accounts[index] = makeUserAccount(
      id: old.id,
      name: input.name.trim(),
      email: old.email,
      role: old.role,
      status: input.status == EditableAccountStatus.active
          ? UserAccountStatus.active
          : UserAccountStatus.inactive,
      activeLeaseCount: old.activeLeaseCount,
      registeredAt: old.registeredAt,
      lastLoginAt: old.lastLoginAt,
      neverLoggedIn: old.lastLoginAt == null,
      loginMethods: old.loginMethods,
      pendingEmail: changesEmail ? email : null,
      pendingEmailExpiresAt: changesEmail ? pendingExpiresAt : null,
      properties: old.properties,
      tenancy: old.tenancy,
    );
  }

  @override
  Future<List<UserAccountSummary>> list({
    String? email,
    UserRole? role,
    bool includeDeleted = false,
  }) async {
    calls.add('list');
    listed.add((email: email, role: role, includeDeleted: includeDeleted));
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return [
      for (final a in accounts)
        if ((email == null ||
                a.email.toLowerCase().contains(email.toLowerCase())) &&
            (role == null || a.role == role) &&
            (includeDeleted || a.status != UserAccountStatus.deleted))
          makeUserAccountSummary(
            id: a.id,
            name: a.name,
            email: a.email,
            role: a.role,
            status: a.status,
          ),
    ];
  }

  @override
  Future<UserAccount> get(String id) async {
    calls.add('get:$id');
    final failure = await getScript.next();
    if (failure != null) throw failure;
    return accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => throw const ApiFailure(
        code: 'USER_ACCOUNT_NOT_FOUND',
        statusCode: 404,
      ),
    );
  }
}

/// The bill facts of a notification: November 2026 (1 to 30 Nov), Rp800.000,
/// due 5 Nov 2026, unpaid, no reason and no method, not overdue.
NotificationRentBill makeNotificationRentBill({
  String rentBillId = 'b1',
  int amount = 800000,
  int daysOverdue = 0,
  DateTime? dueDate,
  DateTime? periodStart,
  DateTime? periodEnd,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  PaymentMethod? paymentMethod,
  String? reason,
}) => NotificationRentBill(
  rentBillId: rentBillId,
  amount: amount,
  daysOverdue: daysOverdue,
  dueDate: dueDate ?? DateTime.utc(2026, 11, 5),
  periodStart: periodStart ?? DateTime.utc(2026, 11, 1),
  periodEnd: periodEnd ?? DateTime.utc(2026, 11, 30),
  paymentStatus: paymentStatus,
  paymentMethod: paymentMethod,
  reason: reason,
);

/// The complaint facts of a notification: a new complaint about a leaking tap
/// with no handling note, category or urgency.
NotificationComplaint makeNotificationComplaint({
  String complaintId = 'c1',
  String description = 'Keran air di kamar mandi bocor',
  ComplaintStatus status = ComplaintStatus.new_,
  String? handlingNote,
  String? category,
  ComplaintUrgency? urgency,
}) => NotificationComplaint(
  complaintId: complaintId,
  description: description,
  status: status,
  handlingNote: handlingNote,
  category: category,
  urgency: urgency,
);

/// A [Notification] of [type], unread, created 2 Nov 2026 at 12:00 UTC. It
/// carries only the facts given, as the API does.
Notification makeNotification({
  String id = 'n1',
  NotificationType type = NotificationType.billIssued,
  DateTime? createdAt,
  bool read = false,
  NotificationRentBill? rentBill,
  NotificationComplaint? complaint,
  TenantRef? tenant,
  RoomRef? room,
  PropertyRef? property,
  String? actorName,
}) => Notification(
  id: id,
  type: type,
  createdAt: createdAt ?? DateTime.utc(2026, 11, 2, 12),
  read: read,
  rentBill: rentBill,
  complaint: complaint,
  tenant: tenant,
  room: room,
  property: property,
  actorName: actorName,
);

/// The tenant, room and property that notifications of management name:
/// Budi Santoso in room 08 of Kos Melati.
({TenantRef tenant, RoomRef room, PropertyRef property}) makeNotificationPlace({
  String tenantName = 'Budi Santoso',
  String roomNumber = '08',
  String propertyName = 'Kos Melati',
}) => (
  tenant: TenantRef(id: 't1', name: tenantName),
  room: RoomRef(id: 'r1', number: roomNumber),
  property: PropertyRef(id: 'p1', name: propertyName),
);

/// The settings of a tenant: billing, paymentStatus and complaintProgress, all
/// on.
List<NotificationSettingItem> makeTenantNotificationSettings() => [
  NotificationSettingItem(
    category: NotificationCategory.billing,
    pushEnabled: true,
  ),
  NotificationSettingItem(
    category: NotificationCategory.paymentStatus,
    pushEnabled: true,
  ),
  NotificationSettingItem(
    category: NotificationCategory.complaintProgress,
    pushEnabled: true,
  ),
];

/// The settings of management: newComplaint (all urgencies), receiptUpload,
/// overdueBill and accountActivity, all on.
List<NotificationSettingItem> makeManagementNotificationSettings() => [
  NotificationSettingItem(
    category: NotificationCategory.newComplaint,
    pushEnabled: true,
    urgencyScope: NotificationUrgencyScope.allUrgencies,
  ),
  NotificationSettingItem(
    category: NotificationCategory.receiptUpload,
    pushEnabled: true,
  ),
  NotificationSettingItem(
    category: NotificationCategory.overdueBill,
    pushEnabled: true,
  ),
  NotificationSettingItem(
    category: NotificationCategory.accountActivity,
    pushEnabled: true,
  ),
];

NotificationSettingItem _copyOfSetting(NotificationSettingItem item) =>
    NotificationSettingItem(
      category: item.category,
      pushEnabled: item.pushEnabled,
      urgencyScope: item.urgencyScope,
    );

Notification _copyOfNotification(Notification n, {bool? read}) => Notification(
  id: n.id,
  type: n.type,
  createdAt: n.createdAt,
  read: read ?? n.read,
  rentBill: n.rentBill,
  complaint: n.complaint,
  tenant: n.tenant,
  room: n.room,
  property: n.property,
  actorName: n.actorName,
);

/// A [NotificationRepository] that keeps the notifications and the settings in
/// memory and records its calls.
///
/// [list] returns [notifications] in their order with [unreadCount], which
/// starts as the number of unread ones. [markRead] flips one notification to
/// read and decrements [unreadCount] when it was unread, and fails with
/// `NOTIFICATION_NOT_FOUND` for an unknown id. [markAllRead] flips every
/// notification and sets [unreadCount] to 0. Both change the state only when the
/// call succeeds. [add] appends a notification, as a new event does.
///
/// [settings] returns [settingItems] (the tenant categories unless given).
/// [updateSettings] records the items it receives in [updated] and, when it
/// succeeds, keeps a copy of them as the new settings and returns it. Script
/// failures and gates per method with the `*Script` fields. Every call is also
/// appended to [calls] in order, as `list`, `markRead:<id>`, `markAllRead`,
/// `settings` or `updateSettings`.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    List<Notification>? notifications,
    List<NotificationSettingItem>? settings,
  }) : notifications = notifications ?? [],
       settingItems = settings ?? makeTenantNotificationSettings() {
    unreadCount = this.notifications.where((n) => !n.read).length;
  }

  final List<Notification> notifications;
  List<NotificationSettingItem> settingItems;
  late int unreadCount;

  final calls = <String>[];
  final updated = <List<NotificationSettingItem>>[];

  final listScript = CallScript();
  final markReadScript = CallScript();
  final markAllReadScript = CallScript();
  final settingsScript = CallScript();
  final updateSettingsScript = CallScript();
  final registerPushTokenScript = CallScript();

  /// The token of every [registerPushToken] call, in order, whether it
  /// succeeded or not.
  final registeredTokens = <String>[];

  int get registerPushTokenCalls =>
      calls.where((c) => c.startsWith('registerPushToken:')).length;

  int get listCalls => calls.where((c) => c == 'list').length;
  int get markReadCalls => calls.where((c) => c.startsWith('markRead:')).length;
  int get markAllReadCalls => calls.where((c) => c == 'markAllRead').length;
  int get settingsCalls => calls.where((c) => c == 'settings').length;
  int get updateSettingsCalls =>
      calls.where((c) => c == 'updateSettings').length;

  /// Appends [notification], counting it as unread when it is.
  void add(Notification notification) {
    notifications.add(notification);
    if (!notification.read) unreadCount++;
  }

  @override
  Future<NotificationList> list() async {
    calls.add('list');
    final failure = await listScript.next();
    if (failure != null) throw failure;
    return NotificationList(
      items: [for (final n in notifications) _copyOfNotification(n)],
      unreadCount: unreadCount,
    );
  }

  @override
  Future<Notification> markRead(String notificationId) async {
    calls.add('markRead:$notificationId');
    final failure = await markReadScript.next();
    if (failure != null) throw failure;
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) {
      throw const ApiFailure(code: 'NOTIFICATION_NOT_FOUND', statusCode: 404);
    }
    if (!notifications[index].read) unreadCount--;
    return notifications[index] = _copyOfNotification(
      notifications[index],
      read: true,
    );
  }

  @override
  Future<void> markAllRead() async {
    calls.add('markAllRead');
    final failure = await markAllReadScript.next();
    if (failure != null) throw failure;
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = _copyOfNotification(notifications[i], read: true);
    }
    unreadCount = 0;
  }

  @override
  Future<void> registerPushToken(String token) async {
    calls.add('registerPushToken:$token');
    registeredTokens.add(token);
    final failure = await registerPushTokenScript.next();
    if (failure != null) throw failure;
  }

  @override
  Future<NotificationSettings> settings() async {
    calls.add('settings');
    final failure = await settingsScript.next();
    if (failure != null) throw failure;
    return NotificationSettings(
      items: [for (final item in settingItems) _copyOfSetting(item)],
    );
  }

  @override
  Future<NotificationSettings> updateSettings(
    List<NotificationSettingItem> items,
  ) async {
    calls.add('updateSettings');
    updated.add([for (final item in items) _copyOfSetting(item)]);
    final failure = await updateSettingsScript.next();
    if (failure != null) throw failure;
    settingItems = [for (final item in items) _copyOfSetting(item)];
    return NotificationSettings(
      items: [for (final item in settingItems) _copyOfSetting(item)],
    );
  }
}

/// A [PushMessaging] that never touches Firebase. It answers from fields,
/// counts its calls, and emits the events that a test triggers.
///
/// [requestPermission] returns [permissionGranted]; [token] returns
/// [currentToken]; [initialOpened] returns [initial]. The streams are broadcast
/// streams, so an event that no one listens to is dropped, as with Firebase.
/// [refreshTokenTo] makes [currentToken] the new token and emits it. [open]
/// emits a tapped push and [receiveForeground] a message that arrived while the
/// app is open.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({
    this.permissionGranted = true,
    this.currentToken,
    this.initial,
  });

  bool permissionGranted;
  String? currentToken;
  PushOpened? initial;

  var permissionRequests = 0;
  var tokenReads = 0;
  var initialOpenedReads = 0;

  final _tokenRefreshes = StreamController<String>.broadcast();
  final _opened = StreamController<PushOpened>.broadcast();
  final _foreground = StreamController<void>.broadcast();

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<String?> token() async {
    tokenReads++;
    return currentToken;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshes.stream;

  @override
  Stream<PushOpened> get onOpened => _opened.stream;

  @override
  Future<PushOpened?> initialOpened() async {
    initialOpenedReads++;
    return initial;
  }

  @override
  Stream<void> get onForegroundMessage => _foreground.stream;

  void refreshTokenTo(String token) {
    currentToken = token;
    _tokenRefreshes.add(token);
  }

  void open(PushOpened push) => _opened.add(push);

  void receiveForeground() => _foreground.add(null);
}

/// A [HealthRepository] that counts its calls and answers from [script].
///
/// Each call first takes the next scripted outcome (null means success). Set
/// `script.gate` to hold every call in flight until it completes.
class FakeHealthRepository implements HealthRepository {
  final script = CallScript();

  var checks = 0;

  @override
  Future<void> check() async {
    checks++;
    final failure = await script.next();
    if (failure != null) throw failure;
  }
}

/// The whole app with a fake session store and no network.
///
/// Without [health] every server check succeeds.
///
/// Without [push] the app gets a [FakePushMessaging] that grants the permission
/// and has no token, so nothing is registered.
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
  ManagerRepository? managers,
  ComplaintRepository? complaints,
  RentBillRepository? rentBills,
  ManagementRentBillRepository? managementRentBills,
  LeaseRepository? leases,
  AccountRepository? accounts,
  DashboardRepository? dashboard,
  NotificationRepository? notifications,
  UserAccountRepository? userAccounts,
  HealthRepository? health,
  PushMessaging? push,
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
      managerRepositoryProvider.overrideWithValue(
        managers ?? FakeManagerRepository(),
      ),
      complaintRepositoryProvider.overrideWithValue(
        complaints ?? FakeComplaintRepository(),
      ),
      rentBillRepositoryProvider.overrideWithValue(
        rentBills ?? FakeRentBillRepository(),
      ),
      managementRentBillRepositoryProvider.overrideWithValue(
        managementRentBills ?? FakeManagementRentBillRepository(),
      ),
      leaseRepositoryProvider.overrideWithValue(
        leases ?? FakeLeaseRepository(),
      ),
      accountRepositoryProvider.overrideWithValue(
        accounts ?? FakeAccountRepository(),
      ),
      dashboardRepositoryProvider.overrideWithValue(
        dashboard ?? FakeDashboardRepository(),
      ),
      notificationRepositoryProvider.overrideWithValue(
        notifications ?? FakeNotificationRepository(),
      ),
      userAccountRepositoryProvider.overrideWithValue(
        userAccounts ?? FakeUserAccountRepository(),
      ),
      healthRepositoryProvider.overrideWithValue(
        health ?? FakeHealthRepository(),
      ),
      pushMessagingProvider.overrideWithValue(push ?? FakePushMessaging()),
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
