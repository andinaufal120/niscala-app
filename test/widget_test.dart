import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import 'helpers/a11y.dart';
import 'helpers/fakes.dart';

Finder appBarTitle(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('shows the sign in screen when nothing is stored', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Masuk ke Niscala'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows a progress indicator while the session is restored', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildTestApp(store: NeverReadySessionStore()));
    await tester.pump();

    try {
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Memuat'), findsAtLeastNWidgets(1));
      expect(find.byType(NavigationBar), findsNothing);
    } finally {
      handle.dispose();
    }
  });

  for (final role in [UserRole.owner, UserRole.manager]) {
    testWidgets('lands a verified $role on the home tab with five tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(store: InMemorySessionStore(storedSession(role: role))),
      );
      await tester.pumpAndSettle();

      for (final label in [
        'Beranda',
        'Keluhan',
        'Pembayaran',
        'Properti',
        'Akun',
      ]) {
        expect(navLabel(label), findsOneWidget);
      }
      expect(appBarTitle('Beranda'), findsOneWidget);
    });
  }

  testWidgets('lands a verified tenant on the home tab with four tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Beranda', 'Keluhan', 'Pembayaran', 'Akun']) {
      expect(navLabel(label), findsOneWidget);
    }
    expect(navLabel('Properti'), findsNothing);
    expect(appBarTitle('Beranda'), findsOneWidget);
  });

  testWidgets('shows the admin screen without tabs for an admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        store: InMemorySessionStore(storedSession(role: UserRole.admin)),
      ),
    );
    await tester.pumpAndSettle();

    expect(appBarTitle('Admin'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  for (final role in [UserRole.owner, UserRole.tenant]) {
    testWidgets('shows email verification for an unverified $role', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          store: InMemorySessionStore(
            storedSession(role: role, emailVerified: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(appBarTitle('Verifikasi email'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  }

  testWidgets('the sign in route shows the real screen, not a placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderScreen), findsNothing);
    expect(find.text('Fitur ini belum tersedia'), findsNothing);
  });

  testWidgets('configures the Indonesian locale and localizations', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('id'));
    expect(app.supportedLocales, const [Locale('id')]);
    expect(
      app.localizationsDelegates,
      containsAll([
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ]),
    );
  });

  testWidgets('uses the app theme', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, const Color(0xFF0E5E52));
  });

  testWidgets('does not clamp the system text scale', (tester) async {
    late TextScaler scaler;
    await pumpAtLargeText(tester, buildTestApp());
    await tester.pumpAndSettle();

    scaler = MediaQuery.of(tester.element(find.byType(Scaffold).first))
        .textScaler;

    expect(scaler.scale(10), 20);
  });

  testWidgets('sign in screen meets accessibility guidelines', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('verification screen meets accessibility guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        store: InMemorySessionStore(storedSession(emailVerified: false)),
      ),
    );
    await tester.pumpAndSettle();

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('sign in screen fits at large text size', (tester) async {
    await pumpAtLargeText(tester, buildTestApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
