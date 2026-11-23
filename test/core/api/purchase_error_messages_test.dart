import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _fallback = 'Terjadi kesalahan. Coba lagi.';

const _table = {
  'SUBSCRIPTION_ORDER_CLOSED':
      'Pesanan ini sudah ditutup. Buat pesanan baru untuk membayar.',
  'PURCHASE_TOKEN_IN_USE': 'Pembelian ini sudah dipakai oleh akun lain.',
  'PURCHASE_TOKEN_INVALID':
      'Google Play tidak mengenali pembelian ini. Coba bayar lagi.',
  'PURCHASE_PRODUCT_MISMATCH': 'Paket yang dibeli tidak sesuai dengan pesanan.',
  'GOOGLE_PLAY_UNREACHABLE':
      'Google Play sedang tidak dapat dijangkau. Coba lagi nanti.',
};

void main() {
  group('errorMessageFor', () {
    for (final entry in _table.entries) {
      test('maps ${entry.key} to its Indonesian text', () {
        expect(errorMessageFor(ApiFailure(code: entry.key)), entry.value);
      });

      test('gives the same text whatever the status of ${entry.key}', () {
        expect(
          errorMessageFor(ApiFailure(code: entry.key, statusCode: 409)),
          entry.value,
        );
        expect(
          errorMessageFor(ApiFailure(code: entry.key, statusCode: 503)),
          entry.value,
        );
      });

      test('does not fall back to the generic message for ${entry.key}', () {
        expect(errorMessageFor(ApiFailure(code: entry.key)), isNot(_fallback));
      });
    }
  });
}
