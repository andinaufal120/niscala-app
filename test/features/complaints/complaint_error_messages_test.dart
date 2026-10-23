import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _messages = {
  'NO_ACTIVE_LEASE':
      'Anda belum memiliki masa sewa aktif. Hubungi pengelola kost.',
  'COMPLAINT_NOT_FOUND': 'Keluhan tidak ditemukan.',
};

String _messageOf(String code) => errorMessageFor(ApiFailure(code: code));

void main() {
  for (final entry in _messages.entries) {
    test('maps an ApiFailure with ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('${entry.key} is not the generic message', () {
      expect(_messageOf(entry.key), isNot(_messageOf('SOMETHING_NEW')));
    });

    test('the message of ${entry.key} contains no English word', () {
      const english = ['lease', 'complaint', 'not found', 'active', 'error'];
      final message = _messageOf(entry.key).toLowerCase();
      for (final word in english) {
        expect(message.contains(word), isFalse, reason: '"$message" has $word');
      }
    });
  }
}
