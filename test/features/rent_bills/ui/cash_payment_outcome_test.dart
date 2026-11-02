import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'cash_payment_ui_helpers.dart';

Uri _uri(WidgetTester tester) => currentUri(tester);

/// Expects the bill detail to show a bill paid in cash on [paidOn].
void _expectPaidInCash(DateTime paidOn) {
  expect(statusBadge('Lunas'), findsWidgets);
  expect(find.text('Metode pembayaran'), findsOneWidget);
  expect(find.text('Tunai'), findsOneWidget);
  expect(find.text('Tanggal dibayar'), findsOneWidget);
  expect(find.textContaining(dateText(paidOn)), findsWidgets);
}

void main() {
  setUpAll(initializeIndonesianDates);

  group('after recording from the overview', () {
    testWidgets('returns to the overview', (tester) async {
      await openCashFlow(tester);

      await recordCash(tester, 'Wati', 'Rp850.000');

      expect(_uri(tester).path, overviewPath);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(saveButton(), findsNothing);
      expect(dateField(), findsNothing);
    });

    testWidgets('returns to the overview for a Manager too', (tester) async {
      final repos = await openCashFlow(tester, role: UserRole.manager);

      await recordCash(tester, 'Wati', 'Rp850.000');

      expect(repos.management.cashCalls, 1);
      expect(_uri(tester).path, overviewPath);
    });

    testWidgets('sends one request', (tester) async {
      final repos = await openCashFlow(tester);

      await recordCash(tester, 'Wati', 'Rp850.000');

      expect(repos.management.cashCalls, 1);
      expect(repos.management.cashPayments.single.id, 'b6');
    });

    testWidgets('loads the overview again', (tester) async {
      final repos = cashRepositories();
      await pumpReview(tester, repos);
      final loadsBefore = repos.management.overviewCalls;
      await press(tester, actionButton(cashLabel));

      await recordCash(tester, 'Wati', 'Rp850.000');

      expect(repos.management.overviewCalls, greaterThan(loadsBefore));
    });

    testWidgets('takes the paid tenant out of the unpaid list', (tester) async {
      await openCashFlow(tester);
      await recordCash(tester, 'Wati', 'Rp850.000');

      expect(find.text('Wati'), findsNothing);
      expect(find.text('Rina Putri'), findsOneWidget);
    });

    testWidgets('shows the tenant as Lunas among all tenants', (tester) async {
      await openCashFlow(tester);
      await recordCash(tester, 'Wati', 'Rp850.000');

      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();

      expect(inRow('Wati', find.text('Lunas')), findsOneWidget);
      expect(inRow('Wati', find.text('Belum Bayar')), findsNothing);
    });

    testWidgets('shows a rejected tenant as Lunas among all tenants', (
      tester,
    ) async {
      await openCashFlow(tester);
      await recordCash(tester, 'Rina Putri', 'Rp830.000');

      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();

      expect(inRow('Rina Putri', find.text('Lunas')), findsOneWidget);
      expect(inRow('Rina Putri', find.text('Ditolak')), findsNothing);
    });

    testWidgets('no longer offers a paid bill for payment', (tester) async {
      await openCashFlow(tester);
      await recordCash(tester, 'Wati', 'Rp850.000');

      await press(tester, actionButton(cashLabel));

      expect(find.text('Wati'), findsNothing);
      expect(find.text('Rina Putri'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('loads the payable bills again', (tester) async {
      final repos = await openCashFlow(tester);
      await recordCash(tester, 'Wati', 'Rp850.000');
      final loadsBefore = repos.management.payableListCalls;

      await press(tester, actionButton(cashLabel));

      expect(repos.management.payableListCalls, greaterThan(loadsBefore));
    });

    testWidgets('offers the other bills of the tenant that remain', (
      tester,
    ) async {
      await openCashFlow(tester);
      await recordCash(tester, 'Budi Santoso', 'Rp800.000');

      await press(tester, actionButton(cashLabel));
      await press(tester, find.text('Budi Santoso'));

      expect(find.text('Rp790.000'), findsOneWidget);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('lists the empty state after the last payable bill', (
      tester,
    ) async {
      final repos = cashRepositories(
        bills: [
          makeRentBill(
            id: 'b6',
            tenantId: 't6',
            tenantName: 'Wati',
            roomNumber: '11',
            amount: 850000,
          ),
        ],
      );
      await openCashFlow(tester, repos: repos);
      await recordCash(tester, 'Wati', 'Rp850.000');

      await press(tester, actionButton(cashLabel));

      expect(find.textContaining(noPayableMessage), findsOneWidget);
    });

    testWidgets('shows the bill as Lunas by cash with the date picked', (
      tester,
    ) async {
      await openCashFlow(tester);
      await chooseTenantAndBill(tester, 'Wati', 'Rp850.000');
      final picked = await pickDateInPreviousMonthOfField(tester);
      await confirmReceived(tester);
      await saveCash(tester);

      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wati'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rp850.000'));
      await tester.pumpAndSettle();

      expect(_uri(tester).path, billPath('b6'));
      _expectPaidInCash(picked);
    });

    testWidgets('leaves the bills of other properties alone', (tester) async {
      final repos = await openCashFlow(tester);
      await recordCash(tester, 'Wati', 'Rp850.000');

      goTo(tester, cashPath('p2'));
      await tester.pumpAndSettle();

      expect(find.text('Lina'), findsOneWidget);
      expect(repos.management.cashCalls, 1);
    });
  });

  group('after recording from the bill', () {
    Future<ReviewRepositories> record(
      WidgetTester tester,
      String billId, {
      ReviewRepositories? repos,
      UserRole role = UserRole.owner,
    }) async {
      final shown = await openCashFlowFromBill(
        tester,
        billId,
        repos: repos,
        role: role,
      );
      await confirmReceived(tester);
      await saveCash(tester);
      return shown;
    }

    testWidgets('returns to the bill', (tester) async {
      await record(tester, 'b1');

      expect(_uri(tester).path, billPath('b1'));
      expect(saveButton(), findsNothing);
      expect(find.text('Detail Tagihan'), findsOneWidget);
    });

    testWidgets('sends one request for that bill', (tester) async {
      final repos = await record(tester, 'b1');

      expect(repos.management.cashPayments.map((c) => c.id), ['b1']);
    });

    testWidgets('shows the bill as Lunas by cash with today as its date', (
      tester,
    ) async {
      await record(tester, 'b1');

      _expectPaidInCash(today());
      expect(statusBadge('Belum Bayar'), findsNothing);
    });

    testWidgets('shows the bill as Lunas by cash for a Manager', (
      tester,
    ) async {
      await record(tester, 'b1', role: UserRole.manager);

      _expectPaidInCash(today());
    });

    testWidgets('shows a rejected bill as Lunas without its reason', (
      tester,
    ) async {
      await record(tester, 'b3');

      _expectPaidInCash(today());
      expect(statusBadge('Ditolak'), findsNothing);
      expect(find.text('Alasan penolakan'), findsNothing);
      expect(find.text('Foto buram.'), findsNothing);
    });

    testWidgets('shows the date that was picked', (tester) async {
      await openCashFlowFromBill(tester, 'b1');
      final picked = await pickDateInPreviousMonthOfField(tester);
      await confirmReceived(tester);

      await saveCash(tester);

      _expectPaidInCash(picked);
    });

    testWidgets('loads the bill again', (tester) async {
      final repos = cashRepositories();
      await pumpReview(tester, repos, path: billPath('b1'));
      final loadsBefore = repos.rentBills.getCalls;
      await press(tester, actionButton(cashLabel));
      await confirmReceived(tester);

      await saveCash(tester);

      expect(repos.rentBills.getCalls, greaterThan(loadsBefore));
    });

    testWidgets('offers no payment action any more', (tester) async {
      await record(tester, 'b1');

      expect(actionButton(cashLabel), findsNothing);
      expectNoReviewActions();
    });

    testWidgets('lists the change in the status history', (tester) async {
      await record(tester, 'b1');

      expect(find.text('Riwayat Status'), findsOneWidget);
      expect(find.textContaining('Siti Pemilik'), findsWidgets);
    });

    testWidgets('shows no notification of its own', (tester) async {
      await record(tester, 'b1');

      expect(find.textContaining('otifikasi'), findsNothing);
      expect(find.textContaining('diberi tahu'), findsNothing);
    });
  });

  group('after recording from the history of a tenant', () {
    testWidgets('shows the bill as paid in the history', (tester) async {
      final repos = cashRepositories();
      await pumpReview(tester, repos, path: historyPath('t6', 'p1'));
      expect(statusBadge('Belum Bayar'), findsOneWidget);
      final loadsBefore = repos.management.tenantListCalls('t6');
      await tester.tap(find.text('Rp850.000'));
      await tester.pumpAndSettle();
      await press(tester, actionButton(cashLabel));
      await confirmReceived(tester);
      await saveCash(tester);

      await pressBack(tester);

      expect(_uri(tester).path, '/pembayaran/penyewa/t6');
      expect(repos.management.tenantListCalls('t6'), greaterThan(loadsBefore));
      expect(statusBadge('Lunas'), findsOneWidget);
      expect(statusBadge('Belum Bayar'), findsNothing);
    });
  });

  group('lists that show the bill', () {
    Future<ReviewRepositories> recordFromBill(WidgetTester tester) async {
      final repos = cashRepositories();
      await pumpReview(tester, repos, path: billPath('b1'));
      return repos;
    }

    Future<void> record(WidgetTester tester) async {
      await press(tester, actionButton(cashLabel));
      await confirmReceived(tester);
      await saveCash(tester);
    }

    testWidgets('the history of the tenant is loaded again', (tester) async {
      final repos = await recordFromBill(tester);
      final provider = tenantRentBillsProvider((
        propertyId: 'p1',
        tenantId: 't1',
      ));
      await containerOf(tester).read(provider.future);
      final loadsBefore = repos.management.tenantListCalls('t1');

      await record(tester);
      await containerOf(tester).read(provider.future);

      expect(repos.management.tenantListCalls('t1'), greaterThan(loadsBefore));
    });

    testWidgets('the list awaiting verification is loaded again', (
      tester,
    ) async {
      final repos = await recordFromBill(tester);
      final provider = awaitingVerificationProvider('p1');
      await containerOf(tester).read(provider.future);
      final loadsBefore = repos.management.verificationListCalls;

      await record(tester);
      await containerOf(tester).read(provider.future);

      expect(repos.management.verificationListCalls, greaterThan(loadsBefore));
    });

    testWidgets('the overview is loaded again', (tester) async {
      final repos = await recordFromBill(tester);
      final provider = paymentOverviewProvider((
        propertyId: 'p1',
        date: today(),
      ));
      await containerOf(tester).read(provider.future);
      final loadsBefore = repos.management.overviewCalls;

      await record(tester);
      await containerOf(tester).read(provider.future);

      expect(repos.management.overviewCalls, greaterThan(loadsBefore));
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the bill after recording': (tester, large) async {
        await openCashFlowFromBill(tester, 'b1', largeText: large);
        await confirmReceived(tester);
        await saveCash(tester);
      },
      'the overview after recording': (tester, large) async {
        await openCashFlow(tester, largeText: large);
        await recordCash(tester, 'Wati', 'Rp850.000');
      },
      'the flow after recording the only bill of a tenant':
          (tester, large) async {
            await openCashFlow(tester, largeText: large);
            await recordCash(tester, 'Wati', 'Rp850.000');
            await press(tester, actionButton(cashLabel));
          },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines on ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size on ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
