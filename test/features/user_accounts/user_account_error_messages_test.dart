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

  test('an owner with an active lease has its own Indonesian message', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'OWNER_HAS_ACTIVE_LEASE', statusCode: 409),
      ),
      'Pemilik ini masih memiliki properti dengan masa sewa aktif.',
    );
  });

  test('the message of an owner with an active lease is not generic', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'OWNER_HAS_ACTIVE_LEASE')),
      isNot(genericErrorMessage),
    );
  });

  test('a tenant with an active lease keeps its Indonesian message', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'TENANT_HAS_ACTIVE_LEASE', statusCode: 409),
      ),
      'Akun ini masih memiliki masa sewa aktif.',
    );
  });

  test('a deleted user account has its own Indonesian message', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'USER_ACCOUNT_DELETED', statusCode: 409),
      ),
      'Akun ini sudah dihapus.',
    );
  });

  test('the message of a missing user account is not the generic one', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'USER_ACCOUNT_NOT_FOUND')),
      isNot(genericErrorMessage),
    );
  });
}
