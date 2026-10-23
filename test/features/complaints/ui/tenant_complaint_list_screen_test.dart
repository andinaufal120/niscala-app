import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

/// The header action that opens the new complaint form.
const _newButton = 'Ajukan';

/// The action of the empty state, which opens the same form.
const _emptyAction = 'Ajukan Keluhan';

/// Five complaints of one tenant:
/// - c1 new and classified by the AI (high urgency),
/// - c2 in progress and still being classified,
/// - c3 new and waiting for classification,
/// - c4 new and not classified,
/// - c5 done and classified by hand (low urgency).
List<Complaint> _sample() => [
  makeComplaint(
    id: 'c1',
    description: 'Keran air di kamar mandi bocor.',
    classification: makeComplaintClassification(
      category: 'Pipa dan air',
      urgency: ComplaintUrgency.high,
    ),
  ),
  makeComplaint(
    id: 'c2',
    description: 'Lampu kamar sering mati.',
    status: ComplaintStatus.inProgress,
    classificationState: ComplaintClassificationState.classifying,
  ),
  makeComplaint(
    id: 'c3',
    description: 'Pintu kamar sulit dikunci.',
    classificationState: ComplaintClassificationState.awaitingClassification,
  ),
  makeComplaint(
    id: 'c4',
    description: 'Jendela berderit saat dibuka.',
    classificationState: ComplaintClassificationState.notClassified,
  ),
  makeComplaint(
    id: 'c5',
    description: 'Stop kontak longgar.',
    status: ComplaintStatus.done,
    classification: makeComplaintClassification(
      category: 'Listrik',
      urgency: ComplaintUrgency.low,
      classifiedByName: 'Siti Pemilik',
    ),
  ),
];

FakeComplaintRepository _repo([List<Complaint>? complaints]) =>
    FakeComplaintRepository(complaints: complaints ?? _sample());

