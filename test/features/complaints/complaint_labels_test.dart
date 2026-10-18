import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

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

    test('shows a finished complaint with the success tone', () {
      expect(
        complaintStatusStyles[ComplaintStatus.done]!.tone,
        StatusTone.success,
      );
    });

    test('tells the three statuses apart by tone as well as text', () {
      final tones = complaintStatusStyles.values.map((s) => s.tone);
      expect(tones.toSet(), hasLength(ComplaintStatus.values.length));
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

    test('shows high urgency with the danger tone', () {
      expect(
        complaintUrgencyStyles[ComplaintUrgency.high]!.tone,
        StatusTone.danger,
      );
    });

    test('shows high and low urgency with different tones', () {
      expect(
        complaintUrgencyStyles[ComplaintUrgency.high]!.tone,
        isNot(complaintUrgencyStyles[ComplaintUrgency.low]!.tone),
      );
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
        expect(
          tester.widget<StatusBadge>(find.byType(StatusBadge)).tone,
          complaintStatusStyles[entry.key]!.tone,
        );
      }
    });

    testWidgets('shows the label of an urgency as text', (tester) async {
      for (final entry in _urgencyLabels.entries) {
        await tester.pumpWidget(themedApp(ComplaintBadge.urgency(entry.key)));

        expect(find.text(entry.value), findsOneWidget);
        expect(
          tester.widget<StatusBadge>(find.byType(StatusBadge)).tone,
          complaintUrgencyStyles[entry.key]!.tone,
        );
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
        expect(
          tester.widget<StatusBadge>(find.byType(StatusBadge)).tone,
          complaintClassificationStyles[entry.key]!.tone,
        );
      }
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
