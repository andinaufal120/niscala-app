import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
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
    repository = ApiManagerRepository(managers: ManagersApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiManagerRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

const _properties = [
  {'id': 'p1', 'name': 'Kos Melati', 'address': 'Jl. Melati 1, Bandung'},
  {'id': 'p2', 'name': 'Kos Mawar', 'address': 'Jl. Mawar 2, Bandung'},
];

Map<String, dynamic> _managerJson({
  String id = 'm1',
  bool activated = false,
  bool withUrl = true,
  bool withInvitation = true,
  bool withNickname = true,
}) => {
  'id': id,
  'name': 'Rina Putri',
  'nickname': withNickname ? 'Bu Rina' : null,
  'phone': '081255204471',
  'email': activated ? 'rina@example.com' : null,
  'accountStatus': activated ? 'active' : 'notActivated',
  'properties': _properties,
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
  String id = 'm1',
  bool activated = false,
  bool withNickname = true,
}) => {
  'id': id,
  'name': 'Rina Putri',
  'nickname': withNickname ? 'Bu Rina' : null,
  'phone': '081255204471',
  'email': activated ? 'rina@example.com' : null,
  'accountStatus': activated ? 'active' : 'notActivated',
  'properties': _properties,
};

ManagerInput _input({String? nickname = 'Bu Rina'}) => ManagerInput(
  name: 'Rina Putri',
  nickname: nickname,
  phone: '0812-5520-4471',
  propertyIds: ['p1', 'p2'],
);

