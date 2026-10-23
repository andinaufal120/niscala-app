import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import 'complaint_detail_layout_helpers.dart';
import 'complaint_ui_helpers.dart';

Complaint _classified({
  ComplaintStatus status = ComplaintStatus.new_,
  String? classifiedByName,
}) => makeComplaint(
  status: status,
  classification: makeComplaintClassification(
    category: 'Pipa dan air',
    urgency: ComplaintUrgency.high,
    classifiedByName: classifiedByName,
  ),
);

Future<void> _open(
  WidgetTester tester,
  Complaint complaint, {
  bool narrow = false,
  bool largeText = false,
}) async {
  await pumpComplaintApp(
    tester,
    FakeComplaintRepository(complaints: [complaint]),
    path: '/penyewa/keluhan/c1',
    largeText: largeText,
  );
  if (narrow) await useNarrowScreen(tester);
}

void main() {
  setUpAll(loadAppFont);

  group('detail bar', () {
    testWidgets('is titled Rincian Keluhan without a subtitle', (tester) async {
      await _open(tester, _classified());

      expect(detailBar(tester).title, 'Rincian Keluhan');
      expect(detailBar(tester).subtitle, isNull);
      expect(tester.getSize(find.byType(AppBar)).height, 56);
    });
  });

  group('status card', () {
    for (final status in ComplaintStatus.values) {
      testWidgets('shows the steps of $status in a card titled Status', (
        tester,
      ) async {
        await _open(tester, _classified(status: status));

        expectStatusCard(tester, status);
      });
    }

    testWidgets('no longer shows the status as a lone badge', (tester) async {
      await _open(tester, _classified());

      for (final label in ['Baru', 'Diproses', 'Selesai']) {
        expect(statusBadge(label), findsNothing);
      }
    });

    testWidgets('is read once as Status: <label>', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, _classified(status: ComplaintStatus.done));

        expect(find.bySemanticsLabel('Status: Selesai'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'^Status: ')), findsOneWidget);
        for (final label in ['Baru', 'Diproses', 'Selesai']) {
          expect(find.bySemanticsLabel(label), findsNothing);
        }
      } finally {
        handle.dispose();
      }
    });
  });

  group('classification card', () {
    testWidgets('puts Kategori and Urgensi side by side over their values', (
      tester,
    ) async {
      await _open(tester, _classified(), narrow: true);

      expectEmphasisSectionCard(tester, 'Klasifikasi');
      expectClassificationRow(
        tester,
        category: 'Pipa dan air',
        urgency: 'Tinggi',
      );
    });

    testWidgets('puts the AI disclaimer under a divider in small muted text', (
      tester,
    ) async {
      await _open(tester, _classified(), narrow: true);

      expect(
        find.text('Klasifikasi dibuat AI dan bisa keliru.'),
        findsOneWidget,
      );
      expectDisclaimerUnderDivider(
        tester,
        find.descendant(
          of: sectionCardOf('Klasifikasi'),
          matching: find.byType(StatusBadge),
        ),
      );
    });

    testWidgets('a classification by management has no disclaimer', (
      tester,
    ) async {
      await _open(
        tester,
        _classified(classifiedByName: 'Siti Pemilik'),
        narrow: true,
      );

      expectClassificationRow(
        tester,
        category: 'Pipa dan air',
        urgency: 'Tinggi',
      );
      expect(aiDisclaimer(), findsNothing);
    });
  });

  group('large text', () {
    final cases = <String, Complaint Function()>{
      'classified by the AI': _classified,
      'classified by management': () =>
          _classified(classifiedByName: 'Siti Pemilik Kos Melati'),
      'classifying': () => makeComplaint(
        classificationState: ComplaintClassificationState.classifying,
      ),
      'not classified': () => makeComplaint(
        classificationState: ComplaintClassificationState.notClassified,
        status: ComplaintStatus.done,
      ),
    };

    for (final entry in cases.entries) {
      testWidgets('fits at 200 percent text when ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('keeps Kategori, Urgensi and the steps on screen', (
      tester,
    ) async {
      await _open(tester, _classified(), largeText: true);

      expect(tester.takeException(), isNull);
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      for (final finder in [
        find.text('Kategori'),
        find.text('Urgensi'),
        find.text('Pipa dan air'),
        statusSteps(),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      expectClassificationRow(
        tester,
        category: 'Pipa dan air',
        urgency: 'Tinggi',
        mayStack: true,
      );
    });
  });
}
