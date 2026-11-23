import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/screen_brightness.dart';
import 'package:niscala/core/widgets/full_brightness.dart';

import '../../helpers/fakes.dart';
import '../../helpers/lifecycle.dart';

/// A [ScreenBrightnessControl] whose methods throw before returning a future.
class _ThrowingSynchronously implements ScreenBrightnessControl {
  var calls = 0;

  @override
  Future<void> raise() {
    calls++;
    throw StateError('raise failed');
  }

  @override
  Future<void> restore() {
    calls++;
    throw StateError('restore failed');
  }
}

Widget _host(
  ScreenBrightnessControl brightness, {
  bool shown = true,
  String text = 'Kode QR',
}) => ProviderScope(
  overrides: [screenBrightnessProvider.overrideWithValue(brightness)],
  child: MaterialApp(
    home: shown ? FullBrightness(child: Text(text)) : const Text('Kosong'),
  ),
);

void _lifecycle(WidgetTester tester, AppLifecycleState state) =>
    moveLifecycleTo(tester.binding, state);

void main() {
  setUp(() {
    moveLifecycleTo(
      TestWidgetsFlutterBinding.ensureInitialized(),
      AppLifecycleState.resumed,
    );
  });

  group('in the tree', () {
    testWidgets('shows its child', (tester) async {
      await tester.pumpWidget(_host(FakeScreenBrightness()));

      expect(find.text('Kode QR'), findsOneWidget);
    });

    testWidgets('raises the brightness once when it is built', (tester) async {
      final brightness = FakeScreenBrightness();

      await tester.pumpWidget(_host(brightness));
      await tester.pump();

      expect(brightness.events, ['raise']);
    });

    testWidgets('does not touch the brightness before it is built', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();

      await tester.pumpWidget(_host(brightness, shown: false));
      await tester.pump();

      expect(brightness.events, isEmpty);
    });

    testWidgets('restores the brightness once when it is removed', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));

      await tester.pumpWidget(_host(brightness, shown: false));
      await tester.pump();

      expect(brightness.events, ['raise', 'restore']);
    });

    testWidgets('raises again when it is built again after being removed', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));
      await tester.pumpWidget(_host(brightness, shown: false));

      await tester.pumpWidget(_host(brightness));

      expect(brightness.events, ['raise', 'restore', 'raise']);
    });

    testWidgets('a rebuild with a new child does not raise again', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));

      await tester.pumpWidget(_host(brightness, text: 'Kode lain'));
      await tester.pump();

      expect(find.text('Kode lain'), findsOneWidget);
      expect(brightness.events, ['raise']);
    });

    testWidgets('many rebuilds neither raise nor restore', (tester) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));

      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(_host(brightness, text: 'Kode $i'));
      }

      expect(brightness.events, ['raise']);
    });
  });

  group('app lifecycle', () {
    final backgrounds = [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ];

    for (final state in backgrounds) {
      testWidgets('restores the brightness once when the app is $state', (
        tester,
      ) async {
        final brightness = FakeScreenBrightness();
        await tester.pumpWidget(_host(brightness));

        _lifecycle(tester, state);
        await tester.pump();

        expect(brightness.events, ['raise', 'restore']);
      });

      testWidgets('raises it again once, when the app resumes from $state', (
        tester,
      ) async {
        final brightness = FakeScreenBrightness();
        await tester.pumpWidget(_host(brightness));
        _lifecycle(tester, state);

        _lifecycle(tester, AppLifecycleState.resumed);
        await tester.pump();

        expect(brightness.events, ['raise', 'restore', 'raise']);
      });
    }

    testWidgets('going further into the background does not restore again', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));

      _lifecycle(tester, AppLifecycleState.inactive);
      _lifecycle(tester, AppLifecycleState.hidden);
      _lifecycle(tester, AppLifecycleState.paused);
      await tester.pump();

      expect(brightness.events, ['raise', 'restore']);
    });

    testWidgets('coming back through the same states raises only on resume', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));
      _lifecycle(tester, AppLifecycleState.inactive);
      _lifecycle(tester, AppLifecycleState.hidden);
      _lifecycle(tester, AppLifecycleState.paused);

      _lifecycle(tester, AppLifecycleState.hidden);
      _lifecycle(tester, AppLifecycleState.inactive);

      expect(brightness.events, ['raise', 'restore']);

      _lifecycle(tester, AppLifecycleState.resumed);
      await tester.pump();

      expect(brightness.events, ['raise', 'restore', 'raise']);
    });

    testWidgets('several round trips alternate restore and raise', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));

      for (var i = 0; i < 3; i++) {
        _lifecycle(tester, AppLifecycleState.paused);
        _lifecycle(tester, AppLifecycleState.resumed);
      }
      await tester.pump();

      expect(brightness.events, [
        'raise',
        'restore',
        'raise',
        'restore',
        'raise',
        'restore',
        'raise',
      ]);
    });

    testWidgets('removing it after a round trip restores once more', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));
      _lifecycle(tester, AppLifecycleState.paused);
      _lifecycle(tester, AppLifecycleState.resumed);

      await tester.pumpWidget(_host(brightness, shown: false));

      expect(brightness.events, ['raise', 'restore', 'raise', 'restore']);
    });

    testWidgets('does not raise when the app resumes after it was removed', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));
      _lifecycle(tester, AppLifecycleState.paused);
      await tester.pumpWidget(_host(brightness, shown: false));

      _lifecycle(tester, AppLifecycleState.resumed);
      await tester.pump();

      expect(brightness.raiseCalls, 1);
    });

    testWidgets('does not react to the lifecycle after it was removed', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));
      await tester.pumpWidget(_host(brightness, shown: false));
      final eventsAfterRemoval = List.of(brightness.events);

      _lifecycle(tester, AppLifecycleState.paused);
      _lifecycle(tester, AppLifecycleState.resumed);
      await tester.pump();

      expect(brightness.events, eventsAfterRemoval);
      expect(eventsAfterRemoval, ['raise', 'restore']);
    });
  });

  group('failures', () {
    testWidgets('a failing raise is swallowed and the child still shows', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness()
        ..raiseFailure = Exception('no window');

      await tester.pumpWidget(_host(brightness));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Kode QR'), findsOneWidget);
      expect(brightness.events, ['raise']);
    });

    testWidgets('a failing restore on removal is swallowed', (tester) async {
      final brightness = FakeScreenBrightness()
        ..restoreFailure = Exception('no window');
      await tester.pumpWidget(_host(brightness));

      await tester.pumpWidget(_host(brightness, shown: false));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Kosong'), findsOneWidget);
      expect(brightness.events, ['raise', 'restore']);
    });

    testWidgets('a failing restore on going to the background is swallowed', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness()
        ..restoreFailure = Exception('no window');
      await tester.pumpWidget(_host(brightness));

      _lifecycle(tester, AppLifecycleState.paused);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Kode QR'), findsOneWidget);
      expect(brightness.events, ['raise', 'restore']);
    });

    testWidgets('a failing raise on resume is swallowed', (tester) async {
      final brightness = FakeScreenBrightness();
      await tester.pumpWidget(_host(brightness));
      _lifecycle(tester, AppLifecycleState.paused);
      brightness.raiseFailure = Exception('no window');

      _lifecycle(tester, AppLifecycleState.resumed);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Kode QR'), findsOneWidget);
      expect(brightness.events, ['raise', 'restore', 'raise']);
    });

    testWidgets('a failing raise does not stop the later restore', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness()
        ..raiseFailure = Exception('no window');
      await tester.pumpWidget(_host(brightness));

      await tester.pumpWidget(_host(brightness, shown: false));

      expect(tester.takeException(), isNull);
      expect(brightness.events, ['raise', 'restore']);
    });

    testWidgets('a synchronous throw on raise is swallowed', (tester) async {
      final brightness = _ThrowingSynchronously();

      await tester.pumpWidget(_host(brightness));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Kode QR'), findsOneWidget);
      expect(brightness.calls, 1);
    });

    testWidgets('a synchronous throw on restore is swallowed', (tester) async {
      final brightness = _ThrowingSynchronously();
      await tester.pumpWidget(_host(brightness));

      _lifecycle(tester, AppLifecycleState.paused);
      await tester.pumpWidget(_host(brightness, shown: false));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Kosong'), findsOneWidget);
    });
  });

  group('provider', () {
    testWidgets('a test can replace the control with a fake', (tester) async {
      final fake = FakeScreenBrightness();
      final container = ProviderContainer(
        overrides: [screenBrightnessProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      expect(container.read(screenBrightnessProvider), same(fake));
    });
  });
}
