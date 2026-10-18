import 'package:niscala/core/api/api_failure.dart';

const _fallback = 'Terjadi kesalahan. Coba lagi.';

const _sessionEnded = 'Sesi Anda telah berakhir. Silakan masuk lagi.';

const _messages = {
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
  'INVITATION_NOT_FOUND': 'Undangan tidak ditemukan. Periksa tautan Anda.',
  'FORBIDDEN': 'Anda tidak memiliki akses untuk tindakan ini.',
  'ACCESS_TOKEN_INVALID': _sessionEnded,
  'REFRESH_TOKEN_INVALID': _sessionEnded,
};

/// The Indonesian message for an API error code. Unknown codes, and
/// validation failures (which are shown next to their field), get a generic
/// message.
String errorMessage(String code) => _messages[code] ?? _fallback;

/// The Indonesian message for an error caught by a screen. Anything other
/// than an [ApiFailure] gets the generic message.
String errorMessageFor(Object error) =>
    errorMessage(error is ApiFailure ? error.code : 'UNKNOWN');
