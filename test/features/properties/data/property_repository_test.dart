import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

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
    repository = ApiPropertyRepository(
      properties: PropertiesApi(apiClient),
      account: AccountApi(apiClient),
    );
  }

  final requests = <http.Request>[];
  late final ApiPropertyRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _propertyJson(Property p) =>
    jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;

Map<String, dynamic> _summaryJson({
  String id = 'p1',
  String name = 'Kos Melati',
}) => {
  'id': id,
  'name': name,
  'address': 'Jl. Melati 1',
  'roomCount': 10,
  'occupiedRoomCount': 4,
  'managers': [
    {'id': 'm1', 'name': 'Sari'},
  ],
  'editable': true,
};

PropertyInput _input({BankAccount? bank}) => PropertyInput(
  name: 'Kos Melati',
  address: 'Jl. Melati 1',
  bankAccount: bank,
);

final _bank = BankAccount(
  bankName: 'BCA',
  accountNumber: '1234567890',
  accountHolderName: 'Budi Santoso',
);

void main() {
  group('list', () {
    test('gets the properties and unwraps the items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_summaryJson(), _summaryJson(id: 'p2', name: 'Kos Mawar')],
        }),
      );

      final result = await h.repository.list();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties');
      expect(result.map((p) => p.id), ['p1', 'p2']);
      expect(result.first.name, 'Kos Melati');
      expect(result.first.roomCount, 10);
      expect(result.first.occupiedRoomCount, 4);
      expect(result.first.managers.single.name, 'Sari');
      expect(result.first.editable, isTrue);
    });

    test('returns an empty list when there are no properties', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list(), isEmpty);
    });

    test('converts an error response to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('get', () {
    test('gets one property including its bank account', () async {
      final property = makeProperty(
        bankAccount: _bank,
        managers: [ManagerRef(id: 'm1', name: 'Sari')],
      );
      final h = _Harness((_) => _ok(_propertyJson(property)));

      final result = await h.repository.get('p1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties/p1');
      expect(result.name, 'Kos Melati');
      expect(result.address, 'Jl. Melati 1, Bandung');
      expect(result.bankAccount, _bank);
      expect(result.roomCount, 10);
      expect(result.occupiedRoomCount, 4);
      expect(result.vacantRoomCount, 6);
      expect(result.managers.single.name, 'Sari');
    });

    test('returns a property without a bank account', () async {
      final h = _Harness((_) => _ok(_propertyJson(makeProperty())));

      expect((await h.repository.get('p1')).bankAccount, isNull);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.get('p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.get('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('create', () {
    test('posts the input in camelCase with the bank account', () async {
      final h = _Harness((_) => _ok(_propertyJson(makeProperty()), 201));

      final result = await h.repository.create(_input(bank: _bank));

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/properties');
      expect(h.body, {
        'name': 'Kos Melati',
        'address': 'Jl. Melati 1',
        'bankAccount': {
          'bankName': 'BCA',
          'accountNumber': '1234567890',
          'accountHolderName': 'Budi Santoso',
        },
      });
      expect(result.id, 'p1');
    });

    test('sends no bank account when there is none', () async {
      final h = _Harness((_) => _ok(_propertyJson(makeProperty()), 201));

      await h.repository.create(_input());

      expect(h.body['name'], 'Kos Melati');
      expect(h.body['bankAccount'], isNull);
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(409, 'PROPERTY_NAME_TAKEN', field: 'name'),
      );

      await expectLater(
        h.repository.create(_input()),
        throwsA(_failure('PROPERTY_NAME_TAKEN', field: 'name', status: 409)),
      );
    });

    test('keeps the code of a property limit error', () async {
      final h = _Harness((_) => _error(403, 'PROPERTY_LIMIT_REACHED'));

      await expectLater(
        h.repository.create(_input()),
        throwsA(_failure('PROPERTY_LIMIT_REACHED', status: 403)),
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
    test('puts the full input to the property', () async {
      final updated = makeProperty(name: 'Kos Baru', bankAccount: _bank);
      final h = _Harness((_) => _ok(_propertyJson(updated)));

      final result = await h.repository.update('p1', _input(bank: _bank));

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/properties/p1');
      expect(h.body['name'], 'Kos Melati');
      expect(h.body['address'], 'Jl. Melati 1');
      expect(h.body['bankAccount'], {
        'bankName': 'BCA',
        'accountNumber': '1234567890',
        'accountHolderName': 'Budi Santoso',
      });
      expect(result.name, 'Kos Baru');
    });

    test('sends no bank account when there is none', () async {
      final h = _Harness((_) => _ok(_propertyJson(makeProperty())));

      await h.repository.update('p1', _input());

      expect(h.body['bankAccount'], isNull);
    });

    test('keeps the code of a re-authentication error', () async {
      final h = _Harness((_) => _error(403, 'REAUTHENTICATION_REQUIRED'));

      await expectLater(
        h.repository.update('p1', _input(bank: _bank)),
        throwsA(_failure('REAUTHENTICATION_REQUIRED', status: 403)),
      );
    });

    test('keeps the field of a bank account validation error', () async {
      final h = _Harness(
        (_) => _error(400, 'VALIDATION_FAILED', field: 'bankAccount.bankName'),
      );

      await expectLater(
        h.repository.update('p1', _input(bank: _bank)),
        throwsA(
          _failure(
            'VALIDATION_FAILED',
            field: 'bankAccount.bankName',
            status: 400,
          ),
        ),
      );
    });

    test('keeps the code of a read-only error', () async {
      final h = _Harness((_) => _error(403, 'PROPERTY_READ_ONLY'));

      await expectLater(
        h.repository.update('p1', _input()),
        throwsA(_failure('PROPERTY_READ_ONLY', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.update('p1', _input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('delete', () {
    test('sends a DELETE and completes on 204', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('p1');

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/properties/p1');
    });

    test('keeps the code and status of an error response', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.delete('p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.delete('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('reauthenticateWithPassword', () {
    test('posts the password and completes on success', () async {
      final h = _Harness(
        (_) => _ok({
          'reauthenticatedUntil': DateTime.utc(
            2026,
            10,
            18,
            13,
          ).toIso8601String(),
        }),
      );

      await h.repository.reauthenticateWithPassword('rahasia panjang');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/me/reauthentication/password');
      expect(h.body, {'password': 'rahasia panjang'});
    });

    test('completes when the response has no body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.reauthenticateWithPassword('rahasia panjang');

      expect(h.requests, hasLength(1));
    });

    test('keeps the code of a wrong password error', () async {
      final h = _Harness((_) => _error(401, 'PASSWORD_INCORRECT'));

      await expectLater(
        h.repository.reauthenticateWithPassword('salah'),
        throwsA(_failure('PASSWORD_INCORRECT', status: 401)),
      );
    });

    test('keeps the code of a rate limit error', () async {
      final h = _Harness((_) => _error(429, 'TOO_MANY_LOGIN_ATTEMPTS'));

      await expectLater(
        h.repository.reauthenticateWithPassword('salah'),
        throwsA(_failure('TOO_MANY_LOGIN_ATTEMPTS', status: 429)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.reauthenticateWithPassword('x'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
