import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

import '../../helpers/fakes.dart';

const _message =
    'Data ini sudah diubah oleh pengguna lain. Data terbaru sudah dimuat ulang.';

void main() {
  test('maps RESOURCE_VERSION_CONFLICT to its Indonesian message', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'RESOURCE_VERSION_CONFLICT')),
      _message,
    );
  });

  test(
    'maps RESOURCE_VERSION_CONFLICT with its status to the same message',
    () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'RESOURCE_VERSION_CONFLICT', statusCode: 409),
        ),
        _message,
      );
    },
  );

  test('the message reaches screens through the shared helper', () {
    expect(messageOfCode('RESOURCE_VERSION_CONFLICT'), _message);
  });

  test('the message is not the generic fallback', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'RESOURCE_VERSION_CONFLICT')),
      isNot(errorMessageFor(const ApiFailure(code: 'SOMETHING_NEW'))),
    );
  });
}
