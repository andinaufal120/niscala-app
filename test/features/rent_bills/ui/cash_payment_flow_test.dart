import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'cash_payment_ui_helpers.dart';

Uri _uri(WidgetTester tester) => currentUri(tester);

/// The flow with Rina Putri chosen: she has the single payable bill b3, so the
/// form is shown at once.
Future<ReviewRepositories> _formOfRina(
  WidgetTester tester, {
  ReviewRepositories? repos,
  bool largeText = false,
}) async {
  final shown = await openCashFlow(tester, repos: repos, largeText: largeText);
  await press(tester, find.text('Rina Putri'));
  return shown;
}

/// The flow with Budi Santoso chosen: he has two payable bills.
Future<ReviewRepositories> _billsOfBudi(
  WidgetTester tester, {
  ReviewRepositories? repos,
  bool largeText = false,
}) async {
  final shown = await openCashFlow(tester, repos: repos, largeText: largeText);
  await press(tester, find.text('Budi Santoso'));
  return shown;
}

/// Opens the flow while its list of bills is held in flight.
Future<ReviewRepositories> _openWhileLoading(WidgetTester tester) async {
  final repos = cashRepositories();
  await pumpReview(tester, repos);
  repos.management.listScript.gate = Completer<void>();
  await tester.ensureVisible(actionButton(cashLabel));
  await tester.tap(actionButton(cashLabel));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return repos;
}

/// Expects the confirmation checkbox to be one labelled node with the given
/// state and a target of at least 48 dp.
void _expectCheckbox(WidgetTester tester, {required bool checked}) {
  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(find.text(confirmLabel));
    expect(node, isSemantics(hasCheckedState: true, isChecked: checked));
    expect(node.label, contains(confirmLabel));
    expect(node.rect.height, greaterThanOrEqualTo(48));
    expect(node.rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

/// Expects the row of a bill to expose whether it is the chosen one.
void _expectBillChosen(
  WidgetTester tester,
  String amount, {
  required bool chosen,
}) {
  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(find.text(amount));
    expect(
      node,
      anyOf(
        isSemantics(hasSelectedState: true, isSelected: chosen),
        isSemantics(hasCheckedState: true, isChecked: chosen),
      ),
    );
  } finally {
    handle.dispose();
  }
}

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
  'an unknown error': (
    ApiFailure(code: 'SOMETHING_NEW', statusCode: 400),
    'Terjadi kesalahan. Coba lagi.',
  ),
  'a rejection of another field': (
    ApiFailure(code: 'VALIDATION_FAILED', field: 'other', statusCode: 422),
    'Data tidak valid.',
  ),
  'a rejection without a field': (
    ApiFailure(code: 'VALIDATION_FAILED', statusCode: 422),
    'Data tidak valid.',
  ),
};

const _dateFailures = <String, (ApiFailure, String)>{
  'a date in the future': (
    ApiFailure(
      code: 'RECEIVED_ON_IN_FUTURE',
      field: 'receivedOn',
      statusCode: 422,
    ),
    futureDateMessage,
  ),
  'a date that is not valid': (
    ApiFailure(code: 'VALIDATION_FAILED', field: 'receivedOn', statusCode: 422),
    invalidDateMessage,
  ),
};

