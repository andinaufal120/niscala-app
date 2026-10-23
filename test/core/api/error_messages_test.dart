import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/error_messages.dart';

const _fallback = 'Terjadi kesalahan. Coba lagi.';

const _table = {
  'NETWORK_ERROR':
      'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
  'INTERNAL_ERROR': 'Terjadi kesalahan pada server. Coba lagi.',
  'INVALID_CREDENTIALS': 'Email atau kata sandi salah.',
  'TOO_MANY_LOGIN_ATTEMPTS':
      'Terlalu banyak percobaan masuk yang gagal. Coba lagi dalam 15 menit.',
  'EMAIL_ALREADY_REGISTERED': 'Email sudah terdaftar.',
  'EMAIL_NOT_VERIFIED': 'Email belum diverifikasi.',
  'EMAIL_ALREADY_VERIFIED': 'Email sudah diverifikasi.',
  'VERIFICATION_CODE_INVALID': 'Kode verifikasi salah.',
  'VERIFICATION_CODE_EXPIRED':
      'Kode verifikasi sudah kedaluwarsa. Minta kode baru.',
  'VERIFICATION_CODE_TOO_SOON': 'Tunggu sebentar sebelum meminta kode baru.',
  'PASSWORD_TOO_COMMON': 'Kata sandi terlalu umum. Pilih kata sandi lain.',
  'PASSWORD_INCORRECT': 'Kata sandi salah.',
  'PASSWORD_NOT_SET': 'Akun ini belum memiliki kata sandi.',
  'REAUTHENTICATION_REQUIRED': 'Masukkan kata sandi Anda untuk melanjutkan.',
  'PROPERTY_NAME_TAKEN': 'Nama properti sudah dipakai.',
  'PROPERTY_LIMIT_REACHED':
      'Batas jumlah properti pada paket Anda sudah tercapai.',
  'PROPERTY_READ_ONLY':
      'Properti ini hanya bisa dilihat karena paket Anda diturunkan.',
  'PROPERTY_NOT_FOUND': 'Properti tidak ditemukan.',
  'ROOM_NUMBER_TAKEN': 'Nomor kamar sudah dipakai.',
  'ROOM_LIMIT_REACHED': 'Batas jumlah kamar pada paket Anda sudah tercapai.',
  'ROOM_READ_ONLY':
      'Kamar ini hanya bisa dilihat karena paket Anda diturunkan.',
  'ROOM_HAS_ACTIVE_LEASE': 'Kamar ini masih memiliki masa sewa aktif. Akhiri masa sewa terlebih dahulu.',
  'PROPERTY_HAS_ACTIVE_LEASE': 'Masih ada masa sewa aktif di properti ini. Akhiri semua masa sewa terlebih dahulu.',
  'ROOM_NOT_FOUND': 'Kamar tidak ditemukan.',
  'ROOM_NOT_VACANT': 'Kamar sudah terisi.',
  'TENANT_NOT_FOUND': 'Penyewa tidak ditemukan.',
  'FORBIDDEN': 'Anda tidak memiliki akses untuk tindakan ini.',
  'ACCESS_TOKEN_INVALID': 'Sesi Anda telah berakhir. Silakan masuk lagi.',
  'REFRESH_TOKEN_INVALID': 'Sesi Anda telah berakhir. Silakan masuk lagi.',
};

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(errorMessage(entry.key), entry.value);
    });
  }

  test('falls back to the generic message for an unknown code', () {
    expect(errorMessage('SOMETHING_NEW'), _fallback);
  });

  test('falls back to the generic message for an empty code', () {
    expect(errorMessage(''), _fallback);
  });

  test('shows the generic message for a validation failure', () {
    expect(errorMessage('VALIDATION_FAILED'), _fallback);
  });

  test('no message contains an English word', () {
    const english = ['password', 'error', 'invalid', 'failed', 'not found'];
    final messages = [..._table.keys.map(errorMessage), _fallback];

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
