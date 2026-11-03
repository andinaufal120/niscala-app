import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';

import '../../../helpers/date_picker_semantics.dart';
import '../../../helpers/semantics.dart';
import 'payment_status_change_ui_helpers.dart';

const _label = 'Tanggal diterima';

/// The sheet of the unpaid bill with Lunas chosen, which shows the date.
Future<ReviewRepositories> _lunasSheet(
  WidgetTester tester, {
  ReviewRepositories? repos,
}) async {
  final shown = await openChangeSheet(tester, 'u1', repos: repos);
  await chooseStatus(tester, 'Lunas');
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

/// Goes to the previous month in the open picker, picks the 15th and confirms.
/// Returns the day picked.
Future<DateTime> _pickInOpenPicker(WidgetTester tester) async {
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
        .descendant(of: find.byType(Dialog), matching: find.byType(TextButton))
        .last,
  );
  await tester.pumpAndSettle();
  final now = DateTime.now();
  return DateTime(now.year, now.month - 1, 15);
}

void main() {
  setUpAll(initializeIndonesianDates);

  group('date field semantics', () {
    testWidgets('offers the tap action on the node of the field', (
      tester,
    ) async {
      await _lunasSheet(tester);

      await _withSemantics(tester, () async {
        final data = tester.getSemantics(dateField()).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      });
    });

    testWidgets('has one node with the tap action for the label', (
      tester,
    ) async {
      await _lunasSheet(tester);

      await _withSemantics(tester, () async {
        expect(tappableNodesAnnouncing(tester, _label), hasLength(1));
      });
    });

    testWidgets('announces the label and the shown date on that node', (
      tester,
    ) async {
      await _lunasSheet(tester);

      await _withSemantics(tester, () async {
        final node = tappableNodesAnnouncing(tester, _label).single;
        final text = announced(node);
        expect(text, contains(_label));
        expect(text, contains(dateText(today())));
      });
    });

    testWidgets('announces the label once', (tester) async {
      await _lunasSheet(tester);

      await _withSemantics(tester, () async {
        expect(nodesAnnouncing(tester, _label), hasLength(1));
      });
      expectFieldNode(tester, dateLabel);
    });

    testWidgets('opens the date picker when the tap action is performed', (
      tester,
    ) async {
      await _lunasSheet(tester);

      await openDatePickerThroughSemantics(tester, _label);

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('opens a picker at today that stops at today', (tester) async {
      await _lunasSheet(tester);

      await openDatePickerThroughSemantics(tester, _label);

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(sameDay(picker.initialDate, today()), isTrue);
      expect(sameDay(picker.lastDate, today()), isTrue);
    });

    testWidgets('keeps the date when the picker opened this way is cancelled', (
      tester,
    ) async {
      await _lunasSheet(tester);
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
      expect(changeSheet(), findsOneWidget);
      expect(shownDate(tester), dateText(today()));
      await _withSemantics(tester, () async {
        final node = tappableNodesAnnouncing(tester, _label).single;
        expect(announced(node), contains(dateText(today())));
      });
    });

    testWidgets('shows the date picked after opening it this way', (
      tester,
    ) async {
      await _lunasSheet(tester);
      await openDatePickerThroughSemantics(tester, _label);

      final picked = await _pickInOpenPicker(tester);

      expect(shownDate(tester), dateText(picked));
      expect(changeSheet(), findsOneWidget);
    });

    testWidgets('updates the announced value after a date is picked', (
      tester,
    ) async {
      await _lunasSheet(tester);
      await openDatePickerThroughSemantics(tester, _label);
      final picked = await _pickInOpenPicker(tester);

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
      final repos = await _lunasSheet(tester);
      await chooseMethod(tester, 'Tunai');
      await openDatePickerThroughSemantics(tester, _label);
      final picked = await _pickInOpenPicker(tester);
      await typeInto(tester, changeReasonLabel, changeReason);

      await saveChange(tester);

      final request = repos.management.statusChangeRequests.single;
      expect(sameDay(request.receivedOn, picked), isTrue);
    });

    testWidgets('keeps the tap action and the error on the node of the field', (
      tester,
    ) async {
      final repos = changeRepositories();
      repos.management.changeScript.queue.add(
        const ApiFailure(
          code: 'RECEIVED_ON_IN_FUTURE',
          field: 'receivedOn',
          statusCode: 422,
        ),
      );
      await openChangeSheet(tester, 'u1', repos: repos);
      await submitChange(tester, status: 'Lunas', method: 'Tunai');

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
      final repos = changeRepositories();
      repos.management.changeScript.queue.add(
        const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'receivedOn',
          statusCode: 422,
        ),
      );
      await openChangeSheet(tester, 'u1', repos: repos);
      await submitChange(tester, status: 'Lunas', method: 'Tunai');

      await openDatePickerThroughSemantics(tester, _label);

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('keeps a target of at least 48 dp for the field', (
      tester,
    ) async {
      await _lunasSheet(tester);

      await _withSemantics(tester, () async {
        final rect = tappableNodesAnnouncing(tester, _label).single.rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      });
    });
  });
}
