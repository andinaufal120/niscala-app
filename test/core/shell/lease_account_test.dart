import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/lease/ui/lease_card.dart';
import 'package:niscala_api/api.dart';

import '../../features/auth/ui/auth_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeLeaseRepository leases, {
  required UserRole role,
  required String path,
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      store: InMemorySessionStore(storedSession(role: role)),
      leases: leases,
    ),
  );
  await tester.pumpAndSettle();
  goTo(tester, path);
  await tester.pumpAndSettle();
}

void main() {
  group('the tenant Akun tab', () {
    testWidgets('shows the account screen with the lease card', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease());
      await _pump(tester, leases, role: UserRole.tenant, path: '/penyewa/akun');

      expect(currentPath(tester), '/penyewa/akun');
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(LeaseCard), findsOneWidget);
      expect(find.text('Kamar & masa sewa'), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
    });

    testWidgets('shows the lease card between the header and Keluar', (
      tester,
    ) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease());
      await _pump(tester, leases, role: UserRole.tenant, path: '/penyewa/akun');

      final card = tester.getRect(find.byType(LeaseCard));
      expect(
        card.top,
        greaterThanOrEqualTo(tester.getRect(find.byType(ScreenHeader)).bottom),
      );
      expect(
        card.bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Keluar')).dy),
      );
    });

    testWidgets('opens from the Akun tab of the bottom navigation', (
      tester,
    ) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease());
      await _pump(
        tester,
        leases,
        role: UserRole.tenant,
        path: '/penyewa/beranda',
      );
      // The home loads the lease; the shared provider is cached.
      expect(leases.calls, 1);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Akun'),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/akun');
      expect(find.byType(LeaseCard), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(leases.calls, 1);
    });

    testWidgets('shows the contact message when the tenant has no lease', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeLeaseRepository(),
        role: UserRole.tenant,
        path: '/penyewa/akun',
      );

      expect(find.byType(LeaseCard), findsOneWidget);
      expect(find.textContaining('Hubungi pengelola'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await _pump(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
        role: UserRole.tenant,
        path: '/penyewa/akun',
      );

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('the management Akun tab', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('shows no lease card to a $role', (tester) async {
        final leases = FakeLeaseRepository(lease: makeCurrentLease());
        await _pump(tester, leases, role: role, path: '/akun');

        expect(currentPath(tester), '/akun');
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(LeaseCard), findsNothing);
        expect(find.text('Kamar & masa sewa'), findsNothing);
        expect(find.text('Kos Melati'), findsNothing);
        expect(find.text('Keluar'), findsOneWidget);
      });

      testWidgets('does not call the lease endpoint for a $role', (
        tester,
      ) async {
        final leases = FakeLeaseRepository(lease: makeCurrentLease());
        await _pump(tester, leases, role: role, path: '/akun');
        await tester.pump(const Duration(seconds: 5));

        expect(leases.calls, 0);
      });

      testWidgets('meets accessibility guidelines for a $role', (tester) async {
        await _pump(
          tester,
          FakeLeaseRepository(lease: makeCurrentLease()),
          role: role,
          path: '/akun',
        );

        await expectMeetsA11yGuidelines(tester);
      });
    }
  });
}