void main() {
  group('header', () {
    testWidgets('is titled Keluhan Saya on the tenant Keluhan tab', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(find.byType(TenantComplaintListScreen), findsOneWidget);
      expect(headerTitle('Keluhan Saya'), findsOneWidget);
      expect(headerTitle('Keluhan'), findsNothing);
      expect(currentPath(tester), '/penyewa/keluhan');
    });

    testWidgets('the bottom navigation tab stays labelled Keluhan', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Keluhan'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('loads the complaints once', (tester) async {
      final repo = _repo();
      await pumpComplaintApp(tester, repo);

      expect(repo.listCalls, 1);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpComplaintApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Keran air di kamar mandi bocor.'), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows the complaints once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await pumpComplaintApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Keran air di kamar mandi bocor.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpComplaintApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Keran air di kamar mandi bocor.'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpComplaintApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the complaints again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await pumpComplaintApp(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Keran air di kamar mandi bocor.'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpComplaintApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('empty', () {
    testWidgets('explains that there are no complaints and offers to add', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo([]));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_emptyAction), findsOneWidget);
    });

    testWidgets('the empty state action opens the form', (tester) async {
      await pumpComplaintApp(tester, _repo([]));

      await tester.tap(find.text(_emptyAction));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/keluhan/baru');
      expect(find.byType(ComplaintFormScreen), findsOneWidget);
    });

    testWidgets('shows no filter chips without any complaint', (tester) async {
      await pumpComplaintApp(tester, _repo([]));

      expect(filterChip('Aktif'), findsNothing);
    });
  });

  group('rows', () {
    testWidgets('shows the active complaints in the order returned', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      final order = [
        'Keran air di kamar mandi bocor.',
        'Lampu kamar sering mati.',
        'Pintu kamar sulit dikunci.',
        'Jendela berderit saat dibuka.',
      ];
      for (final text in order) {
        expect(find.text(text), findsOneWidget);
      }
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          topOf(tester, find.text(order[i])),
          lessThan(topOf(tester, find.text(order[i + 1]))),
        );
      }
    });

    testWidgets('a classified complaint shows its category and urgency', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Tinggi'), findsOneWidget);
    });

    testWidgets('shows the status of each complaint as text', (tester) async {
      await pumpComplaintApp(tester, _repo());

      expect(statusBadge('Baru'), findsNWidgets(3));
      expect(statusBadge('Diproses'), findsOneWidget);
    });

    testWidgets('marks a complaint still being classified', (tester) async {
      await pumpComplaintApp(tester, _repo());

      expect(statusBadge('Sedang Diklasifikasi'), findsOneWidget);
    });

    testWidgets('marks a complaint waiting for classification', (tester) async {
      await pumpComplaintApp(tester, _repo());

      expect(statusBadge('Menunggu Klasifikasi'), findsOneWidget);
    });

    testWidgets('marks a complaint that is not classified', (tester) async {
      await pumpComplaintApp(tester, _repo());

      expect(statusBadge('Belum Diklasifikasi'), findsOneWidget);
    });

    testWidgets('a classified complaint shows no classification state', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo([
          makeComplaint(
            classification: makeComplaintClassification(
              urgency: ComplaintUrgency.medium,
            ),
          ),
        ]),
      );

      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(statusBadge('Menunggu Klasifikasi'), findsNothing);
      expect(statusBadge('Belum Diklasifikasi'), findsNothing);
      expect(statusBadge('Sedang'), findsOneWidget);
    });

    testWidgets('an unclassified complaint shows no category or urgency', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo([
          makeComplaint(
            classificationState: ComplaintClassificationState.classifying,
          ),
        ]),
      );

      for (final label in ['Rendah', 'Sedang', 'Tinggi']) {
        expect(statusBadge(label), findsNothing);
      }
    });

    testWidgets('reads each complaint as a single merged item', (tester) async {
      await pumpComplaintApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Keran air di kamar mandi bocor.');
      expect(label, contains('Keran air di kamar mandi bocor.'));
      expect(label, contains('Baru'));
      expect(label, contains('Pipa dan air'));
      expect(label, contains('Tinggi'));
      expect(label, isNot(contains('Lampu kamar sering mati.')));
      expect(label, isNot(contains('Diproses')));
    });

    testWidgets('the merged reading names the classification state', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Lampu kamar sering mati.');
      expect(label, contains('Diproses'));
      expect(label, contains('Sedang Diklasifikasi'));
    });

    testWidgets('tapping a complaint opens its detail', (tester) async {
      await pumpComplaintApp(tester, _repo());

      await tester.tap(find.text('Lampu kamar sering mati.'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/keluhan/c2');
      final detail = tester.widget<TenantComplaintDetailScreen>(
        find.byType(TenantComplaintDetailScreen),
      );
      expect(detail.complaintId, 'c2');
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await pumpComplaintApp(tester, _repo());
      await tester.tap(find.text('Lampu kamar sering mati.'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/penyewa/keluhan');
      expect(find.byType(TenantComplaintListScreen), findsOneWidget);
    });
  });

  group('new complaint button', () {
    testWidgets('is in the header, at least 48 dp, and opens the form', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(headerAction(_newButton), findsOneWidget);
      expectTargetSize(tester, _newButton);

      await tester.tap(find.text(_newButton));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/keluhan/baru');
      expect(find.byType(ComplaintFormScreen), findsOneWidget);
    });

    testWidgets('Kembali on the form returns to the list', (tester) async {
      await pumpComplaintApp(tester, _repo());
      await tester.tap(find.text(_newButton));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(find.byType(TenantComplaintListScreen), findsOneWidget);
      expect(currentPath(tester), '/penyewa/keluhan');
    });
  });

  group('filter', () {
    testWidgets('offers Aktif and Selesai in the page body', (tester) async {
      await pumpComplaintApp(tester, _repo());

      for (final label in ['Aktif', 'Selesai']) {
        expect(filterChip(label), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ScreenHeader),
            matching: filterChip(label),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('Aktif is selected by default', (tester) async {
      await pumpComplaintApp(tester, _repo());

      expectChipSelected(tester, 'Aktif', selected: true);
      expectChipSelected(tester, 'Selesai', selected: false);
    });

    testWidgets('Aktif shows the new and in progress complaints only', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(find.text('Keran air di kamar mandi bocor.'), findsOneWidget);
      expect(find.text('Lampu kamar sering mati.'), findsOneWidget);
      expect(find.text('Pintu kamar sulit dikunci.'), findsOneWidget);
      expect(find.text('Jendela berderit saat dibuka.'), findsOneWidget);
      expect(find.text('Stop kontak longgar.'), findsNothing);
    });

    testWidgets('Selesai shows the done complaints only', (tester) async {
      await pumpComplaintApp(tester, _repo());

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Stop kontak longgar.'), findsOneWidget);
      expect(find.text('Keran air di kamar mandi bocor.'), findsNothing);
      expect(find.text('Lampu kamar sering mati.'), findsNothing);
      expectChipSelected(tester, 'Selesai', selected: true);
      expectChipSelected(tester, 'Aktif', selected: false);
    });

    testWidgets('a done complaint with a manual classification shows it', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Listrik'), findsOneWidget);
      expect(statusBadge('Selesai'), findsOneWidget);
      expect(statusBadge('Rendah'), findsOneWidget);
    });

    testWidgets('Aktif brings the active complaints back', (tester) async {
      await pumpComplaintApp(tester, _repo());
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();

      expect(find.text('Keran air di kamar mandi bocor.'), findsOneWidget);
      expect(find.text('Stop kontak longgar.'), findsNothing);
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await pumpComplaintApp(tester, _repo());

      for (final label in ['Aktif', 'Selesai']) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('filtering updates in place without loading again', (
      tester,
    ) async {
      final repo = _repo();
      await pumpComplaintApp(tester, repo);

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Aktif'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
      expect(currentPath(tester), '/penyewa/keluhan');
    });

    testWidgets('explains an empty filter result and keeps the chips', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo([
          makeComplaint(
            classificationState: ComplaintClassificationState.classifying,
          ),
        ]),
      );

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Keran air di kamar mandi bocor.'), findsNothing);
      expect(filterChip('Aktif'), findsOneWidget);
      expect(filterChip('Selesai'), findsOneWidget);
      expect(find.textContaining('Tidak ada keluhan'), findsOneWidget);
    });

    testWidgets('explains an empty Aktif filter when all are done', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo([
          makeComplaint(
            status: ComplaintStatus.done,
            classificationState: ComplaintClassificationState.notClassified,
          ),
        ]),
      );

      expect(find.text('Keran air di kamar mandi bocor.'), findsNothing);
      expect(filterChip('Selesai'), findsOneWidget);
      expect(find.textContaining('Tidak ada keluhan'), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('is a tab root with a ScreenHeader and no app bar', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(find.byType(ScreenHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TenantComplaintListScreen),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
    });

    testWidgets('announces the header title as the page heading', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(headerTitle('Keluhan Saya')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the header action is a filled button outside the list', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(
        find.ancestor(
          of: headerAction(_newButton),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: headerAction(_newButton),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });

    testWidgets('the header stays in place when the list scrolls', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo(), largeText: true);
      final before = tester.getRect(find.byType(ScreenHeader));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(ScreenHeader)), before);
      expect(headerAction(_newButton), findsOneWidget);
    });

    testWidgets('every complaint row is a card holding one complaint', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      expect(
        find.descendant(
          of: find.byType(TenantComplaintListScreen),
          matching: find.byType(Card),
        ),
        findsNWidgets(4),
      );
      for (final text in [
        'Keran air di kamar mandi bocor.',
        'Lampu kamar sering mati.',
        'Pintu kamar sulit dikunci.',
        'Jendela berderit saat dibuka.',
      ]) {
        expect(
          find.ancestor(of: find.text(text), matching: find.byType(Card)),
          findsOneWidget,
        );
      }
    });

    testWidgets(
      'each card has a 16 dp radius, a divider border and no shadow',
      (tester) async {
        await pumpComplaintApp(tester, _repo());

        expectCardLook(
          tester,
          find.descendant(
            of: find.byType(TenantComplaintListScreen),
            matching: find.byType(Card),
          ),
        );
      },
    );

    testWidgets('a card holds the status, category and urgency of its row', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      final card = find.ancestor(
        of: find.text('Keran air di kamar mandi bocor.'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: card, matching: statusBadge('Baru')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Pipa dan air')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: statusBadge('Tinggi')),
        findsOneWidget,
      );
    });

    testWidgets('the filtered rows are cards with the same look', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo());

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(TenantComplaintListScreen),
          matching: find.byType(Card),
        ),
        findsOneWidget,
      );
      expectCardLook(
        tester,
        find.descendant(
          of: find.byType(TenantComplaintListScreen),
          matching: find.byType(Card),
        ),
      );
    });
  });

  group('accessibility', () {
    final states = <String, FakeComplaintRepository Function()>{
      'loaded': _repo,
      'with a single complaint': () => _repo([_sample().first]),
      'empty': () => _repo([]),
      'failed': () => _repo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await pumpComplaintApp(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpComplaintApp(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines with the Selesai filter', (tester) async {
      await pumpComplaintApp(tester, _repo());
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the Selesai filter', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo(), largeText: true);
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines when the filter matches nothing', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo([
          makeComplaint(
            classificationState: ComplaintClassificationState.classifying,
          ),
        ]),
      );
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size when the filter matches nothing', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo([
          makeComplaint(
            classificationState: ComplaintClassificationState.classifying,
          ),
        ]),
        largeText: true,
      );
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpComplaintApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpComplaintApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
