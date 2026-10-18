import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/auth_http_client.dart';

class FakeTokenSource implements TokenSource {
  FakeTokenSource({
    this.accessToken,
    this.refreshResult = true,
    this.refreshedToken = 'new',
    this.refreshDelay = Duration.zero,
  });

  @override
  String? accessToken;

  bool refreshResult;
  String refreshedToken;
  Duration refreshDelay;
  int refreshCalls = 0;
  int expireCalls = 0;

  @override
  Future<bool> refresh() async {
    refreshCalls++;
    await Future<void>.delayed(refreshDelay);
    if (refreshResult) accessToken = refreshedToken;
    return refreshResult;
  }

  @override
  void expire() => expireCalls++;
}

http.Response invalidAccessToken() => http.Response(
  jsonEncode({'code': 'ACCESS_TOKEN_INVALID', 'message': 'expired'}),
  401,
  headers: {'content-type': 'application/json'},
);

void main() {
  final url = Uri.parse('https://api.example.com/v1/properties');

  group('authorization header', () {
    test('adds the bearer token when there is an access token', () async {
      late http.BaseRequest seen;
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          seen = request;
          return http.Response('{}', 200);
        }),
        tokens: FakeTokenSource(accessToken: 'abc'),
      );

      await client.get(url);

      expect(seen.headers['Authorization'], 'Bearer abc');
    });

    test('sends no authorization header without an access token', () async {
      late http.BaseRequest seen;
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          seen = request;
          return http.Response('{}', 200);
        }),
        tokens: FakeTokenSource(),
      );

      await client.get(url);

      expect(
        seen.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
    });

    test('keeps the headers and body the caller set', () async {
      late http.Request seen;
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          seen = request;
          return http.Response('{}', 200);
        }),
        tokens: FakeTokenSource(accessToken: 'abc'),
      );

      await client.post(
        url,
        headers: {'content-type': 'application/json', 'x-custom': '1'},
        body: '{"a":1}',
      );

      expect(seen.method, 'POST');
      expect(seen.url, url);
      expect(seen.headers['x-custom'], '1');
      expect(seen.body, '{"a":1}');
    });
  });

  group('responses that need no refresh', () {
    for (final status in [200, 400, 403, 404, 500]) {
      test('passes a $status response through untouched', () async {
        final tokens = FakeTokenSource(accessToken: 'abc');
        var calls = 0;
        final client = AuthHttpClient(
          inner: MockClient((request) async {
            calls++;
            return http.Response('{"code":"X"}', status);
          }),
          tokens: tokens,
        );

        final response = await client.get(url);

        expect(response.statusCode, status);
        expect(response.body, '{"code":"X"}');
        expect(calls, 1);
        expect(tokens.refreshCalls, 0);
        expect(tokens.expireCalls, 0);
      });
    }

    test('does not refresh on a 401 with another code', () async {
      final tokens = FakeTokenSource(accessToken: 'abc');
      var calls = 0;
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          calls++;
          return http.Response('{"code":"INVALID_CREDENTIALS"}', 401);
        }),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(calls, 1);
      expect(tokens.refreshCalls, 0);
      expect(tokens.expireCalls, 0);
    });

    test('does not refresh on a 401 with a refresh token code', () async {
      final tokens = FakeTokenSource(accessToken: 'abc');
      final client = AuthHttpClient(
        inner: MockClient(
          (request) async =>
              http.Response('{"code":"REFRESH_TOKEN_INVALID"}', 401),
        ),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(tokens.refreshCalls, 0);
    });

    test('does not refresh on a 401 whose body is not JSON', () async {
      final tokens = FakeTokenSource(accessToken: 'abc');
      final client = AuthHttpClient(
        inner: MockClient(
          (request) async => http.Response('<html>nope</html>', 401),
        ),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(tokens.refreshCalls, 0);
    });

    test('does not refresh on a 401 with an empty body', () async {
      final tokens = FakeTokenSource(accessToken: 'abc');
      final client = AuthHttpClient(
        inner: MockClient((request) async => http.Response('', 401)),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(tokens.refreshCalls, 0);
    });
  });

  group('expired access token', () {
    test('refreshes once and re-sends with the new token', () async {
      final tokens = FakeTokenSource(accessToken: 'old');
      final seenAuth = <String?>[];
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          seenAuth.add(request.headers['Authorization']);
          if (request.headers['Authorization'] == 'Bearer old') {
            return invalidAccessToken();
          }
          return http.Response('{"ok":true}', 200);
        }),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 200);
      expect(response.body, '{"ok":true}');
      expect(seenAuth, ['Bearer old', 'Bearer new']);
      expect(tokens.refreshCalls, 1);
      expect(tokens.expireCalls, 0);
    });

    test('re-sends the same method, url, headers and body bytes', () async {
      final tokens = FakeTokenSource(accessToken: 'old');
      final seen = <http.Request>[];
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          seen.add(request);
          if (seen.length == 1) return invalidAccessToken();
          return http.Response('{}', 201);
        }),
        tokens: tokens,
      );
      final body = jsonEncode({'name': 'Kos Melati', 'note': 'ñandú'});

      final response = await client.post(
        url,
        headers: {'content-type': 'application/json', 'x-custom': '1'},
        body: body,
      );

      expect(response.statusCode, 201);
      expect(seen, hasLength(2));
      final first = seen[0];
      final retry = seen[1];
      expect(retry.method, first.method);
      expect(retry.url, first.url);
      expect(retry.bodyBytes, first.bodyBytes);
      expect(retry.body, body);
      expect(retry.headers['x-custom'], '1');
      expect(retry.headers['content-type'], first.headers['content-type']);
      expect(retry.headers['Authorization'], 'Bearer new');
    });

    test('returns the original 401 and expires the session when refresh '
        'fails', () async {
      final tokens = FakeTokenSource(accessToken: 'old', refreshResult: false);
      var calls = 0;
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          calls++;
          return invalidAccessToken();
        }),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(jsonDecode(response.body)['code'], 'ACCESS_TOKEN_INVALID');
      expect(calls, 1);
      expect(tokens.refreshCalls, 1);
      expect(tokens.expireCalls, 1);
    });

    test('returns a second 401 as is without looping', () async {
      final tokens = FakeTokenSource(accessToken: 'old');
      var calls = 0;
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          calls++;
          return invalidAccessToken();
        }),
        tokens: tokens,
      );

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(calls, 2);
      expect(tokens.refreshCalls, 1);
    });

    test('refreshes only once for concurrent requests', () async {
      final tokens = FakeTokenSource(
        accessToken: 'old',
        refreshDelay: const Duration(milliseconds: 20),
      );
      final client = AuthHttpClient(
        inner: MockClient((request) async {
          if (request.headers['Authorization'] == 'Bearer old') {
            return invalidAccessToken();
          }
          return http.Response('{"path":"${request.url.path}"}', 200);
        }),
        tokens: tokens,
      );

      final responses = await Future.wait([
        client.get(Uri.parse('https://api.example.com/a')),
        client.get(Uri.parse('https://api.example.com/b')),
        client.get(Uri.parse('https://api.example.com/c')),
      ]);

      expect(tokens.refreshCalls, 1);
      expect(tokens.expireCalls, 0);
      expect(responses.map((r) => r.statusCode), [200, 200, 200]);
      expect(responses.map((r) => r.body), [
        '{"path":"/a"}',
        '{"path":"/b"}',
        '{"path":"/c"}',
      ]);
    });

    test('expires the session once when concurrent refreshes fail', () async {
      final tokens = FakeTokenSource(
        accessToken: 'old',
        refreshResult: false,
        refreshDelay: const Duration(milliseconds: 20),
      );
      final client = AuthHttpClient(
        inner: MockClient((request) async => invalidAccessToken()),
        tokens: tokens,
      );

      final responses = await Future.wait([client.get(url), client.get(url)]);

      expect(tokens.refreshCalls, 1);
      expect(responses.map((r) => r.statusCode), [401, 401]);
    });
  });
}
