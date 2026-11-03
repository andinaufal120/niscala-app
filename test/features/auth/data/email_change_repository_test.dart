import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

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
  group('confirmEmailChange', () {
    test('posts the token and completes on 204 without a body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.confirmEmailChange('abc');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/auth/email-changes');
      expect(h.body, {'token': 'abc'});
    });

    test('sends the token as it is', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.confirmEmailChange('a+b/c=');

      expect(h.body, {'token': 'a+b/c='});
    });

    test('sends exactly one request', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.confirmEmailChange('abc');

      expect(h.requests, hasLength(1));
    });

    final failures = {
      'EMAIL_CHANGE_NOT_FOUND': 404,
      'EMAIL_CHANGE_USED': 409,
      'EMAIL_CHANGE_EXPIRED': 409,
      'EMAIL_ALREADY_REGISTERED': 409,
    };
    for (final entry in failures.entries) {
      test('keeps the code and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(entry.value, entry.key));

        await expectLater(
          h.repository.confirmEmailChange('abc'),
          throwsA(_failure(entry.key, status: entry.value)),
        );
      });
    }

    test('keeps the code and field of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'token'),
      );

      await expectLater(
        h.repository.confirmEmailChange(''),
        throwsA(_failure('VALIDATION_FAILED', field: 'token', status: 422)),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.confirmEmailChange('abc'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.confirmEmailChange('abc'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.confirmEmailChange('abc'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
