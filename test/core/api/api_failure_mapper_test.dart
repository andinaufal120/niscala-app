import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala_api/api.dart';

void expectNetwork(ApiFailure failure) {
  expect(failure.code, 'NETWORK_ERROR');
  expect(failure.field, isNull);
  expect(failure.statusCode, isNull);
}

void main() {
  group('toApiFailure with a JSON error body', () {
    test('keeps the code, field and status code', () {
      final failure = toApiFailure(
        ApiException(
          422,
          '{"code":"ROOM_NUMBER_TAKEN","field":"number","message":"Taken"}',
        ),
      );

      expect(failure.code, 'ROOM_NUMBER_TAKEN');
      expect(failure.field, 'number');
      expect(failure.statusCode, 422);
    });

    test('leaves the field empty when the body has none', () {
      final failure = toApiFailure(
        ApiException(401, '{"code":"INVALID_CREDENTIALS","message":"No"}'),
      );

      expect(failure.code, 'INVALID_CREDENTIALS');
      expect(failure.field, isNull);
      expect(failure.statusCode, 401);
    });
  });

  group('toApiFailure with a body that is not an error object', () {
    test('uses INTERNAL_ERROR for a 5xx status', () {
      final failure = toApiFailure(ApiException(500, '<html>oops</html>'));

      expect(failure.code, 'INTERNAL_ERROR');
      expect(failure.statusCode, 500);
    });

    test('uses UNKNOWN for a non-5xx status', () {
      final failure = toApiFailure(ApiException(404, 'not json'));

      expect(failure.code, 'UNKNOWN');
      expect(failure.statusCode, 404);
    });

    test('uses UNKNOWN for an empty body', () {
      final failure = toApiFailure(ApiException(400, ''));

      expect(failure.code, 'UNKNOWN');
      expect(failure.statusCode, 400);
    });

    test('uses UNKNOWN for JSON without a code', () {
      final failure = toApiFailure(ApiException(400, '{"message":"x"}'));

      expect(failure.code, 'UNKNOWN');
      expect(failure.statusCode, 400);
    });
  });

  group('toApiFailure with transport errors', () {
    test('maps a socket exception to a network failure', () {
      expectNetwork(toApiFailure(const SocketException('down')));
    });

    test('maps an http client exception to a network failure', () {
      expectNetwork(toApiFailure(http.ClientException('down')));
    });

    test('maps a timeout to a network failure', () {
      expectNetwork(toApiFailure(TimeoutException('slow')));
    });

    test('maps an API exception wrapping an inner exception to a network '
        'failure', () {
      expectNetwork(
        toApiFailure(
          ApiException.withInner(
            400,
            'Connection failed',
            const SocketException('down'),
            StackTrace.empty,
          ),
        ),
      );
    });
  });

  test('passes an ApiFailure through unchanged', () {
    const original = ApiFailure(code: 'FORBIDDEN', statusCode: 403);

    expect(toApiFailure(original), same(original));
  });

  test('maps any other error to UNKNOWN', () {
    final failure = toApiFailure(StateError('boom'));

    expect(failure.code, 'UNKNOWN');
    expect(failure.statusCode, isNull);
  });
}
