import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _table = {
  'PASSWORD_RESET_NOT_FOUND':
      'Tautan atur ulang tidak ditemukan atau tidak berlaku. '
      'Minta tautan baru.',
  'PASSWORD_RESET_USED':
      'Tautan atur ulang ini sudah dipakai atau diganti. Minta tautan baru.',
  'PASSWORD_RESET_EXPIRED':
      'Tautan atur ulang sudah kedaluwarsa. Minta tautan baru.',
};

String _messageOf(String code, {String? field}) =>
    errorMessageFor(ApiFailure(code: code, field: field));

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('maps ${entry.key} with a field to the same message', () {
      expect(_messageOf(entry.key, field: 'token'), entry.value);
    });

    test('${entry.key} is not the generic message', () {
      expect(_messageOf(entry.key), isNot(genericErrorMessage));
    });

    test('${entry.key} does not show the code or English text', () {
      final message = _messageOf(entry.key);
      expect(message, isNot(contains('PASSWORD_RESET')));
      expect(message, isNot(contains('expired')));
      expect(message, isNot(contains('not found')));
    });
  }

  test('the three link messages differ from each other', () {
    expect(_table.values.toSet(), hasLength(3));
  });

  test('every link message says a new link can be requested', () {
    for (final code in _table.keys) {
      expect(_messageOf(code), contains('Minta tautan baru'));
    }
  });

  test('a rejected common password keeps its existing message', () {
    expect(
      _messageOf('PASSWORD_TOO_COMMON', field: 'newPassword'),
      'Kata sandi terlalu umum. Pilih kata sandi lain.',
    );
  });
}
