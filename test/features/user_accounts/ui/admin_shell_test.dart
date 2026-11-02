import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'user_account_ui_helpers.dart';

Finder _headerTitle(String title) =>
    find.descendant(of: find.byType(ScreenHeader), matching: find.text(title));

Finder _logoutButton() =>
    find.ancestor(of: find.text('Keluar'), matching: anyButton());

FakeUserAccountRepository _repo() =>
    FakeUserAccountRepository(accounts: sampleUserAccounts());

void main() {
  group('landing', () {
    testWidgets('an admin lands on the list of user accounts', (tester) async {
      await pumpUserAccountApp(tester, _repo(), path: '/admin');

      expect(currentPath(tester), '/admin');
      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(find.text('Fitur ini belum tersedia'), findsNothing);
    });

    testWidgets('an admin who opens another route lands on the list', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo(), path: '/beranda');

      expect(currentPath(tester), '/admin');
      expect(find.byType(UserAccountListScreen), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('has no bottom navigation', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationDestination), findsNothing);
    });

    testWidgets('has no bottom navigation on the detail either', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo(), path: '/admin/u1');

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('has a header titled Akun Pengguna and no app bar', (
      tester,
    ) async {
      await pumpUserAccountApp(tester, _repo());

      expect(_headerTitle('Akun Pengguna'), findsOneWidget);
      expect(_headerTitle('Admin'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('announces the title as a header', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(_headerTitle('Akun Pengguna')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('keeps the header and Keluar when the accounts fail to load', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpUserAccountApp(tester, repo);

      expect(_headerTitle('Akun Pengguna'), findsOneWidget);
      expect(_logoutButton(), findsOneWidget);
    });
  });

  group('logout', () {
    testWidgets('has a Keluar action in the header', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      expect(find.text('Keluar'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Keluar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the Keluar action is at least 48 by 48 dp', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      final size = tester.getSize(_logoutButton());
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('pressing Keluar logs out and returns to sign in', (
      tester,
    ) async {
      var logouts = 0;
      late ProviderContainer container;
      await pumpUserAccountApp(
        tester,
        _repo(),
        logout: () async {
          logouts++;
          await container.read(sessionControllerProvider.notifier).signOut();
        },
      );
      container = containerOf(tester);

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(logouts, 1);
      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(UserAccountListScreen), findsNothing);
    });

    testWidgets('does not log out until Keluar is pressed', (tester) async {
      var logouts = 0;
      await pumpUserAccountApp(tester, _repo(), logout: () async => logouts++);

      await tester.pump(const Duration(seconds: 1));

      expect(logouts, 0);
      expect(currentPath(tester), '/admin');
    });
  });

  group('other roles', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role never sees the admin screens', (tester) async {
        await pumpUserAccountApp(tester, _repo(), role: role, path: '/admin');

        expect(currentPath(tester), '/beranda');
        expect(find.byType(UserAccountListScreen), findsNothing);
        expect(find.text('Akun Pengguna'), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
      });
    }

    testWidgets('a tenant never sees the admin screens', (tester) async {
      await pumpUserAccountApp(
        tester,
        _repo(),
        role: UserRole.tenant,
        path: '/admin',
      );

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(UserAccountListScreen), findsNothing);
      expect(find.text('Akun Pengguna'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('the shell meets the guidelines', (tester) async {
      await pumpUserAccountApp(tester, _repo());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the shell fits at large text size', (tester) async {
      await pumpUserAccountApp(tester, _repo(), largeText: true);

      expect(tester.takeException(), isNull);
      expect(_headerTitle('Akun Pengguna'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });
  });
}
