import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

const _description = 'Keran air di kamar mandi bocor sejak kemarin.';
const _refresh = 'Segarkan';
const _roles = [UserRole.owner, UserRole.manager];

FakeComplaintRepository _repo([Complaint? complaint]) =>
    FakeComplaintRepository(complaints: [complaint ?? makeComplaint()]);

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  UserRole role = UserRole.owner,
  String id = 'c1',
  bool settle = true,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  repo,
  role: role,
  path: '/keluhan/$id',
  settle: settle,
  largeText: largeText,
);

Complaint _ai({
  ComplaintUrgency urgency = ComplaintUrgency.high,
  String? suggestedAction = 'Panggil tukang ledeng.',
}) => makeComplaint(
  classification: makeComplaintClassification(
    category: 'Pipa dan air',
    urgency: urgency,
    suggestedAction: suggestedAction,
  ),
);

Complaint _manual() => makeComplaint(
  classification: makeComplaintClassification(
    category: 'Pipa dan air',
    urgency: ComplaintUrgency.low,
    suggestedAction: null,
    classifiedByName: 'Siti Pemilik',
  ),
);

Complaint _state(ComplaintClassificationState state) =>
    makeComplaint(classificationState: state);

Complaint _withheld() => makeComplaint(classificationWithheld: true);

