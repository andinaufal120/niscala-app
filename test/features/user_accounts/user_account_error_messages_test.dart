import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

void main() {
  test('a missing user account has its own Indonesian message', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'USER_ACCOUNT_NOT_FOUND', statusCode: 404),
      ),
      'Akun pengguna tidak ditemukan.',
    );
  });

  test('the message of a missing user account is not the generic one', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'USER_ACCOUNT_NOT_FOUND')),
      isNot(genericErrorMessage),
    );
  });
}
