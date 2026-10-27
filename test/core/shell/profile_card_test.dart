import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/account/ui/active_sessions_screen.dart';
import 'package:niscala/features/lease/ui/lease_card.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _roleLabels = {
  UserRole.owner: 'Pemilik Kost',
  UserRole.manager: 'Pengelola Kost',
  UserRole.tenant: 'Penyewa',
  UserRole.admin: 'Admin',
};

const _name = 'Andi Pengguna';
const _email = 'andi@example.com';

/// The account screen alone, without a router, for a role the shell does not
/// show an account tab to.
Widget _bare(
  FakeAccountRepository accounts, {
  Future<void> Function()? logout,
}) => ProviderScope(
  overrides: [
    logoutProvider.overrideWithValue(logout ?? () async {}),
    accountRepositoryProvider.overrideWithValue(accounts),
  ],
  child: themedApp(const AccountScreen()),
);

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

void _expectHeader(WidgetTester tester, String text) {
  expect(find.text(text), findsOneWidget);
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(find.text(text)), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

void main() {
  group('the profile card', () {
    for (final role in _roles) {
      testWidgets('shows the name, email and role label of a $role', (
        tester,
      ) async {
        final accounts = FakeAccountRepository(
          account: makeAccount(role: role),
        );
        await pumpAccountApp(tester, accounts, role: role);

        expect(find.text(_name), findsOneWidget);
        expect(find.text(_email), findsOneWidget);
        expect(find.text(_roleLabels[role]!), findsOneWidget);
      });

      testWidgets('shows no English role name to a $role', (tester) async {
        final accounts = FakeAccountRepository(
          account: makeAccount(role: role),
        );
        await pumpAccountApp(tester, accounts, role: role);

        for (final english in ['Owner', 'Manager', 'Tenant']) {
          expect(find.textContaining(english), findsNothing);
        }
      });

      testWidgets('sits under the header and above Keamanan for a $role', (
        tester,
      ) async {
        final accounts = FakeAccountRepository(
          account: makeAccount(role: role),
        );
        await pumpAccountApp(tester, accounts, role: role);

        expect(
          _top(tester, find.text(_name)),
          greaterThanOrEqualTo(
            tester.getRect(find.byType(ScreenHeader)).bottom,
          ),
        );
        expect(
          _top(tester, find.text(_email)),
          lessThan(_top(tester, find.text('Keamanan'))),
        );
        expect(
          _top(tester, find.text(_roleLabels[role]!)),
          lessThan(_top(tester, find.text('Keamanan'))),
        );
      });
    }

    testWidgets('takes the role label from the account, not the session', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(role: UserRole.manager),
      );
      await pumpAccountApp(tester, accounts, role: UserRole.owner);

      expect(find.text('Pengelola Kost'), findsOneWidget);
      expect(find.text('Pemilik Kost'), findsNothing);
    });

    for (final entry in _roleLabels.entries) {
      testWidgets('shows ${entry.value} for the role ${entry.key.value}', (
        tester,
      ) async {
        final accounts = FakeAccountRepository(
          account: makeAccount(role: entry.key),
        );
        await tester.pumpWidget(_bare(accounts));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(_name), findsOneWidget);
        expect(find.text(_email), findsOneWidget);
      });
    }

    testWidgets('loads the account once', (tester) async {
      final accounts = FakeAccountRepository();
      await pumpAccountApp(tester, accounts);

      expect(accounts.meCalls, 1);
    });

    testWidgets('never prints null for an account without a Google email', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(googleEmail: null),
      );
      await pumpAccountApp(tester, accounts);

      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('shows the initials of a two word name as an avatar', (
      tester,
    ) async {
      await pumpAccountApp(tester, FakeAccountRepository());

      expect(find.text('AP'), findsOneWidget);
    });

    testWidgets('keeps the initials out of the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpAccountApp(tester, FakeAccountRepository());

        expect(find.bySemanticsLabel(RegExp(r'(^|\s)AP($|\s)')), findsNothing);
        expect(find.bySemanticsLabel(_name), findsAtLeastNWidgets(1));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the initials of the name that was loaded', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(name: 'Siti Pemilik'),
      );
      await pumpAccountApp(tester, accounts);

      expect(find.text('SP'), findsOneWidget);
      expect(find.text('Siti Pemilik'), findsOneWidget);
    });
  });

  group('while the profile loads', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(
        tester,
        accounts,
        role: UserRole.manager,
        settle: false,
      );

      expectLoading(tester);
      expect(find.text(_name), findsNothing);
      expect(find.text(_email), findsNothing);
    });

    testWidgets('keeps the rest of the screen working', (tester) async {
      var logouts = 0;
      final accounts = FakeAccountRepository()
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(
        tester,
        accounts,
        role: UserRole.manager,
        logout: () async => logouts++,
        settle: false,
      );

      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
      await tester.tap(find.text('Keluar'));
      await tester.pump();

      expect(logouts, 1);
    });

    testWidgets('shows the profile once loading finishes', (tester) async {
      final gate = Completer<void>();
      final accounts = FakeAccountRepository()..meScript.gate = gate;
      await pumpAccountApp(
        tester,
        accounts,
        role: UserRole.manager,
        settle: false,
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_name), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('does not hold back the lease card of a tenant', (
      tester,
    ) async {
      final accounts = FakeAccountRepository()
        ..meScript.gate = Completer<void>();
      await pumpAccountApp(
        tester,
        accounts,
        role: UserRole.tenant,
        settle: false,
      );

      expect(find.byType(LeaseCard), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
    });
  });

  group('when the profile fails to load', () {
    for (final code in ['NETWORK_ERROR', 'FORBIDDEN', 'INTERNAL_ERROR']) {
      testWidgets('shows the Indonesian message of $code with Coba lagi', (
        tester,
      ) async {
        final accounts = FakeAccountRepository()
          ..meScript.always = ApiFailure(code: code);
        await pumpAccountApp(tester, accounts, role: UserRole.manager);

        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.text(_name), findsNothing);
      });
    }

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final accounts = FakeAccountRepository()
        ..meScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpAccountApp(tester, accounts, role: UserRole.manager);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the account again and shows it', (
      tester,
    ) async {
      final accounts = FakeAccountRepository()
        ..meScript.queue.add(const ApiFailure.network());
      await pumpAccountApp(tester, accounts, role: UserRole.manager);
      expect(accounts.meCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(accounts.meCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_name), findsOneWidget);
    });

    testWidgets('Coba lagi that fails again keeps the error', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, accounts, role: UserRole.manager);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(accounts.meCalls, 2);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('does not retry in the background', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, accounts, role: UserRole.manager);
      await tester.pump(const Duration(seconds: 10));

      expect(accounts.meCalls, 1);
    });

    for (final role in _roles) {
      testWidgets('keeps the rest of the screen working for a $role', (
        tester,
      ) async {
        var logouts = 0;
        final accounts = FakeAccountRepository()
          ..meScript.always = const ApiFailure.network();
        await pumpAccountApp(
          tester,
          accounts,
          role: role,
          logout: () async => logouts++,
        );

        expect(find.text('Keamanan'), findsOneWidget);
        expect(find.text('Perangkat aktif'), findsOneWidget);
        if (role == UserRole.tenant) {
          expect(find.byType(LeaseCard), findsOneWidget);
          expect(find.text('Kos Melati'), findsOneWidget);
        }
        await tester.tap(find.text('Keluar'));
        await tester.pump();

        expect(logouts, 1);
      });
    }

    testWidgets('still opens the active devices page', (tester) async {
      final accounts = FakeAccountRepository()
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, accounts, role: UserRole.manager);

      await tester.tap(find.text('Perangkat aktif'));
      await tester.pumpAndSettle();

      expect(find.byType(ActiveSessionsScreen), findsOneWidget);
    });
  });

  group('the Keamanan section', () {
    for (final role in _roles) {
      testWidgets('is announced as a header for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        _expectHeader(tester, 'Keamanan');
      });

      testWidgets('has the Perangkat aktif row for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(find.text('Perangkat aktif'), findsOneWidget);
        expect(
          _top(tester, find.text('Perangkat aktif')),
          greaterThan(_top(tester, find.text('Keamanan'))),
        );
      });

      testWidgets('keeps Keluar below the row for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(
          _top(tester, find.text('Keluar')),
          greaterThan(_top(tester, find.text('Perangkat aktif'))),
        );
      });

      testWidgets('makes the Perangkat aktif row at least 48 dp for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expectTargetSize(tester, 'Perangkat aktif');
      });

      testWidgets('does not load the devices before the row is opened for a '
          '$role', (tester) async {
        final accounts = FakeAccountRepository();
        await pumpAccountApp(tester, accounts, role: role);

        expect(accounts.sessionsCalls, 0);
      });
    }

    testWidgets('is shown in the account screen of an admin too', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(role: UserRole.admin),
      );
      await tester.pumpWidget(_bare(accounts));
      await tester.pumpAndSettle();

      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });
  });

  group('the order of the account screen', () {
    testWidgets('puts the lease card between the profile and Keamanan for a '
        'tenant', (tester) async {
      await pumpAccountApp(
        tester,
        FakeAccountRepository(account: makeAccount(role: UserRole.tenant)),
        role: UserRole.tenant,
      );

      final header = tester.getRect(find.byType(ScreenHeader)).bottom;
      final profile = _top(tester, find.text(_name));
      final lease = tester.getRect(find.byType(LeaseCard));
      final security = _top(tester, find.text('Keamanan'));
      final row = _top(tester, find.text('Perangkat aktif'));
      final logout = _top(tester, find.text('Keluar'));

      expect(profile, greaterThanOrEqualTo(header));
      expect(lease.top, greaterThan(profile));
      expect(lease.bottom, lessThanOrEqualTo(security));
      expect(security, lessThan(row));
      expect(row, lessThan(logout));
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('shows no lease card to a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(find.byType(LeaseCard), findsNothing);
      });

      testWidgets('puts the profile above Keamanan above Keluar for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(
          _top(tester, find.text(_name)),
          lessThan(_top(tester, find.text('Keamanan'))),
        );
        expect(
          _top(tester, find.text('Keamanan')),
          lessThan(_top(tester, find.text('Keluar'))),
        );
      });
    }
  });

  group('opening the active devices page', () {
    for (final role in _roles) {
      testWidgets('tapping the row opens it at ${sessionsPath(role)}', (
        tester,
      ) async {
        final accounts = FakeAccountRepository();
        await pumpAccountApp(tester, accounts, role: role);

        await tester.tap(find.text('Perangkat aktif'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), sessionsPath(role));
        expect(find.byType(ActiveSessionsScreen), findsOneWidget);
        expect(accounts.sessionsCalls, 1);
      });

      testWidgets('covers the bottom navigation for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(find.text('Perangkat aktif'));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('Kembali returns to the account tab of a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);
        await tester.tap(find.text('Perangkat aktif'));
        await tester.pumpAndSettle();

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(ActiveSessionsScreen), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('can be reached directly by a $role', (tester) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          role: role,
          path: sessionsPath(role),
        );

        expect(currentPath(tester), sessionsPath(role));
        expect(find.byType(ActiveSessionsScreen), findsOneWidget);
      });
    }
  });

  group('accessibility', () {
    final states = <String, FakeAccountRepository Function(UserRole)>{
      'loaded': (role) =>
          FakeAccountRepository(account: makeAccount(role: role)),
      'failed': (role) =>
          FakeAccountRepository(account: makeAccount(role: role))
            ..meScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      for (final role in _roles) {
        testWidgets('meets the guidelines when ${entry.key} for a $role', (
          tester,
        ) async {
          await pumpAccountApp(tester, entry.value(role), role: role);

          await expectMeetsA11yGuidelines(tester);
        });

        testWidgets('fits at large text size when ${entry.key} for a $role', (
          tester,
        ) async {
          await pumpAccountApp(
            tester,
            entry.value(role),
            role: role,
            largeText: true,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final role in _roles) {
      testWidgets('meets the guidelines while loading for a $role', (
        tester,
      ) async {
        final accounts = FakeAccountRepository(account: makeAccount(role: role))
          ..meScript.gate = Completer<void>();
        await pumpAccountApp(tester, accounts, role: role, settle: false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size while loading for a $role', (
        tester,
      ) async {
        final accounts = FakeAccountRepository(account: makeAccount(role: role))
          ..meScript.gate = Completer<void>();
        await pumpAccountApp(
          tester,
          accounts,
          role: role,
          settle: false,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
