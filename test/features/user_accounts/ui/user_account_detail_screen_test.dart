import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/user_accounts/ui/user_account_detail_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_edit_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'user_account_ui_helpers.dart';

UserAccount _owner({
  UserAccountStatus status = UserAccountStatus.active,
  int activeLeaseCount = 3,
  List<AccountPropertyRef>? properties,
  bool neverLoggedIn = false,
  String? pendingEmail,
  DateTime? pendingEmailExpiresAt,
  List<LoginMethod> loginMethods = const [
    LoginMethod.password,
    LoginMethod.google,
  ],
}) => makeUserAccount(
  id: 'u2',
  name: 'Siti Pemilik',
  email: 'siti@example.com',
  role: UserRole.owner,
  status: status,
  activeLeaseCount: activeLeaseCount,
  loginMethods: loginMethods,
  neverLoggedIn: neverLoggedIn,
  pendingEmail: pendingEmail,
  pendingEmailExpiresAt: pendingEmailExpiresAt,
  properties:
      properties ??
      [
        AccountPropertyRef(id: 'p1', name: 'Kos Melati'),
        AccountPropertyRef(id: 'p2', name: 'Kos Mawar'),
      ],
);

UserAccount _tenant({AccountTenancy? tenancy, int activeLeaseCount = 1}) =>
    makeUserAccount(activeLeaseCount: activeLeaseCount, tenancy: tenancy);

AccountTenancy _tenancy({bool noEnd = false}) => AccountTenancy(
  propertyName: 'Kos Melati',
  roomNumber: '08',
  leaseEndDate: noEnd ? null : DateTime.utc(2026, 12, 31),
);

UserAccount _manager() => makeUserAccount(
  id: 'u3',
  name: 'Agus Wijaya',
  email: 'agus@kos.test',
  role: UserRole.manager,
  loginMethods: const [LoginMethod.google],
  properties: [
    AccountPropertyRef(id: 'p1', name: 'Kos Melati'),
    AccountPropertyRef(id: 'p2', name: 'Kos Mawar'),
  ],
);

UserAccount _admin() => makeUserAccount(
  id: 'u4',
  name: 'Rina Admin',
  email: 'rina@niscala.test',
  role: UserRole.admin,
);

FakeUserAccountRepository _repo([List<UserAccount>? accounts]) =>
    FakeUserAccountRepository(
      accounts:
          accounts ??
          [_tenant(tenancy: _tenancy()), _owner(), _manager(), _admin()],
    );

Future<void> _open(
  WidgetTester tester,
  FakeUserAccountRepository repo,
  String id, {
  bool settle = true,
  bool largeText = false,
  FakeAccountRepository? me,
}) => pumpUserAccountApp(
  tester,
  repo,
  path: '/admin/$id',
  settle: settle,
  largeText: largeText,
  me: me,
);

const _delete = 'Hapus Akun';

/// The signed-in admin, whose own account is the one with the id [id].
FakeAccountRepository _signedInAs(String id) => FakeAccountRepository(
  account: makeAccount(id: id, role: UserRole.admin),
);

Finder _dialog() => find.byType(AlertDialog);

Finder _inDialog(Finder finder) =>
    find.descendant(of: _dialog(), matching: finder);

String _dialogText(WidgetTester tester) => tester
    .widgetList<Text>(_inDialog(find.byType(Text)))
    .map((text) => text.data ?? '')
    .join(' ');

Future<void> _askToDelete(WidgetTester tester) =>
    tapVisible(tester, find.text(_delete));

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(_inDialog(find.text('Hapus')));
  await tester.pumpAndSettle();
}

/// Closes a failure dialog with its last button.
Future<void> _closeFailureDialog(WidgetTester tester) async {
  if (_dialog().evaluate().isEmpty) return;
  await tester.tap(find.descendant(of: _dialog(), matching: anyButton()).last);
  await tester.pumpAndSettle();
}

