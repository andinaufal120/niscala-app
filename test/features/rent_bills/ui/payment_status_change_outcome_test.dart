import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'payment_status_change_ui_helpers.dart';

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
  'an unknown code': (
    ApiFailure(code: 'SOMETHING_NEW', statusCode: 400),
    'Terjadi kesalahan. Coba lagi.',
  ),
};

/// Failures that name a field, how to reach them, and where they show.
typedef _FieldCase = ({
  ApiFailure failure,
  String message,
  String status,
  String? method,
  String? where,
});

const _fieldCases = <String, _FieldCase>{
  'a missing reason': (
    failure: ApiFailure(
      code: 'REASON_REQUIRED',
      field: 'reason',
      statusCode: 422,
    ),
    message: changeReasonRequiredMessage,
    status: 'Ditolak',
    method: null,
    where: 'reason',
  ),
  'an invalid reason': (
    failure: ApiFailure(
      code: 'VALIDATION_FAILED',
      field: 'reason',
      statusCode: 422,
    ),
    message: reasonInvalidMessage,
    status: 'Ditolak',
    method: null,
    where: 'reason',
  ),
  'an unchanged status': (
    failure: ApiFailure(
      code: 'STATUS_UNCHANGED',
      field: 'status',
      statusCode: 422,
    ),
    message: statusUnchangedMessage,
    status: 'Ditolak',
    method: null,
    where: 'sheet',
  ),
  'an invalid status': (
    failure: ApiFailure(
      code: 'VALIDATION_FAILED',
      field: 'status',
      statusCode: 422,
    ),
    message: statusInvalidMessage,
    status: 'Ditolak',
    method: null,
    where: 'sheet',
  ),
  'an invalid method': (
    failure: ApiFailure(
      code: 'VALIDATION_FAILED',
      field: 'method',
      statusCode: 422,
    ),
    message: methodInvalidMessage,
    status: 'Lunas',
    method: 'Transfer',
    where: 'sheet',
  ),
  'an invalid date': (
    failure: ApiFailure(
      code: 'VALIDATION_FAILED',
      field: 'receivedOn',
      statusCode: 422,
    ),
    message: invalidDateMessage,
    status: 'Lunas',
    method: 'Tunai',
    where: 'date',
  ),
  'a date in the future': (
    failure: ApiFailure(
      code: 'RECEIVED_ON_IN_FUTURE',
      field: 'receivedOn',
      statusCode: 422,
    ),
    message: futureDateMessage,
    status: 'Lunas',
    method: 'Tunai',
    where: 'date',
  ),
};

/// The error text shown by the field of [kase] in the open sheet.
String? _shownError(WidgetTester tester, _FieldCase kase) =>
    switch (kase.where) {
      'reason' => labeledFieldError(tester, changeReasonLabel),
      'date' => labeledFieldError(tester, dateLabel),
      _ => sheetText(kase.message).evaluate().isEmpty ? null : kase.message,
    };

/// The bills of the review fixtures, which are also the bills of the overview
/// and the lists: b1 unpaid, b2 awaiting, v2 awaiting, b4 paid in cash.
ReviewRepositories _listed() => reviewRepositories();

