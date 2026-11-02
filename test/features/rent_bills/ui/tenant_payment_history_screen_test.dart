import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/ui/payment_overview_screen.dart';
import 'package:niscala/features/rent_bills/ui/rent_bill_detail_screen.dart';
import 'package:niscala/features/rent_bills/ui/tenant_payment_history_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'management_payment_ui_helpers.dart';

const _retry = 'Coba lagi';

/// Bills of Budi Santoso (t1) in Kos Melati, newest period first, plus a bill
/// of another tenant and a bill of the same tenant in another property:
/// - h1 Rp800.000 unpaid (Nov 2026, due 5 Nov 2026),
/// - h2 Rp810.000 awaiting verification (Okt 2026),
/// - h3 Rp820.000 rejected (Sep 2026),
/// - h4 Rp830.000 paid (Agu 2026),
/// - h8 Rp998.000 of t1 in p2,
/// - h9 Rp999.000 of t2 in p1.
List<RentBill> _bills() => [
  makeRentBill(id: 'h1'),
  makeRentBill(
    id: 'h2',
    amount: 810000,
    status: PaymentStatus.awaitingVerification,
    periodStart: day(10, 1),
    periodEnd: day(10, 31),
    dueDate: day(10, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'h3',
    amount: 820000,
    status: PaymentStatus.rejected,
    rejectionReason: 'Foto buram.',
    periodStart: day(9, 1),
    periodEnd: day(9, 30),
    dueDate: day(9, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'h4',
    amount: 830000,
    status: PaymentStatus.paid,
    periodStart: day(8, 1),
    periodEnd: day(8, 31),
    dueDate: day(8, 5),
    isCurrent: false,
  ),
  makeRentBill(id: 'h8', amount: 998000, propertyId: 'p2'),
  makeRentBill(
    id: 'h9',
    amount: 999000,
    tenantId: 't2',
    tenantName: 'Dewi Lestari',
  ),
];

FakeManagementRentBillRepository _management([List<RentBill>? bills]) =>
    FakeManagementRentBillRepository(
      items: {'p1': melatiItems(), 'p2': mawarItems()},
      bills: bills ?? _bills(),
    );

Future<void> _open(
  WidgetTester tester,
  FakeManagementRentBillRepository management, {
  String tenantId = 't1',
  String propertyId = 'p1',
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) => pumpManagementPayments(
  tester,
  management: management,
  rentBills: FakeRentBillRepository(bills: _bills()),
  role: role,
  path: historyPath(tenantId, propertyId),
  settle: settle,
  largeText: largeText,
);

void main() {
  setUpAll(initializeIndonesianDates);

  group('screen', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('opens for a $role titled Riwayat Pembayaran', (
        tester,
      ) async {
        await _open(tester, _management(), role: role);

        expect(find.byType(TenantPaymentHistoryScreen), findsOneWidget);
        expect(appBarTitle('Riwayat Pembayaran'), findsOneWidget);
      });
    }

    testWidgets('covers the bottom navigation bar', (tester) async {
      await _open(tester, _management());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('asks for the bills of that tenant in that property', (
      tester,
    ) async {
      final management = _management();
      await _open(tester, management);

      expect(management.listed, hasLength(1));
      expect(management.listed.single.propertyId, 'p1');
      expect(management.listed.single.tenantId, 't1');
    });

    testWidgets('asks for bills of every status', (tester) async {
      final management = _management();
      await _open(tester, management);

      expect(management.listed.single.statuses, anyOf(isNull, isEmpty));
    });

    testWidgets('takes the property from the location', (tester) async {
      final management = _management();
      await _open(tester, management, propertyId: 'p2');

      expect(management.listed.single.propertyId, 'p2');
    });

    testWidgets('names the tenant', (tester) async {
      await _open(tester, _management());

      expect(find.textContaining('Budi Santoso'), findsWidgets);
    });
  });

  group('loading', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final management = _management()..listScript.gate = Completer<void>();
      await _open(tester, management, settle: false);

      expectLoading(tester);
      expect(find.text('Rp800.000'), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows the bills once loading finishes', (tester) async {
      final gate = Completer<void>();
      final management = _management()..listScript.gate = gate;
      await _open(tester, management, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final management = _management()
        ..listScript.always = const ApiFailure.network();
      await _open(tester, management);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('shows the message of a missing property', (tester) async {
      final management = _management()
        ..listScript.always = const ApiFailure(
          code: 'PROPERTY_NOT_FOUND',
          statusCode: 404,
        );
      await _open(tester, management);

      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows the message of a forbidden response', (tester) async {
      final management = _management()
        ..listScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _open(tester, management);

      expect(
        find.text('Anda tidak memiliki akses untuk tindakan ini.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final management = _management()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, management);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the bills again', (tester) async {
      final management = _management()
        ..listScript.queue.add(const ApiFailure.network());
      await _open(tester, management);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(management.listCalls, 2);
      expect(management.listed.last.tenantId, 't1');
      expect(management.listed.last.propertyId, 'p1');
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final management = _management()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, management);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(management.listCalls, 2);
    });
  });

  group('bills', () {
    testWidgets('lists only the bills of the tenant in the property', (
      tester,
    ) async {
      await _open(tester, _management());

      for (final amount in [
        'Rp800.000',
        'Rp810.000',
        'Rp820.000',
        'Rp830.000',
      ]) {
        expect(find.text(amount), findsOneWidget, reason: amount);
      }
      expect(find.text('Rp998.000'), findsNothing);
      expect(find.text('Rp999.000'), findsNothing);
    });

    testWidgets('lists the bills of another tenant for that tenant', (
      tester,
    ) async {
      await _open(tester, _management(), tenantId: 't2');

      expect(find.text('Rp999.000'), findsOneWidget);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('keeps the order the API returns, newest first', (
      tester,
    ) async {
      await _open(tester, _management());

      const order = ['Rp800.000', 'Rp810.000', 'Rp820.000', 'Rp830.000'];
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          tester.getTopLeft(find.text(order[i])).dy,
          lessThan(tester.getTopLeft(find.text(order[i + 1])).dy),
        );
      }
    });

    testWidgets('every bill is a card holding one bill', (tester) async {
      await _open(tester, _management());

      expect(
        find.descendant(
          of: find.byType(TenantPaymentHistoryScreen),
          matching: find.byType(Card),
        ),
        findsNWidgets(4),
      );
      for (final amount in ['Rp800.000', 'Rp810.000']) {
        expect(billCard(amount), findsOneWidget);
      }
    });

    testWidgets('each card has a 16 dp radius, a divider border, no shadow', (
      tester,
    ) async {
      await _open(tester, _management());

      expectCardLook(
        tester,
        find.descendant(
          of: find.byType(TenantPaymentHistoryScreen),
          matching: find.byType(Card),
        ),
      );
    });

    testWidgets('shows the period of the bill', (tester) async {
      await _open(tester, _management());

      expect(
        inBill('Rp800.000', find.textContaining('1 Nov 2026')),
        findsOneWidget,
      );
      expect(
        inBill('Rp800.000', find.textContaining('30 Nov 2026')),
        findsOneWidget,
      );
      expect(
        inBill('Rp810.000', find.textContaining('1 Okt 2026')),
        findsOneWidget,
      );
      expect(
        inBill('Rp810.000', find.textContaining('31 Okt 2026')),
        findsOneWidget,
      );
    });

    testWidgets('shows the due date of the bill', (tester) async {
      await _open(tester, _management());

      expect(
        inBill('Rp800.000', find.textContaining('Jatuh tempo')),
        findsOneWidget,
      );
      expect(
        inBill('Rp800.000', find.textContaining('5 Nov 2026')),
        findsOneWidget,
      );
      expect(
        inBill('Rp820.000', find.textContaining('5 Sep 2026')),
        findsOneWidget,
      );
    });

    testWidgets('shows the status of every bill as a text badge', (
      tester,
    ) async {
      await _open(tester, _management());

      expect(inBill('Rp800.000', statusBadge('Belum Bayar')), findsOneWidget);
      expect(
        inBill('Rp810.000', statusBadge('Menunggu Verifikasi')),
        findsOneWidget,
      );
      expect(inBill('Rp820.000', statusBadge('Ditolak')), findsOneWidget);
      expect(inBill('Rp830.000', statusBadge('Lunas')), findsOneWidget);
    });

    testWidgets('reads each bill as a single merged item', (tester) async {
      await _open(tester, _management());

      final label = semanticsLabelOf(tester, 'Rp800.000');
      expect(label, contains('Rp800.000'));
      expect(label, contains('Belum Bayar'));
      expect(label, contains('1 Nov 2026'));
      expect(label, contains('5 Nov 2026'));
      expect(label, isNot(contains('Rp810.000')));
      expect(label, isNot(contains('Menunggu Verifikasi')));
    });

    testWidgets('offers no payment action on a bill', (tester) async {
      await _open(tester, _management());

      for (final text in [
        'Verifikasi',
        'Tolak',
        'Ubah Status',
        'Catat Pembayaran Tunai',
        'Transfer sekarang',
        'Unggah ulang bukti',
      ]) {
        expect(find.text(text), findsNothing, reason: text);
      }
    });
  });

  group('empty', () {
    testWidgets('explains that the tenant has no payment history', (
      tester,
    ) async {
      await _open(tester, _management([]));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.textContaining('Belum ada riwayat pembayaran'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the back button when empty', (tester) async {
      await _open(tester, _management([]));

      expect(backButton(), findsOneWidget);
    });
  });

  group('navigation', () {
    Future<void> openFromOverview(
      WidgetTester tester,
      FakeManagementRentBillRepository management, {
      FakeRentBillRepository? rentBills,
    }) async {
      await pumpManagementPayments(
        tester,
        management: management,
        rentBills: rentBills ?? FakeRentBillRepository(bills: _bills()),
      );
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a tenant of the overview opens that history', (
      tester,
    ) async {
      final management = _management();
      await openFromOverview(tester, management);

      expect(currentUri(tester).path, '/pembayaran/penyewa/t1');
      expect(currentUri(tester).queryParameters['properti'], 'p1');
      expect(find.byType(TenantPaymentHistoryScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(management.listed.single.propertyId, 'p1');
      expect(management.listed.single.tenantId, 't1');
    });

    testWidgets('a tenant of the other property opens with that property', (
      tester,
    ) async {
      final management = _management([
        makeRentBill(
          id: 'c2',
          propertyId: 'p2',
          tenantId: 'u2',
          tenantName: 'Lina',
          roomNumber: 'B2',
          amount: 910000,
        ),
      ]);
      await pumpManagementPayments(tester, management: management);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      await tester.tap(find.text('Lina'));
      await tester.pumpAndSettle();

      expect(currentUri(tester).path, '/pembayaran/penyewa/u2');
      expect(currentUri(tester).queryParameters['properti'], 'p2');
      expect(management.listed.single.propertyId, 'p2');
      expect(management.listed.single.tenantId, 'u2');
      expect(find.text('Rp910.000'), findsOneWidget);
    });

    testWidgets('a tenant without a bill can be opened under Semua', (
      tester,
    ) async {
      final management = _management();
      await pumpManagementPayments(tester, management: management);
      await tester.tap(filterChip('Semua'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tono'));
      await tester.pumpAndSettle();

      expect(currentUri(tester).path, '/pembayaran/penyewa/t5');
      expect(find.byType(TenantPaymentHistoryScreen), findsOneWidget);
    });

    testWidgets('Kembali returns to the overview', (tester) async {
      await openFromOverview(tester, _management());

      await pressBack(tester);

      expect(currentPath(tester), overviewPath);
      expect(find.byType(PaymentOverviewScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Kembali keeps the chosen property and filter', (tester) async {
      final management = _management([
        makeRentBill(
          id: 'c1',
          propertyId: 'p2',
          tenantId: 'u1',
          tenantName: 'Agus Salim',
          roomNumber: 'B1',
          amount: 900000,
          status: PaymentStatus.paid,
        ),
      ]);
      await pumpManagementPayments(tester, management: management);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');
      await tester.tap(filterChip('Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agus Salim'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(find.text('Agus Salim'), findsOneWidget);
      expect(find.text('Lina'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expectChipSelected(tester, 'Semua', selected: true);
    });

    testWidgets('tapping a bill opens the detail of that bill', (tester) async {
      await openFromOverview(tester, _management());

      await tester.tap(find.text('Rp810.000'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), billPath('h2'));
      expect(find.byType(RentBillDetailScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali on the bill returns to the history', (tester) async {
      await openFromOverview(tester, _management());
      await tester.tap(find.text('Rp810.000'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentUri(tester).path, '/pembayaran/penyewa/t1');
      expect(currentUri(tester).queryParameters['properti'], 'p1');
      expect(find.byType(TenantPaymentHistoryScreen), findsOneWidget);
    });

    testWidgets('Kembali twice returns from the bill to the overview', (
      tester,
    ) async {
      await openFromOverview(tester, _management());
      await tester.tap(find.text('Rp810.000'));
      await tester.pumpAndSettle();

      await pressBack(tester);
      await pressBack(tester);

      expect(currentPath(tester), overviewPath);
      expect(find.byType(PaymentOverviewScreen), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, FakeManagementRentBillRepository Function()>{
      'loaded': _management,
      'empty': () => _management([]),
      'failed': () =>
          _management()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await _open(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final management = _management()..listScript.gate = Completer<void>();
      await _open(tester, management, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final management = _management()..listScript.gate = Completer<void>();
      await _open(tester, management, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