void main() {
  group('content', () {
    for (final role in _roles) {
      testWidgets('a $role sees the complaint titled Rincian Keluhan', (
        tester,
      ) async {
        final repo = _repo(_ai());
        await _open(tester, repo, role: role);

        expect(find.byType(ManagementComplaintDetailScreen), findsOneWidget);
        expect(appBarTitle('Rincian Keluhan'), findsOneWidget);
        expect(repo.calls, contains('get:c1'));
        expect(currentPath(tester), '/keluhan/c1');
      });
    }

    testWidgets('shows the tenant name, room, timestamp and message', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.textContaining('08'), findsOneWidget);
      expect(find.textContaining('18 Okt 2026'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
    });

    for (final entry in {
      ComplaintStatus.new_: 'Baru',
      ComplaintStatus.inProgress: 'Diproses',
      ComplaintStatus.done: 'Selesai',
    }.entries) {
      testWidgets('shows the status ${entry.value} as text', (tester) async {
        await _open(
          tester,
          _repo(
            makeComplaint(
              status: entry.key,
              classificationState: ComplaintClassificationState.notClassified,
            ),
          ),
        );

        expect(statusBadge(entry.value), findsOneWidget);
      });
    }

    testWidgets('shows the status history with handling notes', (tester) async {
      await _open(
        tester,
        _repo(
          makeComplaint(
            status: ComplaintStatus.inProgress,
            classificationState: ComplaintClassificationState.notClassified,
            statusChanges: [
              statusChange(
                ComplaintStatus.inProgress,
                DateTime.utc(2026, 10, 19, 9),
                note: 'Tukang datang besok pagi.',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tukang datang besok pagi.'), findsOneWidget);
      expect(find.textContaining('19 Okt 2026'), findsOneWidget);
    });

    testWidgets('shows a long message in full', (tester) async {
      final long = ('Kebocoran ' * 40).trim();
      await _open(
        tester,
        _repo(
          makeComplaint(
            description: long,
            classificationState: ComplaintClassificationState.notClassified,
          ),
        ),
      );

      expect(find.text(long), findsOneWidget);
    });
  });

  group('reading order', () {
    testWidgets('shows the status, then the classification, then the message', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      final status = topOf(tester, statusBadge('Baru'));
      final classification = topOf(tester, find.text('Pipa dan air'));
      final tenant = topOf(tester, find.text('Budi Santoso'));
      final message = topOf(tester, find.text(_description));
      expect(status, lessThan(classification));
      expect(classification, lessThan(tenant));
      expect(tenant, lessThan(message));
    });

    for (final state in ComplaintClassificationState.values) {
      testWidgets('keeps the order when the state is $state', (tester) async {
        await _open(tester, _repo(_state(state)));

        final status = topOf(tester, statusBadge('Baru'));
        final classification = topOf(
          tester,
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.data != null &&
                w.data ==
                    switch (state) {
                      ComplaintClassificationState.classifying =>
                        'Sedang Diklasifikasi',
                      ComplaintClassificationState.awaitingClassification =>
                        'Menunggu Klasifikasi',
                      _ => 'Belum Diklasifikasi',
                    },
          ),
        );
        final message = topOf(tester, find.text(_description));
        expect(status, lessThan(classification));
        expect(classification, lessThan(message));
      });
    }

    testWidgets('keeps the order when the AI result is withheld', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      final status = topOf(tester, statusBadge('Baru'));
      final note = topOf(tester, subscriptionNote());
      final message = topOf(tester, find.text(_description));
      expect(status, lessThan(note));
      expect(note, lessThan(message));
    });
  });

  group('read only', () {
    testWidgets('offers no action on a classified complaint', (tester) async {
      await _open(tester, _repo(_ai()));

      expect(actionButtons(), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Ubah Status'), findsNothing);
    });

    for (final state in [
      ComplaintClassificationState.awaitingClassification,
      ComplaintClassificationState.notClassified,
    ]) {
      testWidgets('offers no action when the state is $state', (tester) async {
        await _open(tester, _repo(_state(state)));

        expect(actionButtons(), findsNothing);
        expect(find.byType(TextField), findsNothing);
      });
    }

    testWidgets('offers no action when the AI result is withheld', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      expect(actionButtons(), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('AI classification', () {
    testWidgets('shows category, urgency and suggested action', (tester) async {
      await _open(tester, _repo(_ai()));

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Tinggi'), findsOneWidget);
      expect(find.text('Panggil tukang ledeng.'), findsOneWidget);
    });

    for (final entry in {
      ComplaintUrgency.low: 'Rendah',
      ComplaintUrgency.medium: 'Sedang',
      ComplaintUrgency.high: 'Tinggi',
    }.entries) {
      testWidgets('shows the urgency ${entry.value} as text', (tester) async {
        await _open(tester, _repo(_ai(urgency: entry.key)));

        expect(statusBadge(entry.value), findsOneWidget);
      });
    }

    testWidgets('shows the disclaimer under AI output', (tester) async {
      await _open(tester, _repo(_ai()));

      expect(aiDisclaimer(), findsOneWidget);
    });

    testWidgets('copes with a missing suggested action', (tester) async {
      await _open(tester, _repo(_ai(suggestedAction: null)));

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      expect(aiDisclaimer(), findsOneWidget);
    });

    testWidgets('a classified complaint shows no classification state', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(statusBadge('Menunggu Klasifikasi'), findsNothing);
      expect(statusBadge('Belum Diklasifikasi'), findsNothing);
      expect(subscriptionNote(), findsNothing);
    });
  });

  group('manual classification', () {
    testWidgets('shows category and urgency', (tester) async {
      await _open(tester, _repo(_manual()));

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Rendah'), findsOneWidget);
    });

    testWidgets('names who classified it', (tester) async {
      await _open(tester, _repo(_manual()));

      expect(find.textContaining('Siti Pemilik'), findsOneWidget);
    });

    testWidgets('has no AI disclaimer because it is not AI output', (
      tester,
    ) async {
      await _open(tester, _repo(_manual()));

      expect(aiDisclaimer(), findsNothing);
    });

    testWidgets('is shown without the subscription note', (tester) async {
      await _open(tester, _repo(_manual()));

      expect(subscriptionNote(), findsNothing);
    });
  });

  group('classification state', () {
    testWidgets('classifying shows its label and no AI output', (tester) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.classifying)),
      );

      expect(statusBadge('Sedang Diklasifikasi'), findsOneWidget);
      expect(find.text('Pipa dan air'), findsNothing);
      expect(aiDisclaimer(), findsNothing);
      expect(subscriptionNote(), findsNothing);
    });

    testWidgets('classifying offers a refresh action of at least 48 dp', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.classifying)),
      );

      expect(find.text(_refresh), findsOneWidget);
      expectTargetSize(tester, _refresh);
    });

    testWidgets('refreshing loads the complaint again and shows the result', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.classifying));
      await _open(tester, repo);
      expect(repo.getCalls, 1);

      repo.complaints[0] = _ai(urgency: ComplaintUrgency.medium);
      await tester.tap(find.text(_refresh));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Sedang'), findsOneWidget);
      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(find.text(_refresh), findsNothing);
      expect(aiDisclaimer(), findsOneWidget);
    });

    testWidgets('refreshing can end in awaiting classification', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.classifying));
      await _open(tester, repo);

      repo.complaints[0] = _state(
        ComplaintClassificationState.awaitingClassification,
      );
      await tester.tap(find.text(_refresh));
      await tester.pumpAndSettle();

      expect(statusBadge('Menunggu Klasifikasi'), findsOneWidget);
      expect(find.text(_refresh), findsNothing);
    });

    testWidgets('awaiting classification shows its label and no refresh', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.awaitingClassification)),
      );

      expect(statusBadge('Menunggu Klasifikasi'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
      expect(find.text(_refresh), findsNothing);
      expect(aiDisclaimer(), findsNothing);
    });

    testWidgets('not classified shows its label and no refresh', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.notClassified)),
      );

      expect(statusBadge('Belum Diklasifikasi'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
      expect(find.text(_refresh), findsNothing);
      expect(aiDisclaimer(), findsNothing);
    });
  });

  group('withheld AI result', () {
    testWidgets('shows the subscription note instead of the classification', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      expect(subscriptionNote(), findsOneWidget);
      expect(aiDisclaimer(), findsNothing);
      for (final label in ['Rendah', 'Sedang', 'Tinggi']) {
        expect(statusBadge(label), findsNothing);
      }
    });

    testWidgets('the rest of the screen still works', (tester) async {
      await _open(tester, _repo(_withheld()));

      expect(statusBadge('Baru'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
    });

    testWidgets('shows no classification state beside the note', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(statusBadge('Menunggu Klasifikasi'), findsNothing);
      expect(statusBadge('Belum Diklasifikasi'), findsNothing);
    });

    testWidgets('a manual classification is shown without a note', (
      tester,
    ) async {
      await _open(tester, _repo(_manual()));

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(subscriptionNote(), findsNothing);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text(_description), findsNothing);
    });

    testWidgets('shows the complaint once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo(_ai())..getScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_description), findsOneWidget);
    });

    testWidgets('shows the Indonesian message for an unknown complaint', (
      tester,
    ) async {
      await _open(tester, _repo(), id: 'nope');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Keluhan tidak ditemukan.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('shows the Indonesian message of a network failure', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_description), findsNothing);
    });

    testWidgets('a forbidden response shows its Indonesian message', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _open(tester, repo);

      expect(find.text(errorMessage('FORBIDDEN')), findsOneWidget);
    });

    testWidgets('Coba lagi loads the complaint again', (tester) async {
      final repo = _repo(_ai())
        ..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      expect(repo.getCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_description), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, FakeComplaintRepository Function()>{
      'classified by the AI': () => _repo(_ai()),
      'classified by management': () => _repo(_manual()),
      'classifying': () =>
          _repo(_state(ComplaintClassificationState.classifying)),
      'awaiting classification': () =>
          _repo(_state(ComplaintClassificationState.awaitingClassification)),
      'not classified': () =>
          _repo(_state(ComplaintClassificationState.notClassified)),
      'withheld': () => _repo(_withheld()),
      'with handling notes': () => _repo(
        makeComplaint(
          status: ComplaintStatus.inProgress,
          classificationState: ComplaintClassificationState.notClassified,
          statusChanges: [
            statusChange(
              ComplaintStatus.inProgress,
              DateTime.utc(2026, 10, 19, 9),
              note: 'Tukang datang besok pagi.',
            ),
          ],
        ),
      ),
      'failed': () => _repo()..getScript.always = const ApiFailure.network(),
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

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
