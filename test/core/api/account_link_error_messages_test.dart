import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _table = {
  'PASSWORD_ALREADY_SET': 'Akun ini sudah punya kata sandi.',
  'GOOGLE_ALREADY_LINKED': 'Akun ini sudah terhubung ke Google.',
  'GOOGLE_NOT_LINKED': 'Akun ini belum terhubung ke Google.',
  'PASSWORD_LOGIN_REQUIRED':
      'Masuk dengan email dan kata sandi dulu sebelum menghubungkan Google.',
};

String _messageOf(String code, {String? field, int? statusCode}) =>
    errorMessageFor(
      ApiFailure(code: code, field: field, statusCode: statusCode),
    );

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('maps ${entry.key} with a status and a field to the same message', () {
      expect(
        _messageOf(entry.key, field: 'idToken', statusCode: 409),
        entry.value,
      );
    });

    test('${entry.key} is not the generic message', () {
      expect(_messageOf(entry.key), isNot(genericErrorMessage));
    });

    test('${entry.key} does not show the code', () {
      expect(_messageOf(entry.key), isNot(contains(entry.key)));
    });
  }

  test('every account linking message differs from the others', () {
    expect(_table.values.toSet(), hasLength(_table.length));
  });

  test('the sign-up wording of an already registered Google account stays', () {
    expect(
      _messageOf('GOOGLE_ACCOUNT_ALREADY_REGISTERED'),
      'Akun Google ini sudah terdaftar. Masuk dengan Google.',
    );
  });

  test('the Google messages used by linking keep their wording', () {
    expect(
      _messageOf('GOOGLE_TOKEN_INVALID'),
      'Masuk dengan Google gagal. Coba lagi.',
    );
    expect(
      _messageOf('GOOGLE_EMAIL_UNVERIFIED'),
      'Email akun Google ini belum terverifikasi.',
    );
    expect(
      _messageOf('GOOGLE_ACCOUNT_MISMATCH'),
      'Akun Google yang dipilih berbeda dari akun yang terhubung.',
    );
  });
}
