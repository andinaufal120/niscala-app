import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

const _description = 'Keran air di kamar mandi bocor sejak kemarin.';
const _refresh = 'Segarkan';

/// The classification states that show no AI result: the complaint is still
/// being classified, or the classification failed or never ran.
const _unclassifiedStates = [
  ComplaintClassificationState.classifying,
  ComplaintClassificationState.awaitingClassification,
  ComplaintClassificationState.notClassified,
];

FakeComplaintRepository _repo([Complaint? complaint]) =>
    FakeComplaintRepository(complaints: [complaint ?? makeComplaint()]);

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  String id = 'c1',
  String query = '',
  bool settle = true,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  repo,
  path: '/penyewa/keluhan/$id$query',
  settle: settle,
  largeText: largeText,
);

Complaint _classified({
  ComplaintUrgency urgency = ComplaintUrgency.high,
  String? classifiedByName,
}) => makeComplaint(
  classification: makeComplaintClassification(
    category: 'Pipa dan air',
    urgency: urgency,
    classifiedByName: classifiedByName,
  ),
);

Complaint _unclassified(ComplaintClassificationState state) =>
    makeComplaint(classificationState: state);

Complaint _withHandlingNote() => makeComplaint(
  status: ComplaintStatus.inProgress,
  classificationState: ComplaintClassificationState.notClassified,
  statusChanges: [
    statusChange(
      ComplaintStatus.inProgress,
      DateTime.utc(2026, 10, 19, 9),
      note: 'Tukang datang besok pagi.',
    ),
  ],
);

