import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/slide_page_transitions.dart';
import 'package:niscala/core/theme.dart';

import '../helpers/transitions.dart';

const _home = Key('home');
const _next = Key('next');
const _tick = Duration(milliseconds: 100);

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _pumpSmallApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      navigatorKey: _navigatorKey,
      home: const Scaffold(
        key: _home,
        body: Center(child: Text('Awal')),
      ),
    ),
  );
}

void _push() {
  _navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(
        key: _next,
        body: Center(child: Text('Berikutnya')),
      ),
    ),
  );
}

void main() {
  group('theme', () {
    test('maps every platform to the slide builder', () {
      final builders = buildTheme().pageTransitionsTheme.builders;

      for (final platform in TargetPlatform.values) {
        expect(
          builders[platform],
          isA<SlidePageTransitionsBuilder>(),
          reason: '$platform',
        );
      }
    });

    test('names all six platforms', () {
      expect(TargetPlatform.values, hasLength(6));
      expect(
        buildTheme().pageTransitionsTheme.builders.keys,
        containsAll(TargetPlatform.values),
      );
    });
  });

  group('pushing a route', () {
    testWidgets('slides the new page in from the right', (tester) async {
      await _pumpSmallApp(tester);

      _push();
      await tester.pump();
      await tester.pump(_tick);

      expectMidSlide(tester, find.byKey(_next));
    }, variant: TargetPlatformVariant.all());

    testWidgets('starts the new page off the right edge of the screen', (
      tester,
    ) async {
      await _pumpSmallApp(tester);

      _push();
      await tester.pump();
      await tester.pump();

      expect(
        leftOf(tester, find.byKey(_next)),
        greaterThanOrEqualTo(displayWidth(tester) * 0.9),
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('keeps moving the new page towards the left edge', (
      tester,
    ) async {
      await _pumpSmallApp(tester);

      _push();
      await tester.pump();
      await tester.pump(_tick);
      final early = leftOf(tester, find.byKey(_next));
      await tester.pump(_tick);

      expect(leftOf(tester, find.byKey(_next)), lessThan(early));
    }, variant: TargetPlatformVariant.all());

    testWidgets('moves the old page left a little', (tester) async {
      await _pumpSmallApp(tester);

      _push();
      await tester.pump();
      await tester.pump(_tick);

      final left = leftOf(tester, find.byKey(_home));
      expect(left, lessThan(0));
      expect(left, greaterThan(-displayWidth(tester) / 2));
    }, variant: TargetPlatformVariant.all());

    testWidgets('ends with the new page at x 0', (tester) async {
      await _pumpSmallApp(tester);

      _push();
      await tester.pumpAndSettle();

      expectAtRest(tester, find.byKey(_next));
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.all());

    testWidgets(
      'shows the new page at x 0 after one frame without animations',
      (tester) async {
        useReducedMotion(tester);
        await _pumpSmallApp(tester);

        _push();
        await tester.pump();
        await tester.pump();

        expectAtRest(tester, find.byKey(_next));
        await tester.pump(_tick);
        expectAtRest(tester, find.byKey(_next));
      },
    );
  });

  group('popping a route', () {
    testWidgets('slides the page out to the right', (tester) async {
      await _pumpSmallApp(tester);
      _push();
      await tester.pumpAndSettle();

      _navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(_tick);

      expectMidSlide(tester, find.byKey(_next));
      expect(find.byKey(_home), findsOneWidget);
    }, variant: TargetPlatformVariant.all());

    testWidgets('brings the old page back to x 0', (tester) async {
      await _pumpSmallApp(tester);
      _push();
      await tester.pumpAndSettle();

      _navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(_tick);
      expect(leftOf(tester, find.byKey(_home)), lessThan(0));
      await tester.pumpAndSettle();

      expect(find.byKey(_next), findsNothing);
      expectAtRest(tester, find.byKey(_home));
    }, variant: TargetPlatformVariant.all());

    testWidgets('shows no intermediate offset without animations', (
      tester,
    ) async {
      useReducedMotion(tester);
      await _pumpSmallApp(tester);
      _push();
      await tester.pumpAndSettle();

      _navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(_tick);

      final next = find.byKey(_next);
      if (next.evaluate().isNotEmpty) expectAtRest(tester, next);
      expectAtRest(tester, find.byKey(_home));
    });
  });
}
