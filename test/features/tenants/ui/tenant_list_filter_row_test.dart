import '../../../helpers/fakes.dart';
import '../../../helpers/filter_row.dart';
import 'tenant_ui_helpers.dart';

void main() {
  defineFilterRowTests(
    pump: (tester, {bool largeText = false}) => pumpTenantApp(
      tester,
      FakeTenantRepository(tenants: sampleTenants()),
      largeText: largeText,
    ),
    labels: const ['Semua', 'Aktif', 'Belum Diaktifkan'],
    selected: 'Semua',
    last: 'Belum Diaktifkan',
    overflowsAtLargeText: true,
  );
}
