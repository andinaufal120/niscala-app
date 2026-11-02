import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/ui/payment_pattern_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'payment_review_ui_helpers.dart';

const _title = 'Risiko Pembayaran';
const _path = '/pembayaran/risiko?properti=p1';
const _disclaimer = 'Ringkasan dibuat dengan AI dan bisa keliru.';
const _unavailable = 'Ringkasan belum tersedia';
const _subscriptionNote = 'Ringkasan AI memerlukan langganan aktif.';
const _atRisk = 'Berisiko';
const _emptyMessage = 'Belum ada penyewa dengan sewa aktif';
const _hiddenSummary = 'Ringkasan rahasia yang tidak boleh tampil.';

/// Three tenants of Kos Melati in an order that is neither alphabetical nor by
/// risk:
/// - Rina Putri, room 15: at risk, no summary yet,
/// - Budi Santoso, room 08: not at risk, with a summary,
/// - Wati, room 11: at risk, with a summary, with arrears.
List<PaymentPattern> _melatiPatterns() => [
  makePaymentPattern(
    tenantId: 't3',
    tenantName: 'Rina Putri',
    roomNumber: '15',
    onTimeCount: 2,
    countedBillCount: 5,
    averageDaysLate: 9,
    arrears: 830000,
    atRisk: true,
  ),
  makePaymentPattern(
    tenantId: 't1',
    tenantName: 'Budi Santoso',
    roomNumber: '08',
    onTimeCount: 5,
    countedBillCount: 6,
    averageDaysLate: 1,
    arrears: 0,
    summary: 'Budi membayar mendekati jatuh tempo.',
  ),
  makePaymentPattern(
    tenantId: 't6',
    tenantName: 'Wati',
    roomNumber: '11',
    onTimeCount: 3,
    countedBillCount: 6,
    averageDaysLate: 4,
    arrears: 1700000,
    atRisk: true,
    summary: 'Wati sering membayar setelah jatuh tempo.',
  ),
];

List<PaymentPattern> _mawarPatterns() => [
  makePaymentPattern(
    tenantId: 'u2',
    tenantName: 'Lina',
    roomNumber: 'B2',
    onTimeCount: 4,
    countedBillCount: 4,
  ),
];

/// The same tenants with every summary withheld; one of them still carries
/// summary text in the response.
List<PaymentPattern> _withheldPatterns() => [
  makePaymentPattern(
    tenantId: 't3',
    tenantName: 'Rina Putri',
    roomNumber: '15',
    onTimeCount: 2,
    countedBillCount: 5,
    averageDaysLate: 9,
    arrears: 830000,
    atRisk: true,
    summary: _hiddenSummary,
    summaryWithheld: true,
  ),
  makePaymentPattern(
    tenantId: 't1',
    tenantName: 'Budi Santoso',
    roomNumber: '08',
    summaryWithheld: true,
  ),
];

FakeManagementRentBillRepository _repo({
  Map<String, List<PaymentPattern>>? patterns,
}) => FakeManagementRentBillRepository(
  items: {'p1': melatiItems(), 'p2': mawarItems()},
  patterns: patterns ?? {'p1': _melatiPatterns(), 'p2': _mawarPatterns()},
);

Future<void> _open(
  WidgetTester tester,
  FakeManagementRentBillRepository management, {
  UserRole role = UserRole.owner,
  String path = _path,
  bool settle = true,
  bool largeText = false,
}) => pumpManagementPayments(
  tester,
  management: management,
  role: role,
  path: path,
  settle: settle,
  largeText: largeText,
);

/// The entry of the payment overview that opens the screen.
Finder _entry() => buttonLabelled(_title);

/// Scrolls the overview until [finder] is on screen.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

/// [text] inside the card of the tenant named [name].
Finder _inCard(String name, String text) => inRow(name, find.text(text));

Finder _riskIcon(String name) =>
    inRow(name, find.byIcon(Icons.warning_amber_rounded));

