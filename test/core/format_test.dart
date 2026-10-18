import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('formatRupiah', () {
    const cases = {
      0: 'Rp0',
      1500: 'Rp1.500',
      800000: 'Rp800.000',
      12000000: 'Rp12.000.000',
    };
    for (final entry in cases.entries) {
      test('formats ${entry.key} as ${entry.value}', () {
        expect(formatRupiah(entry.key), entry.value);
      });
    }
  });

  group('formatDate', () {
    final cases = {
      DateTime(2026, 10, 18): '18 Okt 2026',
      DateTime(2027, 1, 1): '1 Jan 2027',
      DateTime(2026, 5, 5): '5 Mei 2026',
      DateTime(2026, 8, 30): '30 Agu 2026',
      DateTime(2026, 12, 31): '31 Des 2026',
    };
    for (final entry in cases.entries) {
      test('formats ${entry.key.toIso8601String()} as ${entry.value}', () {
        expect(formatDate(entry.key), entry.value);
      });
    }
  });
}
