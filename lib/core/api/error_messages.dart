import 'package:niscala/core/api/api_failure.dart';

const _fallback = 'Terjadi kesalahan. Coba lagi.';

const _sessionEnded = 'Sesi Anda telah berakhir. Silakan masuk lagi.';

const _unknownField = 'Data tidak valid.';

/// The Indonesian label of each API field that a validation failure can name.
const _fieldLabels = {
  'email': 'Email',
  'password': 'Kata sandi',
  'fullName': 'Nama lengkap',
  'name': 'Nama properti',
  'address': 'Alamat',
  'bankAccount.bankName': 'Nama bank',
  'bankAccount.accountNumber': 'Nomor rekening',
  'bankAccount.accountHolderName': 'Nama pemilik rekening',
  'number': 'Nomor kamar',
  'baseRate': 'Tarif dasar per bulan',
  'lengthM': 'Panjang',
  'widthM': 'Lebar',
  'facilities': 'Fasilitas',
  'phone': 'Nomor telepon',
  'description': 'Keluhan',
  'file': 'Bukti transfer',
};

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
  'NO_ACTIVE_LEASE':
      'Anda belum memiliki masa sewa aktif. Hubungi pengelola kost.',
  'COMPLAINT_NOT_FOUND': 'Keluhan tidak ditemukan.',
  'RECEIPT_TYPE_INVALID': 'Bukti transfer harus berupa gambar JPG atau PNG.',
  'RECEIPT_TOO_LARGE': 'Ukuran bukti transfer maksimal 5 MB.',
  'RENT_BILL_NOT_UPLOADABLE':
      'Bukti transfer untuk tagihan ini tidak bisa diunggah. '
      'Bayar tunai ke pengelola kost.',
  'PROPERTY_BANK_ACCOUNT_MISSING':
      'Properti ini belum memiliki rekening bank. '
      'Bayar tunai ke pengelola kost.',
  'RENT_BILL_NOT_FOUND': 'Tagihan tidak ditemukan.',
  'RECEIPT_NOT_FOUND': 'Bukti transfer tidak ditemukan.',
  'FORBIDDEN': 'Anda tidak memiliki akses untuk tindakan ini.',
  'ACCESS_TOKEN_INVALID': _sessionEnded,
  'REFRESH_TOKEN_INVALID': _sessionEnded,
};

/// The Indonesian message for an API error code. Unknown codes get the generic
/// message.
String _errorMessage(String code) => _messages[code] ?? _fallback;

/// The labels of the person form fields on screens where a person is named
/// differently from a property. Passed as the [labels] of [validationMessage]
/// or [errorMessageFor].
const personFormLabels = {'name': 'Nama lengkap'};

/// The Indonesian message for a validation failure on [field], such as
/// "Email tidak valid.". [labels] replaces the label of a known field, for a
/// screen that shows the field under another name. A null or unknown field
/// gets a plain message.
String validationMessage(String? field, {Map<String, String>? labels}) {
  if (field == null || !_fieldLabels.containsKey(field)) {
    return _unknownField;
  }
  return '${labels?[field] ?? _fieldLabels[field]} tidak valid.';
}

/// The Indonesian message for an error caught by a screen. A validation
/// failure gets the message of its field, with [labels] applied. Anything
/// other than an [ApiFailure] gets the generic message.
String errorMessageFor(Object error, {Map<String, String>? labels}) {
  if (error is! ApiFailure) return _fallback;
  if (error.code == 'VALIDATION_FAILED') {
    return validationMessage(error.field, labels: labels);
  }
  return _errorMessage(error.code);
}
