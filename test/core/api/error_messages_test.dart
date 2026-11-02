import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
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
  'COMPLAINT_NOT_FOUND': 'Keluhan tidak ditemukan.',
  'COMPLAINT_STATUS_NOT_NEXT':
      'Status keluhan sudah diubah oleh pengguna lain.',
  'SESSION_NOT_FOUND': 'Perangkat ini sudah keluar atau tidak ditemukan.',
  'SESSION_IS_CURRENT':
      'Perangkat yang sedang dipakai keluar lewat tombol Keluar.',
  'CURRENT_PASSWORD_INCORRECT': 'Kata sandi saat ini salah.',
  'PASSWORD_UNCHANGED': 'Kata sandi baru harus berbeda dari yang sekarang.',
  'TOO_MANY_ATTEMPTS':
      'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.',
  'INVITATION_ROLE_MISMATCH':
      'Undangan ini untuk peran lain. Akun Anda tidak dapat menerimanya.',
  'TENANT_HAS_ACTIVE_LEASE': 'Akun ini masih memiliki masa sewa aktif.',
  'MANAGER_ALREADY_ADDED': 'Anda sudah menjadi pengelola untuk pemilik ini.',
  'COMPLAINT_CATEGORY_INVALID':
      'Kategori tidak valid. Pilih kategori dari daftar.',
  'FORBIDDEN': 'Anda tidak memiliki akses untuk tindakan ini.',
  'ACCESS_TOKEN_INVALID': 'Sesi Anda telah berakhir. Silakan masuk lagi.',
  'REFRESH_TOKEN_INVALID': 'Sesi Anda telah berakhir. Silakan masuk lagi.',
};

String _messageOf(String code) => errorMessageFor(ApiFailure(code: code));

void main() {
  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(_messageOf(entry.key), entry.value);
    });

    test('maps ${entry.key} with a field to the same message', () {
      expect(
        errorMessageFor(ApiFailure(code: entry.key, field: 'email')),
        entry.value,
      );
    });
  }

  test('maps a network failure to the message of NETWORK_ERROR', () {
    expect(
      errorMessageFor(const ApiFailure.network()),
      _table['NETWORK_ERROR'],
    );
  });

  test('falls back to the generic message for an unknown code', () {
    expect(_messageOf('SOMETHING_NEW'), _fallback);
  });

  test('falls back to the generic message for an empty code', () {
    expect(_messageOf(''), _fallback);
  });

  test('falls back to the generic message for an error of another type', () {
    expect(errorMessageFor(StateError('boom')), _fallback);
    expect(errorMessageFor('NETWORK_ERROR'), _fallback);
  });

  test('names the field of a validation failure instead of the fallback', () {
    expect(
      errorMessageFor(
        const ApiFailure(code: 'VALIDATION_FAILED', field: 'email'),
      ),
      'Email tidak valid.',
    );
  });

  test('gives the plain message for a validation failure without a field', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'VALIDATION_FAILED')),
      'Data tidak valid.',
    );
  });

  test('no message contains an English word', () {
    const english = ['password', 'error', 'invalid', 'failed', 'not found'];
    final messages = [..._table.keys.map(_messageOf), _fallback];

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
