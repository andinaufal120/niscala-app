import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/api/health_repository.dart';
import 'package:niscala/core/api/server_status.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/widgets/server_status_banner.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _noConnectionText =
    'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
const _unavailableText = 'Layanan sedang tidak tersedia. Coba lagi nanti.';

/// A screen with a title and a button, to see the banner over real content.
class _Screen extends StatelessWidget {
  const _Screen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Layar contoh')),
    body: Center(
      child: FilledButton(onPressed: () {}, child: const Text('Simpan')),
    ),
  );
}

Widget _app(FakeHealthRepository health) => ProviderScope(
  overrides: [healthRepositoryProvider.overrideWithValue(health)],
  child: MaterialApp(
    theme: buildTheme(),
    builder: (context, child) => ServerStatusBanner(child: child!),
    home: const _Screen(),
  ),
);

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(_Screen)));

Future<void> _setProblem(
  WidgetTester tester,
  FakeHealthRepository health,
  ServerProblem problem,
) async {
  health.script.queue.add(switch (problem) {
    ServerProblem.noConnection => const ApiFailure.network(),
    ServerProblem.unavailable => const ApiFailure(
      code: 'UNKNOWN',
      statusCode: 503,
    ),
  });
  await _containerOf(tester).read(serverStatusProvider.notifier).check();
  await tester.pump();
}

Finder _retryButton() => find.widgetWithText(TextButton, 'Coba lagi');

void main() {
  late FakeHealthRepository health;

  setUp(() => health = FakeHealthRepository());

  group('without a problem', () {
    testWidgets('shows only the screen', (tester) async {
      await tester.pumpWidget(_app(health));

      expect(find.text('Layar contoh'), findsOneWidget);
      expect(find.text(_noConnectionText), findsNothing);
      expect(find.text(_unavailableText), findsNothing);
      expect(_retryButton(), findsNothing);
    });

    testWidgets('does not call the server by itself', (tester) async {
      await tester.pumpWidget(_app(health));
      await tester.pump();

      expect(health.checks, 0);
    });
  });

  group('copy', () {
    test('the unavailable message is exported by the error messages', () {
      expect(serviceUnavailableMessage, _unavailableText);
    });

    test('the no connection message is the network error message', () {
      expect(messageOfCode('NETWORK_ERROR'), _noConnectionText);
    });
  });

  group('with no connection', () {
    testWidgets('shows the no connection message and a retry button', (
      tester,
    ) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      expect(find.text(_noConnectionText), findsOneWidget);
      expect(find.text(_unavailableText), findsNothing);
      expect(_retryButton(), findsOneWidget);
    });

    testWidgets('keeps showing the screen below the banner', (tester) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      expect(find.text('Layar contoh'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(AppBar)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(_retryButton()).dy),
      );
    });

    testWidgets('announces the message as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      final live = find.descendant(
        of: find.byType(ServerStatusBanner),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
      expect(
        find.descendant(of: live, matching: find.text(_noConnectionText)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('hides the decorative icon from the screen reader', (
      tester,
    ) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      final icon = find.descendant(
        of: find.byType(ServerStatusBanner),
        matching: find.byType(Icon),
      );
      expect(icon, findsOneWidget);
      expect(
        find.ancestor(of: icon, matching: find.byType(ExcludeSemantics)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(tester, _app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      expect(tester.takeException(), isNull);
      expect(find.text(_noConnectionText), findsOneWidget);
      expect(_retryButton(), findsOneWidget);
    });
  });

  group('with the service unavailable', () {
    testWidgets('shows the unavailable message and a retry button', (
      tester,
    ) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.unavailable);

      expect(find.text(_unavailableText), findsOneWidget);
      expect(find.text(_noConnectionText), findsNothing);
      expect(_retryButton(), findsOneWidget);
    });

    testWidgets('announces the message as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.unavailable);

      final live = find.descendant(
        of: find.byType(ServerStatusBanner),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
      expect(
        find.descendant(of: live, matching: find.text(_unavailableText)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.unavailable);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(tester, _app(health));
      await _setProblem(tester, health, ServerProblem.unavailable);

      expect(tester.takeException(), isNull);
      expect(find.text(_unavailableText), findsOneWidget);
      expect(_retryButton(), findsOneWidget);
    });
  });

  group('retry', () {
    testWidgets('checks the server again when tapped', (tester) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);
      expect(health.checks, 1);

      await tester.tap(_retryButton());
      await tester.pump();

      expect(health.checks, 2);
    });

    testWidgets('hides the banner after the retry succeeds', (tester) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);

      await tester.tap(_retryButton());
      await tester.pumpAndSettle();

      expect(find.text(_noConnectionText), findsNothing);
      expect(_retryButton(), findsNothing);
      expect(find.text('Layar contoh'), findsOneWidget);
    });

    testWidgets('keeps the banner while the retry is in flight', (
      tester,
    ) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);
      final gate = Completer<void>();
      health.script.gate = gate;

      await tester.tap(_retryButton());
      await tester.pump();

      expect(find.text(_noConnectionText), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_noConnectionText), findsNothing);
    });

    testWidgets('switches the message when the retry fails differently', (
      tester,
    ) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.noConnection);
      health.script.queue.add(const ApiFailure(code: 'X', statusCode: 503));

      await tester.tap(_retryButton());
      await tester.pumpAndSettle();

      expect(find.text(_unavailableText), findsOneWidget);
      expect(find.text(_noConnectionText), findsNothing);
    });

    testWidgets('keeps the banner when the retry fails again', (tester) async {
      await tester.pumpWidget(_app(health));
      await _setProblem(tester, health, ServerProblem.unavailable);
      health.script.always = const ApiFailure(code: 'X', statusCode: 503);

      await tester.tap(_retryButton());
      await tester.pumpAndSettle();

      expect(find.text(_unavailableText), findsOneWidget);
      expect(_retryButton(), findsOneWidget);
    });
  });
}