void main() {
  setUpAll(initializeIndonesianDates);

  group('entry on the payment overview', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('is offered to a $role', (tester) async {
        await _open(tester, _repo(), role: role, path: overviewPath);

        expect(_entry(), findsOneWidget);
      });
    }

    testWidgets('opens the screen of the selected property', (tester) async {
      final repo = _repo();
      await _open(tester, repo, path: overviewPath);

      await tester.tap(_entry());
      await tester.pumpAndSettle();

      expect(find.byType(PaymentPatternScreen), findsOneWidget);
      expect(currentUri(tester).path, '/pembayaran/risiko');
      expect(currentUri(tester).queryParameters, {'properti': 'p1'});
    });

    testWidgets('opens the screen of the property chosen on the overview', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, path: overviewPath);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      await tester.tap(_entry());
      await tester.pumpAndSettle();

      expect(currentUri(tester).queryParameters, {'properti': 'p2'});
      expect(find.text('Lina'), findsOneWidget);
      expect(find.text('Rina Putri'), findsNothing);
      expect(repo.calls, contains('patterns:p2'));
    });

    testWidgets('asks for nothing until it is tapped', (tester) async {
      final repo = _repo();
      await _open(tester, repo, path: overviewPath);

      expect(repo.patternCalls, 0);
    });

    testWidgets('stays available while the overview failed', (tester) async {
      final repo = _repo();
      repo.overviewScript.always = const ApiFailure.network();
      await _open(tester, repo, path: overviewPath);

      expect(_entry(), findsOneWidget);
    });

    testWidgets('stays available when no tenant has a bill', (tester) async {
      final repo = _repo();
      repo.items['p1'] = [];
      await _open(tester, repo, path: overviewPath);

      expect(_entry(), findsOneWidget);
    });

    testWidgets('is not offered when there is no property', (tester) async {
      await pumpManagementPayments(
        tester,
        management: _repo(),
        properties: FakePropertyRepository(),
      );

      expect(_entry(), findsNothing);
    });

    testWidgets('sits next to the other entries and keeps them', (
      tester,
    ) async {
      await _open(tester, _repo(), path: overviewPath);

      expect(verificationEntry(), findsOneWidget);
      expect(buttonLabelled('Catat Pembayaran Tunai'), findsOneWidget);
      expect(_entry(), findsOneWidget);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await _open(tester, _repo(), path: overviewPath);
      await _reveal(tester, _entry());

      final handle = tester.ensureSemantics();
      try {
        final rect = tester.getSemantics(_entry()).rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('meets the guidelines with the entry shown', (tester) async {
      await _open(tester, _repo(), path: overviewPath);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('can be reached and opened at large text size', (tester) async {
      final repo = _repo();
      await _open(tester, repo, path: overviewPath, largeText: true);

      await _reveal(tester, _entry());
      expect(tester.takeException(), isNull);
      await tester.tap(_entry());
      await tester.pumpAndSettle();

      expect(find.byType(PaymentPatternScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('screen', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('opens for a $role titled Risiko Pembayaran', (tester) async {
        await _open(tester, _repo(), role: role);

        expect(find.byType(PaymentPatternScreen), findsOneWidget);
        expect(appBarTitle(_title), findsOneWidget);
      });
    }

    testWidgets('is not reachable by a tenant', (tester) async {
      await _open(tester, _repo(), role: UserRole.tenant);

      expect(find.byType(PaymentPatternScreen), findsNothing);
      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('covers the bottom navigation bar', (tester) async {
      await _open(tester, _repo());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('has a back button that returns to the overview', (
      tester,
    ) async {
      await _open(tester, _repo(), path: overviewPath);
      await _reveal(tester, _entry());
      await tester.tap(_entry());
      await tester.pumpAndSettle();

      expect(backButton(), findsOneWidget);
      await pressBack(tester);

      expect(currentUri(tester).path, overviewPath);
      expect(find.byType(PaymentPatternScreen), findsNothing);
    });

    testWidgets('asks for the patterns of the property only', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(repo.calls.where((c) => c.startsWith('patterns:')), [
        'patterns:p1',
      ]);
    });

    testWidgets('loads the patterns again each time it is opened', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, path: overviewPath);
      await _reveal(tester, _entry());
      await tester.tap(_entry());
      await tester.pumpAndSettle();
      await pressBack(tester);

      await _reveal(tester, _entry());
      await tester.tap(_entry());
      await tester.pumpAndSettle();

      expect(repo.patternCalls, 2);
    });

    testWidgets('without a property it says so and asks for nothing', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, path: '/pembayaran/risiko');

      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
      expect(repo.patternCalls, 0);
    });

    testWidgets('does nothing when a tenant card is tapped', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      final callsBefore = List.of(repo.calls);

      await tester.tap(find.text('Rina Putri'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentPatternScreen), findsOneWidget);
      expect(currentUri(tester).path, '/pembayaran/risiko');
      expect(repo.calls, callsBefore);
    });
  });

  group('cards', () {
    testWidgets('list the tenants of the property in the order received', (
      tester,
    ) async {
      await _open(tester, _repo());

      final rina = tester.getTopLeft(find.text('Rina Putri')).dy;
      final budi = tester.getTopLeft(find.text('Budi Santoso')).dy;
      final wati = tester.getTopLeft(find.text('Wati')).dy;
      expect(rina, lessThan(budi));
      expect(budi, lessThan(wati));
    });

    testWidgets('leave out the tenants of another property', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Lina'), findsNothing);
    });

    testWidgets('show the tenant name and the room', (tester) async {
      await _open(tester, _repo());

      expect(_inCard('Rina Putri', 'Kamar 15'), findsOneWidget);
      expect(_inCard('Budi Santoso', 'Kamar 08'), findsOneWidget);
      expect(_inCard('Wati', 'Kamar 11'), findsOneWidget);
    });

    testWidgets('show the on-time count out of the counted bills', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(
        _inCard('Rina Putri', 'Tepat waktu 2 dari 5 tagihan'),
        findsOneWidget,
      );
      expect(
        _inCard('Budi Santoso', 'Tepat waktu 5 dari 6 tagihan'),
        findsOneWidget,
      );
      expect(_inCard('Wati', 'Tepat waktu 3 dari 6 tagihan'), findsOneWidget);
    });

    testWidgets('show the average days late', (tester) async {
      await _open(tester, _repo());

      expect(
        _inCard('Rina Putri', 'Rata-rata terlambat 9 hari'),
        findsOneWidget,
      );
      expect(
        _inCard('Budi Santoso', 'Rata-rata terlambat 1 hari'),
        findsOneWidget,
      );
      expect(_inCard('Wati', 'Rata-rata terlambat 4 hari'), findsOneWidget);
    });

    testWidgets('show the arrears in rupiah', (tester) async {
      await _open(tester, _repo());

      expect(_inCard('Rina Putri', 'Tunggakan Rp830.000'), findsOneWidget);
      expect(_inCard('Budi Santoso', 'Tunggakan Rp0'), findsOneWidget);
      expect(_inCard('Wati', 'Tunggakan Rp1.700.000'), findsOneWidget);
    });

    testWidgets('show the values as returned for a tenant without bills', (
      tester,
    ) async {
      final repo = _repo(
        patterns: {
          'p1': [
            makePaymentPattern(
              tenantName: 'Tono',
              roomNumber: '10',
              onTimeCount: 0,
              countedBillCount: 0,
              averageDaysLate: 0,
            ),
          ],
        },
      );
      await _open(tester, repo);

      expect(_inCard('Tono', 'Tepat waktu 0 dari 0 tagihan'), findsOneWidget);
      expect(_inCard('Tono', 'Rata-rata terlambat 0 hari'), findsOneWidget);
    });

    testWidgets('show Berisiko with an icon only for a tenant at risk', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(_inCard('Rina Putri', _atRisk), findsOneWidget);
      expect(_riskIcon('Rina Putri'), findsOneWidget);
      expect(_inCard('Wati', _atRisk), findsOneWidget);
      expect(_riskIcon('Wati'), findsOneWidget);
      expect(_inCard('Budi Santoso', _atRisk), findsNothing);
      expect(_riskIcon('Budi Santoso'), findsNothing);
      expect(find.text(_atRisk), findsNWidgets(2));
    });

    testWidgets('read as one item for a screen reader', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        final nodes = nodesAnnouncing(tester, 'Wati');
        expect(nodes, hasLength(1));
        final spoken = announced(nodes.single);
        expect(spoken, contains('Kamar 11'));
        expect(spoken, contains('Tepat waktu 3 dari 6 tagihan'));
        expect(spoken, contains('Rata-rata terlambat 4 hari'));
        expect(spoken, contains('Tunggakan Rp1.700.000'));
        expect(spoken, contains(_atRisk));
        expect(spoken, contains('Wati sering membayar setelah jatuh tempo.'));
        expect(spoken, contains(_disclaimer));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('announce Berisiko only for a tenant at risk', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        final budi = announced(nodesAnnouncing(tester, 'Budi Santoso').single);
        expect(budi, isNot(contains(_atRisk)));
        final rina = announced(nodesAnnouncing(tester, 'Rina Putri').single);
        expect(rina, contains(_atRisk));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('mark the title of the screen as a header', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle(_title)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('summary', () {
    testWidgets('shows the summary with the AI disclaimer', (tester) async {
      await _open(tester, _repo());

      expect(
        _inCard('Budi Santoso', 'Budi membayar mendekati jatuh tempo.'),
        findsOneWidget,
      );
      expect(_inCard('Budi Santoso', _disclaimer), findsOneWidget);
      expect(
        _inCard('Wati', 'Wati sering membayar setelah jatuh tempo.'),
        findsOneWidget,
      );
      expect(_inCard('Wati', _disclaimer), findsOneWidget);
    });

    testWidgets('says the summary is not available yet when there is none', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(_inCard('Rina Putri', _unavailable), findsOneWidget);
      expect(_inCard('Rina Putri', _disclaimer), findsNothing);
      expect(find.text(_unavailable), findsOneWidget);
      expect(find.text(_disclaimer), findsNWidgets(2));
    });

    testWidgets('mentions no subscription when summaries are not withheld', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_subscriptionNote), findsNothing);
    });

    testWidgets('shows the subscription note instead of a withheld summary', (
      tester,
    ) async {
      await _open(tester, _repo(patterns: {'p1': _withheldPatterns()}));

      expect(_inCard('Rina Putri', _subscriptionNote), findsOneWidget);
      expect(_inCard('Budi Santoso', _subscriptionNote), findsOneWidget);
    });

    testWidgets('never shows summary text that came with a withheld summary', (
      tester,
    ) async {
      await _open(tester, _repo(patterns: {'p1': _withheldPatterns()}));

      expect(find.textContaining('rahasia'), findsNothing);
      expect(find.text(_hiddenSummary), findsNothing);
      expect(find.text(_disclaimer), findsNothing);
      expect(find.text(_unavailable), findsNothing);
      final handle = tester.ensureSemantics();
      try {
        expect(nodesAnnouncing(tester, _hiddenSummary), isEmpty);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('keeps the facts and the flag when summaries are withheld', (
      tester,
    ) async {
      await _open(tester, _repo(patterns: {'p1': _withheldPatterns()}));

      expect(_inCard('Rina Putri', 'Kamar 15'), findsOneWidget);
      expect(
        _inCard('Rina Putri', 'Tepat waktu 2 dari 5 tagihan'),
        findsOneWidget,
      );
      expect(
        _inCard('Rina Putri', 'Rata-rata terlambat 9 hari'),
        findsOneWidget,
      );
      expect(_inCard('Rina Putri', 'Tunggakan Rp830.000'), findsOneWidget);
      expect(_inCard('Rina Putri', _atRisk), findsOneWidget);
      expect(_riskIcon('Rina Putri'), findsOneWidget);
      expect(_inCard('Budi Santoso', _atRisk), findsNothing);
    });

    testWidgets('decides per tenant whether the summary is withheld', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(
          patterns: {
            'p1': [
              makePaymentPattern(
                tenantId: 't1',
                tenantName: 'Budi Santoso',
                summary: 'Budi tepat waktu.',
              ),
              makePaymentPattern(
                tenantId: 't2',
                tenantName: 'Dewi Lestari',
                roomNumber: '12',
                summary: _hiddenSummary,
                summaryWithheld: true,
              ),
            ],
          },
        ),
      );

      expect(_inCard('Budi Santoso', 'Budi tepat waktu.'), findsOneWidget);
      expect(_inCard('Budi Santoso', _subscriptionNote), findsNothing);
      expect(_inCard('Dewi Lestari', _subscriptionNote), findsOneWidget);
      expect(find.text(_hiddenSummary), findsNothing);
    });
  });

  group('states', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo();
      repo.patternsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Rina Putri'), findsNothing);
    });

    testWidgets('shows the cards once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo();
      repo.patternsScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Rina Putri'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('explains that no tenant has an active lease', (tester) async {
      await _open(tester, _repo(patterns: {'p1': []}));

      expect(find.textContaining(_emptyMessage), findsOneWidget);
      expect(find.text('Rina Putri'), findsNothing);
    });

    testWidgets('shows the Indonesian message of a failure and a retry', (
      tester,
    ) async {
      final repo = _repo();
      repo.patternsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        ),
        findsOneWidget,
      );
      expect(find.text(retryLabel), findsOneWidget);
      expect(find.text('Rina Putri'), findsNothing);
    });

    testWidgets('a forbidden response shows its message', (tester) async {
      final repo = _repo();
      repo.patternsScript.always = const ApiFailure(
        code: 'FORBIDDEN',
        statusCode: 403,
      );
      await _open(tester, repo);

      expect(
        find.text('Anda tidak memiliki akses untuk tindakan ini.'),
        findsOneWidget,
      );
    });

    testWidgets('an unknown property shows the message of its code', (
      tester,
    ) async {
      await _open(tester, _repo(patterns: {}));

      expect(find.text(messageOfCode('PROPERTY_NOT_FOUND')), findsOneWidget);
      expect(find.text(retryLabel), findsOneWidget);
    });

    testWidgets('a server error shows its message', (tester) async {
      final repo = _repo();
      repo.patternsScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, repo);

      expect(
        find.text('Terjadi kesalahan pada server. Coba lagi.'),
        findsOneWidget,
      );
    });

    testWidgets('does not retry a failed load on its own', (tester) async {
      final repo = _repo();
      repo.patternsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await tester.pump(const Duration(seconds: 30));

      expect(repo.patternCalls, 1);
    });

    testWidgets('Coba lagi loads the patterns again', (tester) async {
      final repo = _repo();
      repo.patternsScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text(retryLabel));
      await tester.pumpAndSettle();

      expect(repo.patternCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Rina Putri'), findsOneWidget);
    });

    testWidgets('keeps the failure when the retry fails too', (tester) async {
      final repo = _repo();
      repo.patternsScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, repo);

      await tester.tap(find.text(retryLabel));
      await tester.pumpAndSettle();

      expect(
        find.text('Terjadi kesalahan pada server. Coba lagi.'),
        findsOneWidget,
      );
      expect(repo.patternCalls, 2);
    });
  });

  group('accessibility', () {
    final states = <String, FakeManagementRentBillRepository Function()>{
      'loaded': _repo,
      'withheld': () => _repo(patterns: {'p1': _withheldPatterns()}),
      'empty': () => _repo(patterns: {'p1': []}),
      'failed': () {
        final repo = _repo();
        repo.patternsScript.always = const ApiFailure.network();
        return repo;
      },
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

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo();
      repo.patternsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo();
      repo.patternsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines without a property', (tester) async {
      await _open(tester, _repo(), path: '/pembayaran/risiko');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('shows every card at large text size', (tester) async {
      await _open(tester, _repo(), largeText: true);

      await tester.scrollUntilVisible(
        find.text('Wati'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Wati'), findsOneWidget);
    });
  });
}
