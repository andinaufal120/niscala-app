import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/user_accounts/ui/user_account_detail_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/filter_row.dart';
import 'user_account_ui_helpers.dart';

FakeUserAccountRepository _repo([List<UserAccount>? accounts]) =>
    FakeUserAccountRepository(accounts: accounts ?? sampleUserAccounts());

const _searchLabel = 'Cari email';
const _emptyMessage = 'Tidak ada akun yang cocok';
const _debounce = Duration(milliseconds: 400);

/// Types [text] into the search field and waits long enough for the search to
/// run.
Future<void> _search(WidgetTester tester, String text) async {
  await type(tester, _searchLabel, text);
  await tester.pump(_debounce);
  await tester.pumpAndSettle();
}

Future<void> _chooseRole(WidgetTester tester, String label) async {
  await tester.tap(filterChip(label));
  await tester.pumpAndSettle();
}

Future<void> _toggleDeleted(WidgetTester tester) async {
  await tester.tap(find.text(deletedCheckboxLabel));
  await tester.pumpAndSettle();
}

void main() {
  group('header', () {
    testWidgets('shows the title Akun Pengguna', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Akun Pengguna'),
        ),
        findsOneWidget,
      );
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpUserAccountApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text(_emptyMessage), findsNothing);
    });

    testWidgets('shows the accounts once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await pumpUserAccountApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpUserAccountApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text(_emptyMessage), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpUserAccountApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('shows the message of a server error', (tester) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(
          code: 'INTERNAL_ERROR',
          statusCode: 500,
        );
      await pumpUserAccountApp(tester, repo);

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpUserAccountApp(tester, repo);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
    });

    testWidgets('Coba lagi loads the accounts again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await pumpUserAccountApp(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpUserAccountApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });

    testWidgets('a failed search shows the failure and Coba lagi repeats it', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      repo.listScript.queue.add(const ApiFailure.network());

      await _search(tester, 'budi');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(repo.listed.last.email, 'budi');
      expect(repo.listed[repo.listed.length - 2].email, 'budi');
    });
  });

  group('empty', () {
    testWidgets('says that no account matches when there are none', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo([]));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('says that no account matches the search', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      await _search(tester, 'tidak-ada');

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('says that no account matches the role', (tester) async {
      await pumpUserAccountApp(
        tester,
        _repo([makeUserAccount(role: UserRole.tenant)]),
      );

      await _chooseRole(tester, 'Pemilik');

      expect(find.text(_emptyMessage), findsOneWidget);
    });

    testWidgets('keeps the search field and the filters when nothing matches', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      await _search(tester, 'tidak-ada');

      expect(field(_searchLabel), findsOneWidget);
      expect(textField(tester, _searchLabel).controller?.text, 'tidak-ada');
      for (final label in ['Semua', 'Pemilik', 'Penyewa', 'Pengelola']) {
        expect(filterChip(label), findsOneWidget, reason: label);
      }
      expect(find.text(deletedCheckboxLabel), findsOneWidget);
    });

    testWidgets('lists the accounts again once the search is cleared', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());
      await _search(tester, 'tidak-ada');

      await _search(tester, '');

      expect(find.text(_emptyMessage), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('lists one card per account in the order returned', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      expect(find.byType(Card), findsNWidgets(4));
      final names = [
        'Budi Santoso',
        'Siti Pemilik',
        'Agus Wijaya',
        'Rina Admin',
      ];
      for (var i = 0; i < names.length; i++) {
        expect(find.text(names[i]), findsOneWidget);
        if (i > 0) {
          expect(
            tester.getTopLeft(find.text(names[i - 1])).dy,
            lessThan(tester.getTopLeft(find.text(names[i])).dy),
          );
        }
      }
    });

    testWidgets('shows the name, email, role and status of each account', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      final expected = {
        'Budi Santoso': ('budi@example.com', 'Penyewa', 'Aktif'),
        'Siti Pemilik': ('siti@example.com', 'Pemilik', 'Aktif'),
        'Agus Wijaya': ('agus@kos.test', 'Pengelola', 'Nonaktif'),
        'Rina Admin': ('rina@niscala.test', 'Admin', 'Aktif'),
      };
      for (final entry in expected.entries) {
        final row = accountRow(entry.key);
        final (email, role, status) = entry.value;
        expect(
          find.descendant(of: row, matching: find.text(email)),
          findsOneWidget,
          reason: '${entry.key} email',
        );
        expect(
          find.descendant(of: row, matching: find.text(role)),
          findsOneWidget,
          reason: '${entry.key} role',
        );
        expect(
          find.descendant(of: row, matching: find.text(status)),
          findsOneWidget,
          reason: '${entry.key} status',
        );
      }
    });

    testWidgets('shows the status as a badge with text and an icon', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      expect(statusBadge('Aktif'), findsNWidgets(3));
      expect(statusBadge('Nonaktif'), findsOneWidget);
      final badge = tester.widget<StatusBadge>(
        find.descendant(
          of: accountRow('Agus Wijaya'),
          matching: find.byType(StatusBadge),
        ),
      );
      expect(badge.icon, isNotNull);
    });

    testWidgets('reads each account as a single merged item', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      final label = semanticsLabelOf(tester, 'Agus Wijaya');
      expect(label, contains('Agus Wijaya'));
      expect(label, contains('agus@kos.test'));
      expect(label, contains('Pengelola'));
      expect(label, contains('Nonaktif'));
      expect(label, isNot(contains('Budi Santoso')));
      expect(label, isNot(contains('Siti Pemilik')));
    });

    testWidgets('does not show deleted accounts by default', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expect(find.text('Hendra Kusuma'), findsNothing);
      expect(statusBadge('Dihapus'), findsNothing);
    });

    testWidgets('asks for every role and no deleted account at first', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      expect(repo.listed, hasLength(1));
      expect(repo.listed.single, (
        email: null,
        role: null,
        includeDeleted: false,
      ));
    });

    testWidgets('tapping an account opens its detail', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      await tester.tap(find.text('Siti Pemilik'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/u2');
      final detail = tester.widget<UserAccountDetailScreen>(
        find.byType(UserAccountDetailScreen),
      );
      expect(detail.accountId, 'u2');
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await pumpUserAccountApp(tester, _repo());
      await tester.tap(find.text('Siti Pemilik'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/admin');
      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('has a visible label Cari email', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expect(field(_searchLabel), findsOneWidget);
      expect(find.text(_searchLabel), findsAtLeastNWidgets(1));
    });

    testWidgets('exposes its label to assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpUserAccountApp(tester, _repo());

        expect(
          find.bySemanticsLabel(RegExp(_searchLabel)),
          findsAtLeastNWidgets(1),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('does not search before the typing pauses', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await type(tester, _searchLabel, 'bud');
      await tester.pump(const Duration(milliseconds: 399));

      expect(repo.listCalls, 1);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });

    testWidgets('searches 400 ms after the last keystroke', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await type(tester, _searchLabel, 'bud');
      await tester.pump(const Duration(milliseconds: 399));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(repo.listed.last, (
        email: 'bud',
        role: null,
        includeDeleted: false,
      ));
    });

    testWidgets('each keystroke restarts the wait', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await type(tester, _searchLabel, 'b');
      await tester.pump(const Duration(milliseconds: 300));
      await type(tester, _searchLabel, 'bu');
      await tester.pump(const Duration(milliseconds: 300));
      await type(tester, _searchLabel, 'bud');
      await tester.pump(const Duration(milliseconds: 399));

      expect(repo.listCalls, 1);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(repo.listed.last.email, 'bud');
    });

    testWidgets('shows only the accounts that match the search', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      await _search(tester, 'EXAMPLE.com');

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Pemilik'), findsOneWidget);
      expect(find.text('Agus Wijaya'), findsNothing);
      expect(find.text('Rina Admin'), findsNothing);
    });

    testWidgets('sends the search without the spaces around it', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await _search(tester, '  Budi@Example.com  ');

      expect(repo.listed.last.email, 'Budi@Example.com');
    });

    testWidgets('does not search for blank text', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await _search(tester, '   ');

      expect(repo.listed.every((call) => call.email == null), isTrue);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text(_emptyMessage), findsNothing);
    });

    testWidgets('clearing the search omits the email again', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await _search(tester, 'budi');

      await _search(tester, '');

      expect(repo.listed.last.email, isNull);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });

    testWidgets('keeps the search text while the results load', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      repo.listScript.gate = Completer<void>();

      await type(tester, _searchLabel, 'budi');
      await tester.pump(_debounce);
      await tester.pump();

      expect(textField(tester, _searchLabel).controller?.text, 'budi');
    });

    testWidgets('keeps the chosen role while searching', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await _chooseRole(tester, 'Penyewa');

      await _search(tester, 'budi');

      expect(repo.listed.last, (
        email: 'budi',
        role: UserRole.tenant,
        includeDeleted: false,
      ));
      expectChipSelected(tester, 'Penyewa', selected: true);
    });
  });

  group('role filter', () {
    testWidgets('offers Semua, Pemilik, Penyewa and Pengelola in order', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      final labels = ['Semua', 'Pemilik', 'Penyewa', 'Pengelola'];
      for (final label in labels) {
        expect(filterChip(label), findsOneWidget, reason: label);
      }
      for (var i = 1; i < labels.length; i++) {
        expect(
          tester.getTopLeft(filterChip(labels[i - 1])).dx,
          lessThan(tester.getTopLeft(filterChip(labels[i])).dx),
        );
      }
      expect(filterChip('Admin'), findsNothing);
    });

    testWidgets('starts on Semua', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expectChipSelected(tester, 'Semua', selected: true);
      for (final label in ['Pemilik', 'Penyewa', 'Pengelola']) {
        expectChipSelected(tester, label, selected: false);
      }
    });

    testWidgets('each role chip asks for that role and selects only itself', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      final roles = {
        'Pemilik': UserRole.owner,
        'Penyewa': UserRole.tenant,
        'Pengelola': UserRole.manager,
      };
      for (final entry in roles.entries) {
        await _chooseRole(tester, entry.key);

        expect(repo.listed.last.role, entry.value, reason: entry.key);
        expectChipSelected(tester, entry.key, selected: true);
        expectChipSelected(tester, 'Semua', selected: false);
      }
    });

    testWidgets('shows only the accounts of the chosen role', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      await _chooseRole(tester, 'Pengelola');

      expect(find.text('Agus Wijaya'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Siti Pemilik'), findsNothing);
    });

    testWidgets('Semua asks for every role again', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await _chooseRole(tester, 'Pemilik');

      await _chooseRole(tester, 'Semua');

      expect(repo.listed.last.role, isNull);
      expectChipSelected(tester, 'Semua', selected: true);
      expectChipSelected(tester, 'Pemilik', selected: false);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });

    testWidgets('keeps the search text when the role changes', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await _search(tester, 'example');

      await _chooseRole(tester, 'Pemilik');

      expect(textField(tester, _searchLabel).controller?.text, 'example');
      expect(repo.listed.last, (
        email: 'example',
        role: UserRole.owner,
        includeDeleted: false,
      ));
    });

    testWidgets('choosing the chosen role again changes nothing', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());
      await _chooseRole(tester, 'Pemilik');

      await _chooseRole(tester, 'Pemilik');

      expectChipSelected(tester, 'Pemilik', selected: true);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });

    testWidgets('does not open anything when a chip is chosen', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      await _chooseRole(tester, 'Penyewa');

      expect(currentPath(tester), '/admin');
    });

    defineFilterRowTests(
      pump: (tester, {bool largeText = false}) =>
          pumpUserAccountApp(tester, _repo(), largeText: largeText),
      labels: const ['Semua', 'Pemilik', 'Penyewa', 'Pengelola'],
      selected: 'Semua',
      last: 'Pengelola',
      overflowsAtLargeText: true,
    );
  });

  group('deleted accounts', () {
    testWidgets('offers a checkbox that starts unchecked', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expect(find.text(deletedCheckboxLabel), findsOneWidget);
      expectDeletedCheckbox(tester, checked: false);
    });

    testWidgets('checking it asks for deleted accounts and shows them', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await _toggleDeleted(tester);

      expect(repo.listed.last.includeDeleted, isTrue);
      expectDeletedCheckbox(tester, checked: true);
      expect(find.text('Hendra Kusuma'), findsOneWidget);
      expect(
        find.descendant(
          of: accountRow('Hendra Kusuma'),
          matching: find.text('Dihapus'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('unchecking it hides them again', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await _toggleDeleted(tester);

      await _toggleDeleted(tester);

      expect(repo.listed.last.includeDeleted, isFalse);
      expectDeletedCheckbox(tester, checked: false);
      expect(find.text('Hendra Kusuma'), findsNothing);
    });

    testWidgets('keeps the search and the role when it changes', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await _chooseRole(tester, 'Penyewa');
      await _search(tester, 'example');

      await _toggleDeleted(tester);

      expect(repo.listed.last, (
        email: 'example',
        role: UserRole.tenant,
        includeDeleted: true,
      ));
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Hendra Kusuma'), findsOneWidget);
      expect(find.text('Siti Pemilik'), findsNothing);
    });

    testWidgets('a deleted account opens its detail like any other', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());
      await _toggleDeleted(tester);

      await tester.tap(find.text('Hendra Kusuma'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/u5');
    });
  });

  group('accessibility', () {
    final states = <String, FakeUserAccountRepository Function()>{
      'loaded': _repo,
      'with a single account': () => _repo([makeUserAccount()]),
      'empty': () => _repo([]),
      'failed': () => _repo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await pumpUserAccountApp(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpUserAccountApp(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines with deleted accounts shown', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());
      await _toggleDeleted(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when a search matches nothing', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());
      await _search(tester, 'tidak-ada');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size when a search matches nothing', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo(), largeText: true);
      await _search(tester, 'tidak-ada');

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with deleted accounts shown', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo(), largeText: true);
      await tester.ensureVisible(find.text(deletedCheckboxLabel));
      await _toggleDeleted(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpUserAccountApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpUserAccountApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
