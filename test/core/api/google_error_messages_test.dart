import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _table = {
  'GOOGLE_TOKEN_INVALID': 'Masuk dengan Google gagal. Coba lagi.',
  'GOOGLE_EMAIL_UNVERIFIED': 'Email akun Google ini belum terverifikasi.',
  'GOOGLE_ACCOUNT_ALREADY_REGISTERED':
      'Akun Google ini sudah terdaftar. Masuk dengan Google.',
  'GOOGLE_ACCOUNT_MISMATCH':
      'Akun Google yang dipilih berbeda dari akun yang terhubung.',
  'ACCOUNT_INACTIVE': 'Akun ini dinonaktifkan. Hubungi admin.',
  'GOOGLE_SIGN_IN_UNAVAILABLE': 'Masuk dengan Google belum tersedia.',
};

String _messageOf(String code, {String? field}) =>
    errorMessageFor(ApiFailure(code: code, field: field));

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('maps ${entry.key} with a field to the same message', () {
      expect(_messageOf(entry.key, field: 'idToken'), entry.value);
    });

    test('${entry.key} is not the generic message', () {
      expect(_messageOf(entry.key), isNot(genericErrorMessage));
    });

    test('${entry.key} does not show the code', () {
      expect(_messageOf(entry.key), isNot(contains(entry.key)));
    });
  }

  test('every Google message differs from the others', () {
    expect(_table.values.toSet(), hasLength(_table.length));
  });

  test('the password credential message keeps its wording', () {
    expect(_messageOf('INVALID_CREDENTIALS'), 'Email atau kata sandi salah.');
  });

  test('the existing email conflict message keeps its wording', () {
    expect(_messageOf('EMAIL_ALREADY_REGISTERED'), 'Email sudah terdaftar.');
  });
}
