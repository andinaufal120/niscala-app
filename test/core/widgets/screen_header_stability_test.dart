import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/screen_header.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/layout.dart';

const _shortTitle = 'Properti';
const _shortSubtitle = '3 properti';
const _longTitle = 'Daftar properti milik pemilik kos';
const _longSubtitle = 'Semua properti beserta kamar dan penyewa milik Anda';

Widget _header({
  String title = _shortTitle,
  String? subtitle,
  bool? actionVisible,
  bool withAction = true,
  VoidCallback? onPressed,
}) {
  final action = withAction
      ? FilledButton(onPressed: onPressed ?? () {}, child: const Text('Tambah'))
      : null;
  return themedApp(
    Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          actionVisible == null
              ? ScreenHeader(title: title, subtitle: subtitle, action: action)
              : ScreenHeader(
                  title: title,
                  subtitle: subtitle,
                  action: action,
                  actionVisible: actionVisible,
                ),
          const SizedBox(key: Key('below'), height: 10),
        ],
      ),
    ),
  );
}

/// Shows [screen] on a 360 x 640 dp display.
Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  required bool largeText,
}) async {
  if (largeText) {
    await pumpAtLargeText(tester, screen);
  } else {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen);
  }
  await tester.pumpAndSettle();
}

typedef _Measure = ({
  double height,
  Rect title,
  Rect? subtitle,
  double below,
  Rect? action,
});

_Measure _measure(
  WidgetTester tester, {
  required String title,
  required String? subtitle,
}) => (
  height: tester.getSize(find.byType(ScreenHeader)).height,
  title: tester.getRect(find.text(title)),
  subtitle: subtitle == null ? null : tester.getRect(find.text(subtitle)),
  below: tester.getTopLeft(find.byKey(const Key('below'))).dy,
  action: find.byType(FilledButton).evaluate().isEmpty
      ? null
      : tester.getRect(find.byType(FilledButton)),
);

void _expectRect(Rect actual, Rect expected, String what) {
  expect(actual.left, closeTo(expected.left, 0.5), reason: '$what left');
  expect(actual.top, closeTo(expected.top, 0.5), reason: '$what top');
  expect(actual.width, closeTo(expected.width, 0.5), reason: '$what width');
  expect(actual.height, closeTo(expected.height, 0.5), reason: '$what height');
}

