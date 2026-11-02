import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/date_picker_semantics.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'cash_payment_ui_helpers.dart';

const _label = 'Tanggal diterima';

/// The flow with Rina Putri chosen: her single payable bill shows the form.
Future<ReviewRepositories> _formOfRina(
  WidgetTester tester, {
  ReviewRepositories? repos,
}) async {
  final shown = await openCashFlow(tester, repos: repos);
  await press(tester, find.text('Rina Putri'));
  return shown;
}

/// Runs [body] with semantics enabled.
Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void main() {
  setUpAll(initializeIndonesianDates);

  group('date field semantics', () {
    testWidgets('offers the tap action on the node of the field', (
      tester,
    ) async {
      await _formOfRina(tester);

      await _withSemantics(tester, () async {
        final data = tester.getSemantics(dateField()).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      });
    });

    testWidgets('has one node with the tap action for the label', (
      tester,
    ) async {
      await _formOfRina(tester);

      await _withSemantics(tester, () async {
        expect(tappableNodesAnnouncing(tester, _label), hasLength(1));
      });
    });

    testWidgets('announces the label and the shown date on that node', (
      tester,
    ) async {
      await _formOfRina(tester);

      await _withSemantics(tester, () async {
        final node = tappableNodesAnnouncing(tester, _label).single;
        final text = announced(node);
        expect(text, contains(_label));
        expect(text, contains(dateText(today())));
      });
    });

    testWidgets('announces the label once', (tester) async {
      await _formOfRina(tester);

      await _withSemantics(tester, () async {
        expect(nodesAnnouncing(tester, _label), hasLength(1));
      });
      expectFieldNode(tester, dateLabel);
    });

    testWidgets('opens the date picker when the tap action is performed', (
      tester,
    ) async {
      await _formOfRina(tester);

      await openDatePickerThroughSemantics(tester, _label);

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('opens a picker at today that stops at today', (tester) async {
      await _formOfRina(tester);

      await openDatePickerThroughSemantics(tester, _label);

      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(sameDay(picker.initialDate, today()), isTrue);
      expect(sameDay(picker.lastDate, today()), isTrue);
    });

    testWidgets('keeps the date when the picker opened this way is cancelled', (
      tester,
    ) async {
      await _formOfRina(tester);
      await openDatePickerThroughSemantics(tester, _label);

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
      await _withSemantics(tester, () async {
        final node = tappableNodesAnnouncing(tester, _label).single;
        expect(announced(node), contains(dateText(today())));
      });
    });

    testWidgets('shows the date picked after opening it this way', (
      tester,
    ) async {
      await _formOfRina(tester);
      await openDatePickerThroughSemantics(tester, _label);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byIcon(Icons.chevron_left),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      final now = DateTime.now();
      final picked = DateTime(now.year, now.month - 1, 15);

      expect(shownDate(tester), dateText(picked));
    });

    testWidgets('updates the announced value after a date is picked', (
      tester,
    ) async {
      await _formOfRina(tester);
      final picked = await pickDateInPreviousMonthOfField(tester);

      await _withSemantics(tester, () async {
        final node = tappableNodesAnnouncing(tester, _label).single;
        final text = announced(node);
        expect(text, contains(dateText(picked)));
        expect(text, isNot(contains(dateText(today()))));
        expect(nodesAnnouncing(tester, _label), hasLength(1));
      });
    });

    testWidgets('sends the date picked after opening the picker this way', (
      tester,
    ) async {
      final repos = await _formOfRina(tester);
      await openDatePickerThroughSemantics(tester, _label);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byIcon(Icons.chevron_left),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await confirmReceived(tester);

      await saveCash(tester);

      final now = DateTime.now();
      expect(
        sameDay(
          repos.management.cashPayments.single.receivedOn,
          DateTime(now.year, now.month - 1, 15),
        ),
        isTrue,
      );
    });

    testWidgets('keeps the tap action and the error on the node of the field', (
      tester,
    ) async {
      final repos = cashRepositories();
      repos.management.cashScript.queue.add(
        const ApiFailure(
          code: 'RECEIVED_ON_IN_FUTURE',
          field: 'receivedOn',
          statusCode: 422,
        ),
      );
      await _formOfRina(tester, repos: repos);
      await confirmReceived(tester);
      await saveCash(tester);

      await _withSemantics(tester, () async {
        final nodes = tappableNodesAnnouncing(tester, _label);
        expect(nodes, hasLength(1));
        expect(announced(nodes.single), contains(futureDateMessage));
        expect(nodesAnnouncing(tester, _label), hasLength(1));
      });
    });

    testWidgets('opens the picker through semantics while an error shows', (
      tester,
    ) async {
      final repos = cashRepositories();
      repos.management.cashScript.queue.add(
        const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'receivedOn',
          statusCode: 422,
        ),
      );
      await _formOfRina(tester, repos: repos);
      await confirmReceived(tester);
      await saveCash(tester);

      await openDatePickerThroughSemantics(tester, _label);

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('keeps a target of at least 48 dp for the field', (
      tester,
    ) async {
      await _formOfRina(tester);

      await _withSemantics(tester, () async {
        final rect = tappableNodesAnnouncing(tester, _label).single.rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      });
    });
  });
}
