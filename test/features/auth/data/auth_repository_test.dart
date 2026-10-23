import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

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
    final client = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    final apiClient = ApiClient(basePath: 'http://api.test')..client = client;
    repository = ApiAuthRepository(
      auth: AuthApi(apiClient),
      account: AccountApi(apiClient),
      device: () async => DeviceInfo(name: 'Pixel 8', platform: 'android'),
    );
  }

  _Harness.failing(Object error) {
    final client = MockClient((request) async {
      requests.add(request);
      throw error;
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
  final session = authSessionFor(UserRole.owner);

  group('login', () {
    test(
      'posts the credentials and the device and returns the session',
      () async {
        final h = _Harness((_) => _ok(session.toJson()));

        final result = await h.repository.login(
          email: 'budi@example.com',
          password: 'rahasia panjang',
        );

        expect(h.request.method, 'POST');
        expect(h.request.url.path, '/auth/login');
        expect(h.body, {
          'email': 'budi@example.com',
          'password': 'rahasia panjang',
          'device': {'name': 'Pixel 8', 'platform': 'android'},
        });
        expect(result.accessToken, session.accessToken);
        expect(result.refreshToken, session.refreshToken);
        expect(result.account.role, UserRole.owner);
        expect(result.account.emailVerified, isTrue);
      },
    );

    test('converts an error response to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'INVALID_CREDENTIALS'));

      await expectLater(
        h.repository.login(email: 'a@b.co', password: 'x'),
        throwsA(_failure('INVALID_CREDENTIALS', status: 401)),
      );
    });

    test('keeps the status of a rate limit error', () async {
      final h = _Harness((_) => _error(429, 'TOO_MANY_LOGIN_ATTEMPTS'));

      await expectLater(
        h.repository.login(email: 'a@b.co', password: 'x'),
        throwsA(_failure('TOO_MANY_LOGIN_ATTEMPTS', status: 429)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.login(email: 'a@b.co', password: 'x'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.login(email: 'a@b.co', password: 'x'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.login(email: 'a@b.co', password: 'x'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('registerOwner', () {
    test(
      'posts the sign-up data and the device and returns the session',
      () async {
        final unverified = authSessionFor(UserRole.owner, emailVerified: false);
        final h = _Harness((_) => _ok(unverified.toJson()));

        final result = await h.repository.registerOwner(
          name: 'Budi Santoso',
          email: 'budi@example.com',
          password: ' spasi di tepi ',
        );

        expect(h.request.method, 'POST');
        expect(h.request.url.path, '/auth/register');
        expect(h.body, {
          'name': 'Budi Santoso',
          'email': 'budi@example.com',
          'password': ' spasi di tepi ',
          'device': {'name': 'Pixel 8', 'platform': 'android'},
        });
        expect(result.account.emailVerified, isFalse);
        expect(result.account.role, UserRole.owner);
      },
    );

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(409, 'EMAIL_ALREADY_REGISTERED', field: 'email'),
      );

      await expectLater(
        h.repository.registerOwner(
          name: 'Budi',
          email: 'budi@example.com',
          password: 'x7Kqx7Kq',
        ),
        throwsA(
          _failure('EMAIL_ALREADY_REGISTERED', field: 'email', status: 409),
        ),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.registerOwner(
          name: 'Budi',
          email: 'budi@example.com',
          password: 'x7Kqx7Kq',
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('getMyAccount', () {
    test('gets the account of the signed-in user', () async {
      final account = authSessionFor(
        UserRole.owner,
        emailVerified: false,
      ).account;
      final h = _Harness((_) => _ok(account.toJson()));

      final result = await h.repository.getMyAccount();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/me');
      expect(result.email, 'budi@example.com');
      expect(result.emailVerified, isFalse);
    });

    test('converts an error response to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.getMyAccount(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.getMyAccount(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('sendEmailVerification', () {
    test(
      'posts without a body and returns when a new code may be requested',
      () async {
        final at = DateTime.utc(2026, 10, 18, 12, 1, 30);
        final h = _Harness(
          (_) => _ok(EmailVerificationSent(resendAvailableAt: at).toJson()),
        );

        final result = await h.repository.sendEmailVerification();

        expect(h.request.method, 'POST');
        expect(h.request.url.path, '/auth/email-verification');
        expect(result.isAtSameMomentAs(at), isTrue);
      },
    );

    test('keeps the code of a too-soon error', () async {
      final h = _Harness((_) => _error(429, 'VERIFICATION_CODE_TOO_SOON'));

      await expectLater(
        h.repository.sendEmailVerification(),
        throwsA(_failure('VERIFICATION_CODE_TOO_SOON', status: 429)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.sendEmailVerification(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('confirmEmail', () {
    test('posts the code and returns the account', () async {
      final account = authSessionFor(UserRole.owner).account;
      final h = _Harness((_) => _ok(account.toJson()));

      final result = await h.repository.confirmEmail('123456');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/auth/email-verification/confirmation');
      expect(h.body, {'code': '123456'});
      expect(result.emailVerified, isTrue);
    });

    test('keeps the code of an invalid code error', () async {
      final h = _Harness((_) => _error(400, 'VERIFICATION_CODE_INVALID'));

      await expectLater(
        h.repository.confirmEmail('000000'),
        throwsA(_failure('VERIFICATION_CODE_INVALID', status: 400)),
      );
    });

    test('keeps the code of an expired code error', () async {
      final h = _Harness((_) => _error(400, 'VERIFICATION_CODE_EXPIRED'));

      await expectLater(
        h.repository.confirmEmail('000000'),
        throwsA(_failure('VERIFICATION_CODE_EXPIRED', status: 400)),
      );
    });

    test('keeps the code of an already verified error', () async {
      final h = _Harness((_) => _error(409, 'EMAIL_ALREADY_VERIFIED'));

      await expectLater(
        h.repository.confirmEmail('123456'),
        throwsA(_failure('EMAIL_ALREADY_VERIFIED', status: 409)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.confirmEmail('123456'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
