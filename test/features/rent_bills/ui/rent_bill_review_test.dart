import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'payment_review_ui_helpers.dart';

const _reason = 'Nominal transfer tidak sesuai.';

Future<ReviewRepositories> _open(
  WidgetTester tester, {
  ReviewRepositories? repos,
  String billId = 'b2',
  UserRole role = UserRole.owner,
  bool largeText = false,
  bool settle = true,
}) async {
  final shown = repos ?? reviewRepositories();
  await pumpReview(
    tester,
    shown,
    role: role,
    path: billPath(billId),
    largeText: largeText,
    settle: settle,
  );
  return shown;
}

/// Lets the image codec finish, which runs outside of the fake clock.
Future<void> _decode(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// The shared bill list with the bill `b2` replaced, as another user would
/// have changed it.
void _changeElsewhere(ReviewRepositories repos, RentBill bill) {
  final index = repos.management.bills.indexWhere((b) => b.id == bill.id);
  repos.management.bills[index] = bill;
}

RentBill _paidElsewhere() => makeRentBill(
  id: 'b2',
  tenantId: 't2',
  tenantName: 'Dewi Lestari',
  roomNumber: '12',
  amount: 810000,
  status: PaymentStatus.paid,
  method: PaymentMethod.cash,
  paidOn: DateTime.utc(2026, 11, 3),
);

String _fieldText(WidgetTester tester) =>
    labeledTextField(tester, reasonLabel).controller!.text;

const _failures = <String, (ApiFailure, String)>{
  'a missing bill': (
    ApiFailure(code: 'RENT_BILL_NOT_FOUND', statusCode: 404),
    'Tagihan tidak ditemukan.',
  ),
  'a forbidden response': (
    ApiFailure(code: 'FORBIDDEN', statusCode: 403),
    'Anda tidak memiliki akses untuk tindakan ini.',
  ),
  'a network failure': (
    ApiFailure.network(),
    'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
  ),
  'a server error': (
    ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500),
    'Terjadi kesalahan pada server. Coba lagi.',
  ),
};

