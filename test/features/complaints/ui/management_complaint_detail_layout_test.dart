import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import 'complaint_detail_layout_helpers.dart';
import 'complaint_ui_helpers.dart';

const _description = 'Keran air di kamar mandi bocor sejak kemarin.';
const _roles = [UserRole.owner, UserRole.manager];

Complaint _ai({
  ComplaintStatus status = ComplaintStatus.new_,
  String? suggestedAction = 'Panggil tukang ledeng.',
  String tenantName = 'Budi Santoso',
  String? classifiedByName,
}) => makeComplaint(
  status: status,
  tenantName: tenantName,
  classification: makeComplaintClassification(
    category: 'Pipa dan air',
    urgency: ComplaintUrgency.high,
    suggestedAction: suggestedAction,
    classifiedByName: classifiedByName,
  ),
);

Future<void> _open(
  WidgetTester tester,
  Complaint complaint, {
  UserRole role = UserRole.owner,
  bool narrow = false,
  bool largeText = false,
}) async {
  await pumpComplaintApp(
    tester,
    FakeComplaintRepository(complaints: [complaint]),
    role: role,
    path: '/keluhan/c1',
    largeText: largeText,
  );
  if (narrow) await useNarrowScreen(tester);
}

void main() {
  setUpAll(loadAppFont);

  group('detail bar', () {
    for (final role in _roles) {
      testWidgets('a $role sees Rincian Keluhan with room and tenant', (
        tester,
      ) async {
        await _open(tester, _ai(), role: role);

        final bar = detailBar(tester);
        expect(bar.title, 'Rincian Keluhan');
        expect(bar.subtitle, 'Kamar 08 · Budi Santoso');
        expect(
          find.descendant(
            of: find.byType(DetailAppBar),
            matching: find.text('Kamar 08 · Budi Santoso'),
          ),
          findsOneWidget,
        );
        expect(find.byType(AppBar), findsOneWidget);
      });
    }

    testWidgets('follows the room and tenant of the complaint', (tester) async {
      await _open(
        tester,
        makeComplaint(roomNumber: '12', tenantName: 'Sari Wulandari'),
      );

      expect(detailBar(tester).subtitle, 'Kamar 12 · Sari Wulandari');
    });

    testWidgets('has no subtitle while loading', (tester) async {
      final repo = FakeComplaintRepository(complaints: [makeComplaint()])
        ..getScript.gate = Completer<void>();
      await pumpComplaintApp(
        tester,
        repo,
        role: UserRole.owner,
        path: '/keluhan/c1',
        settle: false,
      );

      expect(detailBar(tester).title, 'Rincian Keluhan');
      expect(detailBar(tester).subtitle, isNull);
    });

    testWidgets('has no subtitle when loading failed', (tester) async {
      final repo = FakeComplaintRepository(complaints: [makeComplaint()])
        ..getScript.always = const ApiFailure.network();
      await pumpComplaintApp(
        tester,
        repo,
        role: UserRole.owner,
        path: '/keluhan/c1',
      );

      expect(detailBar(tester).title, 'Rincian Keluhan');
      expect(detailBar(tester).subtitle, isNull);
    });

    testWidgets('stays 56 dp high with the subtitle', (tester) async {
      await _open(tester, _ai(), narrow: true);

      expect(tester.getSize(find.byType(DetailAppBar)).height, 56);
    });
  });

  group('status card', () {
    for (final status in ComplaintStatus.values) {
      testWidgets('shows the steps of $status in a card titled Status', (
        tester,
      ) async {
        await _open(tester, _ai(status: status));

        expectStatusCard(tester, status);
      });
    }

    testWidgets('no longer shows the status as a lone badge', (tester) async {
      await _open(tester, _ai());

      for (final label in ['Baru', 'Diproses', 'Selesai']) {
        expect(statusBadge(label), findsNothing);
      }
    });

    testWidgets('is read once as Status: <label>', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, _ai(status: ComplaintStatus.inProgress));

        expect(find.bySemanticsLabel('Status: Diproses'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'^Status: ')), findsOneWidget);
        for (final label in ['Baru', 'Diproses', 'Selesai']) {
          expect(find.bySemanticsLabel(label), findsNothing);
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('sits above the classification', (tester) async {
      await _open(tester, _ai());

      expect(
        topOf(tester, sectionCardOf('Status')),
        lessThan(topOf(tester, sectionCardOf('Klasifikasi'))),
      );
    });
  });

  group('classification card', () {
    testWidgets('puts Kategori and Urgensi side by side over their values', (
      tester,
    ) async {
      await _open(tester, _ai(), narrow: true);

      expectEmphasisSectionCard(tester, 'Klasifikasi');
      expectClassificationRow(
        tester,
        category: 'Pipa dan air',
        urgency: 'Tinggi',
      );
    });

    testWidgets('puts the suggested action below as a label and text', (
      tester,
    ) async {
      await _open(tester, _ai(), narrow: true);

      expectSuggestedAction(tester, 'Panggil tukang ledeng.');
    });

    testWidgets('puts the AI disclaimer under a divider in small muted text', (
      tester,
    ) async {
      await _open(tester, _ai(), narrow: true);

      expectDisclaimerUnderDivider(tester, find.text('Panggil tukang ledeng.'));
    });

    testWidgets('keeps the disclaimer text', (tester) async {
      await _open(tester, _ai());

      expect(
        find.text(
          'Klasifikasi dibuat AI dan bisa keliru. '
          'Periksa kembali sebelum bertindak.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('without a suggested action the divider still comes first', (
      tester,
    ) async {
      await _open(tester, _ai(suggestedAction: null), narrow: true);

      expect(find.text('Tindakan yang disarankan'), findsNothing);
      expectClassificationRow(
        tester,
        category: 'Pipa dan air',
        urgency: 'Tinggi',
      );
      expectDisclaimerUnderDivider(
        tester,
        find.descendant(
          of: sectionCardOf('Klasifikasi'),
          matching: find.byType(StatusBadge),
        ),
      );
    });

    testWidgets('a manual classification keeps Kategori and Urgensi in a row', (
      tester,
    ) async {
      await _open(
        tester,
        _ai(suggestedAction: null, classifiedByName: 'Siti Pemilik'),
        narrow: true,
      );

      expectClassificationRow(
        tester,
        category: 'Pipa dan air',
        urgency: 'Tinggi',
      );
      expect(find.textContaining('Siti Pemilik'), findsOneWidget);
      expect(aiDisclaimer(), findsNothing);
    });
  });

  group('tenant message card', () {
    testWidgets('shows the message first, then one muted meta line', (
      tester,
    ) async {
      await _open(tester, _ai(), narrow: true);

      expectSectionCard(tester, 'Pesan penyewa');
      final card = sectionCardOf('Pesan penyewa');
      final message = find.descendant(
        of: card,
        matching: find.text(_description),
      );
      final meta = find.descendant(of: card, matching: tenantMeta());
      expect(message, findsOneWidget);
      expect(meta, findsOneWidget);
      expect(
        tester.getTopLeft(meta).dy,
        greaterThanOrEqualTo(tester.getRect(message).bottom - 1),
      );

      final style = styleOf(tester, meta);
      expect(style.fontSize, 12);
      expect(style.color, NiscalaColors.textMuted);
    });

    testWidgets('holds nothing above the message but the card title', (
      tester,
    ) async {
      await _open(tester, _ai(), narrow: true);

      final card = sectionCardOf('Pesan penyewa');
      final texts = find.descendant(of: card, matching: find.byType(Text));
      final tops = <double, String>{};
      for (final element in texts.evaluate()) {
        final text = (element.widget as Text).data ?? '';
        tops[tester
                .getTopLeft(find.byElementPredicate((e) => e == element))
                .dy] =
            text;
      }
      final ordered = (tops.keys.toList()..sort()).map((k) => tops[k]);
      expect(ordered.first, 'Pesan penyewa');
      expect(ordered.elementAt(1), _description);
      expect(ordered, hasLength(3));
    });
  });

  group('large text', () {
    final cases = <String, Complaint Function()>{
      'classified by the AI': _ai,
      'classified by management': () =>
          _ai(classifiedByName: 'Siti Pemilik Kos Melati'),
      'without a suggested action': () => _ai(suggestedAction: null),
      'a long tenant name': () =>
          _ai(tenantName: 'Budi Santoso Wijayakusuma Hadiningrat'),
      'classifying': () => makeComplaint(
        classificationState: ComplaintClassificationState.classifying,
      ),
      'withheld': () => makeComplaint(classificationWithheld: true),
      'done': () => _ai(status: ComplaintStatus.done),
    };

    for (final entry in cases.entries) {
      testWidgets('fits at 200 percent text when ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
        final bar = tester.getRect(find.byType(DetailAppBar));
        final subtitle = find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.textContaining(' · '),
        );
        expect(tester.getRect(subtitle).bottom, lessThanOrEqualTo(bar.bottom));
      });
    }

    testWidgets('keeps Kategori, Urgensi and the steps on screen', (
      tester,
    ) async {
      await _open(tester, _ai(), largeText: true);

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
