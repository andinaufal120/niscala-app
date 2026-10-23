import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/rent_bills/ui/receipt_view_screen.dart';
import 'package:niscala/features/rent_bills/ui/tenant_payments_screen.dart';
import 'package:niscala/features/rent_bills/ui/upload_receipt_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'rent_bill_ui_helpers.dart';

const _active = 'Tagihan aktif';
const _history = 'Riwayat';
const _transfer = 'Transfer sekarang';
const _reupload = 'Unggah ulang bukti';
const _viewReceipt = 'Lihat bukti';
const _cashHint = 'Bayar tunai ke pengelola kost';

Set<String> _asked(List<PaymentStatus> statuses) =>
    statuses.map((s) => s.value).toSet();

void main() {
  group('screen', () {
    testWidgets('is the tenant Pembayaran tab', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
      expect(currentPath(tester), paymentsPath);
    });

    testWidgets('opens from the Pembayaran tab of the bottom navigation', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo(), path: '/penyewa/beranda');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Pembayaran'),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath(tester), paymentsPath);
      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
    });

    testWidgets('is a tab root with a ScreenHeader and no app bar', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(find.byType(ScreenHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TenantPaymentsScreen),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('announces the header title as the page heading', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      final title = tester
          .widget<ScreenHeader>(find.byType(ScreenHeader))
          .title;
      expect(title, isNotEmpty);
      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(
            find.descendant(
              of: find.byType(ScreenHeader),
              matching: find.text(title),
            ),
          ),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('loading', () {
    testWidgets('asks for the active statuses once', (tester) async {
      final repo = sampleRepo();
      await pumpRentBillApp(tester, repo);

      expect(repo.listCalls, 1);
      expect(_asked(repo.listedStatuses.single), {
        'unpaid',
        'awaitingVerification',
        'rejected',
      });
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = sampleRepo()..listScript.gate = Completer<void>();
      await pumpRentBillApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Rp800.000'), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows the bills once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = sampleRepo()..listScript.gate = gate;
      await pumpRentBillApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = sampleRepo()..listScript.always = const ApiFailure.network();
      await pumpRentBillApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = sampleRepo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpRentBillApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the bills again', (tester) async {
      final repo = sampleRepo()
        ..listScript.queue.add(const ApiFailure.network());
      await pumpRentBillApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = sampleRepo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpRentBillApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('filter', () {
    testWidgets('offers Tagihan aktif and Riwayat in the page body', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      for (final label in [_active, _history]) {
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

    testWidgets('Tagihan aktif is selected by default', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      expectChipSelected(tester, _active, selected: true);
      expectChipSelected(tester, _history, selected: false);
    });

    testWidgets('Tagihan aktif shows unpaid and awaiting bills only', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.text('Rp810.000'), findsOneWidget);
      expect(find.text('Rp820.000'), findsOneWidget);
      expect(find.text('Rp830.000'), findsNothing);
      expect(find.text('Rp840.000'), findsNothing);
    });

    testWidgets('Riwayat asks for the paid status only and shows paid bills', (
      tester,
    ) async {
      final repo = sampleRepo();
      await pumpRentBillApp(tester, repo);

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(_asked(repo.listedStatuses.last), {'paid'});
      expect(find.text('Rp830.000'), findsOneWidget);
      expect(find.text('Rp840.000'), findsOneWidget);
      expect(find.text('Rp800.000'), findsNothing);
      expect(find.text('Rp820.000'), findsNothing);
      expectChipSelected(tester, _history, selected: true);
      expectChipSelected(tester, _active, selected: false);
    });

    testWidgets('no request for the active list ever asks for paid', (
      tester,
    ) async {
      final repo = sampleRepo();
      await pumpRentBillApp(tester, repo);
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();
      await tester.tap(filterChip(_active));
      await tester.pumpAndSettle();

      for (final statuses in repo.listedStatuses) {
        final asked = _asked(statuses);
        expect(
          asked.contains('paid'),
          asked.length == 1,
          reason: 'a request mixes paid with the active statuses: $asked',
        );
      }
    });

    testWidgets('Tagihan aktif brings the active bills back', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      await tester.tap(filterChip(_active));
      await tester.pumpAndSettle();

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.text('Rp830.000'), findsNothing);
    });

    testWidgets('a paid bill that is current is in Riwayat only', (
      tester,
    ) async {
      final repo = FakeRentBillRepository(
        bills: [makeRentBill(id: 'p', status: PaymentStatus.paid)],
      );
      await pumpRentBillApp(tester, repo);
      expect(find.text('Rp800.000'), findsNothing);

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('an unpaid bill from an earlier period is in Tagihan aktif', (
      tester,
    ) async {
      final repo = FakeRentBillRepository(
        bills: [makeRentBill(id: 'old', isCurrent: false, daysOverdue: 40)],
      );
      await pumpRentBillApp(tester, repo);

      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      for (final label in [_active, _history]) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('a history failure shows its message and retry', (
      tester,
    ) async {
      final repo = sampleRepo();
      await pumpRentBillApp(tester, repo);
      repo.listScript.queue.add(const ApiFailure.network());

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Rp830.000'), findsOneWidget);
    });
  });

  group('empty', () {
    testWidgets('explains that there are no active bills', (tester) async {
      await pumpRentBillApp(tester, FakeRentBillRepository());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Tidak ada tagihan aktif'), findsOneWidget);
    });

    testWidgets('explains that there is no history', (tester) async {
      await pumpRentBillApp(tester, FakeRentBillRepository());

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
      expect(find.textContaining('Tidak ada tagihan aktif'), findsNothing);
    });

    testWidgets('keeps both chips when the filter is empty', (tester) async {
      await pumpRentBillApp(tester, FakeRentBillRepository());

      expect(filterChip(_active), findsOneWidget);
      expect(filterChip(_history), findsOneWidget);
    });

    testWidgets('shows only history when no bill is active', (tester) async {
      final repo = FakeRentBillRepository(
        bills: [makeRentBill(status: PaymentStatus.paid)],
      );
      await pumpRentBillApp(tester, repo);
      expect(find.textContaining('Tidak ada tagihan aktif'), findsOneWidget);

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows no history text when only active bills exist', (
      tester,
    ) async {
      await pumpRentBillApp(
        tester,
        FakeRentBillRepository(bills: [makeRentBill()]),
      );

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('shows the active bills in the order returned', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      const order = ['Rp800.000', 'Rp810.000', 'Rp820.000'];
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          tester.getTopLeft(find.text(order[i])).dy,
          lessThan(tester.getTopLeft(find.text(order[i + 1])).dy),
        );
      }
    });

    testWidgets('every bill is a card holding one bill', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(
        find.descendant(
          of: find.byType(TenantPaymentsScreen),
          matching: find.byType(Card),
        ),
        findsNWidgets(3),
      );
      for (final amount in ['Rp800.000', 'Rp810.000', 'Rp820.000']) {
        expect(billCard(amount), findsOneWidget);
      }
    });

    testWidgets('each card has a 16 dp radius, a divider border, no shadow', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expectCardLook(
        tester,
        find.descendant(
          of: find.byType(TenantPaymentsScreen),
          matching: find.byType(Card),
        ),
      );
    });

    testWidgets('shows the period of the bill', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

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
      await pumpRentBillApp(tester, sampleRepo());

      expect(
        inBill('Rp800.000', find.textContaining('Jatuh tempo')),
        findsOneWidget,
      );
      expect(
        inBill('Rp800.000', find.textContaining('5 Nov 2026')),
        findsOneWidget,
      );
    });

    testWidgets('shows the status of each bill as text', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp800.000', statusBadge('Belum Bayar')), findsOneWidget);
      expect(
        inBill('Rp810.000', statusBadge('Menunggu Verifikasi')),
        findsOneWidget,
      );
      expect(inBill('Rp820.000', statusBadge('Belum Bayar')), findsOneWidget);
    });

    testWidgets('Riwayat shows the Lunas badge on paid bills', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(inBill('Rp830.000', statusBadge('Lunas')), findsOneWidget);
      expect(inBill('Rp840.000', statusBadge('Lunas')), findsOneWidget);
    });

    testWidgets('reads each bill as a single merged item', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      final label = semanticsLabelOf(tester, 'Rp800.000');
      expect(label, contains('Rp800.000'));
      expect(label, contains('Belum Bayar'));
      expect(label, contains('1 Nov 2026'));
      expect(label, isNot(contains('Rp810.000')));
      expect(label, isNot(contains('Menunggu Verifikasi')));
    });
  });

  group('overdue', () {
    testWidgets('an overdue bill states how many days late it is', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(
        inBill('Rp820.000', find.text('Terlambat 12 hari')),
        findsOneWidget,
      );
    });

    testWidgets('a bill that is not overdue has no late note', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(
        inBill('Rp800.000', find.textContaining('Terlambat')),
        findsNothing,
      );
      expect(
        inBill('Rp810.000', find.textContaining('Terlambat')),
        findsNothing,
      );
      expect(find.text('Terlambat 12 hari'), findsOneWidget);
    });

    testWidgets('Terlambat is a note and never a status badge', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(statusBadge('Terlambat 12 hari'), findsNothing);
      expect(statusBadge('Terlambat'), findsNothing);
    });

    testWidgets('one day late reads as 1 hari', (tester) async {
      await pumpRentBillApp(
        tester,
        FakeRentBillRepository(bills: [makeRentBill(daysOverdue: 1)]),
      );

      expect(find.text('Terlambat 1 hari'), findsOneWidget);
    });

    testWidgets('a rejected overdue bill shows the late note too', (
      tester,
    ) async {
      await pumpRentBillApp(
        tester,
        FakeRentBillRepository(
          bills: [
            makeRentBill(
              status: PaymentStatus.rejected,
              rejectionReason: 'Foto buram.',
              daysOverdue: 4,
            ),
          ],
        ),
      );

      expect(find.text('Terlambat 4 hari'), findsOneWidget);
    });
  });

  group('rejection', () {
    FakeRentBillRepository rejected() => FakeRentBillRepository(
      bills: [
        makeRentBill(
          status: PaymentStatus.rejected,
          rejectionReason: 'Nominal transfer tidak sesuai.',
        ),
      ],
    );

    testWidgets('shows the Ditolak badge and the reason', (tester) async {
      await pumpRentBillApp(tester, rejected());

      expect(statusBadge('Ditolak'), findsOneWidget);
      expect(
        find.textContaining('Nominal transfer tidak sesuai.'),
        findsOneWidget,
      );
    });

    testWidgets('shows no reason on bills that were not rejected', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(find.textContaining('Nominal transfer'), findsNothing);
      expect(find.textContaining('Alasan'), findsNothing);
    });

    testWidgets('a rejected bill offers to upload the receipt again', (
      tester,
    ) async {
      await pumpRentBillApp(tester, rejected());

      expect(find.text(_reupload), findsOneWidget);
      expect(find.text(_transfer), findsNothing);
    });
  });

  group('upload action', () {
    testWidgets('an unpaid uploadable bill offers Transfer sekarang', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp800.000', find.text(_transfer)), findsOneWidget);
      expectTargetSize(tester, _transfer);
    });

    testWidgets('only the bill the API marks uploadable has the action', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(find.text(_transfer), findsOneWidget);
      expect(inBill('Rp810.000', find.text(_transfer)), findsNothing);
      expect(inBill('Rp820.000', find.text(_transfer)), findsNothing);
      expect(find.text(_reupload), findsNothing);
    });

    testWidgets('an overdue bill of an earlier period has no upload action', (
      tester,
    ) async {
      await pumpRentBillApp(
        tester,
        FakeRentBillRepository(
          bills: [makeRentBill(daysOverdue: 12, isCurrent: false)],
        ),
      );

      expect(find.text(_transfer), findsNothing);
      expect(find.text(_reupload), findsNothing);
    });

    testWidgets('the action follows canUploadReceipt and ignores isCurrent', (
      tester,
    ) async {
      await pumpRentBillApp(
        tester,
        FakeRentBillRepository(
          bills: [
            makeRentBill(
              id: 'earlier',
              isCurrent: false,
              canUploadReceipt: true,
              amount: 811000,
            ),
            makeRentBill(
              id: 'current',
              isCurrent: true,
              canUploadReceipt: false,
              amount: 822000,
            ),
          ],
        ),
      );

      expect(inBill('Rp811.000', find.text(_transfer)), findsOneWidget);
      expect(inBill('Rp822.000', find.text(_transfer)), findsNothing);
    });

    testWidgets('the action opens the upload screen of that bill', (
      tester,
    ) async {
      final repo = sampleRepo();
      await pumpRentBillApp(tester, repo);

      await tester.tap(find.text(_transfer));
      await tester.pumpAndSettle();

      expect(currentPath(tester), uploadPath('b1'));
      expect(find.byType(UploadReceiptScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali on the upload screen returns to the list', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());
      await tester.tap(find.text(_transfer));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), paymentsPath);
      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
    });

    testWidgets('the rejected bill action opens its upload screen', (
      tester,
    ) async {
      await pumpRentBillApp(
        tester,
        FakeRentBillRepository(
          bills: [
            makeRentBill(
              id: 'r1',
              status: PaymentStatus.rejected,
              rejectionReason: 'Foto buram.',
            ),
          ],
        ),
      );

      await tester.tap(find.text(_reupload));
      await tester.pumpAndSettle();

      expect(currentPath(tester), uploadPath('r1'));
    });

    testWidgets('paid bills have no upload action', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.text(_transfer), findsNothing);
      expect(find.text(_reupload), findsNothing);
    });
  });

  group('cash hint', () {
    testWidgets('an unpaid bill that cannot be uploaded to tells to pay cash', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp820.000', find.text(_cashHint)), findsOneWidget);
    });

    testWidgets(
      'a rejected bill that cannot be uploaded to tells to pay cash',
      (tester) async {
        await pumpRentBillApp(
          tester,
          FakeRentBillRepository(
            bills: [
              makeRentBill(
                status: PaymentStatus.rejected,
                rejectionReason: 'Foto buram.',
                isCurrent: false,
                daysOverdue: 9,
              ),
            ],
          ),
        );

        expect(find.text(_cashHint), findsOneWidget);
        expect(find.text(_reupload), findsNothing);
      },
    );

    testWidgets(
      'a bill of a property without a bank account tells to pay cash',
      (tester) async {
        await pumpRentBillApp(
          tester,
          FakeRentBillRepository(
            bills: [makeRentBill(withoutBankAccount: true)],
          ),
        );

        expect(find.text(_cashHint), findsOneWidget);
        expect(find.text(_transfer), findsNothing);
      },
    );

    testWidgets('a bill that can be uploaded to has no cash hint', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp800.000', find.text(_cashHint)), findsNothing);
    });

    testWidgets('a bill awaiting verification has no cash hint', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp810.000', find.text(_cashHint)), findsNothing);
    });

    testWidgets('paid bills have no cash hint', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(find.text(_cashHint), findsNothing);
    });
  });

  group('receipt', () {
    testWidgets('a bill awaiting verification offers to view the receipt', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp810.000', find.text(_viewReceipt)), findsOneWidget);
      expect(find.text(_viewReceipt), findsOneWidget);
      expectTargetSize(tester, _viewReceipt);
    });

    testWidgets('an unpaid bill does not offer to view a receipt', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo());

      expect(inBill('Rp800.000', find.text(_viewReceipt)), findsNothing);
    });

    testWidgets('the action opens the receipt of that bill', (tester) async {
      final repo = sampleRepo()..receipts['b2'] = tinyPng;
      await pumpRentBillApp(tester, repo);

      await tester.tap(find.text(_viewReceipt));
      await tester.pumpAndSettle();

      expect(currentPath(tester), receiptPath('b2'));
      expect(find.byType(ReceiptViewScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali on the receipt returns to the list', (tester) async {
      final repo = sampleRepo()..receipts['b2'] = tinyPng;
      await pumpRentBillApp(tester, repo);
      await tester.tap(find.text(_viewReceipt));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), paymentsPath);
      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
    });
  });

  group('accessibility', () {
    FakeRentBillRepository rich() => FakeRentBillRepository(
      bills: [
        ...sampleBills(),
        makeRentBill(
          id: 'rej',
          amount: 850000,
          status: PaymentStatus.rejected,
          rejectionReason: 'Nominal transfer tidak sesuai dengan tagihan.',
          daysOverdue: 2,
        ),
        makeRentBill(id: 'nobank', amount: 860000, withoutBankAccount: true),
      ],
    );

    final states = <String, FakeRentBillRepository Function()>{
      'loaded': sampleRepo,
      'with rejected and cash bills': rich,
      'empty': FakeRentBillRepository.new,
      'failed': () =>
          sampleRepo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await pumpRentBillApp(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpRentBillApp(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines with the Riwayat filter', (tester) async {
      await pumpRentBillApp(tester, sampleRepo());
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the Riwayat filter', (
      tester,
    ) async {
      await pumpRentBillApp(tester, sampleRepo(), largeText: true);
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines when the history is empty', (
      tester,
    ) async {
      await pumpRentBillApp(tester, FakeRentBillRepository());
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size when the history is empty', (
      tester,
    ) async {
      await pumpRentBillApp(tester, FakeRentBillRepository(), largeText: true);
      await tester.tap(filterChip(_history));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = sampleRepo()..listScript.gate = Completer<void>();
      await pumpRentBillApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = sampleRepo()..listScript.gate = Completer<void>();
      await pumpRentBillApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
