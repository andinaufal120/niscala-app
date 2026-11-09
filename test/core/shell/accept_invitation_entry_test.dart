import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _row = 'Terima undangan';
const _section = 'Undangan';

/// The roles that accept invitations with their existing account.
const _accepting = [UserRole.manager, UserRole.tenant];

String _page(UserRole role) => '${accountPath(role)}/undangan';

FakeAccountRepository _accountOf(UserRole role) =>
    FakeAccountRepository(account: makeAccount(role: role));

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

void main() {
  for (final role in _accepting) {
    group('the Terima undangan row of a $role', () {
      testWidgets('is shown in a section named Undangan', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expect(find.text(_row), findsOneWidget);
        expect(find.text(_section), findsOneWidget);
        expectSectionCard(tester, _section);
        expect(
          find.descendant(
            of: sectionCardOf(_section),
            matching: find.text(_row),
          ),
          findsOneWidget,
        );
      });

      testWidgets('is no longer labelled for managers only', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expect(find.text('Terima undangan pengelola'), findsNothing);
      });

      testWidgets('sits above Keamanan and below the profile', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

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

      testWidgets('keeps the security rows and Keluar', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expect(find.text('Keamanan'), findsOneWidget);
        expect(find.text('Perangkat aktif'), findsOneWidget);
        expect(find.text('Kata sandi'), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);
      });

      testWidgets('is at least 48 dp', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expectTargetSize(tester, _row);
      });

      testWidgets('has a spoken label that starts with its visible text', (
        tester,
      ) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expect(semanticsLabelOf(tester, _row), startsWith(_row));
      });

      testWidgets('follows the role of the session, not the loaded profile', (
        tester,
      ) async {
        await pumpAccountApp(tester, _accountOf(UserRole.owner), role: role);

        expect(find.text(_row), findsOneWidget);
      });

      testWidgets('is shown while the profile loads', (tester) async {
        final accounts = _accountOf(role)..meScript.gate = Completer<void>();
        await pumpAccountApp(tester, accounts, role: role, settle: false);

        expect(find.text(_row), findsOneWidget);
      });

      testWidgets('is shown when the profile fails to load', (tester) async {
        final accounts = _accountOf(role)
          ..meScript.always = const ApiFailure.network();
        await pumpAccountApp(tester, accounts, role: role);

        expect(find.text(_row), findsOneWidget);
      });

      testWidgets('is shown for an account without a password', (tester) async {
        final accounts = FakeAccountRepository(
          account: makeAccount(
            role: role,
            hasPassword: false,
            googleEmail: 'andi@gmail.com',
          ),
        );
        await pumpAccountApp(tester, accounts, role: role);

        expect(find.text(_row), findsOneWidget);
        expect(find.text('Ubah'), findsNothing);
      });

      testWidgets('does not call the API before it is opened', (tester) async {
        final invitations = FakeInvitationRepository();
        useTallScreen(tester);
        await tester.pumpWidget(
          buildTestApp(
            store: InMemorySessionStore(storedSession(role: role)),
            accounts: _accountOf(role),
            invitations: invitations,
          ),
        );
        await tester.pumpAndSettle();
        goTo(tester, accountPath(role));
        await tester.pumpAndSettle();

        expect(invitations.acceptancePreviews, isEmpty);
        expect(invitations.acceptances, isEmpty);
      });
    });

    group('opening the accept invitation page as a $role', () {
      testWidgets('tapping the row opens it', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        await tester.tap(find.text(_row));
        await tester.pumpAndSettle();

        expect(currentPath(tester), _page(role));
        expect(appBarTitle('Terima Undangan'), findsOneWidget);
        expect(find.text('Lanjut'), findsOneWidget);
      });

      testWidgets('covers the bottom navigation', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(find.text(_row));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('Kembali returns to the account tab without a notice', (
        tester,
      ) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);
        await tester.tap(find.text(_row));
        await tester.pumpAndSettle();

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.textContaining('Undangan diterima'), findsNothing);
      });

      testWidgets('can be reached directly', (tester) async {
        await pumpAccountApp(
          tester,
          _accountOf(role),
          role: role,
          path: _page(role),
        );

        expect(currentPath(tester), _page(role));
        expect(appBarTitle('Terima Undangan'), findsOneWidget);
      });

      testWidgets('shows no notice on a fresh account tab', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        expect(find.textContaining('Undangan diterima'), findsNothing);
      });
    });

    group('accessibility of the row of a $role', () {
      testWidgets('meets the guidelines', (tester) async {
        await pumpAccountApp(tester, _accountOf(role), role: role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size', (tester) async {
        await pumpAccountApp(
          tester,
          _accountOf(role),
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_row, skipOffstage: false), findsOneWidget);
      });

      testWidgets('meets the guidelines while the profile loads', (
        tester,
      ) async {
        final accounts = _accountOf(role)..meScript.gate = Completer<void>();
        await pumpAccountApp(tester, accounts, role: role, settle: false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('meets the guidelines when the profile fails to load', (
        tester,
      ) async {
        final accounts = _accountOf(role)
          ..meScript.always = const ApiFailure.network();
        await pumpAccountApp(tester, accounts, role: role);

        await expectMeetsA11yGuidelines(tester);
      });
    });
  }

  group('a tenant account tab with several leases', () {
    testWidgets('keeps the row below the profile and above Keamanan', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.tenant),
        role: UserRole.tenant,
        leases: FakeLeaseRepository(leases: makeTwoLeases()),
      );

      expect(find.text(_row), findsOneWidget);
      expect(
        _top(tester, find.text(_row)),
        lessThan(_top(tester, find.text('Keamanan'))),
      );
      expect(
        _top(tester, find.text(_row)),
        greaterThan(_top(tester, find.text('Andi Pengguna'))),
      );
    });
  });

  group('the row for other roles', () {
    testWidgets('is not shown to an owner', (tester) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.owner),
        role: UserRole.owner,
      );

      expect(find.text(_row), findsNothing);
      expect(find.text(_section), findsNothing);
      expect(find.text('Keamanan'), findsOneWidget);
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

    testWidgets('fits at large text size for an owner without the row', (
      tester,
    ) async {
      await pumpAccountApp(
        tester,
        _accountOf(UserRole.owner),
        role: UserRole.owner,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
