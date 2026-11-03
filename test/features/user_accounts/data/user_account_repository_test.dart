import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/user_accounts/data/user_account_repository.dart';
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
    repository = ApiUserAccountRepository(
      userAccounts: UserAccountsApi(apiClient),
    );
  }

  final requests = <http.Request>[];
  late final ApiUserAccountRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _summaryJson({
  String id = 'u1',
  String role = 'tenant',
  String status = 'active',
}) => {
  'id': id,
  'name': 'Budi Santoso',
  'email': 'budi@example.com',
  'role': role,
  'status': status,
};

Map<String, dynamic> _accountJson({String role = 'tenant', bool full = true}) =>
    {
      'id': 'u1',
      'name': 'Budi Santoso',
      'email': 'budi@example.com',
      'role': role,
      'status': 'active',
      'activeLeaseCount': 1,
      'registeredAt': '2026-10-18T12:00:00Z',
      'lastLoginAt': full ? '2026-10-19T12:00:00Z' : null,
      'loginMethods': full ? ['password', 'google'] : <String>[],
      'pendingEmail': full ? 'baru@example.com' : null,
      'pendingEmailExpiresAt': full ? '2026-10-25T12:00:00Z' : null,
      'properties': full
          ? [
              {'id': 'p1', 'name': 'Kos Melati'},
            ]
          : <Object>[],
      'tenancy': full
          ? {
              'propertyName': 'Kos Melati',
              'roomNumber': '08',
              'leaseEndDate': '2026-12-31',
            }
          : null,
    };

