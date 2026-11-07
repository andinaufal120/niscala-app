import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/health_repository.dart';
import 'package:niscala/core/api/http_providers.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

class _Harness {
  _Harness(Future<http.Response> Function(http.Request request) respond) {
    final client = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(client),
        apiBaseUrlProvider.overrideWithValue('http://api.test'),
      ],
    );
    addTearDown(container.dispose);
  }

  final requests = <http.Request>[];
  late final ProviderContainer container;

  HealthRepository get repository => container.read(healthRepositoryProvider);
}

Matcher _networkFailure() =>
    isA<ApiFailure>().having((f) => f.code, 'code', 'NETWORK_ERROR');

void main() {
  test('sends a GET request to the health path of the base url', () async {
    final h = _Harness(
      (_) async =>
          http.Response(jsonEncode({'status': 'ok'}), 200, headers: _json),
    );

    await h.repository.check();

    expect(h.requests, hasLength(1));
    expect(h.requests.single.method, 'GET');
    expect(h.requests.single.url.toString(), 'http://api.test/health');
  });

  test('sends no authorization header', () async {
    final h = _Harness(
      (_) async =>
          http.Response(jsonEncode({'status': 'ok'}), 200, headers: _json),
    );

    await h.repository.check();

    expect(h.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(h.requests.single.headers.containsKey('authorization'), isFalse);
  });

  test('completes normally when the server answers 200', () async {
    final h = _Harness(
      (_) async =>
          http.Response(jsonEncode({'status': 'ok'}), 200, headers: _json),
    );

    await expectLater(h.repository.check(), completes);
  });

  test('fails with a network failure on a socket exception', () async {
    final h = _Harness((_) async => throw const SocketException('offline'));

    await expectLater(h.repository.check(), throwsA(_networkFailure()));
  });

  test('fails with a network failure on a client exception', () async {
    final h = _Harness((_) async => throw http.ClientException('offline'));

    await expectLater(h.repository.check(), throwsA(_networkFailure()));
  });

  test('fails with the status code and no network code on 503', () async {
    final h = _Harness(
      (_) async => http.Response(
        jsonEncode({'status': 'unavailable'}),
        503,
        headers: _json,
      ),
    );

    await expectLater(
      h.repository.check(),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'statusCode', 503)
            .having((f) => f.code, 'code', isNot('NETWORK_ERROR')),
      ),
    );
  });

  test('fails with an api failure on another error status', () async {
    final h = _Harness((_) async => http.Response('boom', 500));

    await expectLater(
      h.repository.check(),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'statusCode', 500)
            .having((f) => f.code, 'code', isNot('NETWORK_ERROR')),
      ),
    );
  });
}
