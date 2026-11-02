import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/managers/ui/manager_detail_screen.dart';
import 'package:niscala/features/managers/ui/manager_form_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'manager_ui_helpers.dart';

FakeManagerRepository _repo([List<Manager>? managers]) =>
    FakeManagerRepository(managers: managers ?? sampleManagers());

void main() {
  group('header', () {
    testWidgets('shows the title Pengelola and the property name', (
      tester,
    ) async {
      final properties = ownerProperties();
      await pumpManagerApp(tester, _repo(), properties: properties);

      expect(find.byType(ManagerListScreen), findsOneWidget);
      expect(appBarTitle('Pengelola'), findsOneWidget);
      expect(inAppBar('Kos Melati'), findsOneWidget);
      expect(properties.calls, contains('get:p1'));
    });

    testWidgets('still lists the managers when the property cannot load', (
      tester,
    ) async {
      final properties = ownerProperties()
        ..getScript.always = const ApiFailure.network();
      await pumpManagerApp(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsNothing);
      expect(appBarTitle('Pengelola'), findsOneWidget);
      expect(find.text('Agus Santoso'), findsOneWidget);
      expect(find.text('Tambah Pengelola'), findsOneWidget);
    });

    testWidgets('lists only the managers of the property in the path', (
      tester,
    ) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo);

      expect(repo.calls, contains('list:p1'));
      expect(repo.calls, isNot(contains('list:')));
      expect(find.text('Hendra Wijaya'), findsNothing);
      expect(find.text('Agus Santoso'), findsOneWidget);
    });

    testWidgets('another property lists its own managers', (tester) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo, path: '/properti/p2/pengelola');

      expect(repo.calls, contains('list:p2'));
      expect(find.text('Hendra Wijaya'), findsOneWidget);
      expect(find.text('Agus Santoso'), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsNothing);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpManagerApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Agus Santoso'), findsNothing);
    });

    testWidgets('shows the managers once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await pumpManagerApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Agus Santoso'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpManagerApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Agus Santoso'), findsNothing);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpManagerApp(tester, repo);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpManagerApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('a missing property shows its message', (tester) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'PROPERTY_NOT_FOUND');
      await pumpManagerApp(tester, repo);

      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the managers again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await pumpManagerApp(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Agus Santoso'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpManagerApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('empty', () {
    testWidgets('explains that there are no managers', (tester) async {
      await pumpManagerApp(tester, _repo([]));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byType(Text),
        ),
        findsAtLeastNWidgets(2),
      );
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('has a Tambah Pengelola button that opens the add form', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo([]));

      final button = find.descendant(
        of: find.byType(EmptyState),
        matching: find.text('Tambah Pengelola'),
      );
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola/tambah');
      expect(find.byType(ManagerFormScreen), findsOneWidget);
    });

    testWidgets('a property whose managers are all elsewhere is empty', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo([sampleManagers().last]),
        path: '/properti/p1/pengelola',
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Hendra Wijaya'), findsNothing);
    });

    testWidgets('keeps the action when the property cannot be loaded', (
      tester,
    ) async {
      final properties = ownerProperties()
        ..getScript.always = const ApiFailure.network();
      await pumpManagerApp(tester, _repo([]), properties: properties);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Tambah Pengelola'), findsAtLeastNWidgets(1));
    });
  });

  group('rows', () {
    testWidgets('shows one row per manager in the order returned', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      expect(find.byType(Card), findsNWidgets(3));
      for (final name in ['Bu Rina', 'Agus Santoso', 'Dewi Lestari']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('Bu Rina')).dy,
        lessThan(tester.getTopLeft(find.text('Agus Santoso')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Agus Santoso')).dy,
        lessThan(tester.getTopLeft(find.text('Dewi Lestari')).dy),
      );
    });

    testWidgets('a nickname is the main text and the name is secondary', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      final row = managerRow('Bu Rina');
      expect(
        find.descendant(of: row, matching: find.textContaining('Rina Putri')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Bu Rina')).dy,
        lessThan(
          tester
              .getTopLeft(
                find.descendant(
                  of: row,
                  matching: find.textContaining('Rina Putri'),
                ),
              )
              .dy,
        ),
      );
    });

    testWidgets('a manager without a nickname shows the name once', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      final row = managerRow('Agus Santoso');
      expect(
        find.descendant(of: row, matching: find.textContaining('Agus Santoso')),
        findsOneWidget,
      );
    });

    testWidgets('shows the phone number of each manager', (tester) async {
      await pumpManagerApp(tester, _repo());

      for (final entry in {
        'Bu Rina': '081255204471',
        'Agus Santoso': '081377788899',
        'Dewi Lestari': '081311122233',
      }.entries) {
        expect(
          find.descendant(
            of: managerRow(entry.key),
            matching: find.textContaining(entry.value),
          ),
          findsOneWidget,
          reason: entry.key,
        );
      }
    });

    testWidgets('shows the email only once the manager has set one', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      expect(
        find.descendant(
          of: managerRow('Agus Santoso'),
          matching: find.textContaining('agus@example.com'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: managerRow('Bu Rina'),
          matching: find.textContaining('@'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: managerRow('Dewi Lestari'),
          matching: find.textContaining('@'),
        ),
        findsNothing,
      );
    });

    testWidgets('shows every property the manager is assigned to', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      final agus = managerRow('Agus Santoso');
      expect(
        find.descendant(of: agus, matching: find.textContaining('Kos Melati')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: agus, matching: find.textContaining('Kos Mawar')),
        findsOneWidget,
      );
      final dewi = managerRow('Dewi Lestari');
      expect(
        find.descendant(of: dewi, matching: find.textContaining('Kos Melati')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dewi, matching: find.textContaining('Kos Mawar')),
        findsNothing,
      );
    });

    testWidgets('shows the account status as text on every row', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      expect(statusBadge('Belum Diaktifkan'), findsNWidgets(2));
      expect(statusBadge('Aktif'), findsOneWidget);
      expect(
        find.descendant(
          of: managerRow('Agus Santoso'),
          matching: find.text('Aktif'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: managerRow('Bu Rina'),
          matching: find.text('Belum Diaktifkan'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reads each manager as a single merged item', (tester) async {
      await pumpManagerApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Bu Rina');
      expect(label, contains('Bu Rina'));
      expect(label, contains('Rina Putri'));
      expect(label, contains('081255204471'));
      expect(label, contains('Kos Melati'));
      expect(label, contains('Belum Diaktifkan'));
      expect(label, isNot(contains('Agus Santoso')));
      expect(label, isNot(contains('Dewi Lestari')));
    });

    testWidgets('the merged reading of an active manager says Aktif', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Agus Santoso');
      expect(label, contains('081377788899'));
      expect(label, contains('agus@example.com'));
      expect(label, contains('Kos Mawar'));
      expect(label, contains('Aktif'));
      expect(label, isNot(contains('Belum Diaktifkan')));
    });

    testWidgets('tapping a manager opens the detail', (tester) async {
      await pumpManagerApp(tester, _repo());

      await tester.tap(find.text('Agus Santoso'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola/m2');
      final detail = tester.widget<ManagerDetailScreen>(
        find.byType(ManagerDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.managerId, 'm2');
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await pumpManagerApp(tester, _repo());
      await tester.tap(find.text('Agus Santoso'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
      expect(find.text('Bu Rina'), findsOneWidget);
    });
  });

  group('add button', () {
    testWidgets('Tambah Pengelola is at least 48 dp and opens the form', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      expect(find.text('Tambah Pengelola'), findsOneWidget);
      expectTargetSize(tester, 'Tambah Pengelola');

      await tester.tap(find.text('Tambah Pengelola'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola/tambah');
      final form = tester.widget<ManagerFormScreen>(
        find.byType(ManagerFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.managerId, isNull);
    });
  });

  group('structure', () {
    testWidgets('uses the white app bar with the title and property name', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      expectWhiteAppBar(tester);
      expect(appBarTitle('Pengelola'), findsOneWidget);
      expect(inAppBar('Kos Melati'), findsOneWidget);
    });

    testWidgets('shows each manager row as a card with the theme look', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      expect(find.byType(Card), findsNWidgets(3));
      expectCardLook(tester, find.byType(Card));
    });

    testWidgets('each manager sits in a card of its own', (tester) async {
      await pumpManagerApp(tester, _repo());

      for (final name in ['Bu Rina', 'Agus Santoso', 'Dewi Lestari']) {
        expect(
          find.ancestor(of: find.text(name), matching: find.byType(Card)),
          findsOneWidget,
          reason: name,
        );
      }
    });
  });

  group('accessibility', () {
    final states = <String, FakeManagerRepository Function()>{
      'loaded': _repo,
      'with a single manager': () => _repo([makeManager()]),
      'with an active manager': () => _repo([sampleManagers()[1]]),
      'empty': () => _repo([]),
      'failed': () => _repo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await pumpManagerApp(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpManagerApp(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines when the property name is unknown', (
      tester,
    ) async {
      final properties = ownerProperties()
        ..getScript.always = const ApiFailure.network();
      await pumpManagerApp(tester, _repo(), properties: properties);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpManagerApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpManagerApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
