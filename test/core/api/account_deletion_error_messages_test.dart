import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

import '../../helpers/fakes.dart';

const _table = {
  'TENANT_HAS_ACTIVE_LEASE':
      'Penyewa ini masih punya sewa aktif. Akhiri sewa itu lebih dulu.',
  'SUBSCRIPTION_AUTO_RENEWING':
      'Langganan Google Play masih berjalan otomatis. Batalkan langganan di '
      'Google Play lebih dulu.',
};

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
  }

  test('keeps the message of OWNER_HAS_ACTIVE_LEASE for the admin screen', () {
    expect(
      errorMessageFor(const ApiFailure(code: 'OWNER_HAS_ACTIVE_LEASE')),
      'Pemilik ini masih memiliki properti dengan masa sewa aktif.',
    );
  });
}
