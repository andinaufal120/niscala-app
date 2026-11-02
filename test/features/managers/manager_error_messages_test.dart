import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

void main() {
  group('manager error messages', () {
    const messages = {
      'MANAGER_NOT_FOUND': 'Pengelola tidak ditemukan.',
      'MANAGER_NAME_NOT_EDITABLE':
          'Nama Pengelola yang sudah aktif tidak dapat diubah.',
      'MANAGER_ALREADY_ACTIVE':
          'Pengelola ini sudah aktif, tautan undangan tidak diperlukan.',
    };
    for (final entry in messages.entries) {
      test('${entry.key} is explained in Indonesian', () {
        expect(errorMessageFor(ApiFailure(code: entry.key)), entry.value);
      });
    }

    test('a name that cannot be changed keeps its message with a field', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'MANAGER_NAME_NOT_EDITABLE', field: 'name'),
        ),
        'Nama Pengelola yang sudah aktif tidak dapat diubah.',
      );
    });

    test('an unknown property is explained with the property message', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'PROPERTY_NOT_FOUND', field: 'propertyIds.1'),
        ),
        'Properti tidak ditemukan.',
      );
    });

    test('a name validation error names the full name of the person', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'name'),
          labels: personFormLabels,
        ),
        'Nama lengkap tidak valid.',
      );
    });

    test('a phone validation error names the phone number', () {
      expect(
        errorMessageFor(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        ),
        'Nomor telepon tidak valid.',
      );
    });
  });
}
