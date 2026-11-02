import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/ui/payment_verification_list_screen.dart';
import 'package:niscala/features/rent_bills/ui/rent_bill_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'payment_review_ui_helpers.dart';

const _emptyMessage = 'Tidak ada pembayaran yang menunggu verifikasi';

Future<void> _openList(
  WidgetTester tester,
  ReviewRepositories repos, {
  UserRole role = UserRole.owner,
  String path = '/pembayaran/verifikasi?properti=p1',
  bool settle = true,
  bool largeText = false,
}) => pumpReview(
  tester,
  repos,
  role: role,
  path: path,
  settle: settle,
  largeText: largeText,
);

ReviewRepositories _noneAwaiting() =>
    reviewRepositories(bills: [reviewBills().first, reviewBills()[3]]);

void main() {
  setUpAll(initializeIndonesianDates);

  group('entry on the payment overview', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('is offered to a $role', (tester) async {
        await pumpReview(tester, reviewRepositories(), role: role);

        expect(verificationEntry(), findsOneWidget);
      });
    }

    testWidgets('opens the list of the selected property', (tester) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);

      await tester.tap(verificationEntry());
      await tester.pumpAndSettle();

      expect(find.byType(PaymentVerificationListScreen), findsOneWidget);
      expect(currentUri(tester).path, '/pembayaran/verifikasi');
      expect(currentUri(tester).queryParameters, {'properti': 'p1'});
    });

    testWidgets('opens the list of the property chosen on the overview', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      await tester.tap(verificationEntry());
      await tester.pumpAndSettle();

      expect(currentUri(tester).queryParameters, {'properti': 'p2'});
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsNothing);
    });

    testWidgets('loads nothing until it is tapped', (tester) async {
      final repos = reviewRepositories();
      await pumpReview(tester, repos);

      expect(repos.management.calls, ['overview:p1']);
    });

    testWidgets('stays available while the overview failed', (tester) async {
      final repos = reviewRepositories();
      repos.management.overviewScript.always = const ApiFailure.network();
      await pumpReview(tester, repos);

      expect(verificationEntry(), findsOneWidget);
    });

    testWidgets('stays available when no tenant has a bill', (tester) async {
      final repos = reviewRepositories();
      repos.management.items['p1'] = [];
      await pumpReview(tester, repos);

      expect(verificationEntry(), findsOneWidget);
    });

    testWidgets('is not offered when there is no property', (tester) async {
      await pumpReview(
        tester,
        reviewRepositories(),
        properties: FakePropertyRepository(),
      );

      expect(verificationEntry(), findsNothing);
    });

    testWidgets('is not confused with the status of a tenant', (tester) async {
      await pumpReview(tester, reviewRepositories());

      // Dewi Lestari awaits verification: her badge shows the same text but is
      // not the entry.
      expect(find.text('Menunggu Verifikasi'), findsNWidgets(2));
      expect(verificationEntry(), findsOneWidget);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await pumpReview(tester, reviewRepositories());

      final handle = tester.ensureSemantics();
      try {
        final rect = tester.getSemantics(verificationEntry()).rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('meets the guidelines with the entry shown', (tester) async {
      await pumpReview(tester, reviewRepositories());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the entry shown', (tester) async {
      await pumpReview(tester, reviewRepositories(), largeText: true);

      expect(tester.takeException(), isNull);
      expect(verificationEntry(), findsOneWidget);
    });
  });

  group('screen', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('opens for a $role titled Menunggu Verifikasi', (
        tester,
      ) async {
        await _openList(tester, reviewRepositories(), role: role);

        expect(find.byType(PaymentVerificationListScreen), findsOneWidget);
        expect(appBarTitle('Menunggu Verifikasi'), findsOneWidget);
      });
    }

    testWidgets('is not reachable by a tenant', (tester) async {
      await _openList(tester, reviewRepositories(), role: UserRole.tenant);

      expect(find.byType(PaymentVerificationListScreen), findsNothing);
      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('covers the bottom navigation bar', (tester) async {
      await _openList(tester, reviewRepositories());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('has a back button that returns to the overview', (
      tester,
    ) async {
      await _openList(tester, reviewRepositories(), path: overviewPath);
      await tester.tap(verificationEntry());
      await tester.pumpAndSettle();

      expect(backButton(), findsOneWidget);
      await pressBack(tester);

      expect(currentUri(tester).path, overviewPath);
      expect(find.byType(PaymentVerificationListScreen), findsNothing);
    });

    testWidgets('asks for the awaiting bills of the property only', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await _openList(tester, repos);

      final asked = repos.management.listed.single;
      expect(asked.propertyId, 'p1');
      expect(asked.tenantId, isNull);
      expect(asked.statuses, [PaymentStatus.awaitingVerification]);
    });

    testWidgets('without a property it says so and asks for nothing', (
      tester,
    ) async {
      final repos = reviewRepositories();
      await _openList(tester, repos, path: '/pembayaran/verifikasi');

      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
      expect(repos.management.listCalls, 0);
    });
  });

  group('rows', () {
    testWidgets('list the awaiting bills of the property in order', (
      tester,
    ) async {
      await _openList(tester, reviewRepositories());

      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.text('Agus Salim'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Dewi Lestari')).dy,
        lessThan(tester.getTopLeft(find.text('Agus Salim')).dy),
      );
    });

    testWidgets('leave out bills that are not awaiting verification', (
      tester,
    ) async {
      await _openList(tester, reviewRepositories());

      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Sari Wulandari'), findsNothing);
    });

    testWidgets('leave out the bills of another property', (tester) async {
      await _openList(tester, reviewRepositories());

      expect(find.text('Maya'), findsNothing);
    });

    testWidgets('show the tenant, the room, the period and the amount', (
      tester,
    ) async {
      await _openList(tester, reviewRepositories());

      expect(inRow('Dewi Lestari', find.text('Kamar 12')), findsOneWidget);
      expect(inRow('Dewi Lestari', find.text('Rp810.000')), findsOneWidget);
      expect(
        inRow('Dewi Lestari', find.textContaining('1 Nov 2026')),
        findsWidgets,
      );
      expect(
        inRow('Dewi Lestari', find.textContaining('30 Nov 2026')),
        findsWidgets,
      );
      expect(inRow('Agus Salim', find.text('Kamar 21')), findsOneWidget);
      expect(inRow('Agus Salim', find.text('Rp820.000')), findsOneWidget);
      expect(
        inRow('Agus Salim', find.textContaining('1 Okt 2026')),
        findsWidgets,
      );
    });

    testWidgets('read as one item for a screen reader', (tester) async {
      await _openList(tester, reviewRepositories());

      final handle = tester.ensureSemantics();
      try {
        final nodes = nodesAnnouncing(tester, 'Dewi Lestari');
        expect(nodes, hasLength(1));
        final spoken = announced(nodes.single);
        expect(spoken, contains('Kamar 12'));
        expect(spoken, contains('Rp810.000'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('open the bill on top of the list', (tester) async {
      final repos = reviewRepositories();
      await _openList(tester, repos);

      await tester.tap(find.text('Dewi Lestari'));
      await tester.pumpAndSettle();

      expect(find.byType(RentBillDetailScreen), findsOneWidget);
      expect(currentUri(tester).path, billPath('b2'));
      expect(repos.rentBills.calls, contains('get:b2'));
    });

    testWidgets('come back to the list from the bill', (tester) async {
      await _openList(tester, reviewRepositories());
      await tester.tap(find.text('Agus Salim'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentUri(tester).path, '/pembayaran/verifikasi');
      expect(currentUri(tester).queryParameters, {'properti': 'p1'});
      expect(find.text('Agus Salim'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repos = reviewRepositories();
      repos.management.listScript.gate = Completer<void>();
      await _openList(tester, repos, settle: false);

      expectLoading(tester);
      expect(find.text('Dewi Lestari'), findsNothing);
    });

    testWidgets('shows the rows once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repos = reviewRepositories();
      repos.management.listScript.gate = gate;
      await _openList(tester, repos, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('explains that nothing awaits verification', (tester) async {
      await _openList(tester, _noneAwaiting());

      expect(find.textContaining(_emptyMessage), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsNothing);
    });

    testWidgets('shows the Indonesian message of a failure and a retry', (
      tester,
    ) async {
      final repos = reviewRepositories();
      repos.management.listScript.always = const ApiFailure.network();
      await _openList(tester, repos);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        ),
        findsOneWidget,
      );
      expect(find.text(retryLabel), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsNothing);
    });

    testWidgets('a forbidden response shows its message', (tester) async {
      final repos = reviewRepositories();
      repos.management.listScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _openList(tester, repos);

      expect(
        find.text('Anda tidak memiliki akses untuk tindakan ini.'),
        findsOneWidget,
      );
    });

    testWidgets('Coba lagi loads the list again', (tester) async {
      final repos = reviewRepositories();
      repos.management.listScript.queue.add(const ApiFailure.network());
      await _openList(tester, repos);

      await tester.tap(find.text(retryLabel));
      await tester.pumpAndSettle();

      expect(repos.management.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Dewi Lestari'), findsOneWidget);
    });

    testWidgets('keeps the failure when the retry fails too', (tester) async {
      final repos = reviewRepositories();
      repos.management.listScript.always = const ApiFailure(
        code: 'INTERNAL_ERROR',
      );
      await _openList(tester, repos);

      await tester.tap(find.text(retryLabel));
      await tester.pumpAndSettle();

      expect(
        find.text('Terjadi kesalahan pada server. Coba lagi.'),
        findsOneWidget,
      );
      expect(repos.management.listCalls, 2);
    });
  });

  group('accessibility', () {
    final states = <String, ReviewRepositories Function()>{
      'loaded': reviewRepositories,
      'empty': _noneAwaiting,
      'failed': () {
        final repos = reviewRepositories();
        repos.management.listScript.always = const ApiFailure.network();
        return repos;
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await _openList(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await _openList(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repos = reviewRepositories();
      repos.management.listScript.gate = Completer<void>();
      await _openList(tester, repos, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repos = reviewRepositories();
      repos.management.listScript.gate = Completer<void>();
      await _openList(tester, repos, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('rows have a target of at least 48 dp', (tester) async {
      await _openList(tester, reviewRepositories());

      final handle = tester.ensureSemantics();
      try {
        final node = nodesAnnouncing(tester, 'Dewi Lestari').single;
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });
  });
}
