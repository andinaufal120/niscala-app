import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body) =>
    http.Response(jsonEncode(body), 200, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

class _Harness {
  _Harness(http.Response Function(http.Request request) respond) {
    _connect((request) async => respond(request));
  }

  _Harness.failing(Object error) {
    _connect((request) async => throw error);
  }

  void _connect(Future<http.Response> Function(http.Request request) answer) {
    final client = MockClient((request) async {
      requests.add(request);
      return answer(request);
    });
    final apiClient = ApiClient(basePath: 'http://api.test')..client = client;
    repository = ApiAuthRepository(
      auth: AuthApi(apiClient),
      account: AccountApi(apiClient),
      device: () async => DeviceInfo(name: 'Pixel 8', platform: 'android'),
    );
  }

  final requests = <http.Request>[];
  late final ApiAuthRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('requestPasswordReset', () {
    test('posts the email and completes on 202 without a body', () async {
      final h = _Harness((_) => http.Response('', 202));

      await h.repository.requestPasswordReset('budi@example.com');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/auth/password-reset-requests');
      expect(h.body, {'email': 'budi@example.com'});
    });

    test('sends exactly one request', () async {
      final h = _Harness((_) => http.Response('', 202));

      await h.repository.requestPasswordReset('budi@example.com');

      expect(h.requests, hasLength(1));
    });

    test('keeps the code and field of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'email'),
      );

      await expectLater(
        h.repository.requestPasswordReset('budi'),
        throwsA(_failure('VALIDATION_FAILED', field: 'email', status: 422)),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.requestPasswordReset('budi@example.com'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.requestPasswordReset('budi@example.com'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.requestPasswordReset('budi@example.com'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('previewPasswordReset', () {
    test('posts the token and returns the email of the account', () async {
      final h = _Harness(
        (_) => _ok(PasswordResetPreview(email: 'budi@example.com').toJson()),
      );

      final email = await h.repository.previewPasswordReset('abc');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/auth/password-reset-previews');
      expect(h.body, {'token': 'abc'});
      expect(email, 'budi@example.com');
    });

    final failures = {
      'PASSWORD_RESET_NOT_FOUND': 404,
      'PASSWORD_RESET_USED': 409,
      'PASSWORD_RESET_EXPIRED': 409,
    };
    for (final entry in failures.entries) {
      test('keeps the code and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(entry.value, entry.key));

        await expectLater(
          h.repository.previewPasswordReset('abc'),
          throwsA(_failure(entry.key, status: entry.value)),
        );
      });
    }

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.previewPasswordReset('abc'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.previewPasswordReset('abc'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('resetPassword', () {
    test('posts the token and the untouched password, 204 completes', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.resetPassword(
        token: 'abc',
        newPassword: ' kopi tubruk pagi ',
      );

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/auth/password-resets');
      expect(h.body, {'token': 'abc', 'newPassword': ' kopi tubruk pagi '});
    });

    test('keeps the code and field of a common password error', () async {
      final h = _Harness(
        (_) => _error(422, 'PASSWORD_TOO_COMMON', field: 'newPassword'),
      );

      await expectLater(
        h.repository.resetPassword(token: 'abc', newPassword: 'password123'),
        throwsA(
          _failure('PASSWORD_TOO_COMMON', field: 'newPassword', status: 422),
        ),
      );
    });

    test('keeps the code and field of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'newPassword'),
      );

      await expectLater(
        h.repository.resetPassword(token: 'abc', newPassword: 'x'),
        throwsA(
          _failure('VALIDATION_FAILED', field: 'newPassword', status: 422),
        ),
      );
    });

    final failures = {
      'PASSWORD_RESET_NOT_FOUND': 404,
      'PASSWORD_RESET_USED': 409,
      'PASSWORD_RESET_EXPIRED': 409,
    };
    for (final entry in failures.entries) {
      test('keeps the code and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(entry.value, entry.key));

        await expectLater(
          h.repository.resetPassword(token: 'abc', newPassword: 'x7Kqx7Kq'),
          throwsA(_failure(entry.key, status: entry.value)),
        );
      });
    }

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.resetPassword(token: 'abc', newPassword: 'x7Kqx7Kq'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.resetPassword(token: 'abc', newPassword: 'x7Kqx7Kq'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