void main() {
  setUpAll(initializeIndonesianDates);

  group('sending the change', () {
    testWidgets('to Ditolak sends the reason and no method or date', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');

      await submitChange(tester, status: 'Ditolak');

      expect(repos.management.statusChangeRequests, [
        (
          id: 'u1',
          status: PaymentStatus.rejected,
          reason: changeReason,
          method: null,
          receivedOn: null,
        ),
      ]);
      expect(repos.management.changeCalls, 1);
    });

    testWidgets('to Belum Bayar sends the reason and no method or date', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 't1');

      await submitChange(tester, status: 'Belum Bayar');

      expect(repos.management.statusChangeRequests, [
        (
          id: 't1',
          status: PaymentStatus.unpaid,
          reason: changeReason,
          method: null,
          receivedOn: null,
        ),
      ]);
    });

    testWidgets('to Lunas by Transfer sends the method and today', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'w1');

      await submitChange(tester, status: 'Lunas', method: 'Transfer');

      final request = repos.management.statusChangeRequests.single;
      expect(request.id, 'w1');
      expect(request.status, PaymentStatus.paid);
      expect(request.reason, changeReason);
      expect(request.method, PaymentMethod.transfer);
      expect(sameDay(request.receivedOn, today()), isTrue);
    });

    testWidgets('to Lunas by Tunai sends the day picked', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await chooseMethod(tester, 'Tunai');
      final picked = await pickDateInPreviousMonthOfField(tester);
      await typeInto(tester, changeReasonLabel, changeReason);

      await saveChange(tester);

      final request = repos.management.statusChangeRequests.single;
      expect(request.status, PaymentStatus.paid);
      expect(request.method, PaymentMethod.cash);
      expect(sameDay(request.receivedOn, picked), isTrue);
    });

    testWidgets('sends the reason without the blanks around it', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');

      await submitChange(
        tester,
        status: 'Ditolak',
        reason: '  \n Dobel catat.\nCek mutasi.  \n',
      );

      expect(
        repos.management.statusChangeRequests.single.reason,
        'Dobel catat.\nCek mutasi.',
      );
    });

    testWidgets('drops the method and the date when Lunas is left again', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await chooseMethod(tester, 'Tunai');
      await pickDateInPreviousMonthOfField(tester);

      await submitChange(tester, status: 'Ditolak');

      final request = repos.management.statusChangeRequests.single;
      expect(request.status, PaymentStatus.rejected);
      expect(request.method, isNull);
      expect(request.receivedOn, isNull);
    });

    testWidgets('is sent by a Manager too', (tester) async {
      final repos = await openChangeSheet(tester, 'u1', role: UserRole.manager);

      await submitChange(tester, status: 'Ditolak');

      expect(repos.management.changeCalls, 1);
      expect(changeSheet(), findsNothing);
      expect(statusBadge('Ditolak'), findsWidgets);
    });

    testWidgets('a second tap while it is sent sends one request', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repos = changeRepositories();
      repos.management.changeScript.gate = gate;
      await openChangeSheet(tester, 'u1', repos: repos);
      await chooseStatus(tester, 'Ditolak');
      await typeInto(tester, changeReasonLabel, changeReason);

      await tester.tap(actionButton(saveChangeLabel));
      await tester.pump();
      expectBusy(tester);
      final again = actionButton(saveChangeLabel);
      if (again.evaluate().isNotEmpty) {
        await tester.tap(again, warnIfMissed: false);
        await tester.pump();
      }
      expect(repos.management.changeCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repos.management.changeCalls, 1);
      expect(changeSheet(), findsNothing);
      expect(statusBadge('Ditolak'), findsWidgets);
    });

    testWidgets('keeps the sheet open while it is sent', (tester) async {
      final gate = Completer<void>();
      final repos = changeRepositories();
      repos.management.changeScript.gate = gate;
      await openChangeSheet(tester, 'u1', repos: repos);
      await chooseStatus(tester, 'Ditolak');
      await typeInto(tester, changeReasonLabel, changeReason);

      await tester.tap(actionButton(saveChangeLabel));
      await tester.pump();

      expect(changeSheet(), findsOneWidget);
      expect(typedReason(tester), changeReason);

      gate.complete();
      await tester.pumpAndSettle();
    });
  });

  group('the bill after the change', () {
    testWidgets('to Lunas by Transfer shows method, day and history', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      await submitChange(tester, status: 'Lunas', method: 'Transfer');

      expect(changeSheet(), findsNothing);
      expect(currentUri(tester).path, billPath('u1'));
      expect(statusBadge('Lunas'), findsWidgets);
      expect(statusBadge('Belum Bayar'), findsNothing);
      expect(find.text('Metode pembayaran'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Tanggal dibayar'), findsOneWidget);
      expect(find.textContaining(dateText(today())), findsWidgets);
      expect(find.text('Riwayat Status'), findsOneWidget);
      expect(find.text(changeReason), findsOneWidget);
      expect(find.textContaining('Siti Pemilik'), findsWidgets);
    });

    testWidgets('to Lunas by Tunai shows the method Tunai', (tester) async {
      await openChangeSheet(tester, 'j1');

      await submitChange(tester, status: 'Lunas', method: 'Tunai');

      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('Transfer'), findsNothing);
      expect(statusBadge('Lunas'), findsWidgets);
    });

    testWidgets('to Lunas shows the day that was picked', (tester) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await chooseMethod(tester, 'Tunai');
      final picked = await pickDateInPreviousMonthOfField(tester);
      await typeInto(tester, changeReasonLabel, changeReason);

      await saveChange(tester);

      expect(find.text('Tanggal dibayar'), findsOneWidget);
      expect(find.textContaining(dateText(picked)), findsWidgets);
    });

    testWidgets('to Lunas takes the review actions away', (tester) async {
      await openChangeSheet(tester, 'w1');

      await submitChange(tester, status: 'Lunas', method: 'Transfer');

      expectNoReviewActions();
      expect(statusBadge('Menunggu Verifikasi'), findsNothing);
      expect(actionButton(changeLabel), findsOneWidget);
    });

    testWidgets('to Lunas takes the cash payment away', (tester) async {
      await openChangeSheet(tester, 'u1');

      await submitChange(tester, status: 'Lunas', method: 'Tunai');

      expect(actionButton(cashLabel), findsNothing);
      expect(actionButton(changeLabel), findsOneWidget);
    });

    testWidgets('to Ditolak shows the reason as the rejection reason', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      await submitChange(tester, status: 'Ditolak');

      expect(changeSheet(), findsNothing);
      expect(statusBadge('Ditolak'), findsWidgets);
      expect(statusBadge('Belum Bayar'), findsNothing);
      expect(find.text('Alasan penolakan'), findsOneWidget);
      expect(find.text(changeReason), findsWidgets);
      expect(find.text('Riwayat Status'), findsOneWidget);
      expect(find.text('Metode pembayaran'), findsNothing);
      expect(find.text('Tanggal dibayar'), findsNothing);
    });

    testWidgets('to Ditolak still offers the cash payment', (tester) async {
      await openChangeSheet(tester, 'u1');

      await submitChange(tester, status: 'Ditolak');

      expect(actionButton(cashLabel), findsOneWidget);
      expect(actionButton(changeLabel), findsOneWidget);
    });

    testWidgets('from Lunas to Belum Bayar drops the payment details', (
      tester,
    ) async {
      await openChangeSheet(tester, 't1');

      await submitChange(tester, status: 'Belum Bayar');

      expect(statusBadge('Belum Bayar'), findsWidgets);
      expect(statusBadge('Lunas'), findsNothing);
      expect(find.text('Metode pembayaran'), findsNothing);
      expect(find.text('Tanggal dibayar'), findsNothing);
      expect(find.text('Transfer'), findsNothing);
      expect(find.text('Alasan penolakan'), findsNothing);
      expect(find.text(changeReason), findsOneWidget);
      expect(actionButton(cashLabel), findsOneWidget);
    });

    testWidgets('from Lunas in cash to Ditolak drops the payment details', (
      tester,
    ) async {
      await openChangeSheet(tester, 'c1');

      await submitChange(tester, status: 'Ditolak');

      expect(statusBadge('Ditolak'), findsWidgets);
      expect(find.text('Metode pembayaran'), findsNothing);
      expect(find.text('Tanggal dibayar'), findsNothing);
      expect(find.text('Tunai'), findsNothing);
    });

    testWidgets('from Ditolak to Belum Bayar drops the rejection reason', (
      tester,
    ) async {
      await openChangeSheet(tester, 'j1');
      expect(find.text('Foto buram.'), findsOneWidget);

      await submitChange(tester, status: 'Belum Bayar');

      expect(statusBadge('Belum Bayar'), findsWidgets);
      expect(statusBadge('Ditolak'), findsNothing);
      expect(find.text('Alasan penolakan'), findsNothing);
      expect(find.text('Foto buram.'), findsNothing);
    });

    testWidgets('offers the other statuses next, from the new one', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await submitChange(tester, status: 'Lunas', method: 'Transfer');

      await press(tester, actionButton(changeLabel));

      expect(statusChoice('Belum Bayar'), findsOneWidget);
      expect(statusChoice('Ditolak'), findsOneWidget);
      expect(statusChoice('Lunas'), findsNothing);
      expect(typedReason(tester), isEmpty);
    });

    testWidgets('loads the bill again', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      final loadsBefore = repos.rentBills.getCalls;

      await submitChange(tester, status: 'Ditolak');

      expect(repos.rentBills.getCalls, greaterThan(loadsBefore));
    });

    testWidgets('names the person that the API reports in the history', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');
      repos.management.reviewerName = 'Rina Pengelola';

      await submitChange(tester, status: 'Ditolak');

      expect(find.textContaining('Rina Pengelola'), findsWidgets);
    });
  });

  group('lists and overview after the change', () {
    Future<void> openFromVerificationList(
      WidgetTester tester,
      String tenant,
    ) async {
      await tester.tap(verificationEntry());
      await tester.pumpAndSettle();
      await tester.tap(find.text(tenant));
      await tester.pumpAndSettle();
    }

    testWidgets('the verification list drops a bill that was changed', (
      tester,
    ) async {
      final repos = _listed();
      await pumpReview(tester, repos);
      await openFromVerificationList(tester, 'Dewi Lestari');
      final loadsBefore = repos.management.verificationListCalls;

      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Belum Bayar');
      await pressBack(tester);

      expect(currentUri(tester).path, '/pembayaran/verifikasi');
      expect(repos.management.verificationListCalls, greaterThan(loadsBefore));
      expect(find.text('Dewi Lestari'), findsNothing);
      expect(find.text('Agus Salim'), findsOneWidget);
    });

    testWidgets('the verification list of another property is unchanged', (
      tester,
    ) async {
      final repos = _listed();
      await pumpReview(tester, repos, path: billPath('b2'));
      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Belum Bayar');

      goTo(tester, verificationPath('p2'));
      await tester.pumpAndSettle();

      expect(find.text('Maya'), findsOneWidget);
    });

    testWidgets('the overview shows the new status of the bill', (
      tester,
    ) async {
      final repos = _listed();
      await pumpReview(tester, repos);
      final loadsBefore = repos.management.overviewCalls;
      await openFromVerificationList(tester, 'Dewi Lestari');

      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Belum Bayar');
      await pressBack(tester);
      await pressBack(tester);

      expect(currentUri(tester).path, overviewPath);
      expect(repos.management.overviewCalls, greaterThan(loadsBefore));
      expect(inRow('Dewi Lestari', find.text('Belum Bayar')), findsOneWidget);
      expect(
        inRow('Dewi Lestari', find.text('Menunggu Verifikasi')),
        findsNothing,
      );
    });

    testWidgets('the history of the tenant shows the new status', (
      tester,
    ) async {
      final repos = _listed();
      await pumpReview(tester, repos, path: historyPath('t4', 'p1'));
      expect(statusBadge('Lunas'), findsOneWidget);
      final loadsBefore = repos.management.tenantListCalls('t4');

      await tester.tap(find.text('Rp840.000'));
      await tester.pumpAndSettle();
      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Belum Bayar');
      await pressBack(tester);

      expect(currentUri(tester).path, '/pembayaran/penyewa/t4');
      expect(repos.management.tenantListCalls('t4'), greaterThan(loadsBefore));
      expect(statusBadge('Belum Bayar'), findsOneWidget);
      expect(statusBadge('Lunas'), findsNothing);
    });

    testWidgets('the history of the tenant shows a rejected bill', (
      tester,
    ) async {
      final repos = _listed();
      await pumpReview(tester, repos, path: historyPath('t1', 'p1'));

      await tester.tap(find.text('Rp800.000'));
      await tester.pumpAndSettle();
      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Ditolak');
      await pressBack(tester);

      expect(statusBadge('Ditolak'), findsOneWidget);
      expect(statusBadge('Belum Bayar'), findsNothing);
    });

    testWidgets('the cash payment lists a bill that became payable', (
      tester,
    ) async {
      final repos = _listed();
      await pumpReview(tester, repos, path: billPath('b4'));
      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Belum Bayar');

      goTo(tester, cashPath('p1'));
      await tester.pumpAndSettle();

      expect(find.text('Sari Wulandari'), findsOneWidget);
    });

    testWidgets('the cash payment drops a bill that was paid', (tester) async {
      final repos = _listed();
      await pumpReview(tester, repos, path: billPath('b1'));
      await press(tester, actionButton(changeLabel));
      await submitChange(tester, status: 'Lunas', method: 'Tunai');

      goTo(tester, cashPath('p1'));
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.textContaining(noPayableMessage), findsOneWidget);
    });
  });

  group('failures', () {
    for (final entry in _failures.entries) {
      testWidgets('shows ${entry.key} in the sheet and keeps the input', (
        tester,
      ) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(entry.value.$1);
        await openChangeSheet(tester, 'u1', repos: repos);
        await chooseStatus(tester, 'Lunas');
        await chooseMethod(tester, 'Tunai');
        final picked = await pickDateInPreviousMonthOfField(tester);
        await typeInto(tester, changeReasonLabel, changeReason);

        await saveChange(tester);

        expect(find.text(entry.value.$2), findsOneWidget);
        expect(sheetText(entry.value.$2), findsOneWidget);
        expect(changeSheet(), findsOneWidget);
        expect(typedReason(tester), changeReason);
        expectChoiceSemantics(tester, statusChoice('Lunas'), selected: true);
        expectChoiceSemantics(tester, methodChoice('Tunai'), selected: true);
        expect(shownDate(tester), dateText(picked));
        expect(repos.management.changeCalls, 1);
        expect(currentUri(tester).path, billPath('u1'));
        expect(statusBadge('Belum Bayar'), findsOneWidget);
      });

      testWidgets('keeps the message of ${entry.key} until the next try', (
        tester,
      ) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(entry.value.$1);
        await openChangeSheet(tester, 'u1', repos: repos);

        await submitChange(tester, status: 'Ditolak');
        await tester.pump(const Duration(seconds: 30));

        expect(find.text(entry.value.$2), findsOneWidget);
      });

      testWidgets('succeeds on a retry after ${entry.key}', (tester) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(entry.value.$1);
        await openChangeSheet(tester, 'u1', repos: repos);
        await submitChange(tester, status: 'Ditolak');

        await saveChange(tester);

        expect(repos.management.changeCalls, 2);
        expect(repos.management.statusChangeRequests.last.reason, changeReason);
        expect(changeSheet(), findsNothing);
        expect(find.text(entry.value.$2), findsNothing);
        expect(statusBadge('Ditolak'), findsWidgets);
      });
    }

    testWidgets('a failure leaves the bill as it was', (tester) async {
      final repos = changeRepositories();
      repos.management.changeScript.queue.add(const ApiFailure.network());
      await openChangeSheet(tester, 'u1', repos: repos);

      await submitChange(tester, status: 'Ditolak');
      await tester.tap(actionButton(cancelLabel));
      await tester.pumpAndSettle();

      expect(statusBadge('Belum Bayar'), findsOneWidget);
      expect(statusBadge('Ditolak'), findsNothing);
      expect(find.text('Riwayat Status'), findsNothing);
    });

    testWidgets('a bill deleted meanwhile shows its message in the sheet', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');
      repos.management.bills.removeWhere((bill) => bill.id == 'u1');

      await submitChange(tester, status: 'Ditolak');

      expect(sheetText('Tagihan tidak ditemukan.'), findsOneWidget);
      expect(changeSheet(), findsOneWidget);
    });
  });

  group('failures on a field', () {
    for (final entry in _fieldCases.entries) {
      final kase = entry.value;

      testWidgets('shows ${entry.key} next to its field', (tester) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(kase.failure);
        await openChangeSheet(tester, 'u1', repos: repos);

        await submitChange(tester, status: kase.status, method: kase.method);

        expect(_shownError(tester, kase), kase.message);
        expect(find.text(kase.message), findsOneWidget);
        expect(changeSheet(), findsOneWidget);
        expect(typedReason(tester), changeReason);
        expect(repos.management.changeCalls, 1);
      });

      testWidgets('keeps the input after ${entry.key}', (tester) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(kase.failure);
        await openChangeSheet(tester, 'u1', repos: repos);

        await submitChange(tester, status: kase.status, method: kase.method);

        expectChoiceSemantics(
          tester,
          statusChoice(kase.status),
          selected: true,
        );
        if (kase.method != null) {
          expectChoiceSemantics(
            tester,
            methodChoice(kase.method!),
            selected: true,
          );
          expect(shownDate(tester), dateText(today()));
        }
      });

      testWidgets('sends again after ${entry.key}', (tester) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(kase.failure);
        await openChangeSheet(tester, 'u1', repos: repos);
        await submitChange(tester, status: kase.status, method: kase.method);

        await saveChange(tester);

        expect(repos.management.changeCalls, 2);
        expect(changeSheet(), findsNothing);
        expect(find.text(kase.message), findsNothing);
      });
    }

    testWidgets('exposes a failure on the reason on the field', (tester) async {
      final repos = changeRepositories();
      repos.management.changeScript.queue.add(
        _fieldCases['a missing reason']!.failure,
      );
      await openChangeSheet(tester, 'u1', repos: repos);

      await submitChange(tester, status: 'Ditolak');

      expectFieldNode(
        tester,
        changeReasonLabel,
        error: changeReasonRequiredMessage,
      );
    });

    testWidgets('exposes a failure on the date on the field', (tester) async {
      final repos = changeRepositories();
      repos.management.changeScript.queue.add(
        _fieldCases['a date in the future']!.failure,
      );
      await openChangeSheet(tester, 'u1', repos: repos);

      await submitChange(tester, status: 'Lunas', method: 'Tunai');

      expectFieldNode(tester, dateLabel, error: futureDateMessage);
    });

    testWidgets('a bill paid meanwhile reports the unchanged status', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');
      final index = repos.management.bills.indexWhere((b) => b.id == 'u1');
      repos.management.bills[index] = makeRentBill(
        id: 'u1',
        status: PaymentStatus.paid,
        method: PaymentMethod.cash,
        paidOn: DateTime.utc(2026, 11, 3),
      );

      await submitChange(tester, status: 'Lunas', method: 'Transfer');

      expect(sheetText(statusUnchangedMessage), findsOneWidget);
      expect(changeSheet(), findsOneWidget);
      expect(typedReason(tester), changeReason);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the action on an unpaid bill': (tester, large) async {
        await openBill(tester, 'u1', largeText: large);
      },
      'the actions on a bill awaiting verification': (tester, large) async {
        await openBill(tester, 'w1', largeText: large);
      },
      'the action on a paid bill': (tester, large) async {
        await openBill(tester, 't1', largeText: large);
      },
      'the action on a rejected bill': (tester, large) async {
        await openBill(tester, 'j1', largeText: large);
      },
      'the sheet is open': (tester, large) async {
        await openChangeSheet(tester, 'u1', largeText: large);
      },
      'the sheet offers all statuses': (tester, large) async {
        await openChangeSheet(tester, 'w1', largeText: large);
      },
      'a status is chosen': (tester, large) async {
        await openChangeSheet(tester, 'u1', largeText: large);
        await chooseStatus(tester, 'Ditolak');
      },
      'Lunas is chosen': (tester, large) async {
        await openChangeSheet(tester, 'u1', largeText: large);
        await chooseStatus(tester, 'Lunas');
        await chooseMethod(tester, 'Transfer');
      },
      'the sheet refuses empty input': (tester, large) async {
        await openChangeSheet(tester, 'u1', largeText: large);
        await saveChange(tester);
      },
      'the sheet refuses Lunas without a method': (tester, large) async {
        await openChangeSheet(tester, 'u1', largeText: large);
        await chooseStatus(tester, 'Lunas');
        await typeInto(tester, changeReasonLabel, changeReason);
        await saveChange(tester);
      },
      'the server refuses a field': (tester, large) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(
          _fieldCases['a date in the future']!.failure,
        );
        await openChangeSheet(tester, 'u1', repos: repos, largeText: large);
        await submitChange(tester, status: 'Lunas', method: 'Tunai');
      },
      'the server refuses the reason': (tester, large) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(
          _fieldCases['a missing reason']!.failure,
        );
        await openChangeSheet(tester, 'u1', repos: repos, largeText: large);
        await submitChange(tester, status: 'Ditolak');
      },
      'sending fails': (tester, large) async {
        final repos = changeRepositories();
        repos.management.changeScript.queue.add(const ApiFailure.network());
        await openChangeSheet(tester, 'u1', repos: repos, largeText: large);
        await submitChange(tester, status: 'Ditolak');
      },
      'the bill was changed': (tester, large) async {
        await openChangeSheet(tester, 'u1', largeText: large);
        await submitChange(tester, status: 'Lunas', method: 'Transfer');
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

    testWidgets('can be completed at large text size', (tester) async {
      final repos = await openChangeSheet(tester, 'w1', largeText: true);

      await submitChange(tester, status: 'Lunas', method: 'Tunai');

      expect(tester.takeException(), isNull);
      expect(repos.management.changeCalls, 1);
      expect(changeSheet(), findsNothing);
      expect(statusBadge('Lunas'), findsWidgets);
    });

    testWidgets('shows its errors at large text size', (tester) async {
      final repos = await openChangeSheet(tester, 'u1', largeText: true);

      await saveChange(tester);

      expect(tester.takeException(), isNull);
      expect(repos.management.changeCalls, 0);
      expect(sheetText(statusRequiredMessage), findsOneWidget);
      expect(
        labeledFieldError(tester, changeReasonLabel),
        changeReasonRequiredMessage,
      );
    });
  });
}
