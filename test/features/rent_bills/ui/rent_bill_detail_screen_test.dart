import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/ui/rent_bill_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'management_payment_ui_helpers.dart';

const _retry = 'Coba lagi';

DateTime _noon(int month, int dayOfMonth) =>
    DateTime.utc(2026, month, dayOfMonth, 12);

RentBill _unpaid() => makeRentBill(id: 'd1', roomNumber: '17');

RentBill _paidByTransfer() => makeRentBill(
  id: 'd1',
  roomNumber: '17',
  status: PaymentStatus.paid,
  method: PaymentMethod.transfer,
  paidOn: DateTime.utc(2026, 11, 4),
);

RentBill _paidInCash() => makeRentBill(
  id: 'd1',
  roomNumber: '17',
  status: PaymentStatus.paid,
  method: PaymentMethod.cash,
  paidOn: DateTime.utc(2026, 11, 3),
);

RentBill _rejected() => makeRentBill(
  id: 'd1',
  roomNumber: '17',
  status: PaymentStatus.rejected,
  rejectionReason: 'Nominal transfer tidak sesuai.',
  hasReceipt: true,
);

RentBill _awaiting() => makeRentBill(
  id: 'd1',
  roomNumber: '17',
  status: PaymentStatus.awaitingVerification,
);

RentBill _withHistory() => makeRentBill(
  id: 'd1',
  roomNumber: '17',
  status: PaymentStatus.paid,
  method: PaymentMethod.cash,
  paidOn: DateTime.utc(2026, 11, 6),
  statusChanges: [
    makePaymentStatusChange(
      status: PaymentStatus.awaitingVerification,
      changedAt: _noon(11, 3),
      actorName: null,
      manual: false,
      reason: 'Catatan pertama',
    ),
    makePaymentStatusChange(
      status: PaymentStatus.rejected,
      changedAt: _noon(11, 4),
      reason: 'Catatan kedua',
    ),
    makePaymentStatusChange(
      status: PaymentStatus.awaitingVerification,
      changedAt: _noon(11, 5),
      actorName: null,
      manual: false,
      reason: 'Catatan ketiga',
    ),
    makePaymentStatusChange(
      status: PaymentStatus.paid,
      changedAt: _noon(11, 6),
      method: PaymentMethod.cash,
    ),
  ],
);

FakeRentBillRepository _repo(RentBill bill, {bool receipt = false}) =>
    FakeRentBillRepository(
      bills: [bill],
      receipts: receipt ? {bill.id: tinyPng} : {},
    );

Future<void> _open(
  WidgetTester tester,
  FakeRentBillRepository rentBills, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) => pumpManagementPayments(
  tester,
  rentBills: rentBills,
  role: role,
  path: billPath('d1'),
  settle: settle,
  largeText: largeText,
);

