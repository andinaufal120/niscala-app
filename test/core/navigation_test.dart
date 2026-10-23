import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/theme.dart';

import '../helpers/transitions.dart';

const _tick = Duration(milliseconds: 100);

/// A page that leaves to [leaveTo] with its buttons. One button leaves once,
/// the others call the leave twice and three times in the same event, as a
/// double tap that the router has not caught up with would.
class _Page extends StatelessWidget {
  const _Page(this.name, {this.leaveTo = '/a'});

  final String name;
  final String leaveTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('page-$name'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: ValueKey('leave-$name'),
              onPressed: () => leavePageTo(context, leaveTo),
              child: Text('Tutup $name'),
            ),
            TextButton(
              key: ValueKey('leave-twice-$name'),
              onPressed: () {
                leavePageTo(context, leaveTo);
                leavePageTo(context, leaveTo);
              },
              child: Text('Tutup dua kali $name'),
            ),
            TextButton(
              key: ValueKey('leave-thrice-$name'),
              onPressed: () {
                leavePageTo(context, leaveTo);
                leavePageTo(context, leaveTo);
                leavePageTo(context, leaveTo);
              },
              child: Text('Tutup tiga kali $name'),
            ),
          ],
        ),
      ),
    );
  }
}

Finder _page(String name) => find.byKey(ValueKey('page-$name'));

Finder _pageEvenIfHidden(String name) =>
    find.byKey(ValueKey('page-$name'), skipOffstage: false);

Finder _leave(String name) => find.byKey(ValueKey('leave-$name'));

Finder _leaveTwice(String name) => find.byKey(ValueKey('leave-twice-$name'));

Finder _leaveThrice(String name) => find.byKey(ValueKey('leave-thrice-$name'));

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

/// Shows a router with the pages home > a > b > c (and a separate z), opened
/// on [location], with every page leaving to [leaveTo].
Future<GoRouter> _pump(
  WidgetTester tester, {
  String location = '/a/b/c',
  String leaveTo = '/a',
}) async {
  GoRoute route(
    String path,
    String name, [
    List<RouteBase> routes = const [],
  ]) => GoRoute(
    path: path,
    pageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: _Page(name, leaveTo: leaveTo),
    ),
    routes: routes,
  );

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      route('/', 'home', [
        route('a', 'a', [
          route('b', 'b', [route('c', 'c')]),
        ]),
      ]),
      route('/z', 'z'),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: buildTheme(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  router.go(location);
  await tester.pumpAndSettle();
  return router;
}

/// Expects no page except [leaving] to move to the right. The page right under
/// the leaving one may sit a little to the left, as the transition moves it.
void _expectOthersNotSliding(WidgetTester tester, String leaving) {
  for (final name in ['home', 'a', 'b', 'c', 'z']) {
    if (name == leaving) continue;
    final finder = _pageEvenIfHidden(name);
    if (finder.evaluate().isEmpty) continue;
    expect(
      tester.getTopLeft(finder).dx,
      lessThanOrEqualTo(0.01),
      reason: 'page $name must not slide while $leaving leaves',
    );
  }
}

void main() {
  group('leavePageTo', () {
    testWidgets('ends on the target page at rest', (tester) async {
      final router = await _pump(tester);
      expect(_page('c'), findsOneWidget);

      await tester.tap(_leave('c'));
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_page('a'), findsOneWidget);
      expectAtRest(tester, _page('a'));
      expect(_pageEvenIfHidden('b'), findsNothing);
      expect(_pageEvenIfHidden('c'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('slides the leaving page out to the right', (tester) async {
      await _pump(tester);

      await tester.tap(_leave('c'));
      await tester.pump();
      await tester.pump(_tick);

      expectMidSlide(tester, _page('c'));
    });

    testWidgets('keeps moving the leaving page to the right', (tester) async {
      await _pump(tester);

      await tester.tap(_leave('c'));
      await tester.pump();
      await tester.pump(_tick);
      final early = leftOf(tester, _page('c'));
      await tester.pump(_tick);

      expect(leftOf(tester, _page('c')), greaterThan(early));
    });

    testWidgets('slides out only the leaving page, in one animation', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(_leave('c'));
      await tester.pump();
      await tester.pump(_tick);

      _expectOthersNotSliding(tester, 'c');
    });

    testWidgets('leaving from one level below the target pops that level', (
      tester,
    ) async {
      final router = await _pump(tester, location: '/a/b');

      await tester.tap(_leave('b'));
      await tester.pump();
      await tester.pump(_tick);
      expectMidSlide(tester, _page('b'));
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_pageEvenIfHidden('b'), findsNothing);
      expectAtRest(tester, _page('a'));
    });

    testWidgets('keeps the pages below the target in the history', (
      tester,
    ) async {
      final router = await _pump(tester);
      await tester.tap(_leave('c'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_path(router), '/');
      expect(_page('home'), findsOneWidget);
      expectAtRest(tester, _page('home'));
    });

    testWidgets('shows no intermediate offset without animations', (
      tester,
    ) async {
      useReducedMotion(tester);
      final router = await _pump(tester);

      await tester.tap(_leave('c'));
      await tester.pump();
      await tester.pump(_tick);

      if (_page('c').evaluate().isNotEmpty) expectAtRest(tester, _page('c'));
      await tester.pumpAndSettle();
      expect(_path(router), '/a');
      expectAtRest(tester, _page('a'));
    });

    testWidgets('does not pop past the target when called twice at once', (
      tester,
    ) async {
      final router = await _pump(tester);

      await tester.tap(_leaveTwice('c'));
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_page('a'), findsOneWidget);
      expectAtRest(tester, _page('a'));
      expect(_pageEvenIfHidden('c'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_path(router), '/');
      expect(_page('home'), findsOneWidget);
    });

    testWidgets('does not pop past the target when called three times at '
        'once', (tester) async {
      final router = await _pump(tester);

      await tester.tap(_leaveThrice('c'));
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_page('a'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not pop past the target when called again a frame '
        'later', (tester) async {
      final router = await _pump(tester);

      await tester.tap(_leave('c'));
      await tester.pump();
      await tester.tap(_leave('c'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_page('a'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not pop past the target from one level below', (
      tester,
    ) async {
      final router = await _pump(tester, location: '/a/b');

      await tester.tap(_leaveTwice('b'));
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_page('a'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays on the target when already there', (tester) async {
      final router = await _pump(tester, location: '/a');

      await tester.tap(_leave('a'));
      await tester.pumpAndSettle();

      expect(_path(router), '/a');
      expect(_page('a'), findsOneWidget);
      expectAtRest(tester, _page('a'));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_path(router), '/');
    });

    testWidgets('goes to the location when it is not below the page', (
      tester,
    ) async {
      final router = await _pump(tester, leaveTo: '/z');

      await tester.tap(_leave('c'));
      await tester.pumpAndSettle();

      expect(_path(router), '/z');
      expect(_page('z'), findsOneWidget);
      expectAtRest(tester, _page('z'));
      expect(_pageEvenIfHidden('c'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('goes to a location below the page only once when called '
        'twice', (tester) async {
      final router = await _pump(tester, leaveTo: '/z');

      await tester.tap(_leaveTwice('c'));
      await tester.pumpAndSettle();

      expect(_path(router), '/z');
      expect(_page('z'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
