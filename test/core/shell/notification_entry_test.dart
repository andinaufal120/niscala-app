import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_card_row.dart';
import 'package:niscala_api/api.dart';

import '../../features/notifications/ui/notification_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

final _row = find.widgetWithText(ActionCardRow, 'Notifikasi');

FakeAccountRepository _accountOf(UserRole role) =>
    FakeAccountRepository(account: makeAccount(role: role));

Future<void> _pumpAccount(
  WidgetTester tester,
  UserRole role, {
  FakeNotificationRepository? notifications,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    accounts: _accountOf(role),
    leases: FakeLeaseRepository(lease: makeCurrentLease()),
    notifications: notifications,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, accountPath(role));
  await tester.pumpAndSettle();
}

void main() {
  group('the Notifikasi row', () {
    for (final role in _roles) {
      testWidgets('is shown to a $role', (tester) async {
        await _pumpAccount(tester, role);

        expect(_row, findsOneWidget);
      });

      testWidgets('keeps the other rows and Keluar for a $role', (
        tester,
      ) async {
        await _pumpAccount(tester, role);

        expect(find.text('Keamanan'), findsOneWidget);
        expect(find.text('Perangkat aktif'), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);
      });
    }

    testWidgets('follows the role of the session, not the loaded profile', (
      tester,
    ) async {
      final app = buildTestApp(
        store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
        accounts: _accountOf(UserRole.admin),
        leases: FakeLeaseRepository(lease: makeCurrentLease()),
      );
      useTallScreen(tester);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      goTo(tester, accountPath(UserRole.tenant));
      await tester.pumpAndSettle();

      expect(_row, findsOneWidget);
    });

    testWidgets('is at least 48 dp', (tester) async {
      await _pumpAccount(tester, UserRole.owner);

      final handle = tester.ensureSemantics();
      try {
        final rect = tester.getSemantics(_row).rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('has a spoken label that starts with its visible text', (
      tester,
    ) async {
      await _pumpAccount(tester, UserRole.owner);

      final handle = tester.ensureSemantics();
      try {
        expect(tester.getSemantics(_row).label, startsWith('Notifikasi'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('does not call the API before it is opened', (tester) async {
      final notifications = FakeNotificationRepository();
      await _pumpAccount(tester, UserRole.owner, notifications: notifications);

      expect(notifications.calls, isEmpty);
    });
  });

  group('opening the notification list', () {
    for (final role in _roles) {
      final path = role == UserRole.tenant
          ? '/penyewa/akun/notifikasi'
          : '/akun/notifikasi';

      testWidgets('tapping the row opens it at $path for a $role', (
        tester,
      ) async {
        await _pumpAccount(tester, role);

        await tester.tap(_row);
        await tester.pumpAndSettle();

        expect(currentPath(tester), path);
        expect(appBarTitle('Notifikasi'), findsOneWidget);
      });

      testWidgets('covers the bottom navigation for a $role', (tester) async {
        await _pumpAccount(tester, role);
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(_row);
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('Kembali returns to the account tab of a $role', (
        tester,
      ) async {
        await _pumpAccount(tester, role);
        await tester.tap(_row);
        await tester.pumpAndSettle();

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('can be reached directly by a $role', (tester) async {
        await _pumpAccount(tester, role);

        goTo(tester, path);
        await tester.pumpAndSettle();

        expect(currentPath(tester), path);
        expect(appBarTitle('Notifikasi'), findsOneWidget);
      });
    }

    testWidgets('loads the notifications only after the row is tapped', (
      tester,
    ) async {
      final notifications = FakeNotificationRepository();
      await _pumpAccount(
        tester,
        UserRole.manager,
        notifications: notifications,
      );
      expect(notifications.listCalls, 0);

      await tester.tap(_row);
      await tester.pumpAndSettle();

      expect(notifications.listCalls, 1);
    });
  });

  group('accessibility of the row', () {
    for (final role in _roles) {
      testWidgets('meets the guidelines for a $role', (tester) async {
        await _pumpAccount(tester, role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for a $role', (tester) async {
        await _pumpAccount(tester, role, largeText: true);

        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          _row,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(_row, findsOneWidget);
      });
    }
  });
}
