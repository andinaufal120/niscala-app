import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/semantics.dart';
import 'payment_status_change_ui_helpers.dart';

/// The bill of each status, by the label of its status.
const _billOf = {
  'Belum Bayar': 'u1',
  'Menunggu Verifikasi': 'w1',
  'Lunas': 't1',
  'Ditolak': 'j1',
};

/// The statuses the sheet offers for a bill with the current status.
const _offered = {
  'u1': ['Lunas', 'Ditolak'],
  'w1': ['Belum Bayar', 'Lunas', 'Ditolak'],
  't1': ['Belum Bayar', 'Ditolak'],
  'c1': ['Belum Bayar', 'Ditolak'],
  'j1': ['Belum Bayar', 'Lunas'],
};

void main() {
  setUpAll(initializeIndonesianDates);

  group('action on the bill', () {
    for (final entry in _billOf.entries) {
      testWidgets('is offered on a bill that is ${entry.key}', (tester) async {
        await openBill(tester, entry.value);

        expect(actionButton(changeLabel), findsOneWidget);
      });
    }

    testWidgets('is offered on a bill paid in cash', (tester) async {
      await openBill(tester, 'c1');

      expect(statusBadge('Lunas'), findsOneWidget);
      expect(actionButton(changeLabel), findsOneWidget);
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('is offered to a $role', (tester) async {
        await openBill(tester, 'u1', role: role);

        expect(actionButton(changeLabel), findsOneWidget);
      });
    }

    testWidgets('comes with the review actions on a bill awaiting', (
      tester,
    ) async {
      await openBill(tester, 'w1');

      expect(actionButton(verifyLabel), findsOneWidget);
      expect(actionButton(rejectLabel), findsOneWidget);
      expect(actionButton(changeLabel), findsOneWidget);
      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('comes with the cash payment on an unpaid bill', (
      tester,
    ) async {
      await openBill(tester, 'u1');

      expect(actionButton(cashLabel), findsOneWidget);
      expect(actionButton(changeLabel), findsOneWidget);
      expectNoReviewActions();
    });

    testWidgets('comes with the cash payment on a rejected bill', (
      tester,
    ) async {
      await openBill(tester, 'j1');

      expect(actionButton(cashLabel), findsOneWidget);
      expect(actionButton(changeLabel), findsOneWidget);
    });

    testWidgets('stands alone on a paid bill', (tester) async {
      await openBill(tester, 't1');

      expect(actionButton(changeLabel), findsOneWidget);
      expect(actionButton(cashLabel), findsNothing);
      expectNoReviewActions();
    });

    testWidgets('is not offered while the bill loads', (tester) async {
      final repos = changeRepositories();
      repos.rentBills.getScript.gate = Completer<void>();

      await pumpReview(tester, repos, path: billPath('u1'), settle: false);

      expect(actionButton(changeLabel), findsNothing);
    });

    testWidgets('is not offered when the bill fails to load', (tester) async {
      final repos = changeRepositories();
      repos.rentBills.getScript.always = const ApiFailure.network();

      await pumpReview(tester, repos, path: billPath('u1'));

      expect(actionButton(changeLabel), findsNothing);
    });

    testWidgets('is not offered for a bill that does not exist', (
      tester,
    ) async {
      await pumpReview(tester, changeRepositories(), path: billPath('nope'));

      expect(actionButton(changeLabel), findsNothing);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await openBill(tester, 'u1');

      expectTargetSize(tester, changeLabel);
    });

    testWidgets('opens the sheet and sends nothing yet', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');

      expect(changeSheet(), findsOneWidget);
      expect(sheetText(changeTitle), findsOneWidget);
      expect(repos.management.changeCalls, 0);
    });
  });

  group('sheet', () {
    testWidgets('titles itself with a heading', (tester) async {
      await openChangeSheet(tester, 'u1');

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(sheetText(changeTitle)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('has a required multi-line reason field, empty', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      expect(labeledField(changeReasonLabel), findsOneWidget);
      expect(labeledTextField(tester, changeReasonLabel).maxLines, isNot(1));
      expect(
        labeledTextField(tester, changeReasonLabel).decoration?.labelText,
        isNull,
      );
      expect(typedReason(tester), isEmpty);
    });

    testWidgets('announces the reason field once, with its label', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      expectFieldNode(tester, changeReasonLabel);
      expectNoDecorationLabels(tester);
    });

    testWidgets('marks the choice of status as required in text', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      expect(sheetText(newStatusLabel), findsOneWidget);
    });

    testWidgets('has the save button and a cancel button', (tester) async {
      await openChangeSheet(tester, 'u1');

      expect(actionButton(saveChangeLabel), findsOneWidget);
      expect(actionButton(cancelLabel), findsOneWidget);
    });

    for (final entry in _offered.entries) {
      testWidgets('offers the other statuses for bill ${entry.key}', (
        tester,
      ) async {
        await openChangeSheet(tester, entry.key);

        for (final label in offerableStatuses) {
          expect(
            statusChoice(label),
            entry.value.contains(label) ? findsOneWidget : findsNothing,
            reason: label,
          );
        }
        expect(sheetText('Menunggu Verifikasi'), findsNothing);
      });
    }

    testWidgets('offers the statuses as one group of radio choices', (
      tester,
    ) async {
      await openChangeSheet(tester, 'w1');

      for (final label in offerableStatuses) {
        expectChoiceSemantics(tester, statusChoice(label), selected: false);
      }
    });

    testWidgets('has no status chosen at first', (tester) async {
      final repos = await openChangeSheet(tester, 'w1');

      for (final label in offerableStatuses) {
        expectChoiceSemantics(tester, statusChoice(label), selected: false);
      }
      expect(repos.management.changeCalls, 0);
    });

    testWidgets('shows the chosen status as selected, and only that', (
      tester,
    ) async {
      await openChangeSheet(tester, 'w1');

      await chooseStatus(tester, 'Lunas');

      expectChoiceSemantics(tester, statusChoice('Lunas'), selected: true);
      expectChoiceSemantics(tester, statusChoice('Ditolak'), selected: false);
      expectChoiceSemantics(
        tester,
        statusChoice('Belum Bayar'),
        selected: false,
      );

      await chooseStatus(tester, 'Ditolak');

      expectChoiceSemantics(tester, statusChoice('Lunas'), selected: false);
      expectChoiceSemantics(tester, statusChoice('Ditolak'), selected: true);
    });

    testWidgets('has status choices of at least 48 dp', (tester) async {
      await openChangeSheet(tester, 'w1');

      for (final label in offerableStatuses) {
        expectChoiceTargetSize(tester, statusChoice(label));
      }
    });

    testWidgets('asks for no method and no date before Lunas is chosen', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      expect(sheetText(methodGroupLabel), findsNothing);
      expect(sheetText('Transfer'), findsNothing);
      expect(sheetText('Tunai'), findsNothing);
      expect(dateField(), findsNothing);
    });

    for (final label in ['Belum Bayar', 'Ditolak']) {
      testWidgets('asks for no method and no date when $label is chosen', (
        tester,
      ) async {
        await openChangeSheet(tester, 't1');
        await chooseStatus(tester, label);

        expect(sheetText(methodGroupLabel), findsNothing);
        expect(sheetText('Transfer'), findsNothing);
        expect(sheetText('Tunai'), findsNothing);
        expect(dateField(), findsNothing);
      });
    }

    testWidgets('asks for a method and a date when Lunas is chosen', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      await chooseStatus(tester, 'Lunas');

      expect(sheetText(methodGroupLabel), findsOneWidget);
      expect(methodChoice('Transfer'), findsOneWidget);
      expect(methodChoice('Tunai'), findsOneWidget);
      expect(labeledField(dateLabel), findsOneWidget);
    });

    testWidgets('starts the date at today, written in the app format', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');

      await chooseStatus(tester, 'Lunas');

      expect(shownDate(tester), dateText(today()));
    });

    testWidgets('has no method chosen at first', (tester) async {
      await openChangeSheet(tester, 'u1');

      await chooseStatus(tester, 'Lunas');

      expectChoiceSemantics(tester, methodChoice('Transfer'), selected: false);
      expectChoiceSemantics(tester, methodChoice('Tunai'), selected: false);
    });

    testWidgets('shows the chosen method as selected, and only that', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');

      await chooseMethod(tester, 'Transfer');

      expectChoiceSemantics(tester, methodChoice('Transfer'), selected: true);
      expectChoiceSemantics(tester, methodChoice('Tunai'), selected: false);

      await chooseMethod(tester, 'Tunai');

      expectChoiceSemantics(tester, methodChoice('Transfer'), selected: false);
      expectChoiceSemantics(tester, methodChoice('Tunai'), selected: true);
    });

    testWidgets('has method choices of at least 48 dp', (tester) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');

      expectChoiceTargetSize(tester, methodChoice('Transfer'));
      expectChoiceTargetSize(tester, methodChoice('Tunai'));
    });

    testWidgets('hides the method and the date again for another status', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await chooseMethod(tester, 'Tunai');

      await chooseStatus(tester, 'Ditolak');

      expect(sheetText(methodGroupLabel), findsNothing);
      expect(methodChoice('Tunai'), findsNothing);
      expect(dateField(), findsNothing);
    });

    testWidgets('keeps the typed reason when the status changes', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await typeInto(tester, changeReasonLabel, changeReason);

      await chooseStatus(tester, 'Lunas');
      await chooseStatus(tester, 'Ditolak');

      expect(typedReason(tester), changeReason);
    });

    testWidgets('opens the date picker from the date field', (tester) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');

      await press(tester, dateField());

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('opens the picker on today and allows no later day', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await press(tester, dateField());

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(sameDay(picker.initialDate, today()), isTrue);
      expect(sameDay(picker.lastDate, today()), isTrue);
    });

    testWidgets('shows the day picked in the date field', (tester) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');

      final picked = await pickDateInPreviousMonthOfField(tester);

      expect(shownDate(tester), dateText(picked));
      expect(changeSheet(), findsOneWidget);
    });

    testWidgets('keeps the date when the picker is cancelled', (tester) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
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

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(shownDate(tester), dateText(today()));
      expect(changeSheet(), findsOneWidget);
    });

    testWidgets('announces the date field once, with its label', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');

      expectFieldNode(tester, dateLabel);
      expectNoDecorationLabels(tester);
    });

    testWidgets('scrolls at large text size with every input shown', (
      tester,
    ) async {
      await openChangeSheet(tester, 'w1', largeText: true);
      await chooseStatus(tester, 'Lunas');

      expect(
        find.descendant(of: changeSheet(), matching: find.byType(Scrollable)),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('leaving the sheet', () {
    Future<void> fill(WidgetTester tester) async {
      await chooseStatus(tester, 'Lunas');
      await chooseMethod(tester, 'Tunai');
      await typeInto(tester, changeReasonLabel, changeReason);
    }

    testWidgets('Batal closes it and sends nothing', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await fill(tester);

      await tester.tap(actionButton(cancelLabel));
      await tester.pumpAndSettle();

      expect(changeSheet(), findsNothing);
      expect(repos.management.changeCalls, 0);
      expect(statusBadge('Belum Bayar'), findsOneWidget);
      expect(currentUri(tester).path, billPath('u1'));
      expect(actionButton(changeLabel), findsOneWidget);
    });

    testWidgets('tapping outside closes it and sends nothing', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await fill(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(changeSheet(), findsNothing);
      expect(repos.management.changeCalls, 0);
      expect(statusBadge('Belum Bayar'), findsOneWidget);
    });

    testWidgets('the back gesture closes it, not the bill', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await fill(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(changeSheet(), findsNothing);
      expect(currentUri(tester).path, billPath('u1'));
      expect(repos.management.changeCalls, 0);
    });

    testWidgets('opens empty again after it was left', (tester) async {
      await openChangeSheet(tester, 'u1');
      await fill(tester);
      await tester.tap(actionButton(cancelLabel));
      await tester.pumpAndSettle();

      await press(tester, actionButton(changeLabel));

      expect(typedReason(tester), isEmpty);
      expectChoiceSemantics(tester, statusChoice('Lunas'), selected: false);
      expectChoiceSemantics(tester, statusChoice('Ditolak'), selected: false);
      expect(sheetText(methodGroupLabel), findsNothing);
    });
  });

  group('refusing input', () {
    const blanks = {
      'no text': '',
      'only spaces': '   ',
      'only spaces and line breaks': ' \n\t ',
    };
    for (final blank in blanks.entries) {
      testWidgets('a reason with ${blank.key} is refused', (tester) async {
        final repos = await openChangeSheet(tester, 'u1');
        await chooseStatus(tester, 'Ditolak');
        await typeInto(tester, changeReasonLabel, blank.value);

        await saveChange(tester);

        expect(
          labeledFieldError(tester, changeReasonLabel),
          changeReasonRequiredMessage,
        );
        expect(changeReasonField(), findsOneWidget);
        expect(repos.management.changeCalls, 0);
      });
    }

    testWidgets('exposes the refused reason on the field to a screen reader', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Ditolak');

      await saveChange(tester);

      expectFieldNode(
        tester,
        changeReasonLabel,
        error: changeReasonRequiredMessage,
      );
    });

    testWidgets('a blank reason is refused for Lunas too', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await chooseMethod(tester, 'Transfer');

      await saveChange(tester);

      expect(
        labeledFieldError(tester, changeReasonLabel),
        changeReasonRequiredMessage,
      );
      expect(repos.management.changeCalls, 0);
    });

    testWidgets('no status chosen is refused next to the choice', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');
      await typeInto(tester, changeReasonLabel, changeReason);

      await saveChange(tester);

      expect(sheetText(statusRequiredMessage), findsOneWidget);
      expect(repos.management.changeCalls, 0);
      expect(changeSheet(), findsOneWidget);
      expect(typedReason(tester), changeReason);
    });

    testWidgets('a missing status and a missing reason are both shown', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');

      await saveChange(tester);

      expect(sheetText(statusRequiredMessage), findsOneWidget);
      expect(
        labeledFieldError(tester, changeReasonLabel),
        changeReasonRequiredMessage,
      );
      expect(repos.management.changeCalls, 0);
    });

    testWidgets('Lunas without a method is refused next to the choice', (
      tester,
    ) async {
      final repos = await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await typeInto(tester, changeReasonLabel, changeReason);

      await saveChange(tester);

      expect(sheetText(methodRequiredMessage), findsOneWidget);
      expect(repos.management.changeCalls, 0);
      expect(changeSheet(), findsOneWidget);
      expect(typedReason(tester), changeReason);
    });

    testWidgets('a method chosen after the refusal is sent', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await typeInto(tester, changeReasonLabel, changeReason);
      await saveChange(tester);

      await chooseMethod(tester, 'Transfer');
      await saveChange(tester);

      expect(repos.management.changeCalls, 1);
      expect(
        repos.management.statusChangeRequests.single.method,
        PaymentMethod.transfer,
      );
      expect(changeSheet(), findsNothing);
    });

    testWidgets('a reason typed after the refusal is sent', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Ditolak');
      await saveChange(tester);

      await typeInto(tester, changeReasonLabel, changeReason);
      await saveChange(tester);

      expect(repos.management.changeCalls, 1);
      expect(repos.management.statusChangeRequests.single.reason, changeReason);
      expect(changeSheet(), findsNothing);
    });

    testWidgets('a status chosen after the refusal is sent', (tester) async {
      final repos = await openChangeSheet(tester, 'u1');
      await typeInto(tester, changeReasonLabel, changeReason);
      await saveChange(tester);

      await chooseStatus(tester, 'Ditolak');
      await saveChange(tester);

      expect(repos.management.changeCalls, 1);
      expect(
        repos.management.statusChangeRequests.single.status,
        PaymentStatus.rejected,
      );
      expect(changeSheet(), findsNothing);
    });

    testWidgets('the method refusal goes away with the method choice', (
      tester,
    ) async {
      await openChangeSheet(tester, 'u1');
      await chooseStatus(tester, 'Lunas');
      await typeInto(tester, changeReasonLabel, changeReason);
      await saveChange(tester);

      await chooseStatus(tester, 'Ditolak');

      expect(sheetText(methodRequiredMessage), findsNothing);
    });

    testWidgets('exposes a refused status to a screen reader', (tester) async {
      await openChangeSheet(tester, 'u1');
      await saveChange(tester);

      final handle = tester.ensureSemantics();
      try {
        expect(nodesAnnouncing(tester, statusRequiredMessage), isNotEmpty);
      } finally {
        handle.dispose();
      }
    });
  });
}