/// Lets the image codec finish, which runs outside of the fake clock.
Future<void> _decode(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

List<String> _receiptLabels(WidgetTester tester) => [
  for (final node in allSemanticsNodes(tester))
    if (node.label.startsWith('Bukti transfer, ')) node.label,
];

void main() {
  setUpAll(initializeIndonesianDates);

  group('screen', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('opens for a $role titled Detail Tagihan', (tester) async {
        final repo = _repo(_unpaid());
        await _open(tester, repo, role: role);

        expect(find.byType(RentBillDetailScreen), findsOneWidget);
        expect(appBarTitle('Detail Tagihan'), findsOneWidget);
        expect(currentUri(tester).path, billPath('d1'));
      });
    }

    testWidgets('loads the bill of the route', (tester) async {
      final repo = _repo(_unpaid());
      await _open(tester, repo);

      expect(repo.calls, ['get:d1']);
    });

    testWidgets('covers the bottom navigation bar', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('has a back button', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(backButton(), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo(_unpaid())..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('shows the bill once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo(_unpaid())..getScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('failure', () {
    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo(_unpaid())
        ..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('a missing bill shows its message', (tester) async {
      await _open(tester, FakeRentBillRepository());

      expect(find.text('Tagihan tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('a forbidden response shows its message', (tester) async {
      final repo = _repo(_unpaid())
        ..getScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _open(tester, repo);

      expect(
        find.text('Anda tidak memiliki akses untuk tindakan ini.'),
        findsOneWidget,
      );
    });

    testWidgets('an unknown code shows the generic message', (tester) async {
      final repo = _repo(_unpaid())
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the bill again', (tester) async {
      final repo = _repo(_unpaid())
        ..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('keeps the failure when the retry fails too', (tester) async {
      final repo = _repo(_unpaid())
        ..getScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, repo);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.getCalls, 2);
    });
  });

  group('details', () {
    testWidgets('shows the tenant and the room', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.textContaining('Budi Santoso'), findsWidgets);
      expect(find.textContaining('17'), findsWidgets);
    });

    testWidgets('shows the period of the bill', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.textContaining('1 Nov 2026'), findsWidgets);
      expect(find.textContaining('30 Nov 2026'), findsWidgets);
    });

    testWidgets('shows the amount in rupiah', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('shows the due date', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.textContaining('Jatuh tempo'), findsWidgets);
      expect(find.textContaining('5 Nov 2026'), findsWidgets);
    });

    for (final entry in {
      'Belum Bayar': _unpaid,
      'Menunggu Verifikasi': _awaiting,
      'Lunas': _paidByTransfer,
      'Ditolak': _rejected,
    }.entries) {
      testWidgets('shows the status ${entry.key} as a text badge', (
        tester,
      ) async {
        await _open(tester, _repo(entry.value()));

        expect(statusBadge(entry.key), findsOneWidget);
      });
    }

    testWidgets('shows no payment method or date before payment', (
      tester,
    ) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.text('Metode pembayaran'), findsNothing);
      expect(find.text('Tanggal dibayar'), findsNothing);
      expect(find.text('Transfer'), findsNothing);
      expect(find.text('Tunai'), findsNothing);
    });

    testWidgets('shows the method Transfer and the date paid', (tester) async {
      await _open(tester, _repo(_paidByTransfer()));

      expect(find.text('Metode pembayaran'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Tanggal dibayar'), findsOneWidget);
      expect(find.textContaining('4 Nov 2026'), findsOneWidget);
    });

    testWidgets('shows the method Tunai and the date paid', (tester) async {
      await _open(tester, _repo(_paidInCash()));

      expect(find.text('Metode pembayaran'), findsOneWidget);
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.textContaining('3 Nov 2026'), findsOneWidget);
      expect(find.text('Transfer'), findsNothing);
    });

    testWidgets('shows the rejection reason of a rejected bill', (
      tester,
    ) async {
      await _open(tester, _repo(_rejected()));

      expect(find.text('Alasan penolakan'), findsOneWidget);
      expect(find.text('Nominal transfer tidak sesuai.'), findsOneWidget);
    });

    testWidgets('shows no rejection reason on a bill that is not rejected', (
      tester,
    ) async {
      await _open(tester, _repo(_paidByTransfer()));

      expect(find.text('Alasan penolakan'), findsNothing);
    });

    testWidgets('is read only: it offers no payment action', (tester) async {
      await _open(tester, _repo(_awaiting(), receipt: true));

      for (final text in [
        'Verifikasi',
        'Tolak',
        'Ubah Status',
        'Catat Pembayaran Tunai',
        'Transfer sekarang',
        'Unggah Bukti',
        'Unggah ulang bukti',
        'Bayar tunai ke pengelola kost',
      ]) {
        expect(find.text(text), findsNothing, reason: text);
      }
    });

    testWidgets('an unpaid bill is read only too', (tester) async {
      await _open(tester, _repo(_unpaid()));

      for (final text in [
        'Verifikasi',
        'Tolak',
        'Ubah Status',
        'Catat Pembayaran Tunai',
        'Transfer sekarang',
        'Unggah Bukti',
        'Bayar tunai ke pengelola kost',
      ]) {
        expect(find.text(text), findsNothing, reason: text);
      }
    });
  });

  group('status history', () {
    testWidgets('is a heading titled Riwayat Status', (tester) async {
      await _open(tester, _repo(_withHistory()));

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Riwayat Status')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('lists the changes oldest first as returned', (tester) async {
      await _open(tester, _repo(_withHistory()));

      const order = ['Catatan pertama', 'Catatan kedua', 'Catatan ketiga'];
      for (final reason in order) {
        expect(find.text(reason), findsOneWidget, reason: reason);
      }
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          tester.getTopLeft(find.text(order[i])).dy,
          lessThan(tester.getTopLeft(find.text(order[i + 1])).dy),
        );
      }
    });

    testWidgets('shows the status of every change as text', (tester) async {
      await _open(tester, _repo(_withHistory()));

      expect(find.text('Menunggu Verifikasi'), findsNWidgets(2));
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Lunas'), findsNWidgets(2));
    });

    testWidgets('shows the date of every change', (tester) async {
      await _open(tester, _repo(_withHistory()));

      for (final date in [
        '3 Nov 2026',
        '4 Nov 2026',
        '5 Nov 2026',
        '6 Nov 2026',
      ]) {
        expect(find.textContaining(date), findsWidgets, reason: date);
      }
    });

    testWidgets('names the person who made a manual change', (tester) async {
      await _open(tester, _repo(_withHistory()));

      expect(find.textContaining('Siti Pemilik'), findsWidgets);
    });

    testWidgets('shows no placeholder for a change without a person', (
      tester,
    ) async {
      await _open(tester, _repo(_withHistory()));

      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('shows a bill without changes', (tester) async {
      await _open(tester, _repo(_unpaid()));

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    });
  });

  group('receipt', () {
    testWidgets('a bill with a receipt shows the image', (tester) async {
      final repo = _repo(_awaiting(), receipt: true);
      await _open(tester, repo);
      await _decode(tester);

      expect(repo.receiptCalls, 1);
      expect(repo.calls, contains('receipt:d1'));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('labels the image with the tenant and the period', (
      tester,
    ) async {
      await _open(tester, _repo(_awaiting(), receipt: true));
      await _decode(tester);

      final handle = tester.ensureSemantics();
      try {
        final labels = _receiptLabels(tester);
        expect(labels, hasLength(1));
        expect(labels.single, startsWith('Bukti transfer, Budi Santoso, '));
        expect(labels.single, contains('1 Nov 2026'));
        expect(labels.single, contains('30 Nov 2026'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a rejected bill with a receipt shows the image', (
      tester,
    ) async {
      await _open(tester, _repo(_rejected(), receipt: true));
      await _decode(tester);

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Nominal transfer tidak sesuai.'), findsOneWidget);
    });

    testWidgets('a bill without a receipt asks for no image', (tester) async {
      final repo = _repo(_unpaid());
      await _open(tester, repo);

      expect(repo.receiptCalls, 0);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a failed image load keeps the bill and offers a reload', (
      tester,
    ) async {
      final repo = _repo(_awaiting(), receipt: true)
        ..receiptScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Coba lagi loads the image again', (tester) async {
      final repo = _repo(_awaiting(), receipt: true)
        ..receiptScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();
      await _decode(tester);

      expect(repo.receiptCalls, 2);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(_retry), findsNothing);
      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('a missing receipt shows its message and keeps the bill', (
      tester,
    ) async {
      final repo = _repo(_awaiting());
      await _open(tester, repo);

      expect(find.text('Bukti transfer tidak ditemukan.'), findsOneWidget);
      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('bytes that are not an image offer a reload', (tester) async {
      final repo = _repo(_awaiting())
        ..receipts['d1'] = Uint8List.fromList([1, 2, 3]);
      await _open(tester, repo);
      await _decode(tester);

      expect(find.text(_retry), findsOneWidget);
      expect(find.text('Rp800.000'), findsOneWidget);
    });

    testWidgets('shows a progress indicator while the image loads', (
      tester,
    ) async {
      final repo = _repo(_awaiting(), receipt: true)
        ..receiptScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expect(find.text('Rp800.000'), findsOneWidget);
      expectLoading(tester);
    });
  });

  group('accessibility', () {
    final states = <String, FakeRentBillRepository Function()>{
      'unpaid': () => _repo(_unpaid()),
      'paid by transfer': () => _repo(_paidByTransfer()),
      'paid in cash': () => _repo(_paidInCash()),
      'rejected': () => _repo(_rejected(), receipt: true),
      'with a status history': () => _repo(_withHistory()),
      'with a receipt': () => _repo(_awaiting(), receipt: true),
      'failed': () =>
          _repo(_unpaid())..getScript.always = const ApiFailure.network(),
      'failed receipt': () =>
          _repo(_awaiting(), receipt: true)
            ..receiptScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await _open(tester, entry.value());
        await _decode(tester);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);
        await _decode(tester);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo(_unpaid())..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo(_unpaid())..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
