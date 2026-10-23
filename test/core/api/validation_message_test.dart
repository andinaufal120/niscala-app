import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

const _fallback = 'Terjadi kesalahan. Coba lagi.';
const _unknownField = 'Data tidak valid.';

const _knownFields = {
  'email': 'Email tidak valid.',
  'password': 'Kata sandi tidak valid.',
  'fullName': 'Nama lengkap tidak valid.',
  'address': 'Alamat tidak valid.',
  'bankAccount.bankName': 'Nama bank tidak valid.',
  'bankAccount.accountNumber': 'Nomor rekening tidak valid.',
  'bankAccount.accountHolderName': 'Nama pemilik rekening tidak valid.',
  'number': 'Nomor kamar tidak valid.',
  'baseRate': 'Tarif dasar per bulan tidak valid.',
  'lengthM': 'Panjang tidak valid.',
  'widthM': 'Lebar tidak valid.',
  'facilities': 'Fasilitas tidak valid.',
  'phone': 'Nomor telepon tidak valid.',
  'description': 'Keluhan tidak valid.',
};

void main() {
  group('validationMessage', () {
    for (final entry in _knownFields.entries) {
      test('names the label of the ${entry.key} field', () {
        expect(validationMessage(entry.key), entry.value);
      });
    }

    test('names the property name for the name field of a property', () {
      expect(validationMessage('name'), 'Nama properti tidak valid.');
    });

    for (final field in [
      null,
      '',
      'managers',
      'propertyId',
      'somethingNew',
      'lease.gracePeriodDays',
    ]) {
      test('gives the plain message for the field "$field"', () {
        expect(validationMessage(field), _unknownField);
      });
    }

    test('never gives the generic message', () {
      for (final field in [..._knownFields.keys, 'name', null, 'x']) {
        expect(validationMessage(field), isNot(_fallback), reason: '$field');
      }
    });

    test('is written in Indonesian', () {
      const english = ['password', 'error', 'invalid', 'failed', 'not found'];
      for (final field in [..._knownFields.keys, 'name', null]) {
        final message = validationMessage(field).toLowerCase();
        for (final word in english) {
          expect(message.contains(word), isFalse, reason: '$field: $message');
        }
      }
    });
  });

  group('errorMessageFor a validation failure', () {
    test('uses the message of the field', () {
      const failure = ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'email',
        statusCode: 422,
      );

      expect(errorMessageFor(failure), 'Email tidak valid.');
    });

    for (final entry in _knownFields.entries) {
      test('agrees with validationMessage for ${entry.key}', () {
        final failure = ApiFailure(code: 'VALIDATION_FAILED', field: entry.key);

        expect(errorMessageFor(failure), entry.value);
      });
    }

    test('gives the plain message when there is no field', () {
      expect(
        errorMessageFor(const ApiFailure(code: 'VALIDATION_FAILED')),
        _unknownField,
      );
    });

    test('gives the plain message for a field it does not know', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'managers'),
        ),
        _unknownField,
      );
    });

    test('is never the generic message', () {
      for (final field in [..._knownFields.keys, 'name', 'x', null]) {
        expect(
          errorMessageFor(ApiFailure(code: 'VALIDATION_FAILED', field: field)),
          isNot(_fallback),
          reason: '$field',
        );
      }
    });
  });

  group('errorMessageFor other errors', () {
    test('ignores the field of a failure that is not a validation failure', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
        ),
        'Nomor kamar sudah dipakai.',
      );
    });

    test('keeps the generic message for an unknown code with a field', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'SOMETHING_NEW', field: 'email'),
        ),
        _fallback,
      );
    });

    test(
      'keeps the generic message for an error that is not an ApiFailure',
      () {
        expect(errorMessageFor(StateError('boom')), _fallback);
      },
    );

    test('keeps the message of a network failure', () {
      expect(
        errorMessageFor(const ApiFailure.network()),
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    });
  });

  group('personFormLabels', () {
    test('names the name field as the full name', () {
      expect(personFormLabels, {'name': 'Nama lengkap'});
    });
  });

  group('validationMessage with labels', () {
    test('uses the label given for the field instead of the default', () {
      expect(
        validationMessage('name', labels: personFormLabels),
        'Nama lengkap tidak valid.',
      );
    });

    test('keeps the default label of a field the labels do not name', () {
      expect(
        validationMessage('email', labels: personFormLabels),
        'Email tidak valid.',
      );
      expect(
        validationMessage('phone', labels: personFormLabels),
        'Nomor telepon tidak valid.',
      );
    });

    test('keeps the plain message for a field nobody knows', () {
      expect(
        validationMessage('managers', labels: personFormLabels),
        _unknownField,
      );
      expect(validationMessage(null, labels: personFormLabels), _unknownField);
    });

    test('accepts an empty map and a null map like no labels', () {
      expect(
        validationMessage('name', labels: const {}),
        'Nama properti tidak valid.',
      );
      expect(
        validationMessage('name', labels: null),
        'Nama properti tidak valid.',
      );
    });

    test('uses any label map it is given', () {
      expect(
        validationMessage('address', labels: const {'address': 'Alamat kost'}),
        'Alamat kost tidak valid.',
      );
    });

    test('leaves the default table unchanged for later calls', () {
      validationMessage('name', labels: personFormLabels);

      expect(validationMessage('name'), 'Nama properti tidak valid.');
    });
  });

  group('errorMessageFor with labels', () {
    const nameFailure = ApiFailure(code: 'VALIDATION_FAILED', field: 'name');

    test('uses the label for a validation failure on that field', () {
      expect(
        errorMessageFor(nameFailure, labels: personFormLabels),
        'Nama lengkap tidak valid.',
      );
    });

    test('keeps the property label without labels', () {
      expect(errorMessageFor(nameFailure), 'Nama properti tidak valid.');
    });

    test('keeps the default label of other fields', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'email'),
          labels: personFormLabels,
        ),
        'Email tidak valid.',
      );
    });

    test('gives the plain message without a field', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'VALIDATION_FAILED'),
          labels: personFormLabels,
        ),
        _unknownField,
      );
    });

    test('does not change the message of other codes', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'name'),
          labels: personFormLabels,
        ),
        'Nomor kamar sudah dipakai.',
      );
      expect(
        errorMessageFor(const ApiFailure.network(), labels: personFormLabels),
        errorMessageFor(const ApiFailure.network()),
      );
    });

    test('keeps the generic message for an unknown code', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'SOMETHING_NEW', field: 'name'),
          labels: personFormLabels,
        ),
        _fallback,
      );
    });

    test(
      'keeps the generic message for an error that is not an ApiFailure',
      () {
        expect(
          errorMessageFor(StateError('boom'), labels: personFormLabels),
          _fallback,
        );
      },
    );
  });
}
