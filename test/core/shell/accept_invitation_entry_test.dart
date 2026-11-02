import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _row = 'Terima undangan pengelola';
const _section = 'Undangan';
const _page = '/akun/undangan';

FakeAccountRepository _accountOf(UserRole role) =>
    FakeAccountRepository(account: makeAccount(role: role));

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

void main() {
  group('the Terima undangan pengelola row', () {
    testWidgets('is shown to a manager in a section named Undangan', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      expect(find.text(_row), findsOneWidget);
      expect(find.text(_section), findsOneWidget);
      expectSectionCard(tester, _section);
      expect(
        find.descendant(of: sectionCardOf(_section), matching: find.text(_row)),
        findsOneWidget,
      );
    });

    testWidgets('sits above Keamanan and below the profile', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      expect(
        _top(tester, find.text(_section)),
        lessThan(_top(tester, find.text('Keamanan'))),
      );
      expect(
        _top(tester, find.text(_row)),
        lessThan(_top(tester, find.text('Keamanan'))),
      );
      expect(
        _top(tester, find.text(_row)),
        greaterThan(_top(tester, find.text('Andi Pengguna'))),
      );
    });

    testWidgets('keeps the security rows and Keluar for a manager', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
      expect(find.text('Ubah kata sandi'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('is at least 48 dp', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      expectTargetSize(tester, _row);
    });

    testWidgets('has a spoken label that starts with its visible text', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      expect(semanticsLabelOf(tester, _row), startsWith(_row));
    });

    for (final role in [UserRole.owner, UserRole.tenant]) {
      testWidgets('is not shown to a $role', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expect(find.text(_row), findsNothing);
        expect(find.text(_section), findsNothing);
        expect(find.text('Keamanan'), findsOneWidget);
      });
    }

    testWidgets('follows the role of the session, not the loaded profile', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.owner),
        role: UserRole.manager,
      );

      expect(find.text(_row), findsOneWidget);
    });

    testWidgets('is not shown to an owner whose profile says manager', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.owner,
      );

      expect(find.text(_row), findsNothing);
      expect(find.text(_section), findsNothing);
    });

    testWidgets('is shown to a manager while the profile loads', (
      tester,
    ) async {
      final accounts = _accountOf(UserRole.manager)
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(
        tester,
        accounts,
        role: UserRole.manager,
        settle: false,
      );

      expect(find.text(_row), findsOneWidget);
    });

    testWidgets('is shown to a manager when the profile fails to load', (
      tester,
    ) async {
      final accounts = _accountOf(UserRole.manager)
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, accounts, role: UserRole.manager);

      expect(find.text(_row), findsOneWidget);
    });

    testWidgets('is shown to a manager whose account has no password', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(
          role: UserRole.manager,
          hasPassword: false,
          googleEmail: 'andi@gmail.com',
        ),
      );
      await pumpAccountApp(tester, accounts, role: UserRole.manager);

      expect(find.text(_row), findsOneWidget);
      expect(find.text('Ubah kata sandi'), findsNothing);
    });

    testWidgets('does not call the API before it is opened', (tester) async {
      final invitations = FakeInvitationRepository();
      useTallScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          store: InMemorySessionStore(storedSession(role: UserRole.manager)),
          accounts: _accountOf(UserRole.manager),
          invitations: invitations,
        ),
      );
      await tester.pumpAndSettle();
      goTo(tester, '/akun');
      await tester.pumpAndSettle();

      expect(invitations.acceptancePreviews, isEmpty);
      expect(invitations.acceptances, isEmpty);
    });
  });

  group('opening the accept invitation page', () {
    testWidgets('tapping the row opens it at $_page', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      await tester.tap(find.text(_row));
      await tester.pumpAndSettle();

      expect(currentPath(tester), _page);
      expect(appBarTitle('Terima Undangan'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text(_row));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali returns to the account tab without a notice', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );
      await tester.tap(find.text(_row));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.manager));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.textContaining('Undangan diterima'), findsNothing);
    });

    testWidgets('can be reached directly by a manager', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
        path: _page,
      );

      expect(currentPath(tester), _page);
      expect(appBarTitle('Terima Undangan'), findsOneWidget);
    });

    testWidgets('shows no notice on a fresh account tab', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      expect(find.textContaining('Undangan diterima'), findsNothing);
    });
  });

  group('accessibility of the row', () {
    testWidgets('meets the guidelines for a manager', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size for a manager', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.manager),
        role: UserRole.manager,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_row), findsOneWidget);
    });

    testWidgets('meets the guidelines while the profile loads', (tester) async {
      final accounts = _accountOf(UserRole.manager)
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(
        tester,
        accounts,
        role: UserRole.manager,
        settle: false,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when the profile fails to load', (
      tester,
    ) async {
      final accounts = _accountOf(UserRole.manager)
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, accounts, role: UserRole.manager);

      await expectMeetsA11yGuidelines(tester);
    });

    for (final role in [UserRole.owner, UserRole.tenant]) {
      testWidgets('fits at large text size for a $role without the row', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _accountOf(role),
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
