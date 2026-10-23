import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _table = {
  'RECEIPT_TYPE_INVALID': 'Bukti transfer harus berupa gambar JPG atau PNG.',
  'RECEIPT_TOO_LARGE': 'Ukuran bukti transfer maksimal 5 MB.',
  'RENT_BILL_NOT_UPLOADABLE': 'Bukti transfer untuk tagihan ini tidak bisa diunggah. Bayar tunai ke pengelola kost.',
  'PROPERTY_BANK_ACCOUNT_MISSING': 'Properti ini belum memiliki rekening bank. Bayar tunai ke pengelola kost.',
  'RENT_BILL_NOT_FOUND': 'Tagihan tidak ditemukan.',
  'RECEIPT_NOT_FOUND': 'Bukti transfer tidak ditemukan.',
};

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(errorMessageFor(ApiFailure(code: entry.key)), entry.value);
    });
  }

  test('names the receipt file in a validation message', () {
    expect(validationMessage('file'), 'Bukti transfer tidak valid.');
  });

  test('shows the file message for a validation failure on the file', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'VALIDATION_FAILED', field: 'file'),
      ),
      'Bukti transfer tidak valid.',
    );
  });

  test('no message contains an English word', () {
    const english = ['receipt', 'error', 'invalid', 'failed', 'not found'];

    for (final message in _table.keys.map(
      (code) => errorMessageFor(ApiFailure(code: code)),
    )) {
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
