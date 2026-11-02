import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/user_accounts/ui/user_account_detail_screen.dart';
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
}) => pumpUserAccountApp(
  tester,
  repo,
  path: '/admin/$id',
  settle: settle,
  largeText: largeText,
);

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

    testWidgets('does not show an edit or delete action', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Ubah'), findsNothing);
      expect(find.text('Hapus'), findsNothing);
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
