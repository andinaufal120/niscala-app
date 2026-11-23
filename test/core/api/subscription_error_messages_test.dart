import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _fallback = 'Terjadi kesalahan. Coba lagi.';

const _table = {
  'SUBSCRIPTION_NOT_AN_UPGRADE':
      'Paket yang dipilih harus lebih tinggi dari paket Anda saat ini.',
  'SUBSCRIPTION_NOT_A_DOWNGRADE':
      'Paket tujuan harus lebih rendah dari paket Anda saat ini.',
  'KEPT_PROPERTIES_INVALID':
      'Pilihan properti tidak sesuai dengan paket tujuan.',
  'KEPT_ROOMS_INVALID': 'Pilihan kamar tidak sesuai dengan paket tujuan.',
  'SUBSCRIPTION_ORDER_NOT_FOUND': 'Pesanan langganan tidak ditemukan.',
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
      });

      test('does not fall back to the generic message for ${entry.key}', () {
        expect(errorMessageFor(ApiFailure(code: entry.key)), isNot(_fallback));
      });
    }
  });
}
