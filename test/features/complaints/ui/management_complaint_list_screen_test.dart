import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

const _roles = [UserRole.owner, UserRole.manager];

/// Six complaints in the order the API returns them (urgency, then time), which
/// is deliberately not the order of their ids:
/// - c3 new, AI high urgency, Dewi room 12,
/// - c1 in progress, AI medium urgency, Budi room 08,
/// - c6 new, classified by hand (low urgency),
/// - c2 new, still being classified,
/// - c5 new, AI result withheld (no subscription),
/// - c4 done, not classified.
List<Complaint> _sample() => [
  makeComplaint(
    id: 'c3',
    description: 'Atap kamar mandi bocor deras.',
    tenantName: 'Dewi Lestari',
    roomNumber: '12',
    classification: makeComplaintClassification(
      category: 'Pipa dan air',
      urgency: ComplaintUrgency.high,
      suggestedAction: 'Panggil tukang ledeng.',
    ),
  ),
  makeComplaint(
    id: 'c1',
    description: 'Lampu kamar sering mati.',
    status: ComplaintStatus.inProgress,
    classification: makeComplaintClassification(
      category: 'Listrik',
      urgency: ComplaintUrgency.medium,
    ),
  ),
  makeComplaint(
    id: 'c6',
    description: 'Cat dinding mengelupas.',
    tenantName: 'Rina Putri',
    roomNumber: '15',
    classification: makeComplaintClassification(
      category: 'Bangunan',
      urgency: ComplaintUrgency.low,
      classifiedByName: 'Siti Pemilik',
    ),
  ),
  makeComplaint(
    id: 'c2',
    description: 'Pintu kamar sulit dikunci.',
    tenantName: 'Sari Wulandari',
    roomNumber: '09',
    classificationState: ComplaintClassificationState.classifying,
  ),
  makeComplaint(
    id: 'c5',
    description: 'Kipas angin berisik.',
    tenantName: 'Tono',
    roomNumber: '10',
    classificationWithheld: true,
  ),
  makeComplaint(
    id: 'c4',
    description: 'Jendela berderit saat dibuka.',
    status: ComplaintStatus.done,
    tenantName: 'Wati',
    roomNumber: '11',
    classificationState: ComplaintClassificationState.notClassified,
  ),
];

const _order = [
  'Atap kamar mandi bocor deras.',
  'Lampu kamar sering mati.',
  'Cat dinding mengelupas.',
  'Pintu kamar sulit dikunci.',
  'Kipas angin berisik.',
  'Jendela berderit saat dibuka.',
];

FakeComplaintRepository _repo([List<Complaint>? complaints]) =>
    FakeComplaintRepository(complaints: complaints ?? _sample());

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  repo,
  role: role,
  settle: settle,
  largeText: largeText,
);

