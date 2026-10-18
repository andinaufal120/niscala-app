import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

class _Harness {
  _Harness(http.Response Function(http.Request request) respond) {
    _build(
      MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  _Harness.failing(Object error) {
    _build(
      MockClient((request) async {
        requests.add(request);
        throw error;
      }),
    );
  }

  void _build(http.Client client) {
    final apiClient = ApiClient(basePath: 'http://api.test')..client = client;
    repository = ApiTenantRepository(tenants: TenantsApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiTenantRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _tenantJson({
  String id = 't1',
  bool activated = false,
  bool withUrl = true,
  bool withInvitation = true,
}) => {
  'id': id,
  'name': 'Budi Santoso',
  'phone': '081255204471',
  'email': activated ? 'budi@example.com' : null,
  'occupation': 'Karyawan swasta',
  'accountStatus': activated ? 'active' : 'notActivated',
  'emergencyContacts': [
    {'name': 'Siti Rahma', 'relationship': 'Ibu', 'phone': '081355512345'},
    {'name': 'Joko', 'relationship': 'Kakak', 'phone': '081355512346'},
  ],
  'room': {'id': 'r1', 'number': '08'},
  'lease': {
    'billingCycle': 'quarterly',
    'startDate': '2026-01-01',
    'endDate': '2026-12-31',
    'gracePeriodDays': 3,
    'nextBillDate': '2026-04-01',
    'rent': 2100000,
  },
  'invitation': withInvitation
      ? {
          'createdAt': '2026-10-18T12:00:00Z',
          'expired': false,
          'expiresAt': '2026-10-25T12:00:00Z',
          'url': withUrl ? 'https://niscala.example/undangan/abc123' : null,
        }
      : null,
};

Map<String, dynamic> _summaryJson({
  String id = 't1',
  bool activated = false,
  bool withEnd = true,
}) => {
  'id': id,
  'name': 'Budi Santoso',
  'room': {'id': 'r1', 'number': '08'},
  'accountStatus': activated ? 'active' : 'notActivated',
  'billingCycle': 'monthly',
  'leaseEndDate': withEnd ? '2026-12-31' : null,
  'invitationExpiresAt': activated ? null : '2026-10-25T12:00:00Z',
};

NewTenantInput _input({
  List<EmergencyContact>? contacts,
  LeaseInput? lease,
  String? occupation = 'Karyawan swasta',
}) => NewTenantInput(
  roomId: 'r1',
  name: 'Budi Santoso',
  phone: '0812-5520-4471',
  occupation: occupation,
  emergencyContacts:
      contacts ??
      [
        EmergencyContact(
          name: 'Siti Rahma',
          relationship: 'Ibu',
          phone: '081355512345',
        ),
        EmergencyContact(
          name: 'Joko',
          relationship: 'Kakak',
          phone: '081355512346',
        ),
      ],
  lease:
      lease ??
      LeaseInput(
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 12, 31),
        billingCycle: BillingCycle.quarterly,
        rent: 2100000,
        gracePeriodDays: 3,
      ),
);

void main() {
  group('list', () {
    test('gets the tenants of the property and unwraps the items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(),
            _summaryJson(id: 't2', activated: true, withEnd: false),
          ],
        }),
      );

      final result = await h.repository.list('p1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties/p1/tenants');
      expect(result.map((t) => t.id), ['t1', 't2']);
      final first = result.first;
      expect(first.name, 'Budi Santoso');
      expect(first.room.id, 'r1');
      expect(first.room.number, '08');
      expect(first.accountStatus, TenantAccountStatus.notActivated);
      expect(first.billingCycle, BillingCycle.monthly);
      expect(first.leaseEndDate!.year, 2026);
      expect(first.leaseEndDate!.month, 12);
      expect(first.leaseEndDate!.day, 31);
      expect(first.invitationExpiresAt!.toUtc().day, 25);
      expect(result.last.accountStatus, TenantAccountStatus.active);
      expect(result.last.leaseEndDate, isNull);
      expect(result.last.invitationExpiresAt, isNull);
    });

    test('returns an empty list when the property has no tenants', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list('p1'), isEmpty);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.list('p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.list('p1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('get', () {
    test('gets one tenant with lease, contacts and invitation', () async {
      final h = _Harness((_) => _ok(_tenantJson()));

      final result = await h.repository.get('t1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/tenants/t1');
      expect(result.id, 't1');
      expect(result.name, 'Budi Santoso');
      expect(result.phone, '081255204471');
      expect(result.email, isNull);
      expect(result.occupation, 'Karyawan swasta');
      expect(result.accountStatus, TenantAccountStatus.notActivated);
      expect(result.room.id, 'r1');
      expect(result.room.number, '08');
      expect(result.emergencyContacts, hasLength(2));
      expect(result.emergencyContacts.first.name, 'Siti Rahma');
      expect(result.emergencyContacts.first.relationship, 'Ibu');
      expect(result.emergencyContacts.first.phone, '081355512345');
      final lease = result.lease;
      expect(lease.billingCycle, BillingCycle.quarterly);
      expect(lease.rent, 2100000);
      expect(lease.gracePeriodDays, 3);
      expect(lease.startDate!.month, 1);
      expect(lease.endDate!.month, 12);
      expect(lease.nextBillDate!.month, 4);
      final invitation = result.invitation!;
      expect(invitation.expired, isFalse);
      expect(invitation.url, 'https://niscala.example/undangan/abc123');
      expect(invitation.createdAt.toUtc().day, 18);
      expect(invitation.expiresAt.toUtc().day, 25);
    });

    test('gets an active tenant without invitation', () async {
      final h = _Harness(
        (_) => _ok(_tenantJson(activated: true, withInvitation: false)),
      );

      final result = await h.repository.get('t1');

      expect(result.accountStatus, TenantAccountStatus.active);
      expect(result.email, 'budi@example.com');
      expect(result.invitation, isNull);
    });

    test('gets an invitation without a url', () async {
      final h = _Harness((_) => _ok(_tenantJson(withUrl: false)));

      final result = await h.repository.get('t1');

      expect(result.invitation, isNotNull);
      expect(result.invitation!.url, isNull);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'TENANT_NOT_FOUND'));

      await expectLater(
        h.repository.get('t1'),
        throwsA(_failure('TENANT_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.get('t1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('create', () {
    test('posts the input in camelCase to the property', () async {
      final h = _Harness((_) => _ok(_tenantJson(), 201));

      final result = await h.repository.create('p1', _input());

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/properties/p1/tenants');
      expect(h.body['roomId'], 'r1');
      expect(h.body['name'], 'Budi Santoso');
      expect(h.body['phone'], '0812-5520-4471');
      expect(h.body['occupation'], 'Karyawan swasta');
      expect(h.body['emergencyContacts'], [
        {'name': 'Siti Rahma', 'relationship': 'Ibu', 'phone': '081355512345'},
        {'name': 'Joko', 'relationship': 'Kakak', 'phone': '081355512346'},
      ]);
      final lease = h.body['lease'] as Map<String, dynamic>;
      expect(lease['startDate'], '2026-01-01');
      expect(lease['endDate'], '2026-12-31');
      expect(lease['billingCycle'], 'quarterly');
      expect(lease['rent'], 2100000);
      expect(lease['rent'], isA<int>());
      expect(lease['gracePeriodDays'], 3);
      expect(result.id, 't1');
    });

    test('returns the tenant with its invitation url', () async {
      final h = _Harness((_) => _ok(_tenantJson(), 201));

      final result = await h.repository.create('p1', _input());

      expect(result.invitation!.url, 'https://niscala.example/undangan/abc123');
      expect(result.accountStatus, TenantAccountStatus.notActivated);
    });

    test('sends open dates as null', () async {
      final h = _Harness((_) => _ok(_tenantJson(), 201));

      await h.repository.create(
        'p1',
        _input(
          lease: LeaseInput(
            billingCycle: BillingCycle.monthly,
            rent: 750000,
            gracePeriodDays: 0,
          ),
        ),
      );

      final lease = h.body['lease'] as Map<String, dynamic>;
      expect(lease['startDate'], isNull);
      expect(lease['endDate'], isNull);
      expect(lease['billingCycle'], 'monthly');
      expect(lease['gracePeriodDays'], 0);
    });

    test('sends no contacts and no occupation when there are none', () async {
      final h = _Harness((_) => _ok(_tenantJson(), 201));

      await h.repository.create(
        'p1',
        _input(contacts: const [], occupation: null),
      );

      expect(h.body['emergencyContacts'], isEmpty);
      expect(h.body['occupation'], isNull);
    });

    test('keeps the code and field of a room that is not vacant', () async {
      final h = _Harness(
        (_) => _error(409, 'ROOM_NOT_VACANT', field: 'roomId'),
      );

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('ROOM_NOT_VACANT', field: 'roomId', status: 409)),
      );
    });

    test('keeps the field of a phone validation error', () async {
      final h = _Harness(
        (_) => _error(400, 'VALIDATION_FAILED', field: 'phone'),
      );

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('VALIDATION_FAILED', field: 'phone', status: 400)),
      );
    });

    test('keeps the nested field of a lease validation error', () async {
      final h = _Harness(
        (_) => _error(400, 'VALIDATION_FAILED', field: 'lease.rent'),
      );

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(
          _failure('VALIDATION_FAILED', field: 'lease.rent', status: 400),
        ),
      );
    });

    test('keeps the code of a read-only property error', () async {
      final h = _Harness((_) => _error(403, 'PROPERTY_READ_ONLY'));

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('PROPERTY_READ_ONLY', status: 403)),
      );
    });

    test('keeps the code of a read-only room error', () async {
      final h = _Harness((_) => _error(403, 'ROOM_READ_ONLY'));

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('ROOM_READ_ONLY', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
