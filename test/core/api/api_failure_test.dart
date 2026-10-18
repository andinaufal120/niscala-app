import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';

void main() {
  test('keeps the code, field and status code it was created with', () {
    const failure = ApiFailure(
      code: 'ROOM_NUMBER_TAKEN',
      field: 'number',
      statusCode: 409,
    );

    expect(failure.code, 'ROOM_NUMBER_TAKEN');
    expect(failure.field, 'number');
    expect(failure.statusCode, 409);
  });

  test('field and status code are optional', () {
    const failure = ApiFailure(code: 'FORBIDDEN');

    expect(failure.field, isNull);
    expect(failure.statusCode, isNull);
  });

  test('network failure has the network error code and nothing else', () {
    const failure = ApiFailure.network();

    expect(failure.code, 'NETWORK_ERROR');
    expect(failure.field, isNull);
    expect(failure.statusCode, isNull);
  });

  test('is an exception', () {
    expect(const ApiFailure.network(), isA<Exception>());
  });
}