void main() {
  setUpAll(initializeIndonesianDates);

  group('actions', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('are offered to a $role on a bill awaiting verification', (
        tester,
      ) async {
        await _open(tester, role: role);

        expect(actionButton(verifyLabel), findsOneWidget);
        expect(actionButton(rejectLabel), findsOneWidget);
        expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      });
    }

    final others = <String, RentBill Function()>{
      'unpaid': () => makeRentBill(id: 'b2'),
      'paid by transfer': () => makeRentBill(
        id: 'b2',
        status: PaymentStatus.paid,
        method: PaymentMethod.transfer,
        paidOn: DateTime.utc(2026, 11, 4),
      ),
      'paid in cash': () => makeRentBill(
        id: 'b2',
        status: PaymentStatus.paid,
        method: PaymentMethod.cash,
        paidOn: DateTime.utc(2026, 11, 3),
      ),
      'rejected': () => makeRentBill(
        id: 'b2',
        status: PaymentStatus.rejected,
        rejectionReason: _reason,
      ),
    };
    for (final entry in others.entries) {
      testWidgets('are not offered on a bill that is ${entry.key}', (
        tester,
      ) async {
        await _open(tester, repos: reviewRepositories(bills: [entry.value()]));

        expect(find.text('Rp800.000'), findsOneWidget);
        expectNoReviewActions();
      });
    }

    testWidgets('are not offered while the bill loads', (tester) async {
      final repos = reviewRepositories();
      repos.rentBills.getScript.gate = Completer<void>();
      await _open(tester, repos: repos, settle: false);

      expectNoReviewActions();
    });

    testWidgets('are not offered when the bill fails to load', (tester) async {
      final repos = reviewRepositories();
      repos.rentBills.getScript.always = const ApiFailure.network();
      await _open(tester, repos: repos);

      expectNoReviewActions();
    });

    testWidgets('stay offered next to a receipt that fails to load', (
      tester,
    ) async {
      final repos = reviewRepositories(
        bills: [
          makeRentBill(id: 'b2', status: PaymentStatus.awaitingVerification),
        ],
      );
      repos.rentBills.receiptScript.queue.add(const ApiFailure.network());
      await _open(tester, repos: repos);

      expect(find.text(retryLabel), findsOneWidget);
      expect(actionButton(verifyLabel), findsOneWidget);
      expect(actionButton(rejectLabel), findsOneWidget);
    });

    testWidgets('stay offered below a receipt that is shown', (tester) async {
      final repos = reviewRepositories(
        bills: [
          makeRentBill(id: 'b2', status: PaymentStatus.awaitingVerification),
        ],
        withReceipts: true,
      );
      await _open(tester, repos: repos);
      await _decode(tester);

      expect(find.byType(Image), findsOneWidget);
      expect(actionButton(verifyLabel), findsOneWidget);
      expect(actionButton(rejectLabel), findsOneWidget);
    });

    testWidgets('have a target of at least 48 dp', (tester) async {
      await _open(tester);

      expectTargetSize(tester, verifyLabel);
      expectTargetSize(tester, rejectLabel);
    });
  });

  group('verifying', () {
    testWidgets('asks for confirmation and sends nothing yet', (tester) async {
      final repos = await _open(tester);

      await press(tester, actionButton(verifyLabel));

      expect(find.byType(AlertDialog), findsOneWidget);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.title, isA<Text>());
      expect((dialog.title! as Text).data, 'Verifikasi Pembayaran');
      expect(dialog.content, isA<Text>());
      expect(inDialog('Batal'), findsOneWidget);
      expect(inDialog(verifyLabel), findsOneWidget);
      expect(repos.management.verifyCalls, 0);
    });

    testWidgets('announces the dialog title to a screen reader', (
      tester,
    ) async {
      await _open(tester);
      await press(tester, actionButton(verifyLabel));

      final handle = tester.ensureSemantics();
      try {
        expect(nodesAnnouncing(tester, 'Verifikasi Pembayaran'), isNotEmpty);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Batal closes the dialog and sends nothing', (tester) async {
      final repos = await _open(tester);
      await press(tester, actionButton(verifyLabel));

      await tester.tap(inDialog('Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repos.management.verifyCalls, 0);
      expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      expect(actionButton(verifyLabel), findsOneWidget);
      expect(actionButton(rejectLabel), findsOneWidget);
    });

    testWidgets('tapping outside the dialog closes it and sends nothing', (
      tester,
    ) async {
      final repos = await _open(tester);
      await press(tester, actionButton(verifyLabel));

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repos.management.verifyCalls, 0);
    });

    testWidgets('the back gesture closes the dialog, not the bill', (
      tester,
    ) async {
      final repos = await _open(tester);
      await press(tester, actionButton(verifyLabel));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(currentUri(tester).path, billPath('b2'));
      expect(repos.management.verifyCalls, 0);
    });

    testWidgets('confirming verifies the bill once', (tester) async {
      final repos = await _open(tester);

      await verifyAndConfirm(tester);

      expect(repos.management.verified, ['b2']);
      expect(repos.management.verifyCalls, 1);
      expect(repos.management.rejectCalls, 0);
    });

    testWidgets('then shows the bill as Lunas by transfer with its date', (
      tester,
    ) async {
      await _open(tester);

      await verifyAndConfirm(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(statusBadge('Lunas'), findsWidgets);
      expect(find.text('Metode pembayaran'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Tanggal dibayar'), findsOneWidget);
      expect(find.textContaining('7 Nov 2026'), findsWidgets);
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
      expect(currentUri(tester).path, billPath('b2'));
    });

    testWidgets('then offers no action any more', (tester) async {
      await _open(tester);

      await verifyAndConfirm(tester);

      expectNoReviewActions();
    });

    testWidgets('then lists the change in the status history', (tester) async {
      await _open(tester);

      await verifyAndConfirm(tester);

      expect(find.text('Riwayat Status'), findsOneWidget);
      expect(find.textContaining('Siti Pemilik'), findsWidgets);
    });

    testWidgets('shows the tenant no notification of its own', (tester) async {
      await _open(tester);

      await verifyAndConfirm(tester);

      expect(find.textContaining('otifikasi'), findsNothing);
      expect(find.textContaining('diberi tahu'), findsNothing);
    });

    testWidgets('a second tap while it is sent sends one request', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repos = reviewRepositories();
      repos.management.verifyScript.gate = gate;
      await _open(tester, repos: repos);

      await press(tester, actionButton(verifyLabel));
      await tester.tap(inDialog(verifyLabel));
      await tester.pump();

      final again = actionButton(verifyLabel);
      if (again.evaluate().isNotEmpty) {
        await tester.tap(again, warnIfMissed: false);
        await tester.pump();
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          await tester.tap(inDialog(verifyLabel));
          await tester.pump();
        }
      }
      expect(repos.management.verifyCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repos.management.verifyCalls, 1);
      expect(statusBadge('Lunas'), findsWidgets);
    });

    for (final entry in _failures.entries) {
      testWidgets('shows ${entry.key} and keeps the bill to retry', (
        tester,
      ) async {
        final repos = reviewRepositories();
        repos.management.verifyScript.queue.add(entry.value.$1);
        await _open(tester, repos: repos);

        await verifyAndConfirm(tester);

        expect(find.text(entry.value.$2), findsOneWidget);
        expect(currentUri(tester).path, billPath('b2'));
        expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
        expect(actionButton(verifyLabel), findsOneWidget);
        expect(actionButton(rejectLabel), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('keeps the message of ${entry.key} until the next try', (
        tester,
      ) async {
        final repos = reviewRepositories();
        repos.management.verifyScript.queue.add(entry.value.$1);
        await _open(tester, repos: repos);

        await verifyAndConfirm(tester);
        await tester.pump(const Duration(seconds: 30));

        expect(find.text(entry.value.$2), findsOneWidget);
      });

      testWidgets('succeeds on a retry after ${entry.key}', (tester) async {
        final repos = reviewRepositories();
        repos.management.verifyScript.queue.add(entry.value.$1);
        await _open(tester, repos: repos);
        await verifyAndConfirm(tester);

        await verifyAndConfirm(tester);

        expect(repos.management.verifyCalls, 2);
        expect(statusBadge('Lunas'), findsWidgets);
        expect(find.text(entry.value.$2), findsNothing);
        expectNoReviewActions();
      });
    }

    testWidgets('a conflict shows its message and reloads the bill', (
      tester,
    ) async {
      final repos = await _open(tester);
      final loadsBefore = repos.rentBills.getCalls;
      _changeElsewhere(repos, _paidElsewhere());

      await verifyAndConfirm(tester);

      expect(find.text(conflictMessage), findsOneWidget);
      expect(repos.rentBills.getCalls, greaterThan(loadsBefore));
      expect(statusBadge('Lunas'), findsWidgets);
      expect(find.text('Tunai'), findsOneWidget);
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
      expectNoReviewActions();
    });

    testWidgets('a scripted conflict reloads the bill too', (tester) async {
      final repos = reviewRepositories();
      repos.management.verifyScript.queue.add(
        const ApiFailure(code: conflictCode, statusCode: 409),
      );
      await _open(tester, repos: repos);
      final loadsBefore = repos.rentBills.getCalls;

      await verifyAndConfirm(tester);

      expect(find.text(conflictMessage), findsOneWidget);
      expect(repos.rentBills.getCalls, greaterThan(loadsBefore));
    });

    testWidgets('the message of a conflict stays on screen', (tester) async {
      final repos = await _open(tester);
      _changeElsewhere(repos, _paidElsewhere());

      await verifyAndConfirm(tester);
      await tester.pump(const Duration(seconds: 30));

      expect(find.text(conflictMessage), findsOneWidget);
    });
  });

  group('rejecting', () {
    testWidgets('opens a prompt with a required multi-line reason', (
      tester,
    ) async {
      final repos = await _open(tester);

      await press(tester, actionButton(rejectLabel));

      expect(labeledField(reasonLabel), findsOneWidget);
      expect(reasonField(), findsOneWidget);
      expect(labeledTextField(tester, reasonLabel).maxLines, isNot(1));
      expect(labeledTextField(tester, reasonLabel).decoration?.labelText, null);
      expect(_fieldText(tester), isEmpty);
      expect(actionButton(submitRejectionLabel), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(repos.management.rejectCalls, 0);
    });

    testWidgets('titles the prompt with a heading', (tester) async {
      await _open(tester);
      await press(tester, actionButton(rejectLabel));

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Tolak Pembayaran')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('announces the field once, with its label', (tester) async {
      await _open(tester);
      await press(tester, actionButton(rejectLabel));

      expectFieldNode(tester, reasonLabel);
      expectNoDecorationLabels(tester);
    });

    testWidgets('Batal closes the prompt and sends nothing', (tester) async {
      final repos = await _open(tester);
      await press(tester, actionButton(rejectLabel));
      await typeInto(tester, reasonLabel, _reason);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(reasonField(), findsNothing);
      expect(repos.management.rejectCalls, 0);
      expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      expect(actionButton(verifyLabel), findsOneWidget);
      expect(actionButton(rejectLabel), findsOneWidget);
    });

    testWidgets('tapping outside closes the prompt and sends nothing', (
      tester,
    ) async {
      final repos = await _open(tester);
      await press(tester, actionButton(rejectLabel));

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(reasonField(), findsNothing);
      expect(repos.management.rejectCalls, 0);
    });

    testWidgets('the back gesture closes the prompt, not the bill', (
      tester,
    ) async {
      final repos = await _open(tester);
      await press(tester, actionButton(rejectLabel));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(reasonField(), findsNothing);
      expect(currentUri(tester).path, billPath('b2'));
      expect(repos.management.rejectCalls, 0);
    });

    const blanks = {
      'no text': '',
      'only spaces': '   ',
      'only spaces and line breaks': ' \n\t ',
    };
    for (final blank in blanks.entries) {
      testWidgets('a reason with ${blank.key} is refused', (tester) async {
        final repos = await _open(tester);
        await press(tester, actionButton(rejectLabel));
        await typeInto(tester, reasonLabel, blank.value);

        await tester.tap(actionButton(submitRejectionLabel));
        await tester.pumpAndSettle();

        expect(labeledFieldError(tester, reasonLabel), reasonRequiredMessage);
        expect(reasonField(), findsOneWidget);
        expect(repos.management.rejectCalls, 0);
      });
    }

    testWidgets('exposes the refusal on the field to a screen reader', (
      tester,
    ) async {
      await _open(tester);
      await press(tester, actionButton(rejectLabel));

      await tester.tap(actionButton(submitRejectionLabel));
      await tester.pumpAndSettle();

      expectFieldNode(tester, reasonLabel, error: reasonRequiredMessage);
    });

    testWidgets('a reason typed after a refusal is sent', (tester) async {
      final repos = await _open(tester);
      await press(tester, actionButton(rejectLabel));
      await tester.tap(actionButton(submitRejectionLabel));
      await tester.pumpAndSettle();

      await typeInto(tester, reasonLabel, _reason);
      await tester.tap(actionButton(submitRejectionLabel));
      await tester.pumpAndSettle();

      expect(repos.management.rejected, [(id: 'b2', reason: _reason)]);
    });

    testWidgets('sends the reason without the blanks around it', (
      tester,
    ) async {
      final repos = await _open(tester);

      await rejectWith(tester, '  \n Foto buram.\nUnggah ulang.  \n');

      expect(repos.management.rejected, [
        (id: 'b2', reason: 'Foto buram.\nUnggah ulang.'),
      ]);
    });

    testWidgets('then closes the prompt and shows the bill as Ditolak', (
      tester,
    ) async {
      await _open(tester);

      await rejectWith(tester, _reason);

      expect(reasonField(), findsNothing);
      expect(statusBadge('Ditolak'), findsWidgets);
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
      expect(find.text('Alasan penolakan'), findsOneWidget);
      expect(find.text(_reason), findsWidgets);
      expect(currentUri(tester).path, billPath('b2'));
    });

    testWidgets('then offers no action any more', (tester) async {
      await _open(tester);

      await rejectWith(tester, _reason);

      expectNoReviewActions();
    });

    testWidgets('then lists the change in the status history', (tester) async {
      await _open(tester);

      await rejectWith(tester, _reason);

      expect(find.text('Riwayat Status'), findsOneWidget);
      expect(find.textContaining('Siti Pemilik'), findsWidgets);
    });

    testWidgets('shows the tenant no notification of its own', (tester) async {
      await _open(tester);

      await rejectWith(tester, _reason);

      expect(find.textContaining('otifikasi'), findsNothing);
      expect(find.textContaining('diberi tahu'), findsNothing);
    });

    testWidgets('a second tap while it is sent sends one request', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repos = reviewRepositories();
      repos.management.rejectScript.gate = gate;
      await _open(tester, repos: repos);
      await press(tester, actionButton(rejectLabel));
      await typeInto(tester, reasonLabel, _reason);

      await tester.tap(actionButton(submitRejectionLabel));
      await tester.pump();
      final again = actionButton(submitRejectionLabel);
      if (again.evaluate().isNotEmpty) {
        await tester.tap(again, warnIfMissed: false);
        await tester.pump();
      }
      expect(repos.management.rejectCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repos.management.rejectCalls, 1);
      expect(statusBadge('Ditolak'), findsWidgets);
    });

    for (final entry in _failures.entries) {
      testWidgets('shows ${entry.key} in the prompt and keeps the reason', (
        tester,
      ) async {
        final repos = reviewRepositories();
        repos.management.rejectScript.queue.add(entry.value.$1);
        await _open(tester, repos: repos);

        await rejectWith(tester, _reason);

        expect(find.text(entry.value.$2), findsOneWidget);
        expect(reasonField(), findsOneWidget);
        expect(_fieldText(tester), _reason);
        expect(currentUri(tester).path, billPath('b2'));
        expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
        expect(repos.management.rejectCalls, 1);
      });

      testWidgets('keeps the message of ${entry.key} until the next try', (
        tester,
      ) async {
        final repos = reviewRepositories();
        repos.management.rejectScript.queue.add(entry.value.$1);
        await _open(tester, repos: repos);

        await rejectWith(tester, _reason);
        await tester.pump(const Duration(seconds: 30));

        expect(find.text(entry.value.$2), findsOneWidget);
      });

      testWidgets('succeeds on a retry after ${entry.key}', (tester) async {
        final repos = reviewRepositories();
        repos.management.rejectScript.queue.add(entry.value.$1);
        await _open(tester, repos: repos);
        await rejectWith(tester, _reason);

        await tester.tap(actionButton(submitRejectionLabel));
        await tester.pumpAndSettle();

        expect(repos.management.rejected, [
          (id: 'b2', reason: _reason),
          (id: 'b2', reason: _reason),
        ]);
        expect(reasonField(), findsNothing);
        expect(statusBadge('Ditolak'), findsWidgets);
        expect(find.text(entry.value.$2), findsNothing);
      });
    }

    testWidgets('a validation failure on the reason shows next to the field', (
      tester,
    ) async {
      final repos = reviewRepositories();
      repos.management.rejectScript.queue.add(
        const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'reason',
          statusCode: 422,
        ),
      );
      await _open(tester, repos: repos);

      await rejectWith(tester, _reason);

      expect(
        labeledFieldError(tester, reasonLabel),
        'Alasan penolakan tidak valid.',
      );
      expect(reasonField(), findsOneWidget);
      expect(_fieldText(tester), _reason);
      expectFieldNode(
        tester,
        reasonLabel,
        error: 'Alasan penolakan tidak valid.',
      );
    });

    testWidgets('a corrected reason is sent after a validation failure', (
      tester,
    ) async {
      final repos = reviewRepositories();
      repos.management.rejectScript.queue.add(
        const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'reason',
          statusCode: 422,
        ),
      );
      await _open(tester, repos: repos);
      await rejectWith(tester, _reason);

      await typeInto(tester, reasonLabel, 'Foto buram.');
      await tester.tap(actionButton(submitRejectionLabel));
      await tester.pumpAndSettle();

      expect(repos.management.rejected.last.reason, 'Foto buram.');
      expect(statusBadge('Ditolak'), findsWidgets);
    });

    testWidgets('a conflict closes the prompt, shows its message and reloads', (
      tester,
    ) async {
      final repos = await _open(tester);
      final loadsBefore = repos.rentBills.getCalls;
      _changeElsewhere(repos, _paidElsewhere());

      await rejectWith(tester, _reason);

      expect(reasonField(), findsNothing);
      expect(find.text(conflictMessage), findsOneWidget);
      expect(repos.rentBills.getCalls, greaterThan(loadsBefore));
      expect(statusBadge('Lunas'), findsWidgets);
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
      expectNoReviewActions();
    });

    testWidgets('the message of a conflict stays on screen', (tester) async {
      final repos = await _open(tester);
      _changeElsewhere(repos, _paidElsewhere());

      await rejectWith(tester, _reason);
      await tester.pump(const Duration(seconds: 30));

      expect(find.text(conflictMessage), findsOneWidget);
    });
  });

  group('lists and overview after a review', () {
    Future<void> openRowFromList(WidgetTester tester, String tenant) async {
      await tester.tap(verificationEntry());
      await tester.pumpAndSettle();
      await tester.tap(find.text(tenant));
      await tester.pumpAndSettle();
    }

    testWidgets('the verification list drops a verified bill', (tester) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);
      await openRowFromList(tester, 'Dewi Lestari');
      final loadsBefore = repos.management.listCalls;

      await verifyAndConfirm(tester);
      await pressBack(tester);

      expect(currentUri(tester).path, '/pembayaran/verifikasi');
      expect(repos.management.listCalls, greaterThan(loadsBefore));
      expect(find.text('Dewi Lestari'), findsNothing);
      expect(find.text('Agus Salim'), findsOneWidget);
    });

    testWidgets('the verification list drops a rejected bill', (tester) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);
      await openRowFromList(tester, 'Agus Salim');
      final loadsBefore = repos.management.listCalls;

      await rejectWith(tester, _reason);
      await pressBack(tester);

      expect(repos.management.listCalls, greaterThan(loadsBefore));
      expect(find.text('Agus Salim'), findsNothing);
      expect(find.text('Dewi Lestari'), findsOneWidget);
    });

    testWidgets('the verification list empties after the last review', (
      tester,
    ) async {
      final repos = reviewRepositories(
        bills: [
          makeRentBill(
            id: 'b2',
            propertyId: 'p1',
            status: PaymentStatus.awaitingVerification,
            hasReceipt: false,
          ),
        ],
      );
      await pumpReview(tester, repos);
      await openRowFromList(tester, 'Budi Santoso');

      await verifyAndConfirm(tester);
      await pressBack(tester);

      expect(
        find.textContaining('Tidak ada pembayaran yang menunggu verifikasi'),
        findsOneWidget,
      );
    });

    testWidgets('the overview shows a verified bill as paid', (tester) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);
      final loadsBefore = repos.management.overviewCalls;
      await openRowFromList(tester, 'Dewi Lestari');

      await verifyAndConfirm(tester);
      await pressBack(tester);
      await pressBack(tester);

      expect(currentUri(tester).path, overviewPath);
      expect(repos.management.overviewCalls, greaterThan(loadsBefore));
      // Paid bills leave the default filter of unpaid tenants.
      expect(find.text('Dewi Lestari'), findsNothing);
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      expect(inRow('Dewi Lestari', find.text('Lunas')), findsOneWidget);
      expect(
        inRow('Dewi Lestari', find.text('Menunggu Verifikasi')),
        findsNothing,
      );
    });

    testWidgets('the overview shows a rejected bill as rejected', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);
      final loadsBefore = repos.management.overviewCalls;
      await openRowFromList(tester, 'Dewi Lestari');

      await rejectWith(tester, _reason);
      await pressBack(tester);
      await pressBack(tester);

      expect(repos.management.overviewCalls, greaterThan(loadsBefore));
      expect(inRow('Dewi Lestari', find.text('Ditolak')), findsOneWidget);
      expect(
        inRow('Dewi Lestari', find.text('Menunggu Verifikasi')),
        findsNothing,
      );
    });

    testWidgets('the history of the tenant shows a verified bill as paid', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos, path: historyPath('t2', 'p1'));
      expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      final loadsBefore = repos.management.listCalls;

      await tester.tap(find.text('Rp810.000'));
      await tester.pumpAndSettle();
      await verifyAndConfirm(tester);
      await pressBack(tester);

      expect(currentUri(tester).path, '/pembayaran/penyewa/t2');
      expect(repos.management.listCalls, greaterThan(loadsBefore));
      expect(statusBadge('Lunas'), findsOneWidget);
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
    });

    testWidgets('the history of the tenant shows a rejected bill', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos, path: historyPath('t2', 'p1'));

      await tester.tap(find.text('Rp810.000'));
      await tester.pumpAndSettle();
      await rejectWith(tester, _reason);
      await pressBack(tester);

      expect(statusBadge('Ditolak'), findsOneWidget);
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
    });

    testWidgets('a bill reviewed from a link shows fresh data in the list', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos, path: billPath('b2'));
      await verifyAndConfirm(tester);

      goTo(tester, verificationPath('p1'));
      await tester.pumpAndSettle();

      expect(find.text('Dewi Lestari'), findsNothing);
      expect(find.text('Agus Salim'), findsOneWidget);
    });

    testWidgets('a review changes nothing for other properties', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos, path: billPath('b2'));
      await verifyAndConfirm(tester);

      goTo(tester, verificationPath('p2'));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
    });
  });

  group('accessibility', () {
    Future<ReviewRepositories> awaiting(WidgetTester tester, bool large) =>
        _open(tester, largeText: large);

    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'awaiting verification': (tester, large) async {
        await awaiting(tester, large);
      },
      'with a receipt': (tester, large) async {
        final repos = reviewRepositories(
          bills: [
            makeRentBill(id: 'b2', status: PaymentStatus.awaitingVerification),
          ],
          withReceipts: true,
        );
        await _open(tester, repos: repos, largeText: large);
        await _decode(tester);
      },
      'asking to confirm': (tester, large) async {
        await awaiting(tester, large);
        await press(tester, actionButton(verifyLabel));
      },
      'asking for a reason': (tester, large) async {
        await awaiting(tester, large);
        await press(tester, actionButton(rejectLabel));
      },
      'refusing a blank reason': (tester, large) async {
        await awaiting(tester, large);
        await press(tester, actionButton(rejectLabel));
        await press(tester, actionButton(submitRejectionLabel));
      },
      'refusing a reason on the server': (tester, large) async {
        final repos = reviewRepositories();
        repos.management.rejectScript.queue.add(
          const ApiFailure(
            code: 'VALIDATION_FAILED',
            field: 'reason',
            statusCode: 422,
          ),
        );
        await _open(tester, repos: repos, largeText: large);
        await rejectWith(tester, _reason);
      },
      'failing to reject': (tester, large) async {
        final repos = reviewRepositories();
        repos.management.rejectScript.queue.add(const ApiFailure.network());
        await _open(tester, repos: repos, largeText: large);
        await rejectWith(tester, _reason);
      },
      'failing to verify': (tester, large) async {
        final repos = reviewRepositories();
        repos.management.verifyScript.queue.add(const ApiFailure.network());
        await _open(tester, repos: repos, largeText: large);
        await verifyAndConfirm(tester);
      },
      'after a conflict': (tester, large) async {
        final repos = await _open(tester, largeText: large);
        _changeElsewhere(repos, _paidElsewhere());
        await verifyAndConfirm(tester);
      },
      'after verifying': (tester, large) async {
        await awaiting(tester, large);
        await verifyAndConfirm(tester);
      },
      'after rejecting': (tester, large) async {
        await awaiting(tester, large);
        await rejectWith(tester, _reason);
      },
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
  });
}
