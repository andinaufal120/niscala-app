import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala_api/api.dart';

void main() {
  group('billingCycleLabel', () {
    const labels = {
      BillingCycle.weekly: 'Mingguan',
      BillingCycle.monthly: 'Bulanan',
      BillingCycle.quarterly: '3 Bulan',
      BillingCycle.semiannual: '6 Bulan',
      BillingCycle.annual: '12 Bulan',
    };

    for (final entry in labels.entries) {
      test('names ${entry.key} ${entry.value}', () {
        expect(billingCycleLabel(entry.key), entry.value);
      });
    }

    test('covers every billing cycle', () {
      expect(labels.keys, containsAll(BillingCycle.values));
    });
  });

  group('billingCycleUnit', () {
    const units = {
      BillingCycle.weekly: 'minggu',
      BillingCycle.monthly: 'bulan',
      BillingCycle.quarterly: '3 bulan',
      BillingCycle.semiannual: '6 bulan',
      BillingCycle.annual: '12 bulan',
    };

    for (final entry in units.entries) {
      test('names ${entry.key} ${entry.value}', () {
        expect(billingCycleUnit(entry.key), entry.value);
      });
    }

    test('covers every billing cycle', () {
      expect(units.keys, containsAll(BillingCycle.values));
    });
  });

  group('isValidIndonesianMobile', () {
    const valid = {
      'a typical 08 number': '081255204471',
      'an 08 number with dashes': '0812-5520-4471',
      'an 08 number with spaces': '0812 5520 4471',
      'an 08 number with spaces and dashes': '0812 5520-4471',
      'spaces around the number': '  081255204471  ',
      'the shortest 08 number': '0812345678',
      'the longest 08 number': '0812345678901',
      'a typical 628 number': '6281255204471',
      'the shortest 628 number': '62812345678',
      'the longest 628 number': '62812345678901',
    };
    for (final entry in valid.entries) {
      test('accepts ${entry.key}', () {
        expect(isValidIndonesianMobile(entry.value), isTrue);
      });
    }

    const invalid = {
      'an empty string': '',
      'only spaces': '   ',
      'letters': 'abcdefghijkl',
      'an 08 number that is too short': '081234567',
      'an 08 number that is too long': '08123456789012',
      'a 628 number that is too short': '6281234567',
      'a 628 number that is too long': '628123456789012',
      'a number starting with 07': '071255204471',
      'a number without the leading zero': '81255204471',
      'a number with a plus sign': '+6281255204471',
      'a 62 number without the 8': '6221255204471',
      'a landline number': '0227501234',
      'a number with a letter inside': '0812552O4471',
      'a number with dots': '0812.5520.4471',
      'a number with brackets': '(0812) 55204471',
      'a number with a slash': '0812/55204471',
    };
    for (final entry in invalid.entries) {
      test('rejects ${entry.key}', () {
        expect(isValidIndonesianMobile(entry.value), isFalse);
      });
    }
  });
}
