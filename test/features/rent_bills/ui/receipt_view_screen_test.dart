import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/ui/receipt_view_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'rent_bill_ui_helpers.dart';

FakeRentBillRepository _repo() => FakeRentBillRepository(
  bills: [
    makeRentBill(
      id: 'b2',
      status: PaymentStatus.awaitingVerification,
      periodStart: day(10, 1),
      periodEnd: day(10, 31),
    ),
  ],
  receipts: {'b2': tinyPng},
);

Future<void> _open(
  WidgetTester tester,
  FakeRentBillRepository repo, {
  bool largeText = false,
  bool settle = true,
}) => pumpRentBillApp(
  tester,
  repo,
  path: receiptPath('b2'),
  largeText: largeText,
  settle: settle,
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
  group('loaded', () {
    testWidgets('is titled Bukti Transfer and covers the navigation bar', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.byType(ReceiptViewScreen), findsOneWidget);
      expect(appBarTitle('Bukti Transfer'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('loads the receipt and the bill of the route', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(repo.calls, contains('receipt:b2'));
      expect(repo.receiptCalls, 1);
    });

    testWidgets('shows the receipt as an image', (tester) async {
      await _open(tester, _repo());
      await _decode(tester);

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('labels the image with the tenant and the period', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _decode(tester);

      final handle = tester.ensureSemantics();
      try {
        final labels = _receiptLabels(tester);
        expect(labels, hasLength(1));
        expect(labels.single, startsWith('Bukti transfer, Budi Santoso, '));
        expect(labels.single, contains('1 Okt 2026'));
        expect(labels.single, contains('31 Okt 2026'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Kembali returns to the list', (tester) async {
      await _open(tester, _repo());

      await pressBack(tester);

      expect(find.byType(ReceiptViewScreen), findsNothing);
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..receiptScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('failure', () {
    testWidgets('shows the message of the failure and a retry', (tester) async {
      final repo = _repo()..receiptScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a missing receipt shows its message', (tester) async {
      final repo = _repo()..receipts.clear();
      await _open(tester, repo);

      expect(find.text('Bukti transfer tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('a missing bill shows its message', (tester) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'RENT_BILL_NOT_FOUND');
      await _open(tester, repo);

      expect(find.text('Tagihan tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the receipt again', (tester) async {
      final repo = _repo()..receiptScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      await _decode(tester);

      expect(repo.receiptCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('keeps the failure when the retry fails too', (tester) async {
      final repo = _repo()
        ..receiptScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.receiptCalls, 2);
    });

    testWidgets('bytes that are not an image offer a reload', (tester) async {
      final repo = _repo()..receipts['b2'] = Uint8List.fromList([1, 2, 3]);
      await _open(tester, repo);
      await _decode(tester);

      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, FakeRentBillRepository Function()>{
      'loaded': _repo,
      'failed': () =>
          _repo()..receiptScript.always = const ApiFailure.network(),
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
      final repo = _repo()..receiptScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
