import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _messages = {
  'PHOTO_TYPE_INVALID': 'Foto harus JPG atau PNG.',
  'PHOTO_TOO_LARGE': 'Ukuran foto maksimal 5 MB.',
  'COMPLAINT_NOT_NEW': 'Foto hanya bisa diubah selama keluhan berstatus Baru.',
  'PHOTO_NOT_FOUND': 'Foto tidak ditemukan.',
};

String _messageOf(String code, {String? field, int? statusCode}) =>
    errorMessageFor(
      ApiFailure(code: code, field: field, statusCode: statusCode),
    );

void main() {
  for (final entry in _messages.entries) {
    test('maps an ApiFailure with ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('maps ${entry.key} the same whatever field and status it carries', () {
      expect(
        _messageOf(entry.key, field: 'file', statusCode: 422),
        entry.value,
      );
      expect(_messageOf(entry.key, statusCode: 409), entry.value);
    });

    test('${entry.key} is not the generic message', () {
      expect(_messageOf(entry.key), isNot(_messageOf('SOMETHING_NEW')));
    });

    test('the message of ${entry.key} contains no English word', () {
      const english = ['photo', 'file', 'image', 'large', 'found', 'only'];
      final message = _messageOf(entry.key).toLowerCase();
      for (final word in english) {
        expect(message.contains(word), isFalse, reason: '"$message" has $word');
      }
    });
  }

  test('the photo messages differ from the receipt messages', () {
    expect(
      _messageOf('PHOTO_TYPE_INVALID'),
      isNot(_messageOf('RECEIPT_TYPE_INVALID')),
    );
    expect(
      _messageOf('PHOTO_TOO_LARGE'),
      isNot(_messageOf('RECEIPT_TOO_LARGE')),
    );
  });

  test('the four photo messages are distinct', () {
    expect({
      for (final code in _messages.keys) _messageOf(code),
    }, hasLength(_messages.length));
  });
}