void main() {
  group('content', () {
    testWidgets('is titled and loads the complaint of the path', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(find.byType(TenantComplaintDetailScreen), findsOneWidget);
      expect(appBarTitle('Rincian Keluhan'), findsOneWidget);
      expect(repo.calls, contains('get:c1'));
    });

    testWidgets('passes the complaint id of the path to the screen', (
      tester,
    ) async {
      final repo = FakeComplaintRepository(
        complaints: [makeComplaint(id: 'c7')],
      );
      await _open(tester, repo, id: 'c7');

      final screen = tester.widget<TenantComplaintDetailScreen>(
        find.byType(TenantComplaintDetailScreen),
      );
      expect(screen.complaintId, 'c7');
    });

    testWidgets('shows the status, the date and the whole description', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(statusSteps(), findsOneWidget);
      expect(find.textContaining('18 Okt 2026'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
    });

    for (final entry in {
      ComplaintStatus.new_: 'Baru',
      ComplaintStatus.inProgress: 'Diproses',
      ComplaintStatus.done: 'Selesai',
    }.entries) {
      testWidgets('shows the status ${entry.value}', (tester) async {
        await _open(
          tester,
          _repo(
            makeComplaint(
              status: entry.key,
              classificationState: ComplaintClassificationState.notClassified,
            ),
          ),
        );

        expect(
          tester.widget<ComplaintStatusSteps>(statusSteps()).status,
          entry.key,
        );
        expect(
          find.descendant(of: statusSteps(), matching: find.text(entry.value)),
          findsOneWidget,
        );
      });
    }

    testWidgets('shows a long description in full', (tester) async {
      final long = 'Kebocoran ' * 40;
      await _open(tester, _repo(makeComplaint(description: long.trim())));

      expect(find.text(long.trim()), findsOneWidget);
    });

    testWidgets('shows no confirmation when opened from the list', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Keluhan terkirim.'), findsNothing);
    });

    testWidgets('shows the confirmation when opened right after saving', (
      tester,
    ) async {
      await _open(tester, _repo(), query: '?terkirim=1');

      expect(find.text('Keluhan terkirim.'), findsOneWidget);
    });

    testWidgets('exposes the confirmation as a live region', (tester) async {
      await _open(tester, _repo(), query: '?terkirim=1');

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Keluhan terkirim.')),
          isSemantics(isLiveRegion: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('handling notes', () {
    testWidgets('shows each status change with its date and note', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(
          makeComplaint(
            status: ComplaintStatus.done,
            classificationState: ComplaintClassificationState.notClassified,
            statusChanges: [
              statusChange(
                ComplaintStatus.new_,
                DateTime.utc(2026, 10, 18, 12),
              ),
              statusChange(
                ComplaintStatus.inProgress,
                DateTime.utc(2026, 10, 19, 9),
                note: 'Tukang datang besok pagi.',
              ),
              statusChange(
                ComplaintStatus.done,
                DateTime.utc(2026, 10, 20, 15),
                note: 'Keran sudah diganti.',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tukang datang besok pagi.'), findsOneWidget);
      expect(find.text('Keran sudah diganti.'), findsOneWidget);
      expect(find.textContaining('19 Okt 2026'), findsOneWidget);
      expect(find.textContaining('20 Okt 2026'), findsOneWidget);
    });

    testWidgets('shows the notes in the order returned', (tester) async {
      await _open(
        tester,
        _repo(
          makeComplaint(
            status: ComplaintStatus.done,
            classificationState: ComplaintClassificationState.notClassified,
            statusChanges: [
              statusChange(
                ComplaintStatus.inProgress,
                DateTime.utc(2026, 10, 19, 9),
                note: 'Catatan pertama.',
              ),
              statusChange(
                ComplaintStatus.done,
                DateTime.utc(2026, 10, 20, 15),
                note: 'Catatan kedua.',
              ),
            ],
          ),
        ),
      );

      expect(
        topOf(tester, find.text('Catatan pertama.')),
        lessThan(topOf(tester, find.text('Catatan kedua.'))),
      );
    });

    testWidgets('a status change without a note shows only its status', (
      tester,
    ) async {
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
              ),
            ],
          ),
        ),
      );

      expect(find.textContaining('19 Okt 2026'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('a complaint without status changes shows no notes', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.notClassified)),
      );

      expect(find.textContaining('Tukang'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('classification', () {
    testWidgets('a classified complaint shows its category and urgency', (
      tester,
    ) async {
      await _open(tester, _repo(_classified()));

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Tinggi'), findsOneWidget);
    });

    for (final entry in {
      ComplaintUrgency.low: 'Rendah',
      ComplaintUrgency.medium: 'Sedang',
      ComplaintUrgency.high: 'Tinggi',
    }.entries) {
      testWidgets('shows the urgency ${entry.value} as text', (tester) async {
        await _open(tester, _repo(_classified(urgency: entry.key)));

        expect(statusBadge(entry.value), findsOneWidget);
      });
    }

    testWidgets('AI output carries the disclaimer', (tester) async {
      await _open(tester, _repo(_classified()));

      expect(aiDisclaimer(), findsOneWidget);
    });

    testWidgets('a classification set by management has no AI disclaimer', (
      tester,
    ) async {
      await _open(tester, _repo(_classified(classifiedByName: 'Siti Pemilik')));

      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(aiDisclaimer(), findsNothing);
    });

    testWidgets('a classified complaint shows no classification state', (
      tester,
    ) async {
      await _open(tester, _repo(_classified()));

      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(statusBadge('Menunggu Klasifikasi'), findsNothing);
      expect(statusBadge('Belum Diklasifikasi'), findsNothing);
      expect(find.text(_refresh), findsNothing);
    });

    testWidgets('a classified complaint has no refresh action', (tester) async {
      await _open(tester, _repo(_classified()));

      expect(actionButtons(), findsNothing);
    });
  });

  group('classification state', () {
    testWidgets('classifying shows its label and no AI output', (tester) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.classifying)),
      );

      expect(statusBadge('Sedang Diklasifikasi'), findsOneWidget);
      expect(find.text('Pipa dan air'), findsNothing);
      expect(aiDisclaimer(), findsNothing);
    });

    testWidgets('classifying offers a refresh action of at least 48 dp', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.classifying)),
      );

      expect(find.text(_refresh), findsOneWidget);
      expectTargetSize(tester, _refresh);
    });

    testWidgets('refreshing loads the complaint again and shows the result', (
      tester,
    ) async {
      final repo = _repo(
        _unclassified(ComplaintClassificationState.classifying),
      );
      await _open(tester, repo);
      expect(repo.getCalls, 1);

      repo.complaints[0] = _classified(urgency: ComplaintUrgency.medium);
      await tester.tap(find.text(_refresh));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.text('Pipa dan air'), findsOneWidget);
      expect(statusBadge('Sedang'), findsOneWidget);
      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(find.text(_refresh), findsNothing);
      expect(aiDisclaimer(), findsOneWidget);
    });

    testWidgets('refreshing keeps showing classifying while the AI works', (
      tester,
    ) async {
      final repo = _repo(
        _unclassified(ComplaintClassificationState.classifying),
      );
      await _open(tester, repo);

      await tester.tap(find.text(_refresh));
      await tester.pumpAndSettle();

      expect(statusBadge('Sedang Diklasifikasi'), findsOneWidget);
      expect(find.text(_refresh), findsOneWidget);
    });

    testWidgets('refreshing can end in awaiting classification', (
      tester,
    ) async {
      final repo = _repo(
        _unclassified(ComplaintClassificationState.classifying),
      );
      await _open(tester, repo);

      repo.complaints[0] = _unclassified(
        ComplaintClassificationState.awaitingClassification,
      );
      await tester.tap(find.text(_refresh));
      await tester.pumpAndSettle();

      expect(statusBadge('Menunggu Klasifikasi'), findsOneWidget);
      expect(find.text(_refresh), findsNothing);
    });

    testWidgets('a failed refresh shows the failure with a retry', (
      tester,
    ) async {
      final repo = _repo(
        _unclassified(ComplaintClassificationState.classifying),
      );
      await _open(tester, repo);

      repo.getScript.always = const ApiFailure.network();
      await tester.tap(find.text(_refresh));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('awaiting classification shows its label, no AI output', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(
          _unclassified(ComplaintClassificationState.awaitingClassification),
        ),
      );

      expect(statusBadge('Menunggu Klasifikasi'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
      expect(aiDisclaimer(), findsNothing);
      expect(find.text(_refresh), findsNothing);
    });

    testWidgets('not classified shows its label, no AI output', (tester) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.notClassified)),
      );

      expect(statusBadge('Belum Diklasifikasi'), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
      expect(aiDisclaimer(), findsNothing);
      expect(find.text(_refresh), findsNothing);
    });

    for (final state in [
      ComplaintClassificationState.awaitingClassification,
      ComplaintClassificationState.notClassified,
    ]) {
      testWidgets('$state tells the tenant the complaint is saved', (
        tester,
      ) async {
        await _open(tester, _repo(_unclassified(state)));

        expect(find.textContaining('tersimpan'), findsOneWidget);
      });
    }

    for (final state in ComplaintClassificationState.values) {
      testWidgets('the confirmation shows when the state is $state', (
        tester,
      ) async {
        await _open(tester, _repo(_unclassified(state)), query: '?terkirim=1');

        expect(find.text('Keluhan terkirim.'), findsOneWidget);
      });
    }
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
      final repo = _repo()..getScript.gate = gate;
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

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the complaint again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      expect(repo.getCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_description), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('keeps the white app bar titled Rincian Keluhan', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(appBarTitle('Rincian Keluhan'), findsOneWidget);
      expectDetailAppBar(tester);
    });

    testWidgets('puts the message in a section card', (tester) async {
      await _open(tester, _repo());

      expect(
        find.ancestor(
          of: find.text(_description),
          matching: find.byType(SectionCard),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'puts the status history in a section card titled Riwayat status',
      (tester) async {
        await _open(tester, _repo(_withHandlingNote()));

        expectSectionCard(tester, 'Riwayat status');
        expect(
          find.descendant(
            of: sectionCardOf('Riwayat status'),
            matching: find.text('Tukang datang besok pagi.'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'puts an AI classification in an emphasis card titled Klasifikasi',
      (tester) async {
        await _open(tester, _repo(_classified()));

        expectEmphasisSectionCard(tester, 'Klasifikasi');
        expect(
          find.descendant(
            of: sectionCardOf('Klasifikasi'),
            matching: find.text('Pipa dan air'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('puts a manual classification in the emphasis card too', (
      tester,
    ) async {
      await _open(tester, _repo(_classified(classifiedByName: 'Siti Pemilik')));

      expectEmphasisSectionCard(tester, 'Klasifikasi');
    });

    testWidgets('the AI disclaimer sits inside the classification card', (
      tester,
    ) async {
      await _open(tester, _repo(_classified()));

      expect(
        find.descendant(
          of: sectionCardOf('Klasifikasi'),
          matching: aiDisclaimer(),
        ),
        findsOneWidget,
      );
    });

    for (final state in _unclassifiedStates) {
      testWidgets('puts the classification state $state in the emphasis card', (
        tester,
      ) async {
        await _open(tester, _repo(_unclassified(state)));

        expectEmphasisSectionCard(tester, 'Klasifikasi');
        expect(
          find.descendant(
            of: sectionCardOf('Klasifikasi'),
            matching: find.byType(StatusBadge),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('the refresh action sits inside the classification card', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.classifying)),
      );

      expect(
        find.descendant(
          of: sectionCardOf('Klasifikasi'),
          matching: find.text(_refresh),
        ),
        findsOneWidget,
      );
    });

    testWidgets('every section card keeps the card look when classified', (
      tester,
    ) async {
      await _open(tester, _repo(_classified()));

      expectSectionCardLooks(tester);
    });

    testWidgets('every section card keeps the card look with handling notes', (
      tester,
    ) async {
      await _open(tester, _repo(_withHandlingNote()));

      expectSectionCardLooks(tester);
    });
  });

  group('accessibility', () {
    final states = <String, FakeComplaintRepository Function()>{
      'classified': () => _repo(_classified()),
      'classified by management': () =>
          _repo(_classified(classifiedByName: 'Siti Pemilik')),
      'classifying': () =>
          _repo(_unclassified(ComplaintClassificationState.classifying)),
      'awaiting classification': () => _repo(
        _unclassified(ComplaintClassificationState.awaitingClassification),
      ),
      'not classified': () =>
          _repo(_unclassified(ComplaintClassificationState.notClassified)),
      'with handling notes': () => _repo(_withHandlingNote()),
      'failed': () => _repo()..getScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await _open(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines right after saving', (tester) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.classifying)),
        query: '?terkirim=1',
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size right after saving', (tester) async {
      await _open(
        tester,
        _repo(_unclassified(ComplaintClassificationState.classifying)),
        query: '?terkirim=1',
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });

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