void main() {
  group('header', () {
    for (final role in _roles) {
      testWidgets('a $role sees the list titled Keluhan', (tester) async {
        final repo = _repo();
        await _open(tester, repo, role: role);

        expect(find.byType(ManagementComplaintListScreen), findsOneWidget);
        expect(appBarTitle('Keluhan'), findsOneWidget);
        expect(currentPath(tester), '/keluhan');
        expect(repo.listCalls, 1);
      });
    }
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text(_order.first), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows the complaints once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_order.first), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text(_order.first), findsNothing);
    });

    testWidgets('a forbidden response shows its Indonesian message', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _open(tester, repo);

      expect(find.text(errorMessage('FORBIDDEN')), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the complaints again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_order.first), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('empty', () {
    for (final role in _roles) {
      testWidgets('a $role sees an explanatory empty state', (tester) async {
        await _open(tester, _repo([]), role: role);

        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.byType(ErrorView), findsNothing);
      });
    }

    testWidgets('offers no way to add a complaint', (tester) async {
      await _open(tester, _repo([]));

      expect(find.text('Ajukan Keluhan'), findsNothing);
      expect(actionButtons(), findsNothing);
    });

    testWidgets('shows no filter chips without any complaint', (tester) async {
      await _open(tester, _repo([]));

      expect(filterChip('Semua'), findsNothing);
    });
  });

  group('rows', () {
    testWidgets('shows every complaint in the order returned', (tester) async {
      await _open(tester, _repo());

      for (final text in _order) {
        expect(find.text(text), findsOneWidget);
      }
      for (var i = 0; i < _order.length - 1; i++) {
        expect(
          topOf(tester, find.text(_order[i])),
          lessThan(topOf(tester, find.text(_order[i + 1]))),
          reason: '${_order[i]} should come before ${_order[i + 1]}',
        );
      }
    });

    testWidgets('does not sort the complaints again', (tester) async {
      final reversed = _sample().reversed.toList();
      await _open(tester, _repo(reversed));

      expect(
        topOf(tester, find.text(_order.last)),
        lessThan(topOf(tester, find.text(_order.first))),
      );
    });

    testWidgets('shows the room, tenant, property and date of each row', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('Dewi Lestari'), findsOneWidget);
      expect(find.textContaining('Kos Melati'), findsWidgets);
      expect(find.textContaining('18 Okt 2026'), findsWidgets);
    });

    testWidgets('an AI classified row shows category and urgency', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Tinggi'), findsOneWidget);
      expect(find.text('Listrik'), findsOneWidget);
      expect(statusBadge('Sedang'), findsOneWidget);
    });

    testWidgets('a manually classified row shows category and urgency', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Bangunan'), findsOneWidget);
      expect(statusBadge('Rendah'), findsOneWidget);
    });

    testWidgets('an unclassified row shows its state instead', (tester) async {
      await _open(tester, _repo());

      expect(statusBadge('Sedang Diklasifikasi'), findsOneWidget);
      expect(statusBadge('Belum Diklasifikasi'), findsOneWidget);
    });

    testWidgets('a row waiting for classification shows that state', (
      tester,
    ) async {
      await _open(
        tester,
        _repo([
          makeComplaint(
            classificationState:
                ComplaintClassificationState.awaitingClassification,
          ),
        ]),
      );

      expect(statusBadge('Menunggu Klasifikasi'), findsOneWidget);
    });

    testWidgets('shows the status of each complaint as text', (tester) async {
      await _open(tester, _repo());

      expect(statusBadge('Baru'), findsNWidgets(4));
      expect(statusBadge('Diproses'), findsOneWidget);
      expect(statusBadge('Selesai'), findsOneWidget);
    });

    testWidgets(
      'a withheld row shows the subscription note, not the AI result',
      (tester) async {
        await _open(
          tester,
          _repo([
            makeComplaint(
              classificationWithheld: true,
              classificationState: null,
            ),
          ]),
        );

        expect(subscriptionNote(), findsOneWidget);
        for (final label in ['Rendah', 'Sedang', 'Tinggi']) {
          expect(statusBadge(label), findsNothing);
        }
      },
    );

    testWidgets('a withheld row does not show a classification state', (
      tester,
    ) async {
      await _open(tester, _repo([makeComplaint(classificationWithheld: true)]));

      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(statusBadge('Menunggu Klasifikasi'), findsNothing);
      expect(statusBadge('Belum Diklasifikasi'), findsNothing);
    });

    testWidgets(
      'a manual classification is still shown beside a withheld one',
      (tester) async {
        await _open(tester, _repo());

        expect(find.text('Bangunan'), findsOneWidget);
        expect(subscriptionNote(), findsOneWidget);
      },
    );

    testWidgets('a list without a withheld row shows no subscription note', (
      tester,
    ) async {
      await _open(tester, _repo([_sample().first]));

      expect(subscriptionNote(), findsNothing);
    });

    testWidgets('reads each complaint as a single merged item', (tester) async {
      await _open(tester, _repo());

      final label = semanticsLabelOf(tester, 'Atap kamar mandi bocor deras.');
      expect(label, contains('Atap kamar mandi bocor deras.'));
      expect(label, contains('Dewi Lestari'));
      expect(label, contains('12'));
      expect(label, contains('Baru'));
      expect(label, contains('Pipa dan air'));
      expect(label, contains('Tinggi'));
      expect(label, isNot(contains('Lampu kamar sering mati.')));
    });

    testWidgets('the merged reading of a withheld row has the note', (
      tester,
    ) async {
      await _open(tester, _repo());

      final label = semanticsLabelOf(tester, 'Kipas angin berisik.');
      expect(label, contains('langganan'));
    });

    testWidgets('tapping a complaint opens its detail', (tester) async {
      await _open(tester, _repo());

      await tester.tap(find.text('Lampu kamar sering mati.'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/keluhan/c1');
      final detail = tester.widget<ManagementComplaintDetailScreen>(
        find.byType(ManagementComplaintDetailScreen),
      );
      expect(detail.complaintId, 'c1');
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await _open(tester, _repo());
      await tester.tap(find.text('Lampu kamar sering mati.'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/keluhan');
      expect(find.byType(ManagementComplaintListScreen), findsOneWidget);
    });
  });

  group('filter', () {
    testWidgets('offers Semua, Baru, Diproses and Selesai in the body', (
      tester,
    ) async {
      await _open(tester, _repo());

      for (final label in ['Semua', 'Baru', 'Diproses', 'Selesai']) {
        expect(filterChip(label), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: filterChip(label)),
          findsNothing,
        );
      }
    });

    testWidgets('Semua is selected by default and shows every complaint', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectChipSelected(tester, 'Semua', selected: true);
      for (final label in ['Baru', 'Diproses', 'Selesai']) {
        expectChipSelected(tester, label, selected: false);
      }
      for (final text in _order) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      for (final label in ['Semua', 'Baru', 'Diproses', 'Selesai']) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('Baru shows only the new complaints, in order', (tester) async {
      await _open(tester, _repo());

      await tester.tap(filterChip('Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Atap kamar mandi bocor deras.'), findsOneWidget);
      expect(find.text('Cat dinding mengelupas.'), findsOneWidget);
      expect(find.text('Pintu kamar sulit dikunci.'), findsOneWidget);
      expect(find.text('Kipas angin berisik.'), findsOneWidget);
      expect(find.text('Lampu kamar sering mati.'), findsNothing);
      expect(find.text('Jendela berderit saat dibuka.'), findsNothing);
      expect(
        topOf(tester, find.text('Atap kamar mandi bocor deras.')),
        lessThan(topOf(tester, find.text('Cat dinding mengelupas.'))),
      );
      expectChipSelected(tester, 'Baru', selected: true);
      expectChipSelected(tester, 'Semua', selected: false);
    });

    testWidgets('Diproses shows only the complaints in progress', (
      tester,
    ) async {
      await _open(tester, _repo());

      await tester.tap(filterChip('Diproses'));
      await tester.pumpAndSettle();

      expect(find.text('Lampu kamar sering mati.'), findsOneWidget);
      expect(find.text('Atap kamar mandi bocor deras.'), findsNothing);
      expect(find.text('Jendela berderit saat dibuka.'), findsNothing);
    });

    testWidgets('Selesai shows only the done complaints', (tester) async {
      await _open(tester, _repo());

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Jendela berderit saat dibuka.'), findsOneWidget);
      expect(find.text('Atap kamar mandi bocor deras.'), findsNothing);
      expect(find.text('Lampu kamar sering mati.'), findsNothing);
    });

    testWidgets('Semua brings every complaint back', (tester) async {
      await _open(tester, _repo());
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Semua'));
      await tester.pumpAndSettle();

      for (final text in _order) {
        expect(find.text(text), findsOneWidget);
      }
      expectChipSelected(tester, 'Semua', selected: true);
    });

    testWidgets('filtering updates in place without loading again', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await tester.tap(filterChip('Baru'));
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
      expect(currentPath(tester), '/keluhan');
    });

    testWidgets('explains an empty filter result and keeps the chips', (
      tester,
    ) async {
      await _open(
        tester,
        _repo([
          makeComplaint(
            classificationState: ComplaintClassificationState.classifying,
          ),
        ]),
      );

      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      expect(
        find.text('Keran air di kamar mandi bocor sejak kemarin.'),
        findsNothing,
      );
      expect(find.textContaining('Tidak ada keluhan'), findsOneWidget);
      expect(filterChip('Semua'), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, FakeComplaintRepository Function()>{
      'loaded': _repo,
      'with a single complaint': () => _repo([_sample().first]),
      'withheld': () => _repo([_sample()[4]]),
      'empty': () => _repo([]),
      'failed': () => _repo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      for (final role in _roles) {
        testWidgets('meets the guidelines when ${entry.key} for a $role', (
          tester,
        ) async {
          await _open(tester, entry.value(), role: role);

          await expectMeetsA11yGuidelines(tester);
        });
      }

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    for (final label in ['Baru', 'Diproses', 'Selesai']) {
      testWidgets('meets the guidelines with the $label filter', (
        tester,
      ) async {
        await _open(tester, _repo());
        await tester.tap(filterChip(label));
        await tester.pumpAndSettle();

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('fits at large text size with the Baru filter', (tester) async {
      await _open(tester, _repo(), largeText: true);
      await tester.tap(filterChip('Baru'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines when the filter matches nothing', (
      tester,
    ) async {
      await _open(
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

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await _open(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
