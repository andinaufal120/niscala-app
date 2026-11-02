import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _noContent() => http.Response('', 204);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _accountJson({
  String role = 'owner',
  String? googleEmail,
  bool hasPassword = true,
  bool emailVerified = true,
}) => {
  'id': 'account-1',
  'name': 'Andi Pengguna',
  'email': 'andi@example.com',
  'emailVerified': emailVerified,
  'googleEmail': googleEmail,
  'hasPassword': hasPassword,
  'role': role,
};

Map<String, Object?> _sessionJson({
  String id = 's1',
  String deviceName = 'Galaxy A54',
  String platform = 'Android',
  String loginMethod = 'password',
  String lastActiveAt = '2026-10-18T12:00:00Z',
  bool isCurrent = false,
}) => {
  'id': id,
  'deviceName': deviceName,
  'platform': platform,
  'loginMethod': loginMethod,
  'lastActiveAt': lastActiveAt,
  'isCurrent': isCurrent,
};

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
    repository = ApiAccountRepository(
      account: AccountApi(apiClient),
      sessions: SessionsApi(apiClient),
    );
  }

  final requests = <http.Request>[];
  late final ApiAccountRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('me', () {
    test('gets the account of the caller', () async {
      final h = _Harness((_) => _ok(_accountJson()));

      await h.repository.me();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/me');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('maps the fields of the account', () async {
      final h = _Harness(
        (_) => _ok(
          _accountJson(
            role: 'manager',
            googleEmail: 'andi@gmail.com',
            hasPassword: false,
            emailVerified: false,
          ),
        ),
      );

      final account = await h.repository.me();

      expect(account.id, 'account-1');
      expect(account.name, 'Andi Pengguna');
      expect(account.email, 'andi@example.com');
      expect(account.emailVerified, isFalse);
      expect(account.googleEmail, 'andi@gmail.com');
      expect(account.hasPassword, isFalse);
      expect(account.role, UserRole.manager);
    });

    test('maps an account without a linked Google email', () async {
      final h = _Harness((_) => _ok(_accountJson()));

      expect((await h.repository.me()).googleEmail, isNull);
    });

    for (final role in UserRole.values) {
      test('maps the role ${role.value}', () async {
        final h = _Harness((_) => _ok(_accountJson(role: role.value)));

        expect((await h.repository.me()).role, role);
      });
    }

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.me(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.me(),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(h.repository.me(), throwsA(_failure('NETWORK_ERROR')));
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(h.repository.me(), throwsA(_failure('NETWORK_ERROR')));
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.me(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('sessions', () {
    test('gets the sessions of the caller', () async {
      final h = _Harness((_) => _ok({'items': <Object>[]}));

      await h.repository.sessions();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/me/sessions');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('maps the fields of a session', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _sessionJson(
              id: 's9',
              deviceName: 'Redmi Note 12',
              platform: 'iOS',
              loginMethod: 'google',
              lastActiveAt: '2026-10-20T08:30:00Z',
              isCurrent: true,
            ),
          ],
        }),
      );

      final sessions = await h.repository.sessions();

      expect(sessions, hasLength(1));
      expect(sessions.single.id, 's9');
      expect(sessions.single.deviceName, 'Redmi Note 12');
      expect(sessions.single.platform, 'iOS');
      expect(sessions.single.loginMethod, LoginMethod.google);
      expect(sessions.single.lastActiveAt, DateTime.utc(2026, 10, 20, 8, 30));
      expect(sessions.single.isCurrent, isTrue);
    });

    for (final method in LoginMethod.values) {
      test('maps the login method ${method.value}', () async {
        final h = _Harness(
          (_) => _ok({
            'items': [_sessionJson(loginMethod: method.value)],
          }),
        );

        expect((await h.repository.sessions()).single.loginMethod, method);
      });
    }

    test('keeps the order of the response', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _sessionJson(id: 'a', isCurrent: true),
            _sessionJson(id: 'c'),
            _sessionJson(id: 'b'),
          ],
        }),
      );

      final sessions = await h.repository.sessions();

      expect(sessions.map((s) => s.id), ['a', 'c', 'b']);
    });

    test('maps a session that is not the current one', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_sessionJson()],
        }),
      );

      expect((await h.repository.sessions()).single.isCurrent, isFalse);
    });

    test('returns an empty list when there are no sessions', () async {
      final h = _Harness((_) => _ok({'items': <Object>[]}));

      expect(await h.repository.sessions(), isEmpty);
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.sessions(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.sessions(),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.sessions(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.sessions(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.sessions(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('endSession', () {
    test('deletes the session with the id, without a body', () async {
      final h = _Harness((_) => _noContent());

      await h.repository.endSession('s2');

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/me/sessions/s2');
      expect(h.request.url.queryParameters, isEmpty);
      expect(h.request.bodyBytes, isEmpty);
    });

    test('sends one request only', () async {
      final h = _Harness((_) => _noContent());

      await h.repository.endSession('s2');

      expect(h.requests, hasLength(1));
    });

    test('converts a missing session to SESSION_NOT_FOUND', () async {
      final h = _Harness((_) => _error(404, 'SESSION_NOT_FOUND'));

      await expectLater(
        h.repository.endSession('s2'),
        throwsA(_failure('SESSION_NOT_FOUND', status: 404)),
      );
    });

    test('converts the current session to SESSION_IS_CURRENT', () async {
      final h = _Harness((_) => _error(409, 'SESSION_IS_CURRENT'));

      await expectLater(
        h.repository.endSession('current'),
        throwsA(_failure('SESSION_IS_CURRENT', status: 409)),
      );
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.endSession('s2'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.endSession('s2'),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.endSession('s2'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.endSession('s2'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.endSession('s2'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('endOtherSessions', () {
    test('deletes the sessions collection, without a body', () async {
      final h = _Harness((_) => _noContent());

      await h.repository.endOtherSessions();

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/me/sessions');
      expect(h.request.url.queryParameters, isEmpty);
      expect(h.request.bodyBytes, isEmpty);
    });

    test('sends one request only', () async {
      final h = _Harness((_) => _noContent());

      await h.repository.endOtherSessions();

      expect(h.requests, hasLength(1));
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.endOtherSessions(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.endOtherSessions(),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.endOtherSessions(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.endOtherSessions(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.endOtherSessions(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  ProviderContainer containerWith(FakeAccountRepository repository) {
    final container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('meProvider', () {
    test('resolves to the account of the repository', () async {
      final account = makeAccount(role: UserRole.tenant);
      final container = containerWith(FakeAccountRepository(account: account));

      expect(await container.read(meProvider.future), account);
    });

    test('fetches once however often it is read', () async {
      final repository = FakeAccountRepository();
      final container = containerWith(repository);

      await container.read(meProvider.future);
      await container.read(meProvider.future);

      expect(repository.meCalls, 1);
    });

    test('fetches again after it is invalidated', () async {
      final repository = FakeAccountRepository();
      final container = containerWith(repository);
      await container.read(meProvider.future);

      container.invalidate(meProvider);
      await container.read(meProvider.future);

      expect(repository.meCalls, 2);
    });

    test('exposes a failure of the repository', () async {
      final repository = FakeAccountRepository()
        ..meScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      final container = containerWith(repository);

      await expectLater(
        container.read(meProvider.future),
        throwsA(_failure('INTERNAL_ERROR')),
      );
    });

    test('does not retry a failure in the background', () async {
      final repository = FakeAccountRepository()
        ..meScript.always = const ApiFailure.network();
      final container = containerWith(repository);
      container.listen(meProvider, (_, _) {});

      await expectLater(
        container.read(meProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(repository.meCalls, 1);
    });

    test('does not fetch the sessions', () async {
      final repository = FakeAccountRepository();
      final container = containerWith(repository);

      await container.read(meProvider.future);

      expect(repository.sessionsCalls, 0);
    });
  });

  group('sessionsProvider', () {
    test('resolves to the sessions of the repository', () async {
      final devices = [
        makeSession(id: 'current', isCurrent: true),
        makeSession(id: 's2'),
      ];
      final container = containerWith(FakeAccountRepository(devices: devices));

      expect(await container.read(sessionsProvider.future), devices);
    });

    test('fetches once however often it is read', () async {
      final repository = FakeAccountRepository();
      final container = containerWith(repository);

      await container.read(sessionsProvider.future);
      await container.read(sessionsProvider.future);

      expect(repository.sessionsCalls, 1);
    });

    test('fetches again after it is invalidated', () async {
      final repository = FakeAccountRepository();
      final container = containerWith(repository);
      await container.read(sessionsProvider.future);

      container.invalidate(sessionsProvider);
      await container.read(sessionsProvider.future);

      expect(repository.sessionsCalls, 2);
    });

    test('exposes a failure of the repository', () async {
      final repository = FakeAccountRepository()
        ..sessionsScript.always = const ApiFailure(code: 'FORBIDDEN');
      final container = containerWith(repository);

      await expectLater(
        container.read(sessionsProvider.future),
        throwsA(_failure('FORBIDDEN')),
      );
    });

    test('does not retry a failure in the background', () async {
      final repository = FakeAccountRepository()
        ..sessionsScript.always = const ApiFailure.network();
      final container = containerWith(repository);
      container.listen(sessionsProvider, (_, _) {});

      await expectLater(
        container.read(sessionsProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(repository.sessionsCalls, 1);
    });

    test('does not fetch the account', () async {
      final repository = FakeAccountRepository();
      final container = containerWith(repository);

      await container.read(sessionsProvider.future);

      expect(repository.meCalls, 0);
    });
  });
}