void main() {
  group('list', () {
    test('gets the accounts and unwraps the items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(),
            _summaryJson(id: 'u2', role: 'owner', status: 'inactive'),
            _summaryJson(id: 'u3', role: 'admin', status: 'deleted'),
          ],
        }),
      );

      final result = await h.repository.list();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/user-accounts');
      expect(result.map((a) => a.id), ['u1', 'u2', 'u3']);
      final first = result.first;
      expect(first.name, 'Budi Santoso');
      expect(first.email, 'budi@example.com');
      expect(first.role, UserRole.tenant);
      expect(first.status, UserAccountStatus.active);
      expect(result[1].role, UserRole.owner);
      expect(result[1].status, UserAccountStatus.inactive);
      expect(result[2].role, UserRole.admin);
      expect(result[2].status, UserAccountStatus.deleted);
    });

    test('sends no email and no role without a filter', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list();

      expect(h.request.url.queryParameters.containsKey('email'), isFalse);
      expect(h.request.url.queryParameters.containsKey('role'), isFalse);
      expect(
        h.request.url.queryParameters['includeDeleted'],
        anyOf(isNull, 'false'),
      );
    });

    test('sends the email filter', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(email: 'budi@');

      expect(h.request.url.queryParameters['email'], 'budi@');
    });

    test('sends the role filter as its wire value', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(role: UserRole.manager);

      expect(h.request.url.queryParameters['role'], 'manager');
    });

    test('asks for deleted accounts when told to', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(includeDeleted: true);

      expect(h.request.url.queryParameters['includeDeleted'], 'true');
    });

    test('sends every filter together', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(
        email: 'rina',
        role: UserRole.owner,
        includeDeleted: true,
      );

      expect(h.request.url.queryParameters, {
        'email': 'rina',
        'role': 'owner',
        'includeDeleted': 'true',
      });
    });

    test('returns an empty list when nothing matches', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list(email: 'zzz'), isEmpty);
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
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
    test('gets one account with its details', () async {
      final h = _Harness((_) => _ok(_accountJson()));

      final result = await h.repository.get('u1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/user-accounts/u1');
      expect(result.id, 'u1');
      expect(result.name, 'Budi Santoso');
      expect(result.email, 'budi@example.com');
      expect(result.role, UserRole.tenant);
      expect(result.status, UserAccountStatus.active);
      expect(result.activeLeaseCount, 1);
      expect(result.registeredAt.toUtc().day, 18);
      expect(result.lastLoginAt!.toUtc().day, 19);
      expect(result.loginMethods, [LoginMethod.password, LoginMethod.google]);
      expect(result.pendingEmail, 'baru@example.com');
      expect(result.pendingEmailExpiresAt!.toUtc().day, 25);
      expect(result.properties.single.name, 'Kos Melati');
      expect(result.tenancy!.propertyName, 'Kos Melati');
      expect(result.tenancy!.roomNumber, '08');
      expect(result.tenancy!.leaseEndDate!.day, 31);
    });

    test(
      'gets an account that never signed in and has nothing pending',
      () async {
        final h = _Harness(
          (_) => _ok(_accountJson(role: 'admin', full: false)),
        );

        final result = await h.repository.get('u1');

        expect(result.role, UserRole.admin);
        expect(result.lastLoginAt, isNull);
        expect(result.loginMethods, isEmpty);
        expect(result.pendingEmail, isNull);
        expect(result.pendingEmailExpiresAt, isNull);
        expect(result.properties, isEmpty);
        expect(result.tenancy, isNull);
      },
    );

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'USER_ACCOUNT_NOT_FOUND'));

      await expectLater(
        h.repository.get('u1'),
        throwsA(_failure('USER_ACCOUNT_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.get('u1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.get('u1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('update', () {
    UserAccountInput input({
      String name = 'Budi Baru',
      String email = 'baru@example.com',
      EditableAccountStatus status = EditableAccountStatus.active,
    }) => UserAccountInput(name: name, email: email, status: status);

    test('puts the full input and returns the saved account', () async {
      final h = _Harness(
        (_) =>
            _ok({..._accountJson(), 'name': 'Budi Baru', 'status': 'inactive'}),
      );

      final result = await h.repository.update(
        'u1',
        input(status: EditableAccountStatus.inactive),
      );

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/user-accounts/u1');
      expect(h.request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(h.request.body), {
        'name': 'Budi Baru',
        'email': 'baru@example.com',
        'status': 'inactive',
      });
      expect(result.id, 'u1');
      expect(result.name, 'Budi Baru');
      expect(result.status, UserAccountStatus.inactive);
      expect(result.pendingEmail, 'baru@example.com');
      expect(result.pendingEmailExpiresAt!.toUtc().day, 25);
    });

    test('sends an active status as its wire value', () async {
      final h = _Harness((_) => _ok(_accountJson()));

      await h.repository.update('u7', input());

      expect(h.request.url.path, '/user-accounts/u7');
      expect(jsonDecode(h.request.body)['status'], 'active');
    });

    test('sends the name and email untouched', () async {
      final h = _Harness((_) => _ok(_accountJson()));

      await h.repository.update(
        'u1',
        input(name: 'Budi  Baru', email: 'Budi.Baru@Example.com'),
      );

      final body = jsonDecode(h.request.body);
      expect(body['name'], 'Budi  Baru');
      expect(body['email'], 'Budi.Baru@Example.com');
    });

    test('sends exactly one request', () async {
      final h = _Harness((_) => _ok(_accountJson()));

      await h.repository.update('u1', input());

      expect(h.requests, hasLength(1));
    });

    test('keeps the code, field and status of a taken email', () async {
      final h = _Harness(
        (_) => _error(409, 'EMAIL_ALREADY_REGISTERED', field: 'email'),
      );

      await expectLater(
        h.repository.update('u1', input()),
        throwsA(
          _failure('EMAIL_ALREADY_REGISTERED', field: 'email', status: 409),
        ),
      );
    });

    final conflicts = {
      'CANNOT_MODIFY_OWN_ACCOUNT': 409,
      'USER_ACCOUNT_DELETED': 409,
      'USER_ACCOUNT_NOT_FOUND': 404,
      'FORBIDDEN': 403,
    };
    for (final entry in conflicts.entries) {
      test('keeps the code and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(entry.value, entry.key));

        await expectLater(
          h.repository.update('u1', input()),
          throwsA(_failure(entry.key, status: entry.value)),
        );
      });
    }

    test('keeps the field of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'name'),
      );

      await expectLater(
        h.repository.update('u1', input(name: '')),
        throwsA(_failure('VALIDATION_FAILED', field: 'name', status: 422)),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.update('u1', input()),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.update('u1', input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('delete', () {
    test('sends DELETE for the account and accepts 204', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('u1');

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/user-accounts/u1');
      expect(h.request.url.query, isEmpty);
    });

    test('puts the id of the account in the path', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('u7');

      expect(h.request.url.path, '/user-accounts/u7');
    });

    test('sends no body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('u1');

      expect(h.request.body, isEmpty);
    });

    test('sends exactly one request', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('u1');

      expect(h.requests, hasLength(1));
    });

    test('completes with no value', () async {
      final h = _Harness((_) => http.Response('', 204));

      await expectLater(h.repository.delete('u1'), completion(isNull));
    });

    final failures = {
      'OWNER_HAS_ACTIVE_LEASE': 409,
      'TENANT_HAS_ACTIVE_LEASE': 409,
      'CANNOT_MODIFY_OWN_ACCOUNT': 409,
      'USER_ACCOUNT_DELETED': 409,
      'USER_ACCOUNT_NOT_FOUND': 404,
      'FORBIDDEN': 403,
    };
    for (final entry in failures.entries) {
      test('keeps the code and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(entry.value, entry.key));

        await expectLater(
          h.repository.delete('u1'),
          throwsA(_failure(entry.key, status: entry.value)),
        );
      });
    }

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.delete('u1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.delete('u1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.delete('u1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('fake', () {
    test('delete marks the account deleted and keeps the rest', () async {
      final repo = FakeUserAccountRepository(
        accounts: [
          makeUserAccount(),
          makeUserAccount(id: 'u2', name: 'Siti'),
        ],
      );

      await repo.delete('u1');

      expect(repo.deleted, ['u1']);
      expect(repo.calls, ['delete:u1']);
      expect((await repo.get('u1')).status, UserAccountStatus.deleted);
      expect((await repo.get('u1')).name, 'Budi Santoso');
      expect((await repo.get('u2')).status, UserAccountStatus.active);
    });
  });

  group('providers', () {
    ProviderContainer containerWith(FakeUserAccountRepository repo) {
      final container = ProviderContainer(
        overrides: [userAccountRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      return container;
    }

    const ({String? email, UserRole? role, bool includeDeleted}) all = (
      email: null,
      role: null,
      includeDeleted: false,
    );

    test('the list provider asks the repository with the query', () async {
      final repo = FakeUserAccountRepository(
        accounts: [
          makeUserAccount(),
          makeUserAccount(id: 'u2', name: 'Siti', role: UserRole.owner),
        ],
      );
      final container = containerWith(repo);

      final result = await container.read(
        userAccountListProvider((
          email: null,
          role: UserRole.owner,
          includeDeleted: true,
        )).future,
      );

      expect(result.map((a) => a.id), ['u2']);
      expect(repo.listed.single, (
        email: null,
        role: UserRole.owner,
        includeDeleted: true,
      ));
    });

    test('equal queries share one request', () async {
      final repo = FakeUserAccountRepository(accounts: [makeUserAccount()]);
      final container = containerWith(repo);

      await container.read(userAccountListProvider(all).future);
      await container.read(
        userAccountListProvider((
          email: null,
          role: null,
          includeDeleted: false,
        )).future,
      );

      expect(repo.listCalls, 1);
    });

    test('different queries make their own requests', () async {
      final repo = FakeUserAccountRepository(accounts: [makeUserAccount()]);
      final container = containerWith(repo);

      await container.read(userAccountListProvider(all).future);
      await container.read(
        userAccountListProvider((
          email: 'budi',
          role: null,
          includeDeleted: false,
        )).future,
      );

      expect(repo.listCalls, 2);
    });

    test('a failed list is not retried in the background', () async {
      final repo = FakeUserAccountRepository()
        ..listScript.always = const ApiFailure.network();
      final container = containerWith(repo);
      final subscription = container.listen(
        userAccountListProvider(all),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(userAccountListProvider(all).future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(repo.listCalls, 1);
    });

    test('the detail provider gets the account by id', () async {
      final repo = FakeUserAccountRepository(
        accounts: [makeUserAccount(id: 'u7', name: 'Rina')],
      );
      final container = containerWith(repo);

      final account = await container.read(
        userAccountDetailProvider('u7').future,
      );

      expect(account.name, 'Rina');
      expect(repo.calls, ['get:u7']);
    });

    test('a failed detail is not retried in the background', () async {
      final repo = FakeUserAccountRepository();
      final container = containerWith(repo);
      final subscription = container.listen(
        userAccountDetailProvider('missing'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container.read(userAccountDetailProvider('missing').future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(repo.getCalls, 1);
    });
  });
}
