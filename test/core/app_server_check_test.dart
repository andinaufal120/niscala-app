import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/server_status_banner.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala_api/api.dart';

import '../helpers/fakes.dart';

const _noConnectionText =
    'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
const _unavailableText = 'Layanan sedang tidak tersedia. Coba lagi nanti.';

/// Sends the app to the background and back to the foreground.
void _backgroundAndResume(WidgetTester tester) {
  final binding = tester.binding;
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  late FakeHealthRepository health;

  setUp(() => health = FakeHealthRepository());

  group('at start-up', () {
    testWidgets('checks the server once when nothing is stored', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      expect(health.checks, 1);
    });

    for (final role in UserRole.values) {
      testWidgets('checks the server once for a stored $role session', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestApp(
            health: health,
            store: InMemorySessionStore(storedSession(role: role)),
          ),
        );
        await tester.pumpAndSettle();

        expect(health.checks, 1);
      });
    }

    testWidgets('checks the server once for an unverified session', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          health: health,
          store: InMemorySessionStore(storedSession(emailVerified: false)),
        ),
      );
      await tester.pumpAndSettle();

      expect(health.checks, 1);
    });

    testWidgets('checks the server before the stored session is read', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(health: health, store: NeverReadySessionStore()),
      );
      await tester.pump();

      expect(health.checks, 1);
    });

    testWidgets('shows no banner when the check succeeds', (tester) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      expect(find.text(_noConnectionText), findsNothing);
      expect(find.text(_unavailableText), findsNothing);
    });

    testWidgets('shows the no connection banner over the sign in screen', (
      tester,
    ) async {
      health.script.always = const ApiFailure.network();

      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      expect(find.byType(ServerStatusBanner), findsOneWidget);
      expect(find.text(_noConnectionText), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows the unavailable banner over a signed in screen', (
      tester,
    ) async {
      health.script.always = const ApiFailure(code: 'X', statusCode: 503);

      await tester.pumpWidget(
        buildTestApp(
          health: health,
          store: InMemorySessionStore(storedSession()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_unavailableText), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('does not block routing while the check never completes', (
      tester,
    ) async {
      health.script.gate = Completer<void>();

      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      expect(health.checks, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('does not block a stored session while the check hangs', (
      tester,
    ) async {
      health.script.gate = Completer<void>();

      await tester.pumpWidget(
        buildTestApp(
          health: health,
          store: InMemorySessionStore(storedSession()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text(_noConnectionText), findsNothing);
    });
  });

  group('on resume', () {
    testWidgets('checks the server again after the app was paused', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();
      expect(health.checks, 1);

      _backgroundAndResume(tester);
      await tester.pumpAndSettle();

      expect(health.checks, 2);
    });

    testWidgets('does not check while the app goes to the background', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(health.checks, 1);
    });

    testWidgets('checks again on every resume', (tester) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      _backgroundAndResume(tester);
      await tester.pumpAndSettle();
      _backgroundAndResume(tester);
      await tester.pumpAndSettle();

      expect(health.checks, 3);
    });

    testWidgets('checks again on resume for a signed in session', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          health: health,
          store: InMemorySessionStore(storedSession()),
        ),
      );
      await tester.pumpAndSettle();

      _backgroundAndResume(tester);
      await tester.pumpAndSettle();

      expect(health.checks, 2);
    });

    testWidgets('hides the banner when the check on resume succeeds', (
      tester,
    ) async {
      health.script.queue.add(const ApiFailure.network());
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();
      expect(find.text(_noConnectionText), findsOneWidget);

      _backgroundAndResume(tester);
      await tester.pumpAndSettle();

      expect(find.text(_noConnectionText), findsNothing);
    });

    testWidgets('shows the banner when the check on resume fails', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();
      expect(find.text(_noConnectionText), findsNothing);
      health.script.queue.add(const ApiFailure.network());

      _backgroundAndResume(tester);
      await tester.pumpAndSettle();

      expect(find.text(_noConnectionText), findsOneWidget);
    });

    testWidgets('shares the request when a check is still in flight', (
      tester,
    ) async {
      health.script.gate = Completer<void>();
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      _backgroundAndResume(tester);
      await tester.pumpAndSettle();

      expect(health.checks, 1);
    });

    testWidgets('stops checking once the app is removed', (tester) async {
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      _backgroundAndResume(tester);
      await tester.pump();

      expect(health.checks, 1);
    });
  });

  group('retry button', () {
    testWidgets('checks the server again and hides the banner on success', (
      tester,
    ) async {
      health.script.queue.add(const ApiFailure.network());
      await tester.pumpWidget(buildTestApp(health: health));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Coba lagi'));
      await tester.pumpAndSettle();

      expect(health.checks, 2);
      expect(find.text(_noConnectionText), findsNothing);
    });
  });
}