void main() {
  group('list', () {
    test('gets the managers of the property and unwraps the items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(),
            _summaryJson(id: 'm2', activated: true, withNickname: false),
          ],
        }),
      );

      final result = await h.repository.list(propertyId: 'p1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/managers');
      expect(h.request.url.queryParameters, {'propertyId': 'p1'});
      expect(result.map((m) => m.id), ['m1', 'm2']);
      final first = result.first;
      expect(first.name, 'Rina Putri');
      expect(first.nickname, 'Bu Rina');
      expect(first.phone, '081255204471');
      expect(first.email, isNull);
      expect(first.accountStatus, ManagerAccountStatus.notActivated);
      expect(first.properties.map((p) => p.id), ['p1', 'p2']);
      expect(first.properties.first.name, 'Kos Melati');
      expect(first.properties.first.address, 'Jl. Melati 1, Bandung');
      expect(result.last.accountStatus, ManagerAccountStatus.active);
      expect(result.last.email, 'rina@example.com');
      expect(result.last.nickname, isNull);
    });

    test('sends no query without a property', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list();

      expect(h.request.url.path, '/managers');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('returns an empty list when there are no managers', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list(propertyId: 'p1'), isEmpty);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.list(propertyId: 'p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.list(propertyId: 'p1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.list(propertyId: 'p1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list(propertyId: 'p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('get', () {
    test('gets one manager with properties and invitation', () async {
      final h = _Harness((_) => _ok(_managerJson()));

      final result = await h.repository.get('m1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/managers/m1');
      expect(result.id, 'm1');
      expect(result.name, 'Rina Putri');
      expect(result.nickname, 'Bu Rina');
      expect(result.phone, '081255204471');
      expect(result.email, isNull);
      expect(result.accountStatus, ManagerAccountStatus.notActivated);
      expect(result.properties, hasLength(2));
      expect(result.properties.last.name, 'Kos Mawar');
      expect(result.properties.last.address, 'Jl. Mawar 2, Bandung');
      final invitation = result.invitation!;
      expect(invitation.expired, isFalse);
      expect(invitation.url, 'https://niscala.example/undangan/abc123');
      expect(invitation.createdAt.toUtc().day, 18);
      expect(invitation.expiresAt.toUtc().day, 25);
    });

    test('gets an active manager without invitation', () async {
      final h = _Harness(
        (_) => _ok(
          _managerJson(
            activated: true,
            withInvitation: false,
            withNickname: false,
          ),
        ),
      );

      final result = await h.repository.get('m1');

      expect(result.accountStatus, ManagerAccountStatus.active);
      expect(result.email, 'rina@example.com');
      expect(result.nickname, isNull);
      expect(result.invitation, isNull);
    });

    test('gets an invitation without a url', () async {
      final h = _Harness((_) => _ok(_managerJson(withUrl: false)));

      final result = await h.repository.get('m1');

      expect(result.invitation, isNotNull);
      expect(result.invitation!.url, isNull);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'MANAGER_NOT_FOUND'));

      await expectLater(
        h.repository.get('m1'),
        throwsA(_failure('MANAGER_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.get('m1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('create', () {
    test('posts the input in camelCase', () async {
      final h = _Harness((_) => _ok(_managerJson(), 201));

      final result = await h.repository.create(_input());

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/managers');
      expect(h.body, {
        'name': 'Rina Putri',
        'nickname': 'Bu Rina',
        'phone': '0812-5520-4471',
        'propertyIds': ['p1', 'p2'],
      });
      expect(result.id, 'm1');
    });

    test('returns the manager with its invitation url', () async {
      final h = _Harness((_) => _ok(_managerJson(), 201));

      final result = await h.repository.create(_input());

      expect(result.invitation!.url, 'https://niscala.example/undangan/abc123');
      expect(result.accountStatus, ManagerAccountStatus.notActivated);
    });

    test('sends a missing nickname as null', () async {
      final h = _Harness((_) => _ok(_managerJson(withNickname: false), 201));

      await h.repository.create(_input(nickname: null));

      expect(h.body.containsKey('nickname'), isTrue);
      expect(h.body['nickname'], isNull);
    });

    test('keeps the field of an unknown property', () async {
      final h = _Harness(
        (_) => _error(404, 'PROPERTY_NOT_FOUND', field: 'propertyIds.1'),
      );

      await expectLater(
        h.repository.create(_input()),
        throwsA(
          _failure('PROPERTY_NOT_FOUND', field: 'propertyIds.1', status: 404),
        ),
      );
    });

    test('keeps the field of a phone validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'phone'),
      );

      await expectLater(
        h.repository.create(_input()),
        throwsA(_failure('VALIDATION_FAILED', field: 'phone', status: 422)),
      );
    });

    test('keeps the field of a name validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'name'),
      );

      await expectLater(
        h.repository.create(_input()),
        throwsA(_failure('VALIDATION_FAILED', field: 'name', status: 422)),
      );
    });

    test('keeps the field of a property list validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'propertyIds'),
      );

      await expectLater(
        h.repository.create(_input()),
        throwsA(
          _failure('VALIDATION_FAILED', field: 'propertyIds', status: 422),
        ),
      );
    });

    test('keeps the code of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.create(_input()),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.create(_input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('update', () {
    test('puts the full input to the manager', () async {
      final h = _Harness((_) => _ok(_managerJson()));

      final result = await h.repository.update('m1', _input());

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/managers/m1');
      expect(h.body, {
        'name': 'Rina Putri',
        'nickname': 'Bu Rina',
        'phone': '0812-5520-4471',
        'propertyIds': ['p1', 'p2'],
      });
      expect(result.id, 'm1');
      expect(result.properties, hasLength(2));
    });

    test('sends a cleared nickname as null', () async {
      final h = _Harness((_) => _ok(_managerJson(withNickname: false)));

      final result = await h.repository.update('m1', _input(nickname: null));

      expect(h.body['nickname'], isNull);
      expect(result.nickname, isNull);
    });

    test('keeps the field of a name that cannot be changed', () async {
      final h = _Harness(
        (_) => _error(422, 'MANAGER_NAME_NOT_EDITABLE', field: 'name'),
      );

      await expectLater(
        h.repository.update('m1', _input()),
        throwsA(
          _failure('MANAGER_NAME_NOT_EDITABLE', field: 'name', status: 422),
        ),
      );
    });

    test('keeps the code and status of a manager that is gone', () async {
      final h = _Harness((_) => _error(404, 'MANAGER_NOT_FOUND'));

      await expectLater(
        h.repository.update('m1', _input()),
        throwsA(_failure('MANAGER_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the field of an unknown property', () async {
      final h = _Harness(
        (_) => _error(404, 'PROPERTY_NOT_FOUND', field: 'propertyIds.0'),
      );

      await expectLater(
        h.repository.update('m1', _input()),
        throwsA(
          _failure('PROPERTY_NOT_FOUND', field: 'propertyIds.0', status: 404),
        ),
      );
    });

    test('keeps the field of a phone validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'phone'),
      );

      await expectLater(
        h.repository.update('m1', _input()),
        throwsA(_failure('VALIDATION_FAILED', field: 'phone', status: 422)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.update('m1', _input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('delete', () {
    test('deletes the manager and returns when there is no body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('m1');

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/managers/m1');
    });

    test('keeps the code and status of a manager that is gone', () async {
      final h = _Harness((_) => _error(404, 'MANAGER_NOT_FOUND'));

      await expectLater(
        h.repository.delete('m1'),
        throwsA(_failure('MANAGER_NOT_FOUND', status: 404)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.delete('m1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.delete('m1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('regenerateInvitation', () {
    test(
      'posts to the invitation of the manager and maps the result',
      () async {
        final h = _Harness(
          (_) => _ok({
            'createdAt': '2026-10-20T08:00:00Z',
            'expired': false,
            'expiresAt': '2026-10-27T08:00:00Z',
            'url': 'https://niscala.example/undangan/new456',
          }),
        );

        final result = await h.repository.regenerateInvitation('m1');

        expect(h.request.method, 'POST');
        expect(h.request.url.path, '/managers/m1/invitation');
        expect(result.url, 'https://niscala.example/undangan/new456');
        expect(result.expired, isFalse);
        expect(result.createdAt.toUtc().day, 20);
        expect(result.expiresAt.toUtc().day, 27);
      },
    );

    test('keeps the code and status of an active manager', () async {
      final h = _Harness((_) => _error(409, 'MANAGER_ALREADY_ACTIVE'));

      await expectLater(
        h.repository.regenerateInvitation('m1'),
        throwsA(_failure('MANAGER_ALREADY_ACTIVE', status: 409)),
      );
    });

    test('keeps the code and status of a manager that is gone', () async {
      final h = _Harness((_) => _error(404, 'MANAGER_NOT_FOUND'));

      await expectLater(
        h.repository.regenerateInvitation('m1'),
        throwsA(_failure('MANAGER_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.regenerateInvitation('m1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
