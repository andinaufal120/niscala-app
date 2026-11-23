import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _error(int status, String code) => http.Response(
  jsonEncode({'code': code, 'field': null, 'message': 'English text'}),
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
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(basePath: 'http://api.test')..client = client,
        ),
      ],
    );
    addTearDown(container.dispose);
    repository = container.read(accountRepositoryProvider);
  }

  final requests = <http.Request>[];
  late final AccountRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('deleteMyAccount', () {
    test('deletes the account of the caller without a body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.deleteMyAccount();

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/me');
      expect(h.request.url.queryParameters, isEmpty);
      expect(h.request.bodyBytes, isEmpty);
    });

    test('sends no version precondition', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.deleteMyAccount();

      expect(h.request.headers.containsKey('if-match'), isFalse);
    });

    test('sends one request only', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.deleteMyAccount();

      expect(h.requests, hasLength(1));
    });

    final failures = <String, ({int status, String code})>{
      'an owner with an active lease': (
        status: 409,
        code: 'OWNER_HAS_ACTIVE_LEASE',
      ),
      'a tenant with an active lease': (
        status: 409,
        code: 'TENANT_HAS_ACTIVE_LEASE',
      ),
      'a subscription that renews automatically': (
        status: 409,
        code: 'SUBSCRIPTION_AUTO_RENEWING',
      ),
      'a missing recent re-authentication': (
        status: 403,
        code: 'REAUTHENTICATION_REQUIRED',
      ),
      'a forbidden call': (status: 403, code: 'FORBIDDEN'),
      'an invalid access token': (status: 401, code: 'ACCESS_TOKEN_INVALID'),
    };
    for (final entry in failures.entries) {
      test('keeps the code and status of ${entry.key}', () async {
        final f = entry.value;
        final h = _Harness((_) => _error(f.status, f.code));

        await expectLater(
          h.repository.deleteMyAccount(),
          throwsA(_failure(f.code, status: f.status)),
        );
      });
    }

    test('does not retry a failed request', () async {
      final h = _Harness((_) => _error(409, 'OWNER_HAS_ACTIVE_LEASE'));

      await expectLater(
        h.repository.deleteMyAccount(),
        throwsA(isA<ApiFailure>()),
      );

      expect(h.requests, hasLength(1));
    });

    test('never exposes the English text of the API', () async {
      final h = _Harness((_) => _error(409, 'OWNER_HAS_ACTIVE_LEASE'));

      await expectLater(
        h.repository.deleteMyAccount(),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.toString(),
            'text',
            isNot(contains('English text')),
          ),
        ),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.deleteMyAccount(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.deleteMyAccount(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.deleteMyAccount(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
