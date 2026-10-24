import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/home/ui/tenant_home_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala/features/rent_bills/ui/tenant_payments_screen.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// The title of a tab: every tab root has its own header instead of an app
/// bar.
Finder tabTitle(String title) =>
    find.descendant(of: find.byType(ScreenHeader), matching: find.text(title));

/// The title of a tenant tab. The tenant Keluhan tab is labelled Keluhan in the
/// navigation bar, but its header reads Keluhan Saya.
Finder tenantTabTitle(String title) => title == 'Keluhan'
    ? find.descendant(
        of: find.byType(ScreenHeader),
        matching: find.text('Keluhan Saya'),
      )
    : tabTitle(title);

Finder appBarTitle(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

int selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

String currentPath(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(NiscalaApp)),
  );
  return container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;
}

void goTo(WidgetTester tester, String path) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(NiscalaApp)),
  );
  container.read(routerProvider).go(path);
}

Future<void> pumpShell(
  WidgetTester tester,
  UserRole role, {
  Future<void> Function()? logout,
  InMemorySessionStore? store,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      store: store ?? InMemorySessionStore(storedSession(role: role)),
      logout: logout,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('management shell', () {
    const labels = ['Beranda', 'Keluhan', 'Pembayaran', 'Properti', 'Akun'];
    const paths = ['/beranda', '/keluhan', '/pembayaran', '/properti', '/akun'];

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('shows the five tabs in order for a $role', (tester) async {
        await pumpShell(tester, role);

        final destinations = tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label);
        expect(destinations, labels);
      });
    }

    testWidgets('starts on the home tab', (tester) async {
      await pumpShell(tester, UserRole.owner);

      expect(currentPath(tester), '/beranda');
      expect(selectedIndex(tester), 0);
      expect(tabTitle('Beranda'), findsOneWidget);
    });

    for (var i = 0; i < labels.length; i++) {
      testWidgets('tapping ${labels[i]} opens ${paths[i]}', (tester) async {
        await pumpShell(tester, UserRole.owner);

        await tester.tap(navLabel(labels[i]));
        await tester.pumpAndSettle();

        expect(currentPath(tester), paths[i]);
        expect(selectedIndex(tester), i);
        expect(tabTitle(labels[i]), findsOneWidget);
      });

      testWidgets('selects ${labels[i]} when the route is ${paths[i]}', (
        tester,
      ) async {
        await pumpShell(tester, UserRole.owner);

        goTo(tester, paths[i]);
        await tester.pumpAndSettle();

        expect(selectedIndex(tester), i);
      });
    }

    testWidgets('shows placeholders for tabs that are not built yet', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.owner);

      for (final label in ['Beranda', 'Pembayaran']) {
        await tester.tap(navLabel(label));
        await tester.pumpAndSettle();
        expect(find.byType(PlaceholderScreen), findsOneWidget);
        expect(find.text('Fitur ini belum tersedia'), findsOneWidget);
      }
    });

    testWidgets('the management Keluhan tab keeps the header Keluhan', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.owner);

      await tester.tap(navLabel('Keluhan'));
      await tester.pumpAndSettle();

      expect(tabTitle('Keluhan'), findsOneWidget);
      expect(find.text('Keluhan Saya'), findsNothing);
    });

    testWidgets('shows the property list on the properties tab', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.owner);

      await tester.tap(navLabel('Properti'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
    });

    testWidgets('shows the account screen on the account tab', (tester) async {
      await pumpShell(tester, UserRole.owner);

      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
    });

    testWidgets('redirects a management user away from tenant routes', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.owner);

      goTo(tester, '/penyewa/akun');
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/beranda');
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await pumpShell(tester, UserRole.owner);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets accessibility guidelines on the account tab', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.owner);
      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        buildTestApp(store: InMemorySessionStore(storedSession())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('tenant shell', () {
    const labels = ['Beranda', 'Keluhan', 'Pembayaran', 'Akun'];
    const paths = [
      '/penyewa/beranda',
      '/penyewa/keluhan',
      '/penyewa/pembayaran',
      '/penyewa/akun',
    ];

    testWidgets('shows the four tabs in order', (tester) async {
      await pumpShell(tester, UserRole.tenant);

      final destinations = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((d) => d.label);
      expect(destinations, labels);
    });

    testWidgets('starts on the home tab', (tester) async {
      await pumpShell(tester, UserRole.tenant);

      expect(currentPath(tester), '/penyewa/beranda');
      expect(selectedIndex(tester), 0);
    });

    for (var i = 0; i < labels.length; i++) {
      testWidgets('tapping ${labels[i]} opens ${paths[i]}', (tester) async {
        await pumpShell(tester, UserRole.tenant);

        await tester.tap(navLabel(labels[i]));
        await tester.pumpAndSettle();

        expect(currentPath(tester), paths[i]);
        expect(selectedIndex(tester), i);
        expect(tenantTabTitle(labels[i]), findsOneWidget);
      });
    }

    testWidgets('the Keluhan tab is labelled Keluhan and titled Keluhan Saya', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.tenant);

      await tester.tap(navLabel('Keluhan'));
      await tester.pumpAndSettle();

      expect(navLabel('Keluhan'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Keluhan Saya'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Keluhan'),
        ),
        findsNothing,
      );
    });

    testWidgets('shows the home screen on the home tab', (tester) async {
      await pumpShell(tester, UserRole.tenant);

      await tester.tap(navLabel('Beranda'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantHomeScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
    });

    testWidgets('shows the payments screen instead of a placeholder', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.tenant);

      await tester.tap(navLabel('Pembayaran'));
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
    });

    testWidgets('shows the account screen on the account tab', (tester) async {
      await pumpShell(tester, UserRole.tenant);

      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('redirects a tenant away from management routes', (
      tester,
    ) async {
      await pumpShell(tester, UserRole.tenant);

      goTo(tester, '/properti');
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await pumpShell(tester, UserRole.tenant);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        buildTestApp(
          store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('account screen', () {
    testWidgets('shows the title and a Keluar button', (tester) async {
      await pumpShell(tester, UserRole.owner);
      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      expect(tabTitle('Akun'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('pressing Keluar logs out and returns to sign in', (
      tester,
    ) async {
      var logouts = 0;
      late ProviderContainer container;
      await tester.pumpWidget(
        buildTestApp(
          store: InMemorySessionStore(storedSession()),
          logout: () async {
            logouts++;
            await container.read(sessionControllerProvider.notifier).signOut();
          },
        ),
      );
      await tester.pumpAndSettle();
      container = ProviderScope.containerOf(
        tester.element(find.byType(NiscalaApp)),
      );
      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(logouts, 1);
      expect(find.byType(NavigationBar), findsNothing);
      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Keluar works for a tenant too', (tester) async {
      var logouts = 0;
      late ProviderContainer container;
      await tester.pumpWidget(
        buildTestApp(
          store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
          logout: () async {
            logouts++;
            await container.read(sessionControllerProvider.notifier).signOut();
          },
        ),
      );
      await tester.pumpAndSettle();
      container = ProviderScope.containerOf(
        tester.element(find.byType(NiscalaApp)),
      );
      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(logouts, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Keluar button is at least 48 by 48 dp', (tester) async {
      await pumpShell(tester, UserRole.owner);
      await tester.tap(navLabel('Akun'));
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find.ancestor(of: find.text('Keluar'), matching: anyButton()),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
