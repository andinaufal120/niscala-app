import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  await tester.pumpWidget(const SizedBox());
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

    testWidgets('starts the title at the screen gutter without a back button', (
      tester,
    ) async {
      await _show(tester);

      expect(find.byTooltip('Kembali'), findsNothing);
      expect(
        tester.getTopLeft(_in(_title)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets('starts the title at the gutter with subtitle and actions but '
        'no back button', (tester) async {
      await _show(tester, subtitle: _subtitle, actions: [_action()]);

      expect(
        tester.getTopLeft(_in(_title)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
      expect(
        tester.getTopLeft(_in(_subtitle)).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets(
      'does not reserve the back button space without a back button',
      (tester) async {
        await _show(tester);
        final without = tester.getTopLeft(_in(_title)).dx;

        await _show(tester, canPop: true);

        expect(without, lessThan(tester.getTopLeft(_in(_title)).dx - 24));
      },
    );

    testWidgets(
      'puts the title at the same x on every bar with a back button',
      (tester) async {
        await _show(tester, canPop: true);
        final plain = tester.getTopLeft(_in(_title)).dx;

        await _show(
          tester,
          title: 'Undangan Penyewa',
          subtitle: _subtitle,
          actions: [_action()],
          canPop: true,
        );

        expect(find.byTooltip('Kembali'), findsOneWidget);
        expect(
          tester.getTopLeft(_in('Undangan Penyewa')).dx,
          closeTo(plain, 0.5),
        );
      },
    );

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
      bool canPop = false,
    }) async {
      await pumpAtLargeText(
        tester,
        _app(
          title: title,
          subtitle: subtitle,
          actions: actions,
          canPop: canPop,
        ),
      );
      await tester.pumpAndSettle();
      if (canPop) {
        await tester.tap(find.text('Buka'));
        await tester.pumpAndSettle();
      }
    }

    double barHeight(WidgetTester tester) =>
        tester.getSize(find.byType(DetailAppBar)).height;

    /// The height of the title and subtitle texts laid out one under the other.
    double blockHeight(WidgetTester tester, String title, String? subtitle) {
      final first = tester.getRect(_in(title));
      final last = subtitle == null ? first : tester.getRect(_in(subtitle));
      return last.bottom - first.top;
    }

    void expectCentred(WidgetTester tester, String title, String? subtitle) {
      final first = tester.getRect(_in(title));
      final last = subtitle == null ? first : tester.getRect(_in(subtitle));
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(
        (first.top + last.bottom) / 2,
        closeTo(bar.center.dy, 1),
        reason: 'the title block is centred in the bar',
      );
    }

    testWidgets('has no empty band under a one line title at 200 percent', (
      tester,
    ) async {
      await large(tester);

      expect(tester.takeException(), isNull);
      expect(barHeight(tester), greaterThanOrEqualTo(56));
      expect(barHeight(tester), lessThanOrEqualTo(72));
    });

    testWidgets('is as tall as the text block plus 16 dp at 200 percent', (
      tester,
    ) async {
      await large(tester, subtitle: _subtitle);

      final block = blockHeight(tester, _title, _subtitle);
      expect(barHeight(tester), closeTo(math.max(56, block + 16), 1));
      expect(barHeight(tester), lessThanOrEqualTo(block + 24));
    });

    testWidgets('is as tall as the text block plus 16 dp for a title only', (
      tester,
    ) async {
      await large(tester);

      final block = blockHeight(tester, _title, null);
      expect(barHeight(tester), closeTo(math.max(56, block + 16), 1));
    });

    testWidgets('is as tall as the wrapped text plus 16 dp at 200 percent', (
      tester,
    ) async {
      const title = 'Rincian keluhan dari penyewa kamar';
      const subtitle = 'Kamar 08 · Budi Santoso Wijayakusuma';
      await large(
        tester,
        title: title,
        subtitle: subtitle,
        actions: [_action()],
      );

      final block = blockHeight(tester, title, subtitle);
      expect(tester.takeException(), isNull);
      expect(barHeight(tester), closeTo(math.max(56, block + 16), 1));
      expect(barHeight(tester), lessThanOrEqualTo(block + 24));
    });

    testWidgets('is 56 dp or the text block plus 16 dp at normal text', (
      tester,
    ) async {
      await _show(tester, subtitle: _subtitle);

      final first = tester.getRect(_in(_title));
      final last = tester.getRect(_in(_subtitle));
      expect(
        tester.getSize(find.byType(DetailAppBar)).height,
        closeTo(math.max(56, last.bottom - first.top + 16), 1),
      );
    });

    testWidgets('centres a one line title in the bar at 200 percent', (
      tester,
    ) async {
      await large(tester);

      expectCentred(tester, _title, null);
    });

    testWidgets('centres title and subtitle in the bar at 200 percent', (
      tester,
    ) async {
      await large(tester, subtitle: _subtitle);

      expectCentred(tester, _title, _subtitle);
    });

    testWidgets('centres a wrapped title block in the bar at 200 percent', (
      tester,
    ) async {
      const title = 'Rincian keluhan dari penyewa kamar';
      const subtitle = 'Kamar 08 · Budi Santoso Wijayakusuma';
      await large(
        tester,
        title: title,
        subtitle: subtitle,
        actions: [_action()],
      );

      expectCentred(tester, title, subtitle);
    });

    testWidgets('centres the title in the 56 dp bar at normal text', (
      tester,
    ) async {
      await _show(tester);

      expectCentred(tester, _title, null);
    });

    testWidgets('centres the title and subtitle in the 56 dp bar at normal '
        'text', (tester) async {
      await _show(tester, subtitle: _subtitle);

      expectCentred(tester, _title, _subtitle);
    });

    testWidgets('keeps a 48 dp back button centred at 200 percent', (
      tester,
    ) async {
      await large(tester, canPop: true);

      final back = tester.getRect(find.byTooltip('Kembali'));
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(back.width, greaterThanOrEqualTo(48));
      expect(back.height, greaterThanOrEqualTo(48));
      expect(back.center.dy, closeTo(bar.center.dy, 1));
      expect(back.top, greaterThanOrEqualTo(bar.top));
      expect(back.bottom, lessThanOrEqualTo(bar.bottom));
    });

    testWidgets('keeps a 48 dp back button centred next to a tall wrapped '
        'title', (tester) async {
      await large(
        tester,
        title: 'Rincian keluhan dari penyewa kamar',
        subtitle: 'Kamar 08 · Budi Santoso Wijayakusuma',
        actions: [_action()],
        canPop: true,
      );

      final back = tester.getRect(find.byTooltip('Kembali'));
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(tester.takeException(), isNull);
      expect(back.width, greaterThanOrEqualTo(48));
      expect(back.height, greaterThanOrEqualTo(48));
      expect(back.center.dy, closeTo(bar.center.dy, 1));
    });

    testWidgets('keeps a 48 dp action centred at 200 percent', (tester) async {
      await large(tester, actions: [_action()]);

      final action = tester.getRect(find.byTooltip('Bagikan'));
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(action.width, greaterThanOrEqualTo(48));
      expect(action.height, greaterThanOrEqualTo(48));
      expect(action.center.dy, closeTo(bar.center.dy, 1));
    });

    testWidgets('keeps a 48 dp action centred next to a tall wrapped title', (
      tester,
    ) async {
      await large(
        tester,
        title: 'Rincian keluhan dari penyewa kamar',
        subtitle: 'Kamar 08 · Budi Santoso Wijayakusuma',
        actions: [_action()],
      );

      final action = tester.getRect(find.byTooltip('Bagikan'));
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(action.width, greaterThanOrEqualTo(48));
      expect(action.height, greaterThanOrEqualTo(48));
      expect(action.center.dy, closeTo(bar.center.dy, 1));
    });

    testWidgets('reports the height it is laid out with at 200 percent', (
      tester,
    ) async {
      await large(tester, subtitle: _subtitle);

      expect(
        tester
            .widget<DetailAppBar>(find.byType(DetailAppBar))
            .preferredSize
            .height,
        closeTo(barHeight(tester), 0.5),
      );
    });

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

    testWidgets('wraps a long title and subtitle instead of ellipsizing at 200 '
        'percent', (tester) async {
      const title = 'Rincian keluhan dari penyewa kamar';
      const subtitle = 'Kamar 08 · Budi Santoso Wijayakusuma';
      await large(
        tester,
        title: title,
        subtitle: subtitle,
        actions: [_action()],
      );

      expect(tester.takeException(), isNull);
      for (final text in [title, subtitle]) {
        final widget = tester.widget<Text>(_in(text));
        expect(widget.overflow, isNot(TextOverflow.ellipsis), reason: text);
        expect(widget.maxLines, isNull, reason: text);
        final paragraph = tester.renderObject<RenderParagraph>(_in(text));
        expect(paragraph.didExceedMaxLines, isFalse, reason: text);
        expect(
          paragraph.size.height,
          greaterThan(paragraph.preferredLineHeight * 1.5),
          reason: '$text is laid out across several lines',
        );
      }
    });

    testWidgets('grows past the one line bar when the text wraps at 200 '
        'percent', (tester) async {
      await large(tester);
      final oneLine = tester.getSize(find.byType(DetailAppBar)).height;

      await large(
        tester,
        title: 'Rincian keluhan dari penyewa kamar',
        subtitle: 'Kamar 08 · Budi Santoso Wijayakusuma',
        actions: [_action()],
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DetailAppBar)).height,
        greaterThan(oneLine),
      );
      final bar = tester.getRect(find.byType(DetailAppBar));
      expect(
        tester.getRect(_in('Rincian keluhan dari penyewa kamar')).top,
        greaterThanOrEqualTo(bar.top),
      );
      expect(
        tester.getRect(_in('Kamar 08 · Budi Santoso Wijayakusuma')).bottom,
        lessThanOrEqualTo(bar.bottom),
      );
    });

    testWidgets('does not ellipsize at normal text either', (tester) async {
      await _show(
        tester,
        title: 'Rincian keluhan dari penyewa kamar',
        subtitle: 'Kamar 08 · Budi Santoso Wijayakusuma',
      );

      for (final text in [
        'Rincian keluhan dari penyewa kamar',
        'Kamar 08 · Budi Santoso Wijayakusuma',
      ]) {
        final widget = tester.widget<Text>(_in(text));
        expect(widget.overflow, isNot(TextOverflow.ellipsis), reason: text);
        expect(widget.maxLines, isNull, reason: text);
      }
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
