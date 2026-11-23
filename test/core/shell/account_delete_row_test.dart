import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_card_row.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _title = 'Hapus akun';
const _subtitle = 'Hapus akun dan data pribadi Anda secara permanen';

String _deletePath(UserRole role) => '${accountPath(role)}/hapus-akun';

Finder _row() =>
    find.ancestor(of: find.text(_title), matching: find.byType(ActionCardRow));

void main() {
  group('the Hapus akun row', () {
    for (final role in _roles) {
      testWidgets('is shown to a $role with its subtitle and icon', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(find.text(_title), findsOneWidget);
        expect(find.text(_subtitle), findsOneWidget);
        expect(_row(), findsOneWidget);
        expect(
          find.descendant(
            of: _row(),
            matching: find.byIcon(Icons.delete_outline),
          ),
          findsOneWidget,
        );
      });

      testWidgets('sits after the Keamanan section for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(
          tester.getTopLeft(find.text(_title)).dy,
          greaterThan(tester.getBottomLeft(find.text('Perangkat aktif')).dy),
        );
      });

      testWidgets('scrolls with the content of the tab for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(
          find.ancestor(
            of: find.text(_title),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.text('Keluar'),
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
        );
      });

      testWidgets('is one labelled button of at least 48 dp for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        final handle = tester.ensureSemantics();
        try {
          final node = tester.getSemantics(find.text(_title));
          expect(node, isSemantics(isButton: true, hasTapAction: true));
          expect(node.label, startsWith(_title));
          expect(node.label, contains(_subtitle));
          expect(node.rect.height, greaterThanOrEqualTo(48));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('opens the delete account page for a $role', (tester) async {
        final accounts = FakeAccountRepository();
        await pumpAccountApp(tester, accounts, role: role);

        await tapVisible(tester, find.text(_title));

        expect(currentPath(tester), _deletePath(role));
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Hapus Akun'), findsOneWidget);
        expect(accounts.deleteAccountCalls, 0);
      });
    }

    testWidgets('does not delete anything when it is tapped', (tester) async {
      final accounts = FakeAccountRepository();
      await pumpAccountApp(tester, accounts);

      await tapVisible(tester, find.text(_title));

      expect(accounts.deleteAccountCalls, 0);
    });

    testWidgets('is not shown to an admin', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRoleProvider.overrideWithValue(UserRole.admin),
            accountRepositoryProvider.overrideWithValue(
              FakeAccountRepository(account: makeAccount(role: UserRole.admin)),
            ),
          ],
          child: themedApp(const AccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_title), findsNothing);
      expect(find.text(_subtitle), findsNothing);
    });

    testWidgets('keeps the Keluar button of the tab', (tester) async {
      await pumpAccountApp(tester, FakeAccountRepository());

      expect(find.text('Keluar'), findsOneWidget);
    });

    for (final role in _roles) {
      testWidgets('keeps the tab accessible for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('keeps the tab free of overflow for a $role at large text', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_title), findsOneWidget);
      });
    }
  });
}
