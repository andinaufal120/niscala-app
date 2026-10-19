import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

final _tokens = buildTheme().extension<NiscalaTokens>()!;

final _statusTokens = <ComplaintStatus, BadgeColors Function(NiscalaTokens)>{
  ComplaintStatus.new_: (t) => t.complaintNew,
  ComplaintStatus.inProgress: (t) => t.complaintInProgress,
  ComplaintStatus.done: (t) => t.complaintDone,
};

final _urgencyTokens = <ComplaintUrgency, BadgeColors Function(NiscalaTokens)>{
  ComplaintUrgency.low: (t) => t.urgencyLow,
  ComplaintUrgency.medium: (t) => t.urgencyMedium,
  ComplaintUrgency.high: (t) => t.urgencyHigh,
};

final _classificationTokens =
    <ComplaintClassificationState, BadgeColors Function(NiscalaTokens)>{
      ComplaintClassificationState.classifying: (t) =>
          t.classificationClassifying,
      ComplaintClassificationState.awaitingClassification: (t) =>
          t.classificationAwaiting,
      ComplaintClassificationState.notClassified: (t) =>
          t.classificationNotClassified,
    };

void _expectColours(WidgetTester tester, BadgeColors expected) {
  final colors = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;
  expect(colors.background, expected.background);
  expect(colors.foreground, expected.foreground);
  expect(colors.border, expected.border);
}

const _statusLabels = {
  ComplaintStatus.new_: 'Baru',
  ComplaintStatus.inProgress: 'Diproses',
  ComplaintStatus.done: 'Selesai',
};

const _urgencyLabels = {
  ComplaintUrgency.low: 'Rendah',
  ComplaintUrgency.medium: 'Sedang',
  ComplaintUrgency.high: 'Tinggi',
};

const _classificationLabels = {
  ComplaintClassificationState.classifying: 'Sedang Diklasifikasi',
  ComplaintClassificationState.awaitingClassification: 'Menunggu Klasifikasi',
  ComplaintClassificationState.notClassified: 'Belum Diklasifikasi',
};

void main() {
  group('complaint status', () {
    for (final entry in _statusLabels.entries) {
      test('labels ${entry.key} ${entry.value}', () {
        expect(complaintStatusStyles[entry.key]!.label, entry.value);
      });
    }

    test('has one entry per status and no other', () {
      expect(
        complaintStatusStyles.keys,
        unorderedEquals(ComplaintStatus.values),
      );
    });

    test('uses a different label for every status', () {
      final labels = complaintStatusStyles.values.map((s) => s.label);
      expect(labels.toSet(), hasLength(ComplaintStatus.values.length));
    });
  });

  group('complaint urgency', () {
    for (final entry in _urgencyLabels.entries) {
      test('labels ${entry.key} ${entry.value}', () {
        expect(complaintUrgencyStyles[entry.key]!.label, entry.value);
      });
    }

    test('has one entry per urgency and no other', () {
      expect(
        complaintUrgencyStyles.keys,
        unorderedEquals(ComplaintUrgency.values),
      );
    });

    test('uses a different label for every urgency', () {
      final labels = complaintUrgencyStyles.values.map((s) => s.label);
      expect(labels.toSet(), hasLength(ComplaintUrgency.values.length));
    });
  });

  group('complaint classification state', () {
    for (final entry in _classificationLabels.entries) {
      test('labels ${entry.key} ${entry.value}', () {
        expect(complaintClassificationStyles[entry.key]!.label, entry.value);
      });
    }

    test('has one entry per classification state and no other', () {
      expect(
        complaintClassificationStyles.keys,
        unorderedEquals(ComplaintClassificationState.values),
      );
    });

    test('uses a different label for every state', () {
      final labels = complaintClassificationStyles.values.map((s) => s.label);
      expect(
        labels.toSet(),
        hasLength(ComplaintClassificationState.values.length),
      );
    });
  });

  group('ComplaintBadge', () {
    testWidgets('shows the label of a status as text', (tester) async {
      for (final entry in _statusLabels.entries) {
        await tester.pumpWidget(themedApp(ComplaintBadge.status(entry.key)));

        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('shows the label of an urgency as text', (tester) async {
      for (final entry in _urgencyLabels.entries) {
        await tester.pumpWidget(themedApp(ComplaintBadge.urgency(entry.key)));

        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('shows the label of a classification state as text', (
      tester,
    ) async {
      for (final entry in _classificationLabels.entries) {
        await tester.pumpWidget(
          themedApp(ComplaintBadge.classification(entry.key)),
        );

        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('colours each status from its token', (tester) async {
      for (final entry in _statusTokens.entries) {
        await tester.pumpWidget(themedApp(ComplaintBadge.status(entry.key)));

        _expectColours(tester, entry.value(_tokens));
      }
    });

    testWidgets('colours each urgency from its token', (tester) async {
      for (final entry in _urgencyTokens.entries) {
        await tester.pumpWidget(themedApp(ComplaintBadge.urgency(entry.key)));

        _expectColours(tester, entry.value(_tokens));
      }
    });

    testWidgets('colours each classification state from its token', (
      tester,
    ) async {
      for (final entry in _classificationTokens.entries) {
        await tester.pumpWidget(
          themedApp(ComplaintBadge.classification(entry.key)),
        );

        _expectColours(tester, entry.value(_tokens));
      }
    });

    testWidgets('tells the three statuses apart by colour as well as text', (
      tester,
    ) async {
      final backgrounds = <Color>{};
      for (final status in ComplaintStatus.values) {
        await tester.pumpWidget(themedApp(ComplaintBadge.status(status)));
        backgrounds.add(
          tester
              .widget<StatusBadge>(find.byType(StatusBadge))
              .colors
              .background,
        );
      }

      expect(backgrounds, hasLength(ComplaintStatus.values.length));
    });

    testWidgets('shows high urgency with the strongest colour', (tester) async {
      await tester.pumpWidget(
        themedApp(ComplaintBadge.urgency(ComplaintUrgency.high)),
      );

      final high = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;
      await tester.pumpWidget(
        themedApp(ComplaintBadge.urgency(ComplaintUrgency.low)),
      );
      final low = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;

      expect(high.background, isNot(low.background));
      expect(high.background, const Color(0xFF9A3412));
    });

    testWidgets('speaks its label, so colour never carries the meaning', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          themedApp(
            ComplaintBadge.classification(
              ComplaintClassificationState.classifying,
            ),
          ),
        );

        expect(find.bySemanticsLabel('Sedang Diklasifikasi'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