void main() {
  group('header', () {
    testWidgets('shows the title Rincian Akun and a back button', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
      expect(appBarTitle('Rincian Akun'), findsOneWidget);
      expect(backButton(), findsOneWidget);
      expectWhiteAppBar(tester);
    });

    testWidgets('hides the logout action of the list', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Keluar'), findsNothing);
      expect(find.text('Akun Pengguna'), findsNothing);
    });

    testWidgets('asks for the account in the path', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u2');

      final detail = tester.widget<UserAccountDetailScreen>(
        find.byType(UserAccountDetailScreen),
      );
      expect(detail.accountId, 'u2');
      expect(repo.calls, contains('get:u2'));
      expect(repo.calls, isNot(contains('get:u1')));
    });

    testWidgets('Kembali returns to the list', (tester) async {
      await _open(tester, _repo(), 'u1');

      await pressBack(tester);

      expect(currentPath(tester), '/admin');
      expect(find.byType(UserAccountListScreen), findsOneWidget);
    });

    testWidgets('opened from the list, it loads the tapped account', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);

      await tester.tap(find.text('Rina Admin'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/u4');
      expect(repo.calls, contains('get:u4'));
      expect(find.text('rina@niscala.test'), findsOneWidget);
    });
  });

  group('access', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role cannot open an account', (tester) async {
        final repo = _repo();
        await pumpUserAccountApp(tester, repo, role: role, path: '/admin/u1');

        expect(currentPath(tester), '/beranda');
        expect(find.byType(UserAccountDetailScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }

    testWidgets('a tenant cannot open an account', (tester) async {
      final repo = _repo();
      await pumpUserAccountApp(
        tester,
        repo,
        role: UserRole.tenant,
        path: '/admin/u1',
      );

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(UserAccountDetailScreen), findsNothing);
      expect(repo.calls, isEmpty);
    });

    for (final role in [UserRole.owner, UserRole.manager, UserRole.tenant]) {
      testWidgets('a $role cannot open the list of accounts', (tester) async {
        final repo = _repo();
        await pumpUserAccountApp(tester, repo, role: role, path: '/admin');

        expect(currentPath(tester), isNot(startsWith('/admin')));
        expect(find.byType(UserAccountListScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false);

      expectLoading(tester);
      expect(find.text('budi@example.com'), findsNothing);
    });

    testWidgets('shows the account once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _open(tester, repo, 'u1', settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('budi@example.com'), findsNothing);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo, 'u1');

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 1);
    });

    testWidgets('Coba lagi loads the account again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, 'u1');
      expect(repo.getCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('budi@example.com'), findsOneWidget);
    });

    testWidgets('shows that the account was not found', (tester) async {
      await _open(tester, _repo(), 'missing');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text(messageOfCode('USER_ACCOUNT_NOT_FOUND')),
        findsOneWidget,
      );
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
      expect(backButton(), findsOneWidget);
    });
  });

  group('identity', () {
    testWidgets('shows the name, email, role and status', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('Penyewa'), findsOneWidget);
      expect(statusBadge('Aktif'), findsOneWidget);
    });

    final roles = {
      'u2': ('Pemilik', 'siti@example.com'),
      'u3': ('Pengelola', 'agus@kos.test'),
      'u4': ('Admin', 'rina@niscala.test'),
    };
    for (final entry in roles.entries) {
      testWidgets('shows the role label ${entry.value.$1}', (tester) async {
        await _open(tester, _repo(), entry.key);

        expect(find.text(entry.value.$1), findsOneWidget);
        expect(find.text(entry.value.$2), findsOneWidget);
      });
    }

    testWidgets('shows an inactive account as Nonaktif', (tester) async {
      await _open(
        tester,
        _repo([_owner(status: UserAccountStatus.inactive)]),
        'u2',
      );

      expect(statusBadge('Nonaktif'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNothing);
    });

    testWidgets('shows a deleted account as Dihapus', (tester) async {
      await _open(
        tester,
        _repo([_owner(status: UserAccountStatus.deleted)]),
        'u2',
      );

      expect(statusBadge('Dihapus'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNothing);
    });

    testWidgets('the status badge has an icon next to its text', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(
        tester.widget<StatusBadge>(find.byType(StatusBadge)).icon,
        isNotNull,
      );
    });
  });

  group('edit action', () {
    for (final id in ['u1', 'u2', 'u3', 'u4']) {
      testWidgets('is offered for the account $id', (tester) async {
        await _open(tester, _repo(), id);

        expect(find.text('Ubah'), findsOneWidget);
      });
    }

    testWidgets('is offered for an inactive account', (tester) async {
      await _open(
        tester,
        _repo([_owner(status: UserAccountStatus.inactive)]),
        'u2',
      );

      expect(find.text('Ubah'), findsOneWidget);
    });

    testWidgets('is hidden for a deleted account', (tester) async {
      await _open(
        tester,
        _repo([_owner(status: UserAccountStatus.deleted)]),
        'u2',
      );

      expect(find.text('Ubah'), findsNothing);
      expect(statusBadge('Dihapus'), findsOneWidget);
    });

    testWidgets('opens the edit screen of the account', (tester) async {
      await _open(tester, _repo(), 'u2');

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/u2/ubah');
      expect(find.byType(UserAccountEditScreen), findsOneWidget);
    });

    testWidgets('is at least 48 dp', (tester) async {
      await _open(tester, _repo(), 'u1');

      expectTargetSize(tester, 'Ubah');
    });

    testWidgets('Kembali from the edit screen returns to the detail', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/admin/u1');
      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
    });
  });

  group('delete action', () {
    testWidgets('Hapus Akun is a danger button of at least 48 dp', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(
        find.descendant(
          of: find.byType(DangerButton),
          matching: find.text(_delete),
        ),
        findsOneWidget,
      );
      expectTargetSize(tester, _delete);
    });

    for (final id in ['u1', 'u2', 'u3', 'u4']) {
      testWidgets('is offered for the account $id', (tester) async {
        await _open(tester, _repo(), id);

        expect(find.text(_delete), findsOneWidget);
      });
    }

    testWidgets('is offered for an inactive account', (tester) async {
      await _open(
        tester,
        _repo([_owner(status: UserAccountStatus.inactive)]),
        'u2',
      );

      expect(find.text(_delete), findsOneWidget);
    });

    testWidgets('is offered next to Ubah', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Ubah'), findsOneWidget);
      expect(find.text(_delete), findsOneWidget);
    });

    testWidgets('is hidden for a deleted account', (tester) async {
      await _open(
        tester,
        _repo([_owner(status: UserAccountStatus.deleted)]),
        'u2',
      );

      expect(find.text(_delete), findsNothing);
      expect(statusBadge('Dihapus'), findsOneWidget);
    });

    testWidgets('is hidden for the account of the signed-in admin', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u4', me: _signedInAs('u4'));

      expect(find.text('rina@niscala.test'), findsOneWidget);
      expect(find.text(_delete), findsNothing);
    });

    testWidgets('is offered for another account to the signed-in admin', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1', me: _signedInAs('u4'));

      expect(find.text(_delete), findsOneWidget);
    });

    testWidgets('is hidden while the signed-in account is loading', (
      tester,
    ) async {
      final me = _signedInAs('u4')..meScript.gate = Completer<void>();
      await _open(tester, _repo(), 'u1', me: me, settle: false);

      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text(_delete), findsNothing);
    });

    testWidgets('appears once the signed-in account has loaded', (
      tester,
    ) async {
      final gate = Completer<void>();
      final me = _signedInAs('u4')..meScript.gate = gate;
      await _open(tester, _repo(), 'u1', me: me, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_delete), findsOneWidget);
    });

    testWidgets('stays hidden for the own account once it has loaded', (
      tester,
    ) async {
      final gate = Completer<void>();
      final me = _signedInAs('u4')..meScript.gate = gate;
      await _open(tester, _repo(), 'u4', me: me, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_delete), findsNothing);
    });

    testWidgets('is hidden when the signed-in account failed to load', (
      tester,
    ) async {
      final me = _signedInAs('u4')
        ..meScript.always = const ApiFailure.network();
      await _open(tester, _repo(), 'u1', me: me);

      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text(_delete), findsNothing);
      expect(find.text('Ubah'), findsOneWidget);
    });

    testWidgets('is not offered while the account is loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false);

      expect(find.text(_delete), findsNothing);
    });

    testWidgets('is not offered when the account failed to load', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');

      expect(find.text(_delete), findsNothing);
    });

    testWidgets('is not offered for an account that is not found', (
      tester,
    ) async {
      await _open(tester, _repo(), 'missing');

      expect(find.text(_delete), findsNothing);
    });
  });

  group('delete', () {
    /// Opens the detail of Budi by tapping him in the list.
    Future<void> openFromList(
      WidgetTester tester,
      FakeUserAccountRepository repo,
    ) async {
      await pumpUserAccountApp(tester, repo);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
    }

    FakeUserAccountRepository sampleRepo() =>
        FakeUserAccountRepository(accounts: sampleUserAccounts());

    testWidgets('asks for confirmation naming the account', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _askToDelete(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(_inDialog(find.text('Hapus')), findsOneWidget);
      final text = _dialogText(tester);
      expect(text, contains('Hapus akun ini? Semua sesinya akan diakhiri.'));
      expect(text, contains('Budi Santoso'));
      expect(text, contains('budi@example.com'));
      expect(repo.deleted, isEmpty);
      expect(repo.deleteCalls, 0);
    });

    testWidgets('the confirmation names the account that is open', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u2');

      await _askToDelete(tester);

      final text = _dialogText(tester);
      expect(text, contains('Siti Pemilik'));
      expect(text, contains('siti@example.com'));
      expect(text, isNot(contains('Budi Santoso')));
    });

    testWidgets('Batal makes no call and keeps the detail unchanged', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      final loadsBefore = repo.getCalls;
      await _askToDelete(tester);

      await tester.tap(_inDialog(find.text('Batal')));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(repo.deleted, isEmpty);
      expect(repo.deleteCalls, 0);
      expect(repo.getCalls, loadsBefore);
      expect(currentPath(tester), '/admin/u1');
      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
      expect(statusBadge('Aktif'), findsOneWidget);
      expect(find.text(_delete), findsOneWidget);
    });

    testWidgets('dismissing the dialog makes no call', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(repo.deleted, isEmpty);
      expect(currentPath(tester), '/admin/u1');
    });

    testWidgets('can be asked again after cancelling', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);
      await tester.tap(_inDialog(find.text('Batal')));
      await tester.pumpAndSettle();

      await _askToDelete(tester);
      await _confirmDelete(tester);

      expect(repo.deleted, ['u1']);
    });

    testWidgets('confirming deletes the account and returns to the list', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['u1']);
      expect(repo.calls, contains('delete:u1'));
      expect(_dialog(), findsNothing);
      expect(currentPath(tester), '/admin');
      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(find.byType(UserAccountDetailScreen), findsNothing);
    });

    for (final id in ['u2', 'u3', 'u4']) {
      testWidgets('deletes the account $id', (tester) async {
        final repo = _repo();
        await _open(tester, repo, id);
        await _askToDelete(tester);

        await _confirmDelete(tester);

        expect(repo.deleted, [id]);
        expect(currentPath(tester), '/admin');
      });
    }

    testWidgets('an inactive account can be deleted', (tester) async {
      final repo = _repo([_owner(status: UserAccountStatus.inactive)]);
      await _open(tester, repo, 'u2');
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['u2']);
      expect(currentPath(tester), '/admin');
    });

    testWidgets('only the open account is deleted', (tester) async {
      final repo = sampleRepo();
      await openFromList(tester, repo);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['u1']);
      expect(
        repo.accounts.where((a) => a.status == UserAccountStatus.deleted),
        hasLength(2),
      );
      expect(
        repo.accounts.firstWhere((a) => a.id == 'u2').status,
        isNot(UserAccountStatus.deleted),
      );
    });

    testWidgets('the list is reloaded and no longer shows the account', (
      tester,
    ) async {
      final repo = sampleRepo();
      await openFromList(tester, repo);
      final loadsBefore = repo.listCalls;
      expect(find.text('Budi Santoso'), findsOneWidget);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Siti Pemilik'), findsOneWidget);
      expect(find.text('Rina Admin'), findsOneWidget);
    });

    testWidgets('the list is reloaded when the detail was opened directly', (
      tester,
    ) async {
      final repo = sampleRepo();
      await pumpUserAccountApp(tester, repo);
      final loadsBefore = repo.listCalls;
      goTo(tester, '/admin/u1');
      await tester.pumpAndSettle();
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(currentPath(tester), '/admin');
      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('the list shows the account as Dihapus when asked for', (
      tester,
    ) async {
      final repo = sampleRepo();
      await pumpUserAccountApp(tester, repo);
      await tester.tap(find.text(deletedCheckboxLabel));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: accountRow('Budi Santoso'),
          matching: find.text('Aktif'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(currentPath(tester), '/admin');
      expect(
        find.descendant(
          of: accountRow('Budi Santoso'),
          matching: find.text('Dihapus'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: accountRow('Budi Santoso'),
          matching: find.text('Aktif'),
        ),
        findsNothing,
      );
    });

    testWidgets('the detail of the deleted account is loaded again', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);
      await _confirmDelete(tester);

      goTo(tester, '/admin/u1');
      await tester.pumpAndSettle();

      expect(statusBadge('Dihapus'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNothing);
      expect(find.text(_delete), findsNothing);
      expect(find.text('Ubah'), findsNothing);
    });

    testWidgets('the list still shows the account after cancelling', (
      tester,
    ) async {
      final repo = sampleRepo();
      await openFromList(tester, repo);
      await _askToDelete(tester);
      await tester.tap(_inDialog(find.text('Batal')));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/admin');
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('stays on the detail until the delete is done', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..deleteScript.gate = gate;
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);
      await tester.tap(_inDialog(find.text('Hapus')));
      await tester.pump();

      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
      expect(find.byType(UserAccountListScreen), findsNothing);
      expect(currentPath(tester), '/admin/u1');

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(currentPath(tester), '/admin');
    });

    testWidgets('the button is disabled while the delete is in flight', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..deleteScript.gate = gate;
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);
      await tester.tap(_inDialog(find.text('Hapus')));
      await tester.pump();

      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text(_delete), matching: anyButton()),
      );
      expect(button.onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a second tap while it is in flight sends one request', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..deleteScript.gate = gate;
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);

      await tester.tap(_inDialog(find.text('Hapus')));
      await tester.pump();
      await tester.tap(find.text(_delete), warnIfMissed: false);
      await tester.pump();

      expect(_dialog(), findsNothing);
      expect(repo.deleted, ['u1']);
      expect(currentPath(tester), '/admin/u1');

      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.deleted, ['u1']);
      expect(repo.deleteCalls, 1);
      expect(currentPath(tester), '/admin');
    });

    testWidgets('the button is enabled again after a failure', (tester) async {
      final repo = _repo()..deleteScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, 'u1');
      await _askToDelete(tester);
      await _confirmDelete(tester);
      await _closeFailureDialog(tester);

      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text(_delete), matching: anyButton()),
      );
      expect(button.onPressed, isNotNull);
    });

    group('failure', () {
      final codes = [
        'OWNER_HAS_ACTIVE_LEASE',
        'TENANT_HAS_ACTIVE_LEASE',
        'CANNOT_MODIFY_OWN_ACCOUNT',
        'FORBIDDEN',
        'INTERNAL_ERROR',
        'NETWORK_ERROR',
      ];
      for (final code in codes) {
        testWidgets('$code shows its Indonesian message and changes nothing', (
          tester,
        ) async {
          final repo = _repo()
            ..deleteScript.queue.add(
              code == 'NETWORK_ERROR'
                  ? const ApiFailure.network()
                  : ApiFailure(code: code),
            );
          await _open(tester, repo, 'u2');
          await _askToDelete(tester);

          await _confirmDelete(tester);

          expect(_dialog(), findsOneWidget);
          expect(_inDialog(find.text(messageOfCode(code))), findsOneWidget);
          expect(_inDialog(find.text('Mengerti')), findsOneWidget);
          expect(currentPath(tester), '/admin/u2');
          expect(find.byType(UserAccountDetailScreen), findsOneWidget);
          expect(
            repo.accounts.every((a) => a.status != UserAccountStatus.deleted),
            isTrue,
          );
          expect(find.text('siti@example.com'), findsOneWidget);
          expect(statusBadge('Aktif'), findsOneWidget);
        });
      }

      testWidgets('an owner with an active lease is told why', (tester) async {
        final repo = _repo()
          ..deleteScript.queue.add(
            const ApiFailure(code: 'OWNER_HAS_ACTIVE_LEASE', statusCode: 409),
          );
        await _open(tester, repo, 'u2');
        await _askToDelete(tester);

        await _confirmDelete(tester);

        expect(
          find.text(
            'Pemilik ini masih memiliki properti dengan masa sewa aktif.',
          ),
          findsOneWidget,
        );
        expect(find.text(genericErrorMessage), findsNothing);
      });

      testWidgets('a tenant with an active lease is told why', (tester) async {
        final repo = _repo()
          ..deleteScript.queue.add(
            const ApiFailure(code: 'TENANT_HAS_ACTIVE_LEASE', statusCode: 409),
          );
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);

        await _confirmDelete(tester);

        expect(
          find.text('Akun ini masih memiliki masa sewa aktif.'),
          findsOneWidget,
        );
      });

      testWidgets('an unknown error code shows the generic message', (
        tester,
      ) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);

        await _confirmDelete(tester);

        expect(_inDialog(find.text(genericErrorMessage)), findsOneWidget);
      });

      testWidgets('a failure dialog stays until it is closed', (tester) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure(code: 'INTERNAL_ERROR'));
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);
        await _confirmDelete(tester);

        await tester.pump(const Duration(seconds: 30));
        await tester.pumpAndSettle();

        expect(_dialog(), findsOneWidget);
        expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      });

      testWidgets('Mengerti closes the dialog and keeps the detail', (
        tester,
      ) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);
        await _confirmDelete(tester);

        await tester.tap(_inDialog(find.text('Mengerti')));
        await tester.pumpAndSettle();

        expect(_dialog(), findsNothing);
        expect(currentPath(tester), '/admin/u1');
        expect(find.text('budi@example.com'), findsOneWidget);
        expect(find.text(_delete), findsOneWidget);
      });

      testWidgets('a failure does not reload the account', (tester) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure(code: 'INTERNAL_ERROR'));
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);
        await _confirmDelete(tester);
        await _closeFailureDialog(tester);

        expect(repo.getCalls, 1);
      });

      testWidgets('the list still shows the account after a failure', (
        tester,
      ) async {
        final repo = sampleRepo()
          ..deleteScript.queue.add(const ApiFailure.network());
        await openFromList(tester, repo);
        await _askToDelete(tester);
        await _confirmDelete(tester);
        await _closeFailureDialog(tester);

        await pressBack(tester);

        expect(currentPath(tester), '/admin');
        expect(find.text('Budi Santoso'), findsOneWidget);
      });

      testWidgets('can be tried again after a failure', (tester) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);
        await _confirmDelete(tester);
        await _closeFailureDialog(tester);

        await _askToDelete(tester);
        await _confirmDelete(tester);

        expect(repo.deleted, ['u1', 'u1']);
        expect(currentPath(tester), '/admin');
        expect(repo.accounts.first.status, UserAccountStatus.deleted);
      });

      testWidgets('an account that was deleted meanwhile is shown as deleted', (
        tester,
      ) async {
        final repo = _repo();
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);
        repo.accounts[0] = makeUserAccount(status: UserAccountStatus.deleted);

        await _confirmDelete(tester);

        expect(
          _inDialog(find.text(messageOfCode('USER_ACCOUNT_DELETED'))),
          findsOneWidget,
        );
        await _closeFailureDialog(tester);

        expect(repo.getCalls, 2);
        expect(currentPath(tester), '/admin/u1');
        expect(statusBadge('Dihapus'), findsOneWidget);
        expect(find.text(_delete), findsNothing);
        expect(find.text('Ubah'), findsNothing);
      });

      testWidgets('an account that is already gone shows the message and '
          'reloads', (tester) async {
        final repo = _repo();
        await _open(tester, repo, 'u1');
        await _askToDelete(tester);
        repo.accounts.removeWhere((a) => a.id == 'u1');

        await _confirmDelete(tester);

        expect(
          _inDialog(find.text(messageOfCode('USER_ACCOUNT_NOT_FOUND'))),
          findsOneWidget,
        );
        await _closeFailureDialog(tester);

        expect(repo.getCalls, 2);
        expect(find.byType(ErrorView), findsOneWidget);
        expect(
          find.text(messageOfCode('USER_ACCOUNT_NOT_FOUND')),
          findsOneWidget,
        );
        expect(find.text(_delete), findsNothing);
      });

      for (final code in ['USER_ACCOUNT_DELETED', 'USER_ACCOUNT_NOT_FOUND']) {
        testWidgets('$code reloads the account', (tester) async {
          final repo = _repo()
            ..deleteScript.queue.add(ApiFailure(code: code, statusCode: 409));
          await _open(tester, repo, 'u1');
          await _askToDelete(tester);

          await _confirmDelete(tester);

          expect(_inDialog(find.text(messageOfCode(code))), findsOneWidget);
          await _closeFailureDialog(tester);
          expect(repo.getCalls, 2);
          expect(currentPath(tester), '/admin/u1');
        });
      }
    });
  });

  group('login', () {
    testWidgets('shows a password login as Kata sandi', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Kata sandi'), findsOneWidget);
      expect(find.text('Google'), findsNothing);
    });

    testWidgets('shows a Google login as Google', (tester) async {
      await _open(tester, _repo(), 'u3');

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Kata sandi'), findsNothing);
    });

    testWidgets('shows both login methods', (tester) async {
      await _open(tester, _repo(), 'u2');

      expect(find.text('Kata sandi'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('shows neither method when the account has none', (
      tester,
    ) async {
      await _open(tester, _repo([_owner(loginMethods: const [])]), 'u2');

      expect(find.text('Kata sandi'), findsNothing);
      expect(find.text('Google'), findsNothing);
    });

    testWidgets('shows the registration date', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Terdaftar'), findsOneWidget);
      expect(find.textContaining('18 Okt 2026'), findsOneWidget);
    });

    testWidgets('shows the date of the last login', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Terakhir masuk'), findsOneWidget);
      expect(find.textContaining('19 Okt 2026'), findsOneWidget);
      expect(find.text('Belum pernah masuk'), findsNothing);
    });

    testWidgets('says Belum pernah masuk when the account never signed in', (
      tester,
    ) async {
      await _open(tester, _repo([_owner(neverLoggedIn: true)]), 'u2');

      expect(find.text('Terakhir masuk'), findsOneWidget);
      expect(find.text('Belum pernah masuk'), findsOneWidget);
      expect(find.textContaining('19 Okt 2026'), findsNothing);
    });
  });

  group('pending email', () {
    testWidgets('is not shown when there is none', (tester) async {
      await _open(tester, _repo(), 'u2');

      expect(find.text('Email baru menunggu konfirmasi'), findsNothing);
      expect(find.text('Tautan berlaku sampai'), findsNothing);
    });

    testWidgets('shows the new email and when its link expires', (
      tester,
    ) async {
      final repo = _repo([
        _owner(
          pendingEmail: 'siti.baru@example.com',
          pendingEmailExpiresAt: DateTime.utc(2026, 10, 25, 12),
        ),
      ]);
      await _open(tester, repo, 'u2');

      expect(find.text('Email baru menunggu konfirmasi'), findsOneWidget);
      expect(find.text('siti.baru@example.com'), findsOneWidget);
      expect(find.text('Tautan berlaku sampai'), findsOneWidget);
      expect(find.textContaining('25 Okt 2026'), findsOneWidget);
    });

    testWidgets('keeps showing the current email next to the new one', (
      tester,
    ) async {
      final repo = _repo([
        _owner(
          pendingEmail: 'siti.baru@example.com',
          pendingEmailExpiresAt: DateTime.utc(2026, 10, 25, 12),
        ),
      ]);
      await _open(tester, repo, 'u2');

      expect(find.text('siti@example.com'), findsOneWidget);
    });
  });

  group('owner', () {
    testWidgets('lists the owned properties', (tester) async {
      await _open(tester, _repo(), 'u2');

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('shows the number of active leases', (tester) async {
      await _open(tester, _repo(), 'u2');

      expect(find.text('Masa sewa aktif'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows zero active leases', (tester) async {
      await _open(tester, _repo([_owner(activeLeaseCount: 0)]), 'u2');

      expect(find.text('Masa sewa aktif'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows no property when the owner has none', (tester) async {
      await _open(tester, _repo([_owner(properties: const [])]), 'u2');

      expect(find.text('Kos Melati'), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('shows no tenancy', (tester) async {
      await _open(tester, _repo(), 'u2');

      expect(find.textContaining('31 Des 2026'), findsNothing);
    });
  });

  group('manager', () {
    testWidgets('lists the assigned properties', (tester) async {
      await _open(tester, _repo(), 'u3');

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('does not show active leases', (tester) async {
      await _open(tester, _repo(), 'u3');

      expect(find.text('Masa sewa aktif'), findsNothing);
    });
  });

  group('tenant', () {
    testWidgets('shows the property, room and end of the lease', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.textContaining('08'), findsOneWidget);
      expect(find.textContaining('31 Des 2026'), findsOneWidget);
    });

    testWidgets('shows the number of active leases', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Masa sewa aktif'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows no lease end for a lease without an end date', (
      tester,
    ) async {
      await _open(
        tester,
        _repo([_tenant(tenancy: _tenancy(noEnd: true))]),
        'u1',
      );

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.textContaining('08'), findsOneWidget);
      expect(find.textContaining('Des 2026'), findsNothing);
    });

    testWidgets('shows no property or room without a tenancy', (tester) async {
      await _open(
        tester,
        _repo([_tenant(tenancy: null, activeLeaseCount: 0)]),
        'u1',
      );

      expect(find.text('Kos Melati'), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('budi@example.com'), findsOneWidget);
    });
  });

  group('admin', () {
    testWidgets('shows no properties, tenancy or active leases', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u4');

      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Masa sewa aktif'), findsNothing);
      expect(find.text('rina@niscala.test'), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, (FakeUserAccountRepository, String)>{
      'a tenant': (_repo(), 'u1'),
      'a tenant without a tenancy': (
        _repo([_tenant(tenancy: null, activeLeaseCount: 0)]),
        'u1',
      ),
      'an owner': (_repo(), 'u2'),
      'an owner without properties': (
        _repo([_owner(properties: const [])]),
        'u2',
      ),
      'a manager': (_repo(), 'u3'),
      'an admin': (_repo(), 'u4'),
      'an inactive account': (
        _repo([_owner(status: UserAccountStatus.inactive)]),
        'u2',
      ),
      'a deleted account': (
        _repo([_owner(status: UserAccountStatus.deleted)]),
        'u2',
      ),
      'an account that never signed in': (
        _repo([_owner(neverLoggedIn: true)]),
        'u2',
      ),
      'an account with a pending email': (
        _repo([
          _owner(
            pendingEmail: 'siti.baru@example.com',
            pendingEmailExpiresAt: DateTime.utc(2026, 10, 25, 12),
          ),
        ]),
        'u2',
      ),
      'a failure': (
        _repo()..getScript.always = const ApiFailure.network(),
        'u1',
      ),
      'an account that is not found': (_repo(), 'missing'),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await _open(tester, entry.value.$1, entry.value.$2);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for ${entry.key}', (tester) async {
        await _open(tester, entry.value.$1, entry.value.$2, largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines for the own account', (tester) async {
      await _open(tester, _repo(), 'u4', me: _signedInAs('u4'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size for the own account', (tester) async {
      await _open(
        tester,
        _repo(),
        'u4',
        me: _signedInAs('u4'),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines when the signed-in account failed', (
      tester,
    ) async {
      final me = _signedInAs('u4')
        ..meScript.always = const ApiFailure.network();
      await _open(tester, _repo(), 'u1', me: me);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the delete action is labelled for assistive technology', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      final handle = tester.ensureSemantics();
      try {
        expect(find.bySemanticsLabel(_delete), findsOneWidget);
        expect(
          tester.getSemantics(find.text(_delete)),
          isSemantics(isButton: true, isEnabled: true),
        );
      } finally {
        handle.dispose();
      }
    });

    for (final large in [false, true]) {
      final suffix = large ? 'fits at large text size' : 'meets the guidelines';

      testWidgets('$suffix on the delete confirmation', (tester) async {
        await _open(tester, _repo(), 'u2', largeText: large);
        await _askToDelete(tester);

        if (large) {
          expect(tester.takeException(), isNull);
        } else {
          await expectMeetsA11yGuidelines(tester);
        }
      });

      testWidgets('$suffix after a failed delete', (tester) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, 'u2', largeText: large);
        await _askToDelete(tester);
        await _confirmDelete(tester);

        if (large) {
          expect(tester.takeException(), isNull);
        } else {
          await expectMeetsA11yGuidelines(tester);
        }
      });

      testWidgets('$suffix after an owner with an active lease', (
        tester,
      ) async {
        final repo = _repo()
          ..deleteScript.queue.add(
            const ApiFailure(code: 'OWNER_HAS_ACTIVE_LEASE', statusCode: 409),
          );
        await _open(tester, repo, 'u2', largeText: large);
        await _askToDelete(tester);
        await _confirmDelete(tester);

        if (large) {
          expect(tester.takeException(), isNull);
        } else {
          await expectMeetsA11yGuidelines(tester);
        }
      });
    }

    testWidgets('the confirmation buttons are labelled and at least 48 dp', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');
      await _askToDelete(tester);

      final handle = tester.ensureSemantics();
      try {
        for (final label in ['Batal', 'Hapus']) {
          final node = tester.getSemantics(_inDialog(find.text(label)));
          expect(node, isSemantics(isButton: true));
          expect(node.rect.height, greaterThanOrEqualTo(48));
          expect(node.rect.width, greaterThanOrEqualTo(48));
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('announces the title of the screen as a header', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle('Rincian Akun')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
