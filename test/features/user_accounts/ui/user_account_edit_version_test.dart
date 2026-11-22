import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/user_accounts/ui/user_account_detail_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_edit_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'user_account_ui_helpers.dart';

const _name = 'Nama lengkap (wajib)';
const _email = 'Email (wajib)';
const _conflict = ApiFailure(code: 'RESOURCE_VERSION_CONFLICT');
const _conflictMessage =
    'Data ini sudah diubah oleh pengguna lain. Data terbaru sudah dimuat ulang.';

UserAccount _account({int version = 3, String name = 'Budi Santoso'}) =>
    makeUserAccount(id: 'u1', name: name, version: version);

Future<void> _open(
  WidgetTester tester,
  FakeUserAccountRepository repo, {
  bool largeText = false,
}) => pumpUserAccountApp(
  tester,
  repo,
  path: '/admin/u1/ubah',
  largeText: largeText,
);

Future<void> _save(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled('Simpan'));

void main() {
  group('the edit screen sends the version it read', () {
    testWidgets('sends the version of the loaded account', (tester) async {
      final repo = FakeUserAccountRepository(accounts: [_account(version: 3)]);
      await _open(tester, repo);

      await _save(tester);

      expect(repo.updatedVersions, [3]);
    });

    testWidgets('sends version 1 for an account at its first version', (
      tester,
    ) async {
      final repo = FakeUserAccountRepository(accounts: [_account(version: 1)]);
      await _open(tester, repo);

      await _save(tester);

      expect(repo.updatedVersions, [1]);
    });

    testWidgets('sends a larger version unchanged', (tester) async {
      final repo = FakeUserAccountRepository(accounts: [_account(version: 7)]);
      await _open(tester, repo);

      await _save(tester);

      expect(repo.updatedVersions, [7]);
    });

    testWidgets('sends the version together with the edited values', (
      tester,
    ) async {
      final repo = FakeUserAccountRepository(accounts: [_account(version: 4)]);
      await _open(tester, repo);
      await type(tester, _name, 'Budi Baru');

      await _save(tester);

      expect(repo.updated.single.id, 'u1');
      expect(repo.updated.single.input.name, 'Budi Baru');
      expect(repo.updatedVersions, [4]);
    });
  });

  group('a version conflict on edit', () {
    FakeUserAccountRepository conflictingRepo() {
      final repo = FakeUserAccountRepository(accounts: [_account(version: 3)]);
      repo.updateScript.queue.add(_conflict);
      return repo;
    }

    testWidgets('closes the screen and returns to the account detail', (
      tester,
    ) async {
      await _open(tester, conflictingRepo());

      await _save(tester);

      expect(find.byType(UserAccountEditScreen), findsNothing);
      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/admin/u1');
    });

    testWidgets(
      'shows the message in a snack bar on the screen it returns to',
      (tester) async {
        await _open(tester, conflictingRepo());

        await _save(tester);

        expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
        expect(messageOfCode('RESOURCE_VERSION_CONFLICT'), _conflictMessage);
      },
    );

    testWidgets('shows the message once and shows no success snack bar', (
      tester,
    ) async {
      await _open(tester, conflictingRepo());

      await _save(tester);

      expect(find.text(_conflictMessage), findsOneWidget);
      expect(find.text('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('sends the update once and does not retry', (tester) async {
      final repo = conflictingRepo();
      await _open(tester, repo);

      await _save(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updatedVersions, [3]);
    });

    testWidgets('reloads the account and shows the changed data', (
      tester,
    ) async {
      final repo = conflictingRepo();
      await _open(tester, repo);
      final loadsBefore = repo.getCalls;
      repo.accounts[0] = _account(version: 5, name: 'Budi Terbaru');

      await _save(tester);

      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(find.text('Budi Terbaru'), findsAtLeastNWidgets(1));
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('the next edit sends the newer version', (tester) async {
      final repo = conflictingRepo();
      await _open(tester, repo);
      repo.accounts[0] = _account(version: 5, name: 'Budi Terbaru');
      await _save(tester);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      goTo(tester, '/admin/u1/ubah');
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _name).controller!.text, 'Budi Terbaru');
      await _save(tester);

      expect(repo.updatedVersions, [3, 5]);
    });

    testWidgets('meets the accessibility guidelines with the snack bar', (
      tester,
    ) async {
      await _open(tester, conflictingRepo());

      await _save(tester);

      expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the snack bar', (tester) async {
      await _open(tester, conflictingRepo(), largeText: true);

      await _save(tester);

      expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('other failures on edit stay on the screen', () {
    testWidgets('a field error shows inline and does not close the screen', (
      tester,
    ) async {
      final repo = FakeUserAccountRepository(accounts: [_account()])
        ..updateScript.queue.add(
          const ApiFailure(code: 'EMAIL_ALREADY_REGISTERED', field: 'email'),
        );
      await _open(tester, repo);

      await _save(tester);

      expect(fieldError(tester, _email), isNotNull);
      expect(find.byType(UserAccountEditScreen), findsOneWidget);
      expect(currentPath(tester), '/admin/u1/ubah');
      expect(find.text(_conflictMessage), findsNothing);
    });

    testWidgets(
      'a network failure shows a banner and does not close the screen',
      (tester) async {
        final repo = FakeUserAccountRepository(accounts: [_account()])
          ..updateScript.queue.add(const ApiFailure.network());
        await _open(tester, repo);

        await _save(tester);

        expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
        expect(find.byType(UserAccountEditScreen), findsOneWidget);
        expect(find.text(_conflictMessage), findsNothing);
      },
    );

    testWidgets('a retry after a failure sends the same version', (
      tester,
    ) async {
      final repo = FakeUserAccountRepository(accounts: [_account(version: 6)])
        ..updateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _save(tester);

      await _save(tester);

      expect(repo.updatedVersions, [6, 6]);
    });
  });
}
