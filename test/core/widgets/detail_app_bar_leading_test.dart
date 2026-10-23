import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';

import '../../helpers/a11y.dart';
import '../../helpers/layout.dart';

const _title = 'Rincian Keluhan';
const _subtitle = 'Kamar 08 · Budi Santoso';

Widget _app({
  String? subtitle,
  List<DetailBarAction>? actions,
  bool showBack = true,
  Widget? leading,
  bool canPop = false,
}) {
  Widget bar() => Scaffold(
    appBar: DetailAppBar(
      title: _title,
      subtitle: subtitle,
      actions: actions,
      leading: leading,
      showBack: showBack,
    ),
    body: const SizedBox.expand(),
  );
  return MaterialApp(
    theme: buildTheme(),
    locale: const Locale('id'),
    supportedLocales: const [Locale('id')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: canPop
        ? Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => bar())),
                  child: const Text('Buka'),
                ),
              ),
            ),
          )
        : bar(),
  );
}

Future<void> _show(
  WidgetTester tester, {
  String? subtitle,
  List<DetailBarAction>? actions,
  bool showBack = true,
  Widget? leading,
  bool canPop = false,
  bool largeText = false,
}) async {
  if (largeText) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    _app(
      subtitle: subtitle,
      actions: actions,
      showBack: showBack,
      leading: leading,
      canPop: canPop,
    ),
  );
  if (canPop) {
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }
}

Finder _in(String text) =>
    find.descendant(of: find.byType(DetailAppBar), matching: find.text(text));

Widget _closeLeading(void Function() onTap, {double width = 48}) =>
    GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        key: const ValueKey('leading'),
        width: width,
        child: const Icon(Icons.close),
      ),
    );

void main() {
  setUpAll(loadAppFont);

  group('showBack', () {
    testWidgets('shows a back button on a route that can pop by default', (
      tester,
    ) async {
      await _show(tester, canPop: true);

      expect(find.byTooltip('Kembali'), findsOneWidget);
      expect(
        tester.getTopLeft(_in(_title)).dx,
        greaterThan(NiscalaSpacing.gutter + 24),
      );
    });

    testWidgets('shows a back button when showBack is true', (tester) async {
      await _show(tester, canPop: true, showBack: true);

      expect(find.byTooltip('Kembali'), findsOneWidget);
    });

    testWidgets('shows no back button on a route that cannot pop', (
      tester,
    ) async {
      await _show(tester, showBack: true);

      expect(find.byTooltip('Kembali'), findsNothing);
      expect(
        tester.getTopLeft(_in(_title)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets('shows no back button when showBack is false', (tester) async {
      await _show(tester, canPop: true, showBack: false);

      expect(find.byTooltip('Kembali'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.byType(BackButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.byIcon(Icons.chevron_left),
        ),
        findsNothing,
      );
    });

    testWidgets('puts the title at the gutter when showBack is false', (
      tester,
    ) async {
      await _show(tester, canPop: true, showBack: false, subtitle: _subtitle);

      expect(
        tester.getTopLeft(_in(_title)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
      expect(
        tester.getTopLeft(_in(_subtitle)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets('reserves no slot when showBack is false', (tester) async {
      await _show(tester, canPop: true, showBack: false);
      final without = tester.getTopLeft(_in(_title)).dx;

      await _show(tester, canPop: true);

      expect(without, lessThan(tester.getTopLeft(_in(_title)).dx - 24));
    });

    testWidgets('puts the title at the gutter at 200 percent text', (
      tester,
    ) async {
      await _show(tester, canPop: true, showBack: false, largeText: true);

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(_in(_title)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets('keeps the action when showBack is false', (tester) async {
      var taps = 0;
      await _show(
        tester,
        canPop: true,
        showBack: false,
        actions: [DetailBarAction.text(label: 'Ubah', onPressed: () => taps++)],
      );

      await tester.tap(find.text('Ubah'));

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is 56 dp high for a one line title', (tester) async {
      await _show(tester, canPop: true, showBack: false);

      expect(tester.getSize(find.byType(DetailAppBar)).height, 56);
    });
  });

  group('custom leading', () {
    testWidgets('shows the widget and passes taps to it', (tester) async {
      var taps = 0;
      await _show(tester, leading: _closeLeading(() => taps++));

      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.byIcon(Icons.close),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.close));

      expect(taps, 1);
    });

    testWidgets('keeps it inside the bar', (tester) async {
      await _show(tester, leading: _closeLeading(() {}));

      final bar = tester.getRect(find.byType(DetailAppBar));
      final icon = tester.getRect(find.byIcon(Icons.close));
      expect(icon.left, greaterThanOrEqualTo(bar.left));
      expect(icon.top, greaterThanOrEqualTo(bar.top));
      expect(icon.bottom, lessThanOrEqualTo(bar.bottom));
    });

    testWidgets('starts the title after a 48 dp widget', (tester) async {
      await _show(tester, leading: _closeLeading(() {}));

      expect(
        tester.getTopLeft(_in(_title)).dx,
        greaterThanOrEqualTo(
          tester.getRect(find.byIcon(Icons.close)).right - 1,
        ),
      );
      expect(tester.getTopLeft(_in(_title)).dx, greaterThanOrEqualTo(48));
    });

    testWidgets('starts the title after a widget wider than 48 dp', (
      tester,
    ) async {
      await _show(tester, leading: _closeLeading(() {}, width: 72));

      final widgetRect = tester.getRect(find.byKey(const ValueKey('leading')));
      expect(widgetRect.width, 72);
      expect(
        tester.getTopLeft(_in(_title)).dx,
        greaterThanOrEqualTo(widgetRect.right - 1),
      );
    });

    testWidgets('reserves at least 48 dp for a narrower widget', (
      tester,
    ) async {
      await _show(tester, leading: _closeLeading(() {}, width: 24));

      expect(tester.getTopLeft(_in(_title)).dx, greaterThanOrEqualTo(48));
    });

    testWidgets('replaces the back button on a route that can pop', (
      tester,
    ) async {
      await _show(tester, canPop: true, leading: _closeLeading(() {}));

      expect(find.byTooltip('Kembali'), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows a SizedBox holding an icon as a real widget', (
      tester,
    ) async {
      await _show(
        tester,
        leading: const SizedBox(width: 48, child: Icon(Icons.close)),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(tester.getTopLeft(_in(_title)).dx, greaterThanOrEqualTo(48));
    });

    testWidgets('keeps the 48 dp widget centred at 200 percent text', (
      tester,
    ) async {
      await _show(
        tester,
        leading: _closeLeading(() {}),
        subtitle: _subtitle,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(
        tester.getRect(find.byIcon(Icons.close)).center.dy,
        closeTo(bar.center.dy, 1),
      );
    });

    testWidgets('meets the guidelines with an icon button as leading', (
      tester,
    ) async {
      await _show(
        tester,
        leading: IconButton(
          tooltip: 'Tutup',
          icon: const Icon(Icons.close),
          onPressed: () {},
        ),
      );

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