void main() {
  setUpAll(initializeIndonesianDates);

  group('tenants', () {
    testWidgets('lists the tenants with a payable bill, once each', (
      tester,
    ) async {
      await openCashFlow(tester);

      expect(find.text('Rina Putri'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Wati'), findsOneWidget);
    });

    testWidgets('leaves out tenants whose bills cannot be paid', (
      tester,
    ) async {
      await openCashFlow(tester);

      expect(find.text('Dewi Lestari'), findsNothing);
      expect(find.text('Sari Wulandari'), findsNothing);
    });

    testWidgets('leaves out the tenants of other properties', (tester) async {
      await openCashFlow(tester);

      expect(find.text('Lina'), findsNothing);
    });

    testWidgets('shows the room of each tenant', (tester) async {
      await openCashFlow(tester);

      expect(inRow('Rina Putri', find.text('Kamar 15')), findsOneWidget);
      expect(inRow('Budi Santoso', find.text('Kamar 08')), findsOneWidget);
      expect(inRow('Wati', find.text('Kamar 11')), findsOneWidget);
    });

    testWidgets('keeps the order in which the API returns the bills', (
      tester,
    ) async {
      await openCashFlow(tester);

      final rina = tester.getTopLeft(find.text('Rina Putri')).dy;
      final budi = tester.getTopLeft(find.text('Budi Santoso')).dy;
      final wati = tester.getTopLeft(find.text('Wati')).dy;
      expect(rina, lessThan(budi));
      expect(budi, lessThan(wati));
    });

    testWidgets('asks only for the unpaid and rejected bills of the property', (
      tester,
    ) async {
      final repos = await openCashFlow(tester);

      expect(repos.management.payableListCalls, 1);
      final call = repos.management.listed.last;
      expect(call.propertyId, 'p1');
      expect(call.tenantId, isNull);
      expect(call.statuses!.toSet(), {
        PaymentStatus.unpaid,
        PaymentStatus.rejected,
      });
    });

    testWidgets('asks for the bills of the property of the chosen entry', (
      tester,
    ) async {
      final repos = cashRepositories();
      await pumpReview(tester, repos);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      await press(tester, actionButton(cashLabel));

      expect(repos.management.listed.last.propertyId, 'p2');
    });

    testWidgets('reads a row as one item with the name and the room', (
      tester,
    ) async {
      await openCashFlow(tester);

      final label = semanticsLabelOf(tester, 'Rina Putri');

      expect(label, contains('Rina Putri'));
      expect(label, contains('Kamar 15'));
    });

    testWidgets('gives each row a target of at least 48 dp', (tester) async {
      await openCashFlow(tester);

      expectTargetSize(tester, 'Rina Putri');
      expectTargetSize(tester, 'Budi Santoso');
    });

    testWidgets('shows no form before a tenant is chosen', (tester) async {
      await openCashFlow(tester);

      expect(dateField(), findsNothing);
      expect(find.text(confirmLabel), findsNothing);
      expect(saveButton(), findsNothing);
    });

    testWidgets('shows a progress indicator while the bills load', (
      tester,
    ) async {
      await _openWhileLoading(tester);

      expectLoading(tester);
      expect(find.text('Rina Putri'), findsNothing);
      expect(saveButton(), findsNothing);
    });

    testWidgets('explains that no bill awaits payment', (tester) async {
      final repos = cashRepositories(
        bills: [
          makeRentBill(id: 'b2', status: PaymentStatus.awaitingVerification),
          makeRentBill(
            id: 'b4',
            status: PaymentStatus.paid,
            method: PaymentMethod.cash,
            paidOn: DateTime.utc(2026, 11, 3),
          ),
        ],
      );

      await openCashFlow(tester, repos: repos);

      expect(find.textContaining(noPayableMessage), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(saveButton(), findsNothing);
    });

    testWidgets('explains that a property without bills has none to pay', (
      tester,
    ) async {
      await openCashFlow(tester, repos: cashRepositories(bills: []));

      expect(find.textContaining(noPayableMessage), findsOneWidget);
    });

    testWidgets('shows a failure with a way to retry', (tester) async {
      final repos = cashRepositories();
      repos.management.listScript.queue.add(const ApiFailure.network());

      await openCashFlow(tester, repos: repos);

      expect(
        find.text(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        ),
        findsOneWidget,
      );
      expect(find.text(retryLabel), findsOneWidget);
      expect(find.text('Rina Putri'), findsNothing);
    });

    testWidgets('loads the bills again on retry', (tester) async {
      final repos = cashRepositories();
      repos.management.listScript.queue.add(const ApiFailure.network());
      await openCashFlow(tester, repos: repos);

      await tester.tap(find.text(retryLabel));
      await tester.pumpAndSettle();

      expect(repos.management.payableListCalls, 2);
      expect(find.text('Rina Putri'), findsOneWidget);
      expect(find.text(retryLabel), findsNothing);
    });
  });

  group('bills of a tenant', () {
    testWidgets('are listed with the period, amount, due date and status', (
      tester,
    ) async {
      await _billsOfBudi(tester);

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.textContaining('1 Nov 2026 - 30 Nov 2026'), findsOneWidget);
      expect(find.textContaining('Jatuh tempo 5 Nov 2026'), findsOneWidget);
      expect(statusBadge('Belum Bayar'), findsOneWidget);
      expect(find.text('Rp790.000'), findsOneWidget);
      expect(find.textContaining('1 Okt 2026 - 31 Okt 2026'), findsOneWidget);
      expect(find.textContaining('Jatuh tempo 5 Okt 2026'), findsOneWidget);
      expect(statusBadge('Ditolak'), findsOneWidget);
    });

    testWidgets('leave out the bills of other tenants', (tester) async {
      await _billsOfBudi(tester);

      expect(find.text('Rp830.000'), findsNothing);
      expect(find.text('Rp850.000'), findsNothing);
    });

    testWidgets('keep the form hidden until one is chosen', (tester) async {
      await _billsOfBudi(tester);

      expect(dateField(), findsNothing);
      expect(find.text(confirmLabel), findsNothing);
      expect(saveButton(), findsNothing);
    });

    testWidgets('show the form once one is chosen', (tester) async {
      await _billsOfBudi(tester);

      await press(tester, find.text('Rp800.000'));

      expect(dateField(), findsOneWidget);
      expect(find.text(confirmLabel), findsOneWidget);
      expect(saveButton(), findsOneWidget);
    });

    testWidgets('show which one is chosen', (tester) async {
      await _billsOfBudi(tester);
      await press(tester, find.text('Rp800.000'));

      _expectBillChosen(tester, 'Rp800.000', chosen: true);
      _expectBillChosen(tester, 'Rp790.000', chosen: false);
    });

    testWidgets('can be changed before saving', (tester) async {
      final repos = await _billsOfBudi(tester);
      await press(tester, find.text('Rp800.000'));
      await press(tester, find.text('Rp790.000'));

      _expectBillChosen(tester, 'Rp790.000', chosen: true);
      _expectBillChosen(tester, 'Rp800.000', chosen: false);
      await confirmReceived(tester);
      await saveCash(tester);

      expect(repos.management.cashPayments.map((c) => c.id), ['b0']);
    });

    testWidgets('give each row a target of at least 48 dp', (tester) async {
      await _billsOfBudi(tester);

      expectTargetSize(tester, 'Rp800.000');
      expectTargetSize(tester, 'Rp790.000');
    });

    testWidgets('are not asked for again when a tenant is chosen', (
      tester,
    ) async {
      final repos = await _billsOfBudi(tester);

      expect(repos.management.payableListCalls, 1);
    });

    testWidgets('of a tenant with one bill show that bill and the form', (
      tester,
    ) async {
      await _formOfRina(tester);

      expect(find.text('Rp830.000'), findsOneWidget);
      expect(find.textContaining('Jatuh tempo 5 Nov 2026'), findsOneWidget);
      expect(statusBadge('Ditolak'), findsOneWidget);
      expect(dateField(), findsOneWidget);
      expect(saveButton(), findsOneWidget);
    });
  });

  group('form', () {
    testWidgets('labels the date field and starts at today', (tester) async {
      await _formOfRina(tester);

      expect(labeledField(dateLabel), findsOneWidget);
      expect(shownDate(tester), dateText(today()));
      expect(labeledTextField(tester, dateLabel).readOnly, isTrue);
      expectNoDecorationLabels(tester);
      expectFieldNode(tester, dateLabel);
    });

    testWidgets('gives the date field a target of at least 48 dp', (
      tester,
    ) async {
      await _formOfRina(tester);

      final handle = tester.ensureSemantics();
      try {
        final rect = tester.getSemantics(dateField()).rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('starts with the confirmation unticked', (tester) async {
      await _formOfRina(tester);

      expect(isConfirmed(tester), isFalse);
      _expectCheckbox(tester, checked: false);
    });

    testWidgets('ticks and unticks the confirmation', (tester) async {
      await _formOfRina(tester);

      await confirmReceived(tester);
      expect(isConfirmed(tester), isTrue);
      _expectCheckbox(tester, checked: true);

      await confirmReceived(tester);
      expect(isConfirmed(tester), isFalse);
    });

    testWidgets('sends nothing while the form is filled in', (tester) async {
      final repos = await _formOfRina(tester);
      await confirmReceived(tester);
      await pickDateInPreviousMonthOfField(tester);

      expect(repos.management.cashCalls, 0);
    });

    testWidgets('opens a picker at today that stops at today', (tester) async {
      await _formOfRina(tester);

      await press(tester, dateField());

      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(sameDay(picker.initialDate, today()), isTrue);
      expect(sameDay(picker.lastDate, today()), isTrue);
    });

    testWidgets('keeps the date when the picker is cancelled', (tester) async {
      final repos = await _formOfRina(tester);
      await press(tester, dateField());

      await tester.tap(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextButton),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(shownDate(tester), dateText(today()));
      expect(repos.management.cashCalls, 0);
    });

    testWidgets('shows the date that was picked', (tester) async {
      await _formOfRina(tester);

      final picked = await pickDateInPreviousMonthOfField(tester);

      expect(shownDate(tester), dateText(picked));
    });

    testWidgets('refuses an unticked confirmation and sends nothing', (
      tester,
    ) async {
      final repos = await _formOfRina(tester);

      await saveCash(tester);

      expect(find.text(confirmRequiredMessage), findsOneWidget);
      expect(repos.management.cashCalls, 0);
      expect(saveButton(), findsOneWidget);
      expect(_uri(tester).path, '/pembayaran/tunai');
    });

    testWidgets('announces the refusal as a live message', (tester) async {
      await _formOfRina(tester);
      await saveCash(tester);

      expectLiveRegion(tester, confirmRequiredMessage);
    });

    testWidgets('keeps the choices after a refusal', (tester) async {
      await _formOfRina(tester);
      final picked = await pickDateInPreviousMonthOfField(tester);

      await saveCash(tester);

      expect(shownDate(tester), dateText(picked));
      expect(find.text('Rp830.000'), findsOneWidget);
    });

    testWidgets('sends the bill after a refusal once it is ticked', (
      tester,
    ) async {
      final repos = await _formOfRina(tester);
      await saveCash(tester);

      await confirmReceived(tester);
      await saveCash(tester);

      expect(repos.management.cashPayments.map((c) => c.id), ['b3']);
    });

    testWidgets('sends the chosen bill with today as the date received', (
      tester,
    ) async {
      final repos = await _formOfRina(tester);
      await confirmReceived(tester);

      await saveCash(tester);

      expect(repos.management.cashCalls, 1);
      expect(repos.management.cashPayments.single.id, 'b3');
      expect(
        sameDay(repos.management.cashPayments.single.receivedOn, today()),
        isTrue,
      );
    });

    testWidgets('sends the date that was picked', (tester) async {
      final repos = await _formOfRina(tester);
      final picked = await pickDateInPreviousMonthOfField(tester);
      await confirmReceived(tester);

      await saveCash(tester);

      expect(
        sameDay(repos.management.cashPayments.single.receivedOn, picked),
        isTrue,
      );
    });

    testWidgets('sends one request for the bill chosen among several', (
      tester,
    ) async {
      final repos = await openCashFlow(tester);

      await recordCash(tester, 'Budi Santoso', 'Rp800.000');

      expect(repos.management.cashPayments.map((c) => c.id), ['b1']);
    });

    testWidgets('a second tap while it is sent sends one request', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repos = cashRepositories();
      repos.management.cashScript.gate = gate;
      await _formOfRina(tester, repos: repos);
      await confirmReceived(tester);

      await tester.ensureVisible(saveButton());
      await tester.tap(saveButton());
      await tester.pump();
      expectBusy(tester);
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      final again = saveButton();
      if (again.evaluate().isNotEmpty) {
        await tester.tap(again, warnIfMissed: false);
        await tester.pump();
      }
      expect(repos.management.cashCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repos.management.cashCalls, 1);
    });

    for (final entry in _failures.entries) {
      testWidgets('shows ${entry.key} and keeps the form to retry', (
        tester,
      ) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        final picked = await pickDateInPreviousMonthOfField(tester);
        await confirmReceived(tester);

        await saveCash(tester);

        expect(find.text(entry.value.$2), findsOneWidget);
        expect(_uri(tester).path, '/pembayaran/tunai');
        expect(shownDate(tester), dateText(picked));
        expect(isConfirmed(tester), isTrue);
        expect(saveButton(), findsOneWidget);
        expect(repos.management.cashCalls, 1);
      });

      testWidgets('keeps the message of ${entry.key} until the next try', (
        tester,
      ) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        await confirmReceived(tester);
        await saveCash(tester);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(entry.value.$2), findsOneWidget);
      });

      testWidgets('succeeds on a retry after ${entry.key}', (tester) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        final picked = await pickDateInPreviousMonthOfField(tester);
        await confirmReceived(tester);
        await saveCash(tester);

        await saveCash(tester);

        expect(repos.management.cashCalls, 2);
        expect(
          sameDay(repos.management.cashPayments.last.receivedOn, picked),
          isTrue,
        );
        expect(_uri(tester).path, overviewPath);
        expect(find.text(entry.value.$2), findsNothing);
      });
    }

    for (final entry in _dateFailures.entries) {
      testWidgets('shows ${entry.key} next to the date field', (tester) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        await confirmReceived(tester);

        await saveCash(tester);

        expect(labeledFieldError(tester, dateLabel), entry.value.$2);
        expect(find.text(entry.value.$2), findsOneWidget);
        expect(_uri(tester).path, '/pembayaran/tunai');
        expect(isConfirmed(tester), isTrue);
        expect(saveButton(), findsOneWidget);
      });

      testWidgets('exposes ${entry.key} on the date field to a screen reader', (
        tester,
      ) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        await confirmReceived(tester);
        await saveCash(tester);

        expectFieldNode(tester, dateLabel, error: entry.value.$2);
      });

      testWidgets('keeps the date after ${entry.key}', (tester) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        final picked = await pickDateInPreviousMonthOfField(tester);
        await confirmReceived(tester);

        await saveCash(tester);

        expect(shownDate(tester), dateText(picked));
      });

      testWidgets('sends a corrected date after ${entry.key}', (tester) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(entry.value.$1);
        await _formOfRina(tester, repos: repos);
        await confirmReceived(tester);
        await saveCash(tester);

        final picked = await pickDateInPreviousMonthOfField(tester);
        await saveCash(tester);

        expect(repos.management.cashCalls, 2);
        expect(
          sameDay(repos.management.cashPayments.last.receivedOn, picked),
          isTrue,
        );
        expect(_uri(tester).path, overviewPath);
      });
    }

    testWidgets('a conflict shows its message and loads the bills again', (
      tester,
    ) async {
      final repos = cashRepositories();
      repos.management.cashScript.queue.add(
        const ApiFailure(code: 'RENT_BILL_NOT_PAYABLE', statusCode: 409),
      );
      await _formOfRina(tester, repos: repos);
      await confirmReceived(tester);
      final loadsBefore = repos.management.payableListCalls;

      await saveCash(tester);

      expect(find.text(notPayableMessage), findsOneWidget);
      expect(repos.management.payableListCalls, greaterThan(loadsBefore));
      expect(_uri(tester).path, '/pembayaran/tunai');
    });

    testWidgets('the message of a conflict stays on screen', (tester) async {
      final repos = cashRepositories();
      repos.management.cashScript.queue.add(
        const ApiFailure(code: 'RENT_BILL_NOT_PAYABLE', statusCode: 409),
      );
      await _formOfRina(tester, repos: repos);
      await confirmReceived(tester);
      await saveCash(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(notPayableMessage), findsOneWidget);
    });

    testWidgets('a bill paid elsewhere meanwhile is a conflict', (
      tester,
    ) async {
      final repos = await _formOfRina(tester);
      final index = repos.management.bills.indexWhere((b) => b.id == 'b3');
      repos.management.bills[index] = makeRentBill(
        id: 'b3',
        tenantId: 't3',
        tenantName: 'Rina Putri',
        roomNumber: '15',
        amount: 830000,
        status: PaymentStatus.paid,
        method: PaymentMethod.cash,
        paidOn: DateTime.utc(2026, 11, 3),
      );
      await confirmReceived(tester);
      final loadsBefore = repos.management.payableListCalls;

      await saveCash(tester);

      expect(find.text(notPayableMessage), findsOneWidget);
      expect(repos.management.payableListCalls, greaterThan(loadsBefore));
      expect(_uri(tester).path, '/pembayaran/tunai');
    });

    testWidgets('does not tell the tenant anything of its own', (tester) async {
      await _formOfRina(tester);

      expect(find.textContaining('otifikasi'), findsNothing);
      expect(find.textContaining('diberi tahu'), findsNothing);
    });
  });

  group('bill chosen beforehand', () {
    testWidgets('shows the bill and the form without choosing anything', (
      tester,
    ) async {
      await openCashFlowFromBill(tester, 'b1');

      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('Kamar 08'), findsWidgets);
      expect(find.text('Rp800.000'), findsWidgets);
      expect(find.textContaining('1 Nov 2026 - 30 Nov 2026'), findsWidgets);
      expect(find.textContaining('Jatuh tempo 5 Nov 2026'), findsWidgets);
      expect(statusBadge('Belum Bayar'), findsWidgets);
      expect(dateField(), findsOneWidget);
      expect(find.text(confirmLabel), findsOneWidget);
      expect(saveButton(), findsOneWidget);
      expect(shownDate(tester), dateText(today()));
    });

    testWidgets('shows a rejected bill with its status', (tester) async {
      await openCashFlowFromBill(tester, 'b3');

      expect(find.text('Rp830.000'), findsWidgets);
      expect(statusBadge('Ditolak'), findsWidgets);
      expect(saveButton(), findsOneWidget);
    });

    testWidgets('loads the payable bills of the property of the link', (
      tester,
    ) async {
      final repos = await openCashFlowFromBill(tester, 'c2');

      expect(repos.management.payableListCalls, 1);
      expect(repos.management.listed.last.propertyId, 'p2');
    });

    testWidgets('sends exactly that bill', (tester) async {
      final repos = await openCashFlowFromBill(tester, 'b1');
      await confirmReceived(tester);

      await saveCash(tester);

      expect(repos.management.cashPayments.map((c) => c.id), ['b1']);
      expect(
        sameDay(repos.management.cashPayments.single.receivedOn, today()),
        isTrue,
      );
    });

    testWidgets('refuses an unticked confirmation and sends nothing', (
      tester,
    ) async {
      final repos = await openCashFlowFromBill(tester, 'b1');

      await saveCash(tester);

      expect(find.text(confirmRequiredMessage), findsOneWidget);
      expect(repos.management.cashCalls, 0);
    });

    testWidgets('shows a failure to load with a way to retry', (tester) async {
      final repos = cashRepositories();
      repos.management.listScript.queue.add(const ApiFailure.network());
      await pumpReview(tester, repos, path: billPath('b1'));

      await press(tester, actionButton(cashLabel));

      expect(find.text(retryLabel), findsOneWidget);
      expect(saveButton(), findsNothing);

      await tester.tap(find.text(retryLabel));
      await tester.pumpAndSettle();

      expect(saveButton(), findsOneWidget);
      expect(dateField(), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'listing the tenants': (tester, large) async {
        await openCashFlow(tester, largeText: large);
      },
      'listing the bills of a tenant': (tester, large) async {
        await _billsOfBudi(tester, largeText: large);
      },
      'a bill is chosen': (tester, large) async {
        await _billsOfBudi(tester, largeText: large);
        await press(tester, find.text('Rp800.000'));
      },
      'showing the form': (tester, large) async {
        await _formOfRina(tester, largeText: large);
      },
      'the form is ticked': (tester, large) async {
        await _formOfRina(tester, largeText: large);
        await confirmReceived(tester);
      },
      'refusing an unticked confirmation': (tester, large) async {
        await _formOfRina(tester, largeText: large);
        await saveCash(tester);
      },
      'refusing a date on the server': (tester, large) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(
          const ApiFailure(
            code: 'RECEIVED_ON_IN_FUTURE',
            field: 'receivedOn',
            statusCode: 422,
          ),
        );
        await _formOfRina(tester, repos: repos, largeText: large);
        await confirmReceived(tester);
        await saveCash(tester);
      },
      'failing to save': (tester, large) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(const ApiFailure.network());
        await _formOfRina(tester, repos: repos, largeText: large);
        await confirmReceived(tester);
        await saveCash(tester);
      },
      'after a conflict': (tester, large) async {
        final repos = cashRepositories();
        repos.management.cashScript.queue.add(
          const ApiFailure(code: 'RENT_BILL_NOT_PAYABLE', statusCode: 409),
        );
        await _formOfRina(tester, repos: repos, largeText: large);
        await confirmReceived(tester);
        await saveCash(tester);
      },
      'a bill is chosen beforehand': (tester, large) async {
        await openCashFlowFromBill(tester, 'b1', largeText: large);
      },
      'no bill awaits payment': (tester, large) async {
        await openCashFlow(
          tester,
          repos: cashRepositories(bills: []),
          largeText: large,
        );
      },
      'failing to load the bills': (tester, large) async {
        final repos = cashRepositories();
        repos.management.listScript.always = const ApiFailure.network();
        await openCashFlow(tester, repos: repos, largeText: large);
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

    testWidgets('titles the page with a heading', (tester) async {
      await openCashFlow(tester);

      final handle = tester.ensureSemantics();
      try {
        expect(nodesAnnouncing(tester, cashLabel), isNotEmpty);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('meets the guidelines while the bills load', (tester) async {
      await _openWhileLoading(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the picker is open', (
      tester,
    ) async {
      await _formOfRina(tester);
      await press(tester, dateField());

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
