import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _row = 'Ubah kata sandi';

String _pagePath(UserRole role) => '${accountPath(role)}/kata-sandi';

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

FakeAccountRepository _googleOnly({UserRole role = UserRole.owner}) =>
    FakeAccountRepository(
      account: makeAccount(
        role: role,
        hasPassword: false,
        googleEmail: 'andi@gmail.com',
      ),
    );

void main() {
  group('the Ubah kata sandi row', () {
    for (final role in _roles) {
      testWidgets('is shown to a $role whose account has a password', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );

        expect(find.text(_row), findsOneWidget);
      });

      testWidgets('sits in Keamanan, above Keluar, for a $role', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );

        expect(
          _top(tester, find.text(_row)),
          greaterThan(_top(tester, find.text('Keamanan'))),
        );
        expect(
          _top(tester, find.text(_row)),
          lessThan(_top(tester, find.text('Keluar'))),
        );
        expect(
          find.descendant(
            of: sectionCardOf('Keamanan'),
            matching: find.text(_row),
          ),
          findsOneWidget,
        );
      });

      testWidgets('keeps the Perangkat aktif row for a $role', (tester) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );

        expect(find.text('Perangkat aktif'), findsOneWidget);
      });

      testWidgets('is at least 48 dp for a $role', (tester) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );

        expectTargetSize(tester, _row);
      });
    }

    testWidgets('is not shown to an account without a password', (
      tester,
    ) async {
      await pumpAccountApp(tester, _googleOnly());

      expect(find.text(_row), findsNothing);
    });

    for (final role in _roles) {
      testWidgets('is not shown to a Google-only $role', (tester) async {
        await pumpAccountApp(tester, _googleOnly(role: role), role: role);

        expect(find.text(_row), findsNothing);
      });
    }

    testWidgets('leaves the rest of Keamanan for an account without a '
        'password', (tester) async {
      await pumpAccountApp(tester, _googleOnly());

      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('is not shown while the profile loads', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(tester, accounts, settle: false);

      expect(find.text(_row), findsNothing);
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
    });

    testWidgets('appears when the profile finishes loading', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(tester, accounts, settle: false);

      accounts.meScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(_row), findsOneWidget);
    });

    testWidgets('is not shown when the profile fails to load', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, accounts);

      expect(find.text(_row), findsNothing);
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
    });

    testWidgets('appears after Coba lagi loads the profile', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.queue.add(const ApiFailure.network());
      await pumpAccountApp(tester, accounts);
      expect(find.text(_row), findsNothing);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(_row), findsOneWidget);
    });

    testWidgets('does not call the API before it is opened', (tester) async {
      final accounts = FakeAccountRepository();
      await pumpAccountApp(tester, accounts);

      expect(accounts.changePasswordCalls, 0);
    });
  });

  group('opening the change password page', () {
    for (final role in _roles) {
      testWidgets('tapping the row opens it at ${_pagePath(role)}', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );

        await tester.tap(find.text(_row));
        await tester.pumpAndSettle();

        expect(currentPath(tester), _pagePath(role));
        expect(appBarTitle(_row), findsOneWidget);
        expect(find.text('Simpan kata sandi'), findsOneWidget);
      });

      testWidgets('covers the bottom navigation for a $role', (tester) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(find.text(_row));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('Kembali returns to the account tab of a $role', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );
        await tester.tap(find.text(_row));
        await tester.pumpAndSettle();

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('can be reached directly by a $role', (tester) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
          path: _pagePath(role),
        );

        expect(currentPath(tester), _pagePath(role));
        expect(appBarTitle(_row), findsOneWidget);
      });
    }

    testWidgets('Kembali shows no confirmation on the account tab', (
      tester,
    ) async {
      await pumpAccountApp(tester, FakeAccountRepository());
      await tester.tap(find.text(_row));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(find.textContaining('diperbarui'), findsNothing);
    });

    testWidgets('shows no confirmation on a fresh account tab', (tester) async {
      await pumpAccountApp(tester, FakeAccountRepository());

      expect(find.textContaining('diperbarui'), findsNothing);
    });
  });

  group('accessibility of the row', () {
    for (final role in _roles) {
      testWidgets('meets the guidelines for a $role with a password', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
        );

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for a $role with a password', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(account: makeAccount(role: role)),
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_row), findsOneWidget);
      });
    }

    testWidgets('meets the guidelines for an account without a password', (
      tester,
    ) async {
      await pumpAccountApp(tester, _googleOnly());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size for an account without a password', (
      tester,
    ) async {
      await pumpAccountApp(tester, _googleOnly(), largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('has a spoken label that starts with its visible text', (
      tester,
    ) async {
      await pumpAccountApp(tester, FakeAccountRepository());
      final handle = tester.ensureSemantics();
      try {
        expect(tester.getSemantics(find.text(_row)).label, startsWith(_row));
      } finally {
        handle.dispose();
      }
    });
  });
}
