import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

void main() {
  test('a receipt review of a bill that changed has its own message', () {
    expect(
      errorMessageFor(
        const ApiFailure(
          code: 'RENT_BILL_NOT_AWAITING_VERIFICATION',
          statusCode: 409,
        ),
      ),
      'Status pembayaran sudah diubah oleh pengguna lain.',
    );
  });

  test('an invalid rejection reason names the field', () {
    expect(
      errorMessageFor(
        const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'reason',
          statusCode: 422,
        ),
      ),
      'Alasan penolakan tidak valid.',
    );
  });

  test('the other review failures keep their messages', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'RENT_BILL_NOT_FOUND')),
      'Tagihan tidak ditemukan.',
    );
    expect(
      errorMessageFor(const ApiFailure(code: 'FORBIDDEN')),
      'Anda tidak memiliki akses untuk tindakan ini.',
    );
    expect(
      errorMessageFor(const ApiFailure.network()),
      'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
    );
    expect(
      errorMessageFor(const ApiFailure(code: 'INTERNAL_ERROR')),
      'Terjadi kesalahan pada server. Coba lagi.',
    );
  });
}