void main() {
  setUpAll(loadAppFont);

  test('shows the action by default', () {
    expect(const ScreenHeader(title: _shortTitle).actionVisible, isTrue);
  });

  for (final largeText in [false, true]) {
    final scale = largeText ? '200' : '100';
    for (final subtitle in [null, _shortSubtitle, _longSubtitle]) {
      for (final title in [_shortTitle, _longTitle]) {
        testWidgets('keeps height, title, subtitle and body in place whether '
            'the action is visible or hidden, with title "$title" and '
            'subtitle $subtitle at $scale percent text', (tester) async {
          await _show(
            tester,
            _header(title: title, subtitle: subtitle, actionVisible: false),
            largeText: largeText,
          );
          final hidden = _measure(tester, title: title, subtitle: subtitle);
          await _show(
            tester,
            _header(title: title, subtitle: subtitle, actionVisible: true),
            largeText: largeText,
          );
          final shown = _measure(tester, title: title, subtitle: subtitle);

          expect(tester.takeException(), isNull);
          expect(shown.height, closeTo(hidden.height, 0.5), reason: 'height');
          _expectRect(shown.title, hidden.title, 'title');
          if (subtitle != null) {
            _expectRect(shown.subtitle!, hidden.subtitle!, 'subtitle');
          }
          expect(shown.below, closeTo(hidden.below, 0.5), reason: 'body');
          _expectRect(shown.action!, hidden.action!, 'action');
        });
      }
    }

    testWidgets('does not expose or react to a hidden action at $scale '
        'percent text', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      try {
        await _show(
          tester,
          _header(
            subtitle: _shortSubtitle,
            actionVisible: false,
            onPressed: () => taps++,
          ),
          largeText: largeText,
        );

        expect(find.bySemanticsLabel('Tambah'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(ScreenHeader),
            matching: find.byType(FilledButton),
            skipOffstage: false,
          ),
          findsOneWidget,
          reason: 'the hidden action is still laid out',
        );

        await tester.tapAt(tester.getCenter(find.byType(FilledButton)));
        await tester.pump();
        expect(taps, 0);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('exposes and reacts to a visible action at $scale percent '
        'text', (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      try {
        await _show(
          tester,
          _header(
            subtitle: _shortSubtitle,
            actionVisible: true,
            onPressed: () => taps++,
          ),
          largeText: largeText,
        );

        expect(find.bySemanticsLabel('Tambah'), findsOneWidget);
        await tester.tap(find.byType(FilledButton));
        expect(taps, 1);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('paints nothing for a hidden action at $scale percent text', (
      tester,
    ) async {
      await _show(tester, _header(actionVisible: false), largeText: largeText);

      final opacity = find.ancestor(
        of: find.byType(FilledButton),
        matching: find.byType(Opacity),
      );
      final visibility = find.ancestor(
        of: find.byType(FilledButton),
        matching: find.byType(Visibility),
      );
      final hiddenByOpacity = opacity.evaluate().any(
        (e) => (e.widget as Opacity).opacity == 0,
      );
      final hiddenByVisibility = visibility.evaluate().any((e) {
        final widget = e.widget as Visibility;
        return !widget.visible &&
            widget.maintainSize &&
            widget.maintainState &&
            widget.maintainAnimation;
      });
      expect(hiddenByOpacity || hiddenByVisibility, isTrue);
    });

    testWidgets('wraps a long title and subtitle without ellipsis at $scale '
        'percent text', (tester) async {
      await _show(
        tester,
        _header(title: _longTitle, subtitle: _longSubtitle),
        largeText: largeText,
      );

      expect(tester.takeException(), isNull);
      for (final text in [_longTitle, _longSubtitle]) {
        final widget = tester.widget<Text>(find.text(text));
        expect(widget.overflow, isNot(TextOverflow.ellipsis), reason: text);
        expect(widget.maxLines, isNull, reason: text);
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        expect(paragraph.didExceedMaxLines, isFalse, reason: text);
      }
    });
  }

  testWidgets('lays out the whole long title and subtitle across several '
      'lines at 200 percent text', (tester) async {
    await _show(
      tester,
      _header(title: _longTitle, subtitle: _longSubtitle),
      largeText: true,
    );

    expect(tester.takeException(), isNull);
    final title = tester.renderObject<RenderParagraph>(find.text(_longTitle));
    final subtitle = tester.renderObject<RenderParagraph>(
      find.text(_longSubtitle),
    );
    expect(title.size.height, greaterThan(title.preferredLineHeight * 1.5));
    expect(
      subtitle.size.height,
      greaterThan(subtitle.preferredLineHeight * 1.5),
    );
    final header = tester.getRect(find.byType(ScreenHeader));
    expect(
      tester.getRect(find.text(_longTitle)).bottom,
      lessThan(header.bottom),
    );
    expect(
      tester.getRect(find.text(_longSubtitle)).bottom,
      lessThanOrEqualTo(header.bottom),
    );
    expect(tester.getRect(find.text(_longTitle)).right, lessThan(360));
    expect(tester.getRect(find.text(_longSubtitle)).right, lessThan(360));
  });

  testWidgets('keeps a header without an action at least 48 dp high plus '
      'its padding', (tester) async {
    await _show(tester, _header(withAction: false), largeText: false);

    expect(
      tester.getSize(find.byType(ScreenHeader)).height,
      greaterThanOrEqualTo(48 + NiscalaSpacing.l + NiscalaSpacing.m),
    );
  });

  testWidgets('keeps the same height with a hidden action and with none at '
      '100 percent text and a short title', (tester) async {
    await _show(tester, _header(withAction: false), largeText: false);
    final none = tester.getSize(find.byType(ScreenHeader)).height;
    await _show(tester, _header(actionVisible: false), largeText: false);

    expect(
      tester.getSize(find.byType(ScreenHeader)).height,
      closeTo(none, 0.5),
    );
  });

  testWidgets('gives the title the whole width when there is no action', (
    tester,
  ) async {
    await _show(
      tester,
      _header(title: _longTitle, withAction: false),
      largeText: true,
    );
    final without = tester.getRect(find.text(_longTitle)).width;
    await _show(
      tester,
      _header(title: _longTitle, actionVisible: false),
      largeText: true,
    );

    expect(
      tester.getRect(find.text(_longTitle)).width,
      lessThanOrEqualTo(without + 0.5),
    );
  });

  for (final subtitle in [null, _shortSubtitle]) {
    testWidgets('centres the action against the title block with subtitle '
        '$subtitle', (tester) async {
      await _show(tester, _header(subtitle: subtitle), largeText: false);

      var block = tester.getRect(find.text(_shortTitle));
      if (subtitle != null) {
        block = block.expandToInclude(tester.getRect(find.text(subtitle)));
      }
      expect(
        tester.getRect(find.byType(FilledButton)).center.dy,
        closeTo(block.center.dy, 1),
      );
    });
  }
}
