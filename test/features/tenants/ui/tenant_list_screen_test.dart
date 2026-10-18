import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'tenant_ui_helpers.dart';

const _empty =
    'Belum ada penyewa. Daftarkan penyewa ke kamar kosong, lalu bagikan '
    'tautan undangan agar ia bisa mengaktifkan akun.';
const _emptyFilter = 'Tidak ada penyewa dengan status ini.';

FakeTenantRepository _repo([List<Tenant>? tenants]) =>
    FakeTenantRepository(tenants: tenants ?? sampleTenants());

void main() {
  group('header', () {
    testWidgets('shows the title Penyewa and the property name', (
      tester,
    ) async {
      final properties = propertiesWithMelati();
      await pumpTenantApp(tester, _repo(), properties: properties);

      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(appBarTitle('Penyewa'), findsOneWidget);
      expect(inAppBar('Kos Melati'), findsOneWidget);
      expect(properties.calls, contains('get:p1'));
    });

    testWidgets('still lists the tenants when the property cannot load', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await pumpTenantApp(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsNothing);
      expect(appBarTitle('Penyewa'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
    });

    testWidgets('lists only the tenants of the property in the path', (
      tester,
    ) async {
      final repo = FakeTenantRepository(
        tenants: sampleTenants(),
        otherProperties: {
          'p2': [makeTenant(id: 'x1', name: 'Orang Lain')],
        },
      );
      await pumpTenantApp(tester, repo);

      expect(find.text('Orang Lain'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(repo.calls, contains('list:p1'));
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpTenantApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text(_empty), findsNothing);
    });

    testWidgets('shows the tenants once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await pumpTenantApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpTenantApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpTenantApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the tenants again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await pumpTenantApp(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpTenantApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('empty', () {
    testWidgets('invites the user to register a tenant', (tester) async {
      await pumpTenantApp(tester, _repo([]));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Tambah Penyewa'), findsOneWidget);
      expect(find.text(_emptyFilter), findsNothing);
    });

    testWidgets('Tambah Penyewa opens the add form', (tester) async {
      await pumpTenantApp(tester, _repo([]));

      await tester.tap(find.text('Tambah Penyewa'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/penyewa/tambah');
      expect(find.byType(TenantFormScreen), findsOneWidget);
    });

    testWidgets('a manager is invited to register a tenant too', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo([]), role: UserRole.manager);

      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Tambah Penyewa'), findsOneWidget);
    });

    testWidgets('keeps the action when the property cannot be loaded', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await pumpTenantApp(tester, _repo([]), properties: properties);

      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Tambah Penyewa'), findsOneWidget);
    });

    testWidgets('offers no action for a view-only property', (tester) async {
      await pumpTenantApp(
        tester,
        _repo([]),
        properties: propertiesWithMelati(editable: false),
      );

      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Tambah Penyewa'), findsNothing);
      expect(find.text('Tambah'), findsNothing);
    });
  });

  group('rows', () {
    testWidgets('shows one row per tenant in the order returned', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      for (final name in ['Budi Santoso', 'Sari Wulandari', 'Dewi Lestari']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('Budi Santoso')).dy,
        lessThan(tester.getTopLeft(find.text('Sari Wulandari')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Sari Wulandari')).dy,
        lessThan(tester.getTopLeft(find.text('Dewi Lestari')).dy),
      );
    });

    testWidgets('shows the room number of each tenant', (tester) async {
      await pumpTenantApp(tester, _repo());

      for (final number in ['08', '12', '13']) {
        expect(find.text(number), findsOneWidget);
      }
    });

    testWidgets('an active tenant shows the cycle and the end of the lease', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      expect(find.text('Bulanan · s.d. 31 Des 2026'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNWidgets(2));
    });

    testWidgets('an active tenant without end date shows only the cycle', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      expect(find.text('Mingguan'), findsOneWidget);
    });

    testWidgets('a not activated tenant shows when the invitation ends', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      expect(
        find.text('3 Bulan · tautan undangan s.d. 25 Okt 2026'),
        findsOneWidget,
      );
      expect(statusBadge('Belum Diaktifkan'), findsOneWidget);
    });

    testWidgets('a not activated tenant does not show the lease end', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo([
          makeTenant(
            id: 't2',
            name: 'Sari Wulandari',
            endDate: DateTime.utc(2027, 3, 5),
          ),
        ]),
      );

      expect(find.textContaining('5 Mar 2027'), findsNothing);
      expect(find.textContaining('tautan undangan s.d.'), findsOneWidget);
    });

    const cycles = {
      BillingCycle.weekly: 'Mingguan',
      BillingCycle.monthly: 'Bulanan',
      BillingCycle.quarterly: '3 Bulan',
      BillingCycle.semiannual: '6 Bulan',
      BillingCycle.annual: '12 Bulan',
    };
    for (final entry in cycles.entries) {
      testWidgets('names the ${entry.key} cycle ${entry.value}', (
        tester,
      ) async {
        await pumpTenantApp(
          tester,
          _repo([
            makeTenant(
              accountStatus: TenantAccountStatus.active,
              billingCycle: entry.key,
            ),
          ]),
        );

        expect(find.text('${entry.value} · s.d. 31 Des 2026'), findsOneWidget);
      });
    }

    testWidgets('reads each tenant as a single merged item', (tester) async {
      await pumpTenantApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Budi Santoso');
      expect(label, contains('08'));
      expect(label, contains('Budi Santoso'));
      expect(label, contains('Bulanan · s.d. 31 Des 2026'));
      expect(label, contains('Aktif'));
      expect(label, isNot(contains('Sari Wulandari')));
      expect(label, isNot(contains('Belum Diaktifkan')));
    });

    testWidgets('the merged reading of a not activated tenant says so', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Sari Wulandari');
      expect(label, contains('12'));
      expect(label, contains('3 Bulan · tautan undangan s.d. 25 Okt 2026'));
      expect(label, contains('Belum Diaktifkan'));
    });

    testWidgets('tapping a tenant opens the detail', (tester) async {
      await pumpTenantApp(tester, _repo());

      await tester.tap(find.text('Sari Wulandari'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/penyewa/t2');
      final detail = tester.widget<TenantDetailScreen>(
        find.byType(TenantDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.tenantId, 't2');
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await pumpTenantApp(tester, _repo());
      await tester.tap(find.text('Sari Wulandari'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });
  });

  group('filter', () {
    testWidgets('offers Semua, Aktif and Belum Diaktifkan in the page body', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      for (final label in ['Semua', 'Aktif', 'Belum Diaktifkan']) {
        expect(filterChip(label), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: filterChip(label)),
          findsNothing,
        );
      }
    });

    testWidgets('the chip labels carry no counts', (tester) async {
      await pumpTenantApp(tester, _repo());

      expect(find.textContaining('Semua ('), findsNothing);
      expect(find.textContaining('Aktif ('), findsNothing);
      expect(find.textContaining('Belum Diaktifkan ('), findsNothing);
    });

    testWidgets('Semua is selected by default and shows every tenant', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      expectChipSelected(tester, 'Semua', selected: true);
      expectChipSelected(tester, 'Aktif', selected: false);
      expectChipSelected(tester, 'Belum Diaktifkan', selected: false);
      for (final name in ['Budi Santoso', 'Sari Wulandari', 'Dewi Lestari']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await pumpTenantApp(tester, _repo());

      for (final label in ['Semua', 'Aktif', 'Belum Diaktifkan']) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('Aktif shows only the active tenants', (tester) async {
      await pumpTenantApp(tester, _repo());

      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.text('Sari Wulandari'), findsNothing);
      expectChipSelected(tester, 'Aktif', selected: true);
      expectChipSelected(tester, 'Semua', selected: false);
    });

    testWidgets('Belum Diaktifkan shows only the not activated tenants', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      expect(find.text('Sari Wulandari'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Dewi Lestari'), findsNothing);
      expectChipSelected(tester, 'Belum Diaktifkan', selected: true);
    });

    testWidgets('Semua brings every tenant back', (tester) async {
      await pumpTenantApp(tester, _repo());
      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Sari Wulandari'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expectChipSelected(tester, 'Semua', selected: true);
    });

    testWidgets('filtering updates in place without loading again', (
      tester,
    ) async {
      final repo = _repo();
      await pumpTenantApp(tester, repo);

      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/penyewa');
    });

    testWidgets('explains an empty result and keeps the chips', (tester) async {
      await pumpTenantApp(
        tester,
        _repo([makeTenant(accountStatus: TenantAccountStatus.active)]),
      );

      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      expect(find.text(_emptyFilter), findsOneWidget);
      expect(find.text(_empty), findsNothing);
      expect(find.text('Tambah Penyewa'), findsNothing);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(filterChip('Semua'), findsOneWidget);
    });

    testWidgets('the rows come back after an empty result', (tester) async {
      await pumpTenantApp(
        tester,
        _repo([makeTenant(accountStatus: TenantAccountStatus.active)]),
      );
      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();

      expect(find.text(_emptyFilter), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('an empty property shows no chips', (tester) async {
      await pumpTenantApp(tester, _repo([]));

      expect(filterChip('Semua'), findsNothing);
    });
  });

  group('add button', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role sees Tambah, at least 48 dp, that opens the form', (
        tester,
      ) async {
        await pumpTenantApp(tester, _repo(), role: role);

        expect(find.text('Tambah'), findsOneWidget);
        expectTargetSize(tester, 'Tambah');

        await tester.tap(find.text('Tambah'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/properti/p1/penyewa/tambah');
        final form = tester.widget<TenantFormScreen>(
          find.byType(TenantFormScreen),
        );
        expect(form.propertyId, 'p1');
        expect(form.preselectedRoomId, isNull);
      });
    }

    testWidgets('a view-only property hides Tambah but lists the tenants', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo(),
        properties: propertiesWithMelati(editable: false),
      );

      expect(find.text('Tambah'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, FakeTenantRepository Function()>{
      'loaded': _repo,
      'with a single tenant': () => _repo([makeTenant()]),
      'empty': () => _repo([]),
      'failed': () => _repo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      for (final role in [UserRole.owner, UserRole.manager]) {
        testWidgets('meets the guidelines when ${entry.key} for a $role', (
          tester,
        ) async {
          await pumpTenantApp(tester, entry.value(), role: role);

          await expectMeetsA11yGuidelines(tester);
        });
      }

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpTenantApp(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines when empty for a view-only property', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo([]),
        properties: propertiesWithMelati(editable: false),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines for a view-only property', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo(),
        properties: propertiesWithMelati(editable: false),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when the property name is unknown', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await pumpTenantApp(tester, _repo(), properties: properties);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the Aktif filter', (tester) async {
      await pumpTenantApp(tester, _repo());
      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the Belum Diaktifkan filter', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo(), largeText: true);
      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines when the filter matches nothing', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo([makeTenant(accountStatus: TenantAccountStatus.active)]),
      );
      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size when the filter matches nothing', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo([makeTenant(accountStatus: TenantAccountStatus.active)]),
        largeText: true,
      );
      await tester.tap(filterChip('Belum Diaktifkan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_emptyFilter), findsOneWidget);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpTenantApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpTenantApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
