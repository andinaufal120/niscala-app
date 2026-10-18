import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _messages = {
  'NO_ACTIVE_LEASE':
      'Anda belum memiliki masa sewa aktif. Hubungi pengelola kost.',
  'COMPLAINT_NOT_FOUND': 'Keluhan tidak ditemukan.',
};

void main() {
  for (final entry in _messages.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(errorMessage(entry.key), entry.value);
    });

    test('maps an ApiFailure with ${entry.key} to the same message', () {
      expect(errorMessageFor(ApiFailure(code: entry.key)), entry.value);
    });

    test('${entry.key} is not the generic message', () {
      expect(errorMessage(entry.key), isNot(errorMessage('SOMETHING_NEW')));
    });

    test('the message of ${entry.key} contains no English word', () {
      const english = ['lease', 'complaint', 'not found', 'active', 'error'];
      final message = errorMessage(entry.key).toLowerCase();
      for (final word in english) {
        expect(message.contains(word), isFalse, reason: '"$message" has $word');
      }
    });
  }
}
