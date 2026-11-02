import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/rent_bills/ui/payment_overview_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/filter_row.dart';
import 'management_payment_ui_helpers.dart';

const _unpaidOnly = 'Belum lunas';
const _all = 'Semua';
const _retry = 'Coba lagi';
const _noBillNote = 'Tidak ada tagihan pada tanggal ini';

const _roles = [UserRole.owner, UserRole.manager];

const _unpaidNames = ['Budi Santoso', 'Dewi Lestari', 'Rina Putri', 'Wati'];
const _allNames = [
  'Budi Santoso',
  'Dewi Lestari',
  'Rina Putri',
  'Sari Wulandari',
  'Tono',
  'Wati',
];

Future<void> _open(
  WidgetTester tester, {
  FakeManagementRentBillRepository? management,
  FakePropertyRepository? properties,
  UserRole role = UserRole.owner,
  String path = overviewPath,
  bool settle = true,
  bool largeText = false,
}) => pumpManagementPayments(
  tester,
  management: management,
  properties: properties,
  role: role,
  path: path,
  settle: settle,
  largeText: largeText,
);

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  setUpAll(initializeIndonesianDates);

  group('screen', () {
    for (final role in _roles) {
      testWidgets('is the Pembayaran tab of a $role', (tester) async {
        await _open(tester, role: role);

        expect(find.byType(PaymentOverviewScreen), findsOneWidget);
        expect(find.byType(PlaceholderScreen), findsNothing);
        expect(currentUri(tester).path, overviewPath);
      });
    }

    testWidgets('opens from the Pembayaran tab of the bottom navigation', (
      tester,
    ) async {
      await _open(tester, path: '/beranda');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Pembayaran'),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentUri(tester).path, overviewPath);
      expect(find.byType(PaymentOverviewScreen), findsOneWidget);
    });

    testWidgets('is a tab root with a ScreenHeader and no app bar', (
      tester,
    ) async {
      await _open(tester);

      expect(pembayaranHeader(), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('announces the header title as the page heading', (
      tester,
    ) async {
      await _open(tester);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(pembayaranHeader()),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('keeps the header while loading', (tester) async {
      final management = sampleOverview()
        ..overviewScript.gate = Completer<void>();
      await _open(tester, management: management, settle: false);

      expect(pembayaranHeader(), findsOneWidget);
    });

    testWidgets('keeps the header when the request fails', (tester) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure.network();
      await _open(tester, management: management);

      expect(pembayaranHeader(), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('asks for the overview of the first property once', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      expect(management.calls, ['overview:p1']);
    });

    testWidgets('asks for today, by sending no date or today', (tester) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      expect(isTodayOrNull(management.overviewDates.single), isTrue);
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final management = sampleOverview()
        ..overviewScript.gate = Completer<void>();
      await _open(tester, management: management, settle: false);

      expectLoading(tester);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows the tenants once loading finishes', (tester) async {
      final gate = Completer<void>();
      final management = sampleOverview()..overviewScript.gate = gate;
      await _open(tester, management: management, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a progress indicator while the properties load', (
      tester,
    ) async {
      final properties = twoProperties()..listScript.gate = Completer<void>();
      await _open(tester, properties: properties, settle: false);

      expectLoading(tester);
    });
  });

  group('failure', () {
    testWidgets('shows the Indonesian message of a network failure', (
      tester,
    ) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure.network();
      await _open(tester, management: management);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('shows the message of a missing property', (tester) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure(
          code: 'PROPERTY_NOT_FOUND',
          statusCode: 404,
        );
      await _open(tester, management: management);

      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows the message of a forbidden response', (tester) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _open(tester, management: management);

      expect(
        find.text('Anda tidak memiliki akses untuk tindakan ini.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the server message of a server error', (tester) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, management: management);

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, management: management);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi asks for the same property and date again', (
      tester,
    ) async {
      final management = sampleOverview()
        ..overviewScript.queue.add(const ApiFailure.network());
      await _open(tester, management: management);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(management.calls, ['overview:p1', 'overview:p1']);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, management: management);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(management.overviewCalls, 2);
    });

    testWidgets('a failure of the property list shows its message and retry', (
      tester,
    ) async {
      final properties = twoProperties()
        ..listScript.always = const ApiFailure.network();
      final management = sampleOverview();
      await _open(tester, management: management, properties: properties);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(management.overviewCalls, 0);
    });

    testWidgets('Coba lagi loads the property list again', (tester) async {
      final properties = twoProperties()
        ..listScript.queue.add(const ApiFailure.network());
      final management = sampleOverview();
      await _open(tester, management: management, properties: properties);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(properties.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });
  });

  group('property', () {
    testWidgets('defaults to the first property', (tester) async {
      await _open(tester);

      expect(find.text('Kos Melati'), findsWidgets);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Lina'), findsNothing);
    });

    testWidgets('offers every property of the caller', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Kos Melati').first);
      await tester.pumpAndSettle();

      expect(find.text('Kos Mawar'), findsWidgets);
      expect(find.text('Kos Melati'), findsWidgets);
    });

    testWidgets('choosing another property loads its overview in place', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      expect(management.calls, ['overview:p1', 'overview:p2']);
      expect(currentUri(tester).path, overviewPath);
      expect(find.text('Lina'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('choosing another property keeps the filter', (tester) async {
      await _open(tester);
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      expectChipSelected(tester, _all, selected: true);
      expect(find.text('Agus Salim'), findsOneWidget);
      expect(find.text('Lina'), findsOneWidget);
    });

    testWidgets('choosing the property again shows its tenants', (
      tester,
    ) async {
      await _open(tester);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      await chooseProperty(tester, current: 'Kos Mawar', target: 'Kos Melati');

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Lina'), findsNothing);
    });

    testWidgets('does not change the selection of the property list', (
      tester,
    ) async {
      final properties = twoProperties();
      await _open(tester, properties: properties);

      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      expect(properties.calls, ['list']);
    });

    testWidgets('shows a loading state while the other property loads', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);
      management.overviewScript.gate = Completer<void>();

      await tester.tap(find.text('Kos Melati').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kos Mawar').last);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expectLoading(tester);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('a failure of the other property can be retried', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);
      management.overviewScript.queue.add(
        const ApiFailure(code: 'PROPERTY_NOT_FOUND', statusCode: 404),
      );

      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');
      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(management.calls.last, 'overview:p2');
      expect(find.text('Lina'), findsOneWidget);
    });

    testWidgets('with one property it loads that property', (tester) async {
      final management = sampleOverview();
      await _open(tester, management: management, properties: oneProperty());

      expect(management.calls, ['overview:p1']);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('with no property it explains and asks for no overview', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(
        tester,
        management: management,
        properties: FakePropertyRepository(),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Belum ada properti'), findsOneWidget);
      expect(management.overviewCalls, 0);
      expect(pembayaranHeader(), findsOneWidget);
    });
  });

  group('date', () {
    testWidgets('shows today in the app date format', (tester) async {
      await _open(tester);

      expect(find.text(todayText()), findsOneWidget);
    });

    testWidgets('is a labelled button of at least 48 dp', (tester) async {
      await _open(tester);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text(todayText()));
        expect(node, isSemantics(isButton: true));
        expect(node.label, contains('Tanggal'));
        expect(node.label, contains(todayText()));
      } finally {
        handle.dispose();
      }
      expectTargetSize(tester, todayText());
    });

    testWidgets('opens a date picker without loading anything', (tester) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      await tester.tap(find.text(todayText()));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(management.overviewCalls, 1);
    });

    testWidgets('picking a date loads the overview of that date', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      final picked = await pickDateInPreviousMonth(tester, todayText());

      expect(management.calls, ['overview:p1', 'overview:p1']);
      expect(
        isDay(
          management.overviewDates.last,
          picked.year,
          picked.month,
          picked.day,
        ),
        isTrue,
      );
      expect(find.text(formatDate(picked)), findsOneWidget);
      expect(find.text(todayText()), findsNothing);
    });

    testWidgets('shows the tenants of the picked date', (tester) async {
      final now = DateTime.now();
      final picked = DateTime(now.year, now.month - 1, 15);
      final management = sampleOverview()
        ..itemsOnDate[overviewKey('p1', picked)] = [
          makeOverviewItem(
            tenantId: 't9',
            tenantName: 'Penyewa Lama',
            roomNumber: '99',
            bill: rentBillSummaryOf(makeRentBill(id: 'old', tenantId: 't9')),
          ),
        ];
      await _open(tester, management: management);

      await pickDateInPreviousMonth(tester, todayText());

      expect(find.text('Penyewa Lama'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      await tester.tap(find.text(todayText()));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextButton),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(management.overviewCalls, 1);
      expect(find.text(todayText()), findsOneWidget);
    });

    testWidgets('picking a date keeps the property and the filter', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      await pickDateInPreviousMonth(tester, todayText());

      expect(management.calls.last, 'overview:p2');
      expectChipSelected(tester, _all, selected: true);
      expect(find.text('Agus Salim'), findsOneWidget);
    });

    testWidgets('a failure for a picked date can be retried for that date', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);
      management.overviewScript.queue.add(const ApiFailure.network());

      final picked = await pickDateInPreviousMonth(tester, todayText());
      expect(find.byType(ErrorView), findsOneWidget);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(management.overviewCalls, 3);
      expect(
        isDay(
          management.overviewDates.last,
          picked.year,
          picked.month,
          picked.day,
        ),
        isTrue,
      );
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('stays available while the overview failed', (tester) async {
      final management = sampleOverview()
        ..overviewScript.always = const ApiFailure.network();
      await _open(tester, management: management);

      expect(find.text(todayText()), findsOneWidget);
    });
  });

  group('filter', () {
    testWidgets('offers Belum lunas and Semua in the page body', (
      tester,
    ) async {
      await _open(tester);

      for (final label in [_unpaidOnly, _all]) {
        expect(filterChip(label), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ScreenHeader),
            matching: filterChip(label),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('Belum lunas is selected by default', (tester) async {
      await _open(tester);

      expectChipSelected(tester, _unpaidOnly, selected: true);
      expectChipSelected(tester, _all, selected: false);
    });

    testWidgets('Belum lunas lists every status except Lunas', (tester) async {
      await _open(tester);

      for (final name in _unpaidNames) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Sari Wulandari'), findsNothing);
    });

    testWidgets('Belum lunas leaves out a tenant without a bill', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Tono'), findsNothing);
      expect(find.text(_noBillNote), findsNothing);
    });

    testWidgets('Semua lists every tenant, including the paid and unbilled', (
      tester,
    ) async {
      await _open(tester);

      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      for (final name in _allNames) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expectChipSelected(tester, _all, selected: true);
      expectChipSelected(tester, _unpaidOnly, selected: false);
    });

    testWidgets('Belum lunas brings the unpaid list back', (tester) async {
      await _open(tester);
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      await tester.tap(filterChip(_unpaidOnly));
      await tester.pumpAndSettle();

      expect(find.text('Sari Wulandari'), findsNothing);
      expect(find.text('Tono'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('changing the filter updates the list without a request', (
      tester,
    ) async {
      final management = sampleOverview();
      await _open(tester, management: management);

      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();
      await tester.tap(filterChip(_unpaidOnly));
      await tester.pumpAndSettle();

      expect(management.overviewCalls, 1);
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await _open(tester);

      for (final label in [_unpaidOnly, _all]) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('keeps both chips when the filter is empty', (tester) async {
      await _open(
        tester,
        management: FakeManagementRentBillRepository(items: {'p1': []}),
      );

      expect(filterChip(_unpaidOnly), findsOneWidget);
      expect(filterChip(_all), findsOneWidget);
    });

    defineFilterRowTests(
      pump: (tester, {bool largeText = false}) =>
          _open(tester, largeText: largeText),
      labels: const [_unpaidOnly, _all],
      selected: _unpaidOnly,
      last: _all,
      overflowsAtLargeText: false,
    );
  });

  group('empty', () {
    testWidgets('explains that nothing is left unpaid', (tester) async {
      final management = FakeManagementRentBillRepository(
        items: {
          'p1': [melatiItems()[3]],
        },
      );
      await _open(tester, management: management);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.textContaining('Tidak ada tagihan yang belum lunas'),
        findsOneWidget,
      );
    });

    testWidgets('explains the unpaid filter when only unbilled tenants exist', (
      tester,
    ) async {
      final management = FakeManagementRentBillRepository(
        items: {
          'p1': [melatiItems()[4]],
        },
      );
      await _open(tester, management: management);

      expect(
        find.textContaining('Tidak ada tagihan yang belum lunas'),
        findsOneWidget,
      );
      expect(find.text('Tono'), findsNothing);
    });

    testWidgets('shows the unbilled tenant under Semua', (tester) async {
      final management = FakeManagementRentBillRepository(
        items: {
          'p1': [melatiItems()[4]],
        },
      );
      await _open(tester, management: management);

      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      expect(find.text('Tono'), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('explains that the property has no tenants under Semua', (
      tester,
    ) async {
      final management = FakeManagementRentBillRepository(items: {'p1': []});
      await _open(tester, management: management);
      expect(find.byType(EmptyState), findsOneWidget);

      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Belum ada penyewa'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('lists the tenants in the order returned', (tester) async {
      await _open(tester);

      for (var i = 0; i < _unpaidNames.length - 1; i++) {
        expect(
          _top(tester, _unpaidNames[i]),
          lessThan(_top(tester, _unpaidNames[i + 1])),
        );
      }
    });

    testWidgets('lists every tenant of Semua in the order returned', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      for (var i = 0; i < _allNames.length - 1; i++) {
        expect(
          _top(tester, _allNames[i]),
          lessThan(_top(tester, _allNames[i + 1])),
        );
      }
    });

    testWidgets('every tenant is a card holding one tenant', (tester) async {
      await _open(tester);

      expect(
        find.descendant(
          of: find.byType(PaymentOverviewScreen),
          matching: find.byType(Card),
        ),
        findsNWidgets(_unpaidNames.length),
      );
      for (final name in _unpaidNames) {
        expect(tenantRow(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('each card has a 16 dp radius, a divider border, no shadow', (
      tester,
    ) async {
      await _open(tester);

      expectCardLook(
        tester,
        find.descendant(
          of: find.byType(PaymentOverviewScreen),
          matching: find.byType(Card),
        ),
      );
    });

    testWidgets('shows the room number of the tenant', (tester) async {
      await _open(tester);

      expect(inRow('Budi Santoso', find.textContaining('08')), findsOneWidget);
      expect(inRow('Dewi Lestari', find.textContaining('12')), findsOneWidget);
      expect(inRow('Rina Putri', find.textContaining('15')), findsOneWidget);
    });

    testWidgets('shows the amount of the bill in rupiah', (tester) async {
      await _open(tester);

      expect(inRow('Budi Santoso', find.text('Rp800.000')), findsOneWidget);
      expect(inRow('Dewi Lestari', find.text('Rp810.000')), findsOneWidget);
      expect(inRow('Rina Putri', find.text('Rp830.000')), findsOneWidget);
      expect(inRow('Wati', find.text('Rp850.000')), findsOneWidget);
    });

    testWidgets('shows the status of each bill as a text badge', (
      tester,
    ) async {
      await _open(tester);

      expect(inRow('Budi Santoso', statusBadge('Belum Bayar')), findsOneWidget);
      expect(
        inRow('Dewi Lestari', statusBadge('Menunggu Verifikasi')),
        findsOneWidget,
      );
      expect(inRow('Rina Putri', statusBadge('Ditolak')), findsOneWidget);
      expect(inRow('Wati', statusBadge('Belum Bayar')), findsOneWidget);
    });

    testWidgets('Semua shows the Lunas badge on the paid bill', (tester) async {
      await _open(tester);

      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      expect(inRow('Sari Wulandari', statusBadge('Lunas')), findsOneWidget);
      expect(inRow('Sari Wulandari', find.text('Rp840.000')), findsOneWidget);
    });

    testWidgets('a tenant without a bill has a note and no badge', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      expect(inRow('Tono', find.text(_noBillNote)), findsOneWidget);
      expect(
        inRow('Tono', find.byWidgetPredicate((w) => w is Text && _isStatus(w))),
        findsNothing,
      );
      expect(inRow('Tono', find.textContaining('Rp')), findsNothing);
      expect(inRow('Tono', find.textContaining('10')), findsOneWidget);
    });

    testWidgets('only the tenant without a bill has the note', (tester) async {
      await _open(tester);
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      expect(find.text(_noBillNote), findsOneWidget);
    });

    testWidgets('reads each tenant as a single merged item', (tester) async {
      await _open(tester);

      final label = semanticsLabelOf(tester, 'Budi Santoso');
      expect(label, contains('Budi Santoso'));
      expect(label, contains('08'));
      expect(label, contains('Rp800.000'));
      expect(label, contains('Belum Bayar'));
      expect(label, isNot(contains('Dewi Lestari')));
      expect(label, isNot(contains('Rp810.000')));
    });

    testWidgets('the merged item of a tenant without a bill has the note', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(filterChip(_all));
      await tester.pumpAndSettle();

      final label = semanticsLabelOf(tester, 'Tono');
      expect(label, contains('Tono'));
      expect(label, contains(_noBillNote));
    });

    testWidgets('the merged item states how late an overdue bill is', (
      tester,
    ) async {
      await _open(tester);

      final label = semanticsLabelOf(tester, 'Wati');
      expect(label, contains('12 hari terlambat'));
      expect(label, contains('Belum Bayar'));
    });
  });

  group('overdue', () {
    testWidgets('an overdue bill states how many days late it is', (
      tester,
    ) async {
      await _open(tester);

      expect(inRow('Wati', find.text('12 hari terlambat')), findsOneWidget);
    });

    testWidgets('a rejected bill that is overdue states it too', (
      tester,
    ) async {
      await _open(tester);

      expect(
        inRow('Rina Putri', find.text('3 hari terlambat')),
        findsOneWidget,
      );
    });

    testWidgets('a bill that is not overdue has no late note', (tester) async {
      await _open(tester);

      expect(
        inRow('Budi Santoso', find.textContaining('terlambat')),
        findsNothing,
      );
      expect(
        inRow('Dewi Lestari', find.textContaining('terlambat')),
        findsNothing,
      );
    });

    testWidgets('one day late reads as 1 hari', (tester) async {
      final management = FakeManagementRentBillRepository(
        items: {
          'p1': [
            makeOverviewItem(
              bill: rentBillSummaryOf(makeRentBill(daysOverdue: 1)),
            ),
          ],
        },
      );
      await _open(tester, management: management);

      expect(find.text('1 hari terlambat'), findsOneWidget);
    });

    testWidgets('the late note is a note and never a status badge', (
      tester,
    ) async {
      await _open(tester);

      expect(statusBadge('12 hari terlambat'), findsNothing);
      expect(statusBadge('Terlambat'), findsNothing);
    });

    testWidgets('shows the days the API reports without recomputing them', (
      tester,
    ) async {
      final management = FakeManagementRentBillRepository(
        items: {
          'p1': [
            makeOverviewItem(
              bill: rentBillSummaryOf(
                makeRentBill(
                  daysOverdue: 40,
                  dueDate: DateTime.utc(2099, 1, 1),
                ),
              ),
            ),
          ],
        },
      );
      await _open(tester, management: management);

      expect(find.text('40 hari terlambat'), findsOneWidget);
    });
  });

  group('accessibility', () {
    FakeManagementRentBillRepository rich() => sampleOverview();

    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'loaded': (tester, big) => _open(tester, largeText: big),
      'loaded with Semua': (tester, big) async {
        await _open(tester, largeText: big);
        await tester.tap(filterChip(_all));
        await tester.pumpAndSettle();
      },
      'loaded with the other property': (tester, big) async {
        await _open(tester, largeText: big);
        await chooseProperty(
          tester,
          current: 'Kos Melati',
          target: 'Kos Mawar',
        );
      },
      'with one property': (tester, big) =>
          _open(tester, properties: oneProperty(), largeText: big),
      'empty': (tester, big) => _open(
        tester,
        management: FakeManagementRentBillRepository(items: {'p1': []}),
        largeText: big,
      ),
      'empty under Semua': (tester, big) async {
        await _open(
          tester,
          management: FakeManagementRentBillRepository(items: {'p1': []}),
          largeText: big,
        );
        await tester.tap(filterChip(_all));
        await tester.pumpAndSettle();
      },
      'without a property': (tester, big) =>
          _open(tester, properties: FakePropertyRepository(), largeText: big),
      'failed': (tester, big) => _open(
        tester,
        management: rich()..overviewScript.always = const ApiFailure.network(),
        largeText: big,
      ),
      'failed property list': (tester, big) => _open(
        tester,
        properties: twoProperties()
          ..listScript.always = const ApiFailure.network(),
        largeText: big,
      ),
      'loading': (tester, big) => _open(
        tester,
        management: rich()..overviewScript.gate = Completer<void>(),
        settle: false,
        largeText: big,
      ),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines with the date picker open', (
      tester,
    ) async {
      await _open(tester);
      await tester.tap(find.text(todayText()));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('keeps every row reachable at large text size', (tester) async {
      await _open(tester, largeText: true);

      await tester.ensureVisible(find.text('Wati'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('12 hari terlambat'), findsOneWidget);
    });
  });
}

bool _isStatus(Text text) => const {
  'Belum Bayar',
  'Menunggu Verifikasi',
  'Lunas',
  'Ditolak',
}.contains(text.data);
