import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/subscription/ui/downgrade_screen.dart';
import 'package:niscala/features/subscription/ui/subscription_screen.dart';
import 'package:niscala_api/api.dart';

import '../features/subscription/ui/subscription_ui_helpers.dart';
import '../helpers/fakes.dart';

const _subscription = '/akun/langganan';
const _downgrade = '/akun/langganan/turunkan';

SessionState _signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

void main() {
  group('redirectFor', () {
    for (final path in [_subscription, _downgrade]) {
      test('lets an owner stay on $path', () {
        expect(redirectFor(_signedIn(UserRole.owner), path), isNull);
      });

      test('sends a manager from $path to the management home', () {
        expect(redirectFor(_signedIn(UserRole.manager), path), '/beranda');
      });

      test('sends a tenant from $path to the tenant home', () {
        expect(
          redirectFor(_signedIn(UserRole.tenant), path),
          '/penyewa/beranda',
        );
      });

      test('sends an admin from $path to the admin home', () {
        expect(redirectFor(_signedIn(UserRole.admin), path), '/admin');
      });

      test('sends a signed out user from $path to sign in', () {
        expect(redirectFor(const SignedOut(), path), '/masuk');
      });

      test('sends a user who is still loading from $path to loading', () {
        expect(redirectFor(const SessionLoading(), path), '/memuat');
      });

      test('sends an unverified owner from $path to verification', () {
        expect(
          redirectFor(_signedIn(UserRole.owner, verified: false), path),
          '/verifikasi-email',
        );
      });
    }

    test('keeps a tenant away from the tenant path of the subscription', () {
      expect(
        redirectFor(_signedIn(UserRole.tenant), '/penyewa$_subscription'),
        '/penyewa/beranda',
      );
    });

    test('keeps a manager away from the tenant path of the subscription', () {
      expect(
        redirectFor(_signedIn(UserRole.manager), '/penyewa$_subscription'),
        '/beranda',
      );
    });
  });

  group('the router', () {
    Future<void> pump(
      WidgetTester tester,
      UserRole role,
      String path, {
      FakeSubscriptionRepository? subscriptions,
    }) => pumpSubscriptionApp(
      tester,
      subscriptions ?? FakeSubscriptionRepository(),
      role: role,
      path: path,
    );

    testWidgets('shows the subscription screen to an owner', (tester) async {
      await pump(tester, UserRole.owner, _subscription);

      expect(currentPath(tester), _subscription);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('shows the downgrade screen to an owner', (tester) async {
      await pump(
        tester,
        UserRole.owner,
        '$_downgrade?paket=basic',
        subscriptions: FakeSubscriptionRepository(
          subscription: makeActiveSubscription(planCode: PlanCode.pro),
        ),
      );

      expect(currentPath(tester), _downgrade);
      expect(currentUri(tester).queryParameters['paket'], 'basic');
      expect(find.byType(DowngradeScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('reads the plan of the downgrade from the paket query', (
      tester,
    ) async {
      await pump(
        tester,
        UserRole.owner,
        '$_downgrade?paket=free',
        subscriptions: FakeSubscriptionRepository(
          subscription: makeActiveSubscription(planCode: PlanCode.pro),
        ),
      );

      expect(find.text('Turunkan ke Paket Gratis'), findsOneWidget);
    });

    testWidgets('the downgrade screen sits above the subscription screen', (
      tester,
    ) async {
      await pump(
        tester,
        UserRole.owner,
        '$_downgrade?paket=basic',
        subscriptions: FakeSubscriptionRepository(
          subscription: makeActiveSubscription(planCode: PlanCode.pro),
        ),
      );

      await pressBack(tester);

      expect(currentPath(tester), _subscription);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });

    for (final path in [_subscription, '$_downgrade?paket=basic']) {
      testWidgets('sends a manager from $path to the management home', (
        tester,
      ) async {
        final subscriptions = FakeSubscriptionRepository();
        await pump(
          tester,
          UserRole.manager,
          path,
          subscriptions: subscriptions,
        );

        expect(currentPath(tester), '/beranda');
        expect(find.byType(SubscriptionScreen), findsNothing);
        expect(find.byType(DowngradeScreen), findsNothing);
        expect(subscriptions.calls, isEmpty);
      });

      testWidgets('sends a tenant from $path to the tenant home', (
        tester,
      ) async {
        final subscriptions = FakeSubscriptionRepository();
        await pump(tester, UserRole.tenant, path, subscriptions: subscriptions);

        expect(currentPath(tester), '/penyewa/beranda');
        expect(find.byType(SubscriptionScreen), findsNothing);
        expect(subscriptions.calls, isEmpty);
      });

      testWidgets('sends an admin from $path to the admin home', (
        tester,
      ) async {
        final subscriptions = FakeSubscriptionRepository();
        await pump(tester, UserRole.admin, path, subscriptions: subscriptions);

        expect(currentPath(tester), '/admin');
        expect(find.byType(SubscriptionScreen), findsNothing);
        expect(subscriptions.calls, isEmpty);
      });
    }

    testWidgets('sends a signed out user to sign in', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      useTallScreen(tester);
      await tester.pumpWidget(buildTestApp(subscriptions: subscriptions));
      await tester.pumpAndSettle();

      goTo(tester, _subscription);
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(SubscriptionScreen), findsNothing);
      expect(subscriptions.calls, isEmpty);
    });
  });
}
