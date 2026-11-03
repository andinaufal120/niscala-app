import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/ui/confirm_email_change_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala_api/api.dart';

import '../features/auth/ui/auth_ui_helpers.dart';
import '../helpers/fakes.dart';

const _route = '/konfirmasi-email-baru';

const _homes = {
  UserRole.owner: '/beranda',
  UserRole.manager: '/beranda',
  UserRole.tenant: '/penyewa/beranda',
  UserRole.admin: '/admin',
};

void main() {
  group('redirectFor the email change route', () {
    test('keeps a signed out user on the route', () {
      expect(redirectFor(const SignedOut(), _route), isNull);
    });

    test('sends the route to the loading route while loading', () {
      expect(redirectFor(const SessionLoading(), _route), '/memuat');
    });

    for (final role in UserRole.values) {
      test('sends a verified $role from the route home', () {
        expect(
          redirectFor(SignedIn(role: role, emailVerified: true), _route),
          _homes[role],
        );
      });

      test('sends an unverified $role from the route to verification', () {
        expect(
          redirectFor(SignedIn(role: role, emailVerified: false), _route),
          '/verifikasi-email',
        );
      });
    }

    test('still sends other unknown locations to sign in when signed out', () {
      expect(redirectFor(const SignedOut(), '/konfirmasi-email'), '/masuk');
      expect(
        redirectFor(const SignedOut(), '/konfirmasi-email-baru/x'),
        '/masuk',
      );
    });
  });

  group('navigating to the email change route', () {
    testWidgets('a signed out user reaches the confirmation screen', (
      tester,
    ) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      goTo(tester, _route);
      await tester.pumpAndSettle();

      expect(currentPath(tester), _route);
      expect(find.byType(ConfirmEmailChangeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    for (final role in UserRole.values) {
      testWidgets('a signed in $role visiting the route lands on the home', (
        tester,
      ) async {
        useTallScreen(tester);
        final store = InMemorySessionStore(storedSession(role: role));
        await tester.pumpWidget(buildTestApp(store: store));
        await tester.pumpAndSettle();

        goTo(tester, _route);
        await tester.pumpAndSettle();

        expect(currentPath(tester), _homes[role]);
        expect(find.byType(ConfirmEmailChangeScreen), findsNothing);
      });
    }
  });
}
