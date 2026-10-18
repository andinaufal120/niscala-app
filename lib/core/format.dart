import 'package:intl/intl.dart';

/// Whole rupiah with dot grouping, e.g. "Rp800.000".
String formatRupiah(int amount) =>
    'Rp${NumberFormat.decimalPattern('id').format(amount)}';

/// Day, short month and year in Indonesian, e.g. "18 Okt 2026". Requires
/// `initializeDateFormatting('id')` to have run.
String formatDate(DateTime date) => DateFormat('d MMM y', 'id').format(date);
