import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/ui/forgot_password_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/reset_password_screen.dart';
import 'package:niscala_api/api.dart';

import '../features/auth/ui/auth_ui_helpers.dart';
import '../helpers/fakes.dart';

const _routes = ['/lupa-kata-sandi', '/atur-ulang-kata-sandi'];

const _homes = {
  UserRole.owner: '/beranda',
  UserRole.manager: '/beranda',
  UserRole.tenant: '/penyewa/beranda',
  UserRole.admin: '/admin',
};

void main() {
  group('redirectFor the password reset routes', () {
    for (final route in _routes) {
      test('keeps a signed out user on $route', () {
        expect(redirectFor(const SignedOut(), route), isNull);
      });

      test('sends $route to the loading route while loading', () {
        expect(redirectFor(const SessionLoading(), route), '/memuat');
      });

      for (final role in UserRole.values) {
        test('sends a verified $role from $route home', () {
          expect(
            redirectFor(SignedIn(role: role, emailVerified: true), route),
            _homes[role],
          );
        });

        test('sends an unverified $role from $route to verification', () {
          expect(
            redirectFor(SignedIn(role: role, emailVerified: false), route),
            '/verifikasi-email',
          );
        });
      }
    }

    test('still sends other unknown locations to sign in when signed out', () {
      expect(redirectFor(const SignedOut(), '/lupa-kata'), '/masuk');
      expect(redirectFor(const SignedOut(), '/atur-ulang'), '/masuk');
    });
  });

  group('navigating to the password reset routes', () {
    testWidgets('a signed out user reaches the forgot password screen', (
      tester,
    ) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      goTo(tester, '/lupa-kata-sandi');
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/lupa-kata-sandi');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('a signed out user reaches the reset password screen', (
      tester,
    ) async {
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      goTo(tester, '/atur-ulang-kata-sandi');
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    for (final route in _routes) {
      testWidgets('a signed in owner visiting $route lands on the home', (
        tester,
      ) async {
        useTallScreen(tester);
        final store = InMemorySessionStore(storedSession());
        await tester.pumpWidget(buildTestApp(store: store));
        await tester.pumpAndSettle();

        goTo(tester, route);
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/beranda');
        expect(find.byType(ForgotPasswordScreen), findsNothing);
        expect(find.byType(ResetPasswordScreen), findsNothing);
      });

      testWidgets('a signed in tenant visiting $route lands on the home', (
        tester,
      ) async {
        useTallScreen(tester);
        final store = InMemorySessionStore(
          storedSession(role: UserRole.tenant),
        );
        await tester.pumpWidget(buildTestApp(store: store));
        await tester.pumpAndSettle();

        goTo(tester, route);
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/penyewa/beranda');
      });
    }
  });
}
