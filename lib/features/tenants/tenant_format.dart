import 'package:niscala_api/api.dart';

final _mobilePattern = RegExp(r'^(08|628)[0-9]{8,11}$');

/// The Indonesian name of a billing cycle, e.g. "3 Bulan".
String billingCycleLabel(BillingCycle cycle) => switch (cycle) {
  BillingCycle.weekly => 'Mingguan',
  BillingCycle.monthly => 'Bulanan',
  BillingCycle.quarterly => '3 Bulan',
  BillingCycle.semiannual => '6 Bulan',
  BillingCycle.annual => '12 Bulan',
  _ => throw ArgumentError.value(cycle, 'cycle', 'Unknown billing cycle'),
};

/// The unit of a rent per billing cycle, e.g. "3 bulan" in "Rp2.100.000 / 3
/// bulan".
String billingCycleUnit(BillingCycle cycle) => switch (cycle) {
  BillingCycle.weekly => 'minggu',
  BillingCycle.monthly => 'bulan',
  BillingCycle.quarterly => '3 bulan',
  BillingCycle.semiannual => '6 bulan',
  BillingCycle.annual => '12 bulan',
  _ => throw ArgumentError.value(cycle, 'cycle', 'Unknown billing cycle'),
};

/// Whether [input] is an Indonesian mobile number starting with 08 or 628.
/// Spaces and dashes between the digits are allowed.
bool isValidIndonesianMobile(String input) =>
    _mobilePattern.hasMatch(input.replaceAll(RegExp(r'[ -]'), ''));

/// The first word of a full name, e.g. "Budi" for "Budi Santoso".
String firstNameOf(String fullName) =>
    fullName.trim().split(RegExp(r'\s+')).first;
