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
  String title = _title,
  String? subtitle,
  List<Widget>? actions,
  bool canPop = false,
}) {
  Widget bar() => Scaffold(
    appBar: DetailAppBar(title: title, subtitle: subtitle, actions: actions),
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
  String title = _title,
  String? subtitle,
  List<Widget>? actions,
  bool canPop = false,
}) async {
  await tester.pumpWidget(
    _app(title: title, subtitle: subtitle, actions: actions, canPop: canPop),
  );
  if (canPop) {
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }
}

Finder _in(String text) =>
    find.descendant(of: find.byType(DetailAppBar), matching: find.text(text));

Widget _action() => IconButton(
  onPressed: () {},
  tooltip: 'Bagikan',
  icon: const Icon(Icons.share),
);

void main() {
  setUpAll(loadAppFont);

  group('title', () {
    testWidgets('shows the title inside an app bar', (tester) async {
      await _show(tester);

      expect(_in(_title), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.byType(AppBar),
        ),
        findsOneWidget,
      );
    });

    for (final subtitle in [null, _subtitle]) {
      testWidgets('writes the title 17 bold with subtitle $subtitle', (
        tester,
      ) async {
        await _show(tester, subtitle: subtitle);

        final style = styleOf(tester, _in(_title));
        expect(style.fontSize, 17);
        expect(style.fontWeight, FontWeight.w700);
      });
    }

    testWidgets('is a header for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _show(tester);

        expect(
          tester.getSemantics(_in(_title)),
          isSemantics(label: _title, isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('subtitle', () {
    testWidgets('shows the subtitle under the title, left aligned', (
      tester,
    ) async {
      await _show(tester, subtitle: _subtitle);

      final title = tester.getRect(_in(_title));
      final subtitle = tester.getRect(_in(_subtitle));
      expect(subtitle.top, greaterThanOrEqualTo(title.bottom - 1));
      expect(subtitle.left, closeTo(title.left, 0.5));
    });

    testWidgets('writes the subtitle 12 muted', (tester) async {
      await _show(tester, subtitle: _subtitle);

      final style = styleOf(tester, _in(_subtitle));
      expect(style.fontSize, 12);
      expect(style.color, NiscalaColors.textMuted);
    });

    testWidgets('shows only the title when there is no subtitle', (
      tester,
    ) async {
      await _show(tester);

      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is read after the title and is not a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _show(tester, subtitle: _subtitle);

        final title = tester.getSemantics(_in(_title));
        final subtitle = tester.getSemantics(_in(_subtitle));
        expect(title, isSemantics(label: _title, isHeader: true));
        expect(subtitle, isSemantics(label: _subtitle));
        expect(subtitle, isNot(isSemantics(isHeader: true)));
        expect(
          tester.getRect(_in(_subtitle)).top,
          greaterThanOrEqualTo(tester.getRect(_in(_title)).top),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('height and position', () {
    for (final subtitle in [null, _subtitle]) {
      testWidgets('is 56 dp high with subtitle $subtitle', (tester) async {
        await _show(tester, subtitle: subtitle);

        expect(
          tester.widget<DetailAppBar>(find.byType(DetailAppBar)).preferredSize,
          const Size.fromHeight(56),
        );
        expect(tester.getSize(find.byType(DetailAppBar)).height, 56);
      });
    }

    testWidgets('keeps the content of a subtitled bar inside its 56 dp', (
      tester,
    ) async {
      await _show(tester, subtitle: _subtitle);

      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(tester.getRect(_in(_title)).top, greaterThanOrEqualTo(bar.top));
      expect(
        tester.getRect(_in(_subtitle)).bottom,
        lessThanOrEqualTo(bar.bottom),
      );
    });

    testWidgets('puts the title at the same x with and without a subtitle', (
      tester,
    ) async {
      await _show(tester);
      final plain = tester.getTopLeft(_in(_title)).dx;

      await _show(tester, subtitle: _subtitle);

      expect(tester.getTopLeft(_in(_title)).dx, closeTo(plain, 0.5));
    });

    testWidgets('puts the title at the same x with and without a back button', (
      tester,
    ) async {
      await _show(tester);
      final root = tester.getTopLeft(_in(_title)).dx;

      await _show(tester, canPop: true);

      expect(find.byTooltip('Kembali'), findsOneWidget);
      expect(tester.getTopLeft(_in(_title)).dx, closeTo(root, 0.5));
    });

    testWidgets('leaves the back button room before the title', (tester) async {
      await _show(tester, canPop: true);

      expect(
        tester.getTopLeft(_in(_title)).dx,
        greaterThanOrEqualTo(
          tester.getRect(find.byTooltip('Kembali')).right - 1,
        ),
      );
    });
  });

  group('back button', () {
    testWidgets('shows Kembali when the route can pop and pops it', (
      tester,
    ) async {
      await _show(tester, canPop: true);

      expect(find.byTooltip('Kembali'), findsOneWidget);
      final size = tester.getSize(find.byTooltip('Kembali'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailAppBar), findsNothing);
      expect(find.text('Buka'), findsOneWidget);
    });

    testWidgets('shows no back button on a root route', (tester) async {
      await _show(tester);

      expect(find.byTooltip('Kembali'), findsNothing);
    });
  });

  group('actions', () {
    testWidgets('shows the actions after the title', (tester) async {
      await _show(tester, actions: [_action()]);

      expect(find.byTooltip('Bagikan'), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Bagikan')).left,
        greaterThanOrEqualTo(tester.getRect(_in(_title)).right - 1),
      );
    });

    testWidgets('ends with a 20 dp gutter on the right', (tester) async {
      await _show(tester, actions: [_action()]);

      expect(
        screenWidth(tester) - tester.getRect(find.byTooltip('Bagikan')).right,
        closeTo(20, 0.5),
      );
    });

    testWidgets('keeps the 20 dp gutter after a text button', (tester) async {
      await _show(
        tester,
        subtitle: _subtitle,
        actions: [TextButton(onPressed: () {}, child: const Text('Ubah'))],
      );

      expect(
        screenWidth(tester) - tester.getRect(find.byType(TextButton)).right,
        closeTo(20, 0.5),
      );
    });

    testWidgets('passes taps to the action', (tester) async {
      var taps = 0;
      await _show(
        tester,
        actions: [
          IconButton(
            onPressed: () => taps++,
            tooltip: 'Bagikan',
            icon: const Icon(Icons.share),
          ),
        ],
      );

      await tester.tap(find.byTooltip('Bagikan'));

      expect(taps, 1);
    });

    testWidgets('shows no action when none is given', (tester) async {
      await _show(tester);

      expect(find.byType(IconButton), findsNothing);
    });
  });

  group('text scale', () {
    Future<void> large(
      WidgetTester tester, {
      String? subtitle,
      List<Widget>? actions,
      String title = _title,
    }) async {
      await pumpAtLargeText(
        tester,
        _app(title: title, subtitle: subtitle, actions: actions),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('grows with a subtitle at 200 percent text', (tester) async {
      await large(tester, subtitle: _subtitle);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(DetailAppBar)).height, greaterThan(56));
    });

    testWidgets('keeps title and subtitle inside the bar at 200 percent', (
      tester,
    ) async {
      await large(tester, subtitle: _subtitle);

      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(tester.getRect(_in(_title)).top, greaterThanOrEqualTo(bar.top));
      expect(
        tester.getRect(_in(_subtitle)).bottom,
        lessThanOrEqualTo(bar.bottom),
      );
    });

    testWidgets('is at least 56 dp and fits without a subtitle', (
      tester,
    ) async {
      await large(tester);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DetailAppBar)).height,
        greaterThanOrEqualTo(56),
      );
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(tester.getRect(_in(_title)).bottom, lessThanOrEqualTo(bar.bottom));
    });

    testWidgets('fits a long title, subtitle and action at 200 percent', (
      tester,
    ) async {
      await large(
        tester,
        title: 'Rincian keluhan dari penyewa kamar',
        subtitle: 'Kamar 08 · Budi Santoso Wijayakusuma',
        actions: [_action()],
      );

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(
        tester.getRect(_in('Kamar 08 · Budi Santoso Wijayakusuma')).bottom,
        lessThanOrEqualTo(bar.bottom),
      );
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with a title only', (tester) async {
      await _show(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with subtitle, back button, action', (
      tester,
    ) async {
      await _show(
        tester,
        subtitle: _subtitle,
        actions: [_action()],
        canPop: true,
      );

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
