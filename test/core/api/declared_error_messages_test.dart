import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

import '../../helpers/fakes.dart';

const _table = {
  'TENANT_ALREADY_ACTIVE': 'Penyewa sudah mengaktifkan akunnya, jadi tautan undangan tidak diperlukan lagi.',
  'NOTIFICATION_NOT_FOUND': 'Notifikasi tidak ditemukan.',
  'NOTIFICATION_CATEGORIES_INVALID': 'Pengaturan notifikasi tidak sesuai dengan peran Anda. Muat ulang dan coba lagi.',
};

const _englishTerms = ['Tenant', 'Notification', 'Lease', 'Invite', 'Role'];

void main() {
  final generic = errorMessageFor(const ApiFailure(code: 'SOMETHING_NEW'));

  for (final entry in _table.entries) {
    test('maps ${entry.key} to its Indonesian message', () {
      expect(errorMessageFor(ApiFailure(code: entry.key)), entry.value);
    });

    test('maps ${entry.key} with its status to the same message', () {
      expect(
        errorMessageFor(ApiFailure(code: entry.key, statusCode: 409)),
        entry.value,
      );
    });

    test('${entry.key} reaches screens through the shared helper', () {
      expect(messageOfCode(entry.key), entry.value);
    });

    test('${entry.key} message is not the generic fallback', () {
      expect(errorMessageFor(ApiFailure(code: entry.key)), isNot(generic));
    });

    test('${entry.key} message has no English glossary terms', () {
      final message = errorMessageFor(ApiFailure(code: entry.key));
      for (final term in _englishTerms) {
        expect(message, isNot(contains(term)));
      }
      expect(message, isNot(contains('_')));
    });
  }
}
