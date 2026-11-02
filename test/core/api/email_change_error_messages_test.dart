import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _table = {
  'EMAIL_CHANGE_NOT_FOUND': 'Tautan tidak ditemukan atau tidak valid.',
  'EMAIL_CHANGE_USED': 'Tautan ini sudah digunakan.',
  'EMAIL_CHANGE_EXPIRED':
      'Tautan sudah kedaluwarsa. Minta admin mengirim ulang.',
  'EMAIL_ALREADY_REGISTERED': 'Email sudah terdaftar.',
  'CANNOT_MODIFY_OWN_ACCOUNT':
      'Anda tidak dapat menonaktifkan akun Anda sendiri.',
  'USER_ACCOUNT_DELETED': 'Akun ini sudah dihapus.',
};

String _messageOf(String code, {String? field}) =>
    errorMessageFor(ApiFailure(code: code, field: field));

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('maps ${entry.key} with a field to the same message', () {
      expect(_messageOf(entry.key, field: 'email'), entry.value);
    });

    test('${entry.key} is not the generic message', () {
      expect(_messageOf(entry.key), isNot(genericErrorMessage));
    });

    test('${entry.key} does not show the code', () {
      final message = _messageOf(entry.key);
      expect(message, isNot(contains('_')));
      expect(message, isNot(contains('EMAIL_')));
    });
  }

  test('the messages differ from each other', () {
    expect(_table.values.toSet(), hasLength(_table.length));
  });

  test('an expired link tells the user to ask the admin for a new one', () {
    expect(_messageOf('EMAIL_CHANGE_EXPIRED'), contains('admin'));
  });
}
