import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

String _messageOf(String code, {String? field}) =>
    errorMessageFor(ApiFailure(code: code, field: field));

void main() {
  test('maps REASON_REQUIRED to its Indonesian message', () {
    expect(_messageOf('REASON_REQUIRED'), 'Alasan perubahan wajib diisi.');
  });

  test('maps REASON_REQUIRED with its field to the same message', () {
    expect(
      _messageOf('REASON_REQUIRED', field: 'reason'),
      'Alasan perubahan wajib diisi.',
    );
  });

  test('maps STATUS_UNCHANGED to its Indonesian message', () {
    expect(
      _messageOf('STATUS_UNCHANGED'),
      'Status baru harus berbeda dari status saat ini.',
    );
  });

  test('maps STATUS_UNCHANGED with its field to the same message', () {
    expect(
      _messageOf('STATUS_UNCHANGED', field: 'status'),
      'Status baru harus berbeda dari status saat ini.',
    );
  });

  test('names the payment method in a validation failure', () {
    expect(
      _messageOf('VALIDATION_FAILED', field: 'method'),
      'Metode pembayaran tidak valid.',
    );
  });

  test('names the status in a validation failure', () {
    expect(
      _messageOf('VALIDATION_FAILED', field: 'status'),
      'Status tidak valid.',
    );
  });

  test('names the reason of a rejection in a validation failure', () {
    expect(
      _messageOf('VALIDATION_FAILED', field: 'reason'),
      'Alasan penolakan tidak valid.',
    );
  });

  test('names the reason under another label when a screen asks for it', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'VALIDATION_FAILED', field: 'reason'),
        labels: const {'reason': 'Alasan perubahan'},
      ),
      'Alasan perubahan tidak valid.',
    );
  });

  test('keeps the date received message of an invalid date', () {
    expect(
      _messageOf('VALIDATION_FAILED', field: 'receivedOn'),
      'Tanggal diterima tidak valid.',
    );
  });

  test('keeps the message of a date in the future', () {
    expect(
      _messageOf('RECEIVED_ON_IN_FUTURE', field: 'receivedOn'),
      'Tanggal diterima tidak boleh lebih dari hari ini.',
    );
  });

  test('the new messages contain no English word', () {
    const english = ['password', 'error', 'invalid', 'failed', 'not found'];
    final messages = [
      _messageOf('REASON_REQUIRED'),
      _messageOf('STATUS_UNCHANGED'),
      _messageOf('VALIDATION_FAILED', field: 'method'),
      _messageOf('VALIDATION_FAILED', field: 'status'),
    ];

    for (final message in messages) {
      for (final word in english) {
        expect(
          message.toLowerCase().contains(word),
          isFalse,
          reason: '"$message" contains "$word"',
        );
      }
    }
  });
}
