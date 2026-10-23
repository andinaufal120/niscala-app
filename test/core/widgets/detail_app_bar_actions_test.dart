import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';

import '../../helpers/a11y.dart';
import '../../helpers/layout.dart';

const _title = 'Rincian keluhan dari penyewa kamar';
const _longTitle =
    'Rincian keluhan dari penyewa kamar nomor delapan di Kos Melati';
const _subtitle = 'Kamar 08 · Budi Santoso';

Widget _app({
  String title = _title,
  String? subtitle,
  List<DetailBarAction>? actions,
  bool canPop = false,
}) {
  // The bar has a back button exactly when the test pushes it. Its height is
  // measured before it is built, so the bar is told whether it has one.
  Widget bar() => Scaffold(
    appBar: DetailAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      showBack: canPop,
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

/// Shows the bar on a display [width] dp wide at text scale [scale].
Future<void> _show(
  WidgetTester tester, {
  double width = 360,
  double scale = 1,
  String title = _title,
  String? subtitle,
  List<DetailBarAction>? actions,
  bool canPop = false,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

/// The button that holds the text [label].
Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<ButtonStyleButton>(),
);

double _barHeight(WidgetTester tester) =>
    tester.getSize(find.byType(DetailAppBar)).height;

/// The height of the title and subtitle texts laid out one under the other.
double _blockHeight(WidgetTester tester, String title, String? subtitle) {
  final first = tester.getRect(_in(title));
  final last = subtitle == null ? first : tester.getRect(_in(subtitle));
  return last.bottom - first.top;
}

void _expectFits(WidgetTester tester, String title, String? subtitle) {
  expect(tester.takeException(), isNull);
  final bar = tester.getRect(find.byType(DetailAppBar));
  final block = _blockHeight(tester, title, subtitle);
  expect(_barHeight(tester), closeTo(math.max(56, block + 16), 1));
  expect(tester.getRect(_in(title)).top, greaterThanOrEqualTo(bar.top));
  if (subtitle != null) {
    expect(tester.getRect(_in(subtitle)).bottom, lessThanOrEqualTo(bar.bottom));
  } else {
    expect(tester.getRect(_in(title)).bottom, lessThanOrEqualTo(bar.bottom));
  }
  for (final text in [title, ?subtitle]) {
    final widget = tester.widget<Text>(_in(text));
    expect(widget.overflow, isNot(TextOverflow.ellipsis), reason: text);
    expect(widget.maxLines, isNull, reason: text);
    expect(
      tester.renderObject<RenderParagraph>(_in(text)).didExceedMaxLines,
      isFalse,
      reason: text,
    );
  }
  expect(
    tester.widget<DetailAppBar>(find.byType(DetailAppBar)).preferredSize.height,
    closeTo(_barHeight(tester), 0.5),
    reason: 'the measured height is the laid out height',
  );
}

void main() {
  setUpAll(loadAppFont);

  for (final scale in [1.0, 2.0]) {
    for (final label in ['Ubah', 'Selesai dan tutup']) {
      group(
        'text action "$label" at ${(scale * 100).round()} percent text',
        () {
          Future<void> show(
            WidgetTester tester, {
            String title = _title,
            String? subtitle = _subtitle,
            void Function()? onPressed,
            bool canPop = false,
          }) => _show(
            tester,
            // A long label at 200 percent leaves a 360 dp display almost no
            // room for the title, so that case uses a wider display.
            width: scale > 1 && label.length > 10 ? 600 : 360,
            scale: scale,
            title: title,
            subtitle: subtitle,
            actions: [
              DetailBarAction.text(label: label, onPressed: onPressed ?? () {}),
            ],
            canPop: canPop,
          );

          testWidgets('shows the label once, on one line', (tester) async {
            await show(tester);

            expect(tester.takeException(), isNull);
            expect(_in(label), findsOneWidget);
            final paragraph = tester.renderObject<RenderParagraph>(_in(label));
            expect(
              paragraph.size.height,
              lessThan(paragraph.preferredLineHeight * 1.5),
              reason: 'the label is not wrapped',
            );
          });

          testWidgets('keeps the title and the subtitle left of the action', (
            tester,
          ) async {
            await show(tester);

            final action = tester.getRect(_button(label));
            expect(
              tester.getRect(_in(_title)).right,
              lessThanOrEqualTo(action.left + 0.5),
            );
            expect(
              tester.getRect(_in(_subtitle)).right,
              lessThanOrEqualTo(action.left + 0.5),
            );
          });

          testWidgets('keeps a long title left of the action', (tester) async {
            await show(tester, title: _longTitle);

            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(_in(_longTitle)).right,
              lessThanOrEqualTo(tester.getRect(_button(label)).left + 0.5),
            );
          });

          testWidgets('wraps the title instead of ellipsizing it', (
            tester,
          ) async {
            await show(tester, title: _longTitle);

            final widget = tester.widget<Text>(_in(_longTitle));
            expect(widget.overflow, isNot(TextOverflow.ellipsis));
            expect(widget.maxLines, isNull);
            final paragraph = tester.renderObject<RenderParagraph>(
              _in(_longTitle),
            );
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(
              paragraph.size.height,
              greaterThan(paragraph.preferredLineHeight * 1.5),
              reason: 'the long title is laid out across several lines',
            );
          });

          testWidgets(
            'fits the wrapped text with no overflow and no clipping',
            (tester) async {
              await show(tester, title: _longTitle);

              _expectFits(tester, _longTitle, _subtitle);
            },
          );

          testWidgets('fits a title without a subtitle', (tester) async {
            await show(tester, subtitle: null);

            _expectFits(tester, _title, null);
          });

          testWidgets('keeps a 48 dp action centred with a 20 dp gutter', (
            tester,
          ) async {
            await show(tester, title: _longTitle);

            final action = tester.getRect(_button(label));
            final bar = tester.getRect(find.byType(DetailAppBar));
            expect(action.height, greaterThanOrEqualTo(48));
            expect(action.width, greaterThanOrEqualTo(48));
            expect(screenWidth(tester) - action.right, closeTo(20, 0.5));
            expect(action.center.dy, closeTo(bar.center.dy, 1));
            expect(action.top, greaterThanOrEqualTo(bar.top));
            expect(action.bottom, lessThanOrEqualTo(bar.bottom));
          });

          testWidgets('is wide enough for its label', (tester) async {
            await show(tester);

            final action = tester.getRect(_button(label));
            final text = tester.getRect(_in(label));
            expect(text.left, greaterThanOrEqualTo(action.left - 0.5));
            expect(text.right, lessThanOrEqualTo(action.right + 0.5));
          });

          testWidgets('calls onPressed once when tapped by its label', (
            tester,
          ) async {
            var taps = 0;
            await show(tester, onPressed: () => taps++);

            await tester.tap(find.text(label));

            expect(taps, 1);
          });

          testWidgets('keeps a back button and the action apart', (
            tester,
          ) async {
            await show(tester, canPop: true);

            expect(tester.takeException(), isNull);
            expect(find.byTooltip('Kembali'), findsOneWidget);
            expect(
              tester.getRect(_in(_title)).right,
              lessThanOrEqualTo(tester.getRect(_button(label)).left + 0.5),
            );
            expect(
              tester.getRect(_in(_title)).left,
              greaterThanOrEqualTo(
                tester.getRect(find.byTooltip('Kembali')).right - 1,
              ),
            );
          });

          testWidgets('reports the height it is laid out with', (tester) async {
            await show(tester, title: _longTitle);

            expect(
              tester
                  .widget<DetailAppBar>(find.byType(DetailAppBar))
                  .preferredSize
                  .height,
              closeTo(_barHeight(tester), 0.5),
            );
          });
        },
      );
    }
  }

  group('icon action', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('keeps a 48 dp target at ${(scale * 100).round()} percent', (
        tester,
      ) async {
        await _show(
          tester,
          scale: scale,
          subtitle: _subtitle,
          actions: [
            DetailBarAction.icon(
              icon: Icons.close,
              tooltip: 'Tutup',
              onPressed: () {},
            ),
          ],
        );

        final action = tester.getRect(find.byTooltip('Tutup'));
        final bar = tester.getRect(find.byType(DetailAppBar));
        expect(tester.takeException(), isNull);
        expect(action.width, greaterThanOrEqualTo(48));
        expect(action.height, greaterThanOrEqualTo(48));
        expect(screenWidth(tester) - action.right, closeTo(20, 0.5));
        expect(action.center.dy, closeTo(bar.center.dy, 1));
        expect(
          tester.getRect(_in(_title)).right,
          lessThanOrEqualTo(action.left + 0.5),
        );
        _expectFits(tester, _title, _subtitle);
      });
    }

    testWidgets('shows the icon and is tapped by its tooltip', (tester) async {
      var taps = 0;
      await _show(
        tester,
        actions: [
          DetailBarAction.icon(
            icon: Icons.share,
            tooltip: 'Bagikan',
            onPressed: () => taps++,
          ),
        ],
      );

      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.byIcon(Icons.share),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Bagikan'));

      expect(taps, 1);
    });

    testWidgets('is announced by its tooltip', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _show(
          tester,
          actions: [
            DetailBarAction.icon(
              icon: Icons.share,
              tooltip: 'Bagikan',
              onPressed: () {},
            ),
          ],
        );

        final node = tester.getSemantics(find.byTooltip('Bagikan'));
        expect(node, isSemantics(isButton: true, hasTapAction: true));
        expect('${node.label} ${node.tooltip}', contains('Bagikan'));
      } finally {
        handle.dispose();
      }
    });
  });

  group('title width', () {
    for (final action in <({String name, DetailBarAction action})>[
      (
        name: 'an icon action',
        action: DetailBarAction.icon(
          icon: Icons.close,
          tooltip: 'Tutup',
          onPressed: () {},
        ),
      ),
      (
        name: 'a text action',
        action: DetailBarAction.text(label: 'Ubah', onPressed: () {}),
      ),
    ]) {
      Finder actionFinder() => action.name == 'an icon action'
          ? find.byTooltip('Tutup')
          : _button('Ubah');

      testWidgets('uses the whole width from the gutter to ${action.name} '
          'without a back button', (tester) async {
        await _show(tester, width: 800, actions: [action.action]);
        final oneLine = tester.getRect(_in(_title));
        final actionWidth = tester.getRect(actionFinder()).width;

        // The room from the gutter to the action is the width of the title
        // and 6 dp.
        await _show(
          tester,
          width: oneLine.width + 6 + 20 + actionWidth + 20,
          actions: [action.action],
        );

        expect(tester.takeException(), isNull);
        expect(tester.getTopLeft(_in(_title)).dx, closeTo(20, 0.5));
        expect(
          tester.getRect(_in(_title)).height,
          closeTo(oneLine.height, 0.5),
          reason: 'the title fits on one line',
        );
        expect(
          tester.getRect(_in(_title)).right,
          lessThanOrEqualTo(tester.getRect(actionFinder()).left + 0.5),
        );
        _expectFits(tester, _title, null);
      });

      testWidgets('is narrower with a back button next to ${action.name}', (
        tester,
      ) async {
        await _show(tester, width: 800, actions: [action.action]);
        final oneLine = tester.getRect(_in(_title));
        final actionWidth = tester.getRect(actionFinder()).width;

        await _show(
          tester,
          width: oneLine.width + 6 + 20 + actionWidth + 20,
          actions: [action.action],
          canPop: true,
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(_in(_title)).height,
          greaterThan(oneLine.height * 1.5),
          reason: 'the back button takes room, so the title wraps',
        );
        expect(
          tester.getRect(_in(_title)).right,
          lessThanOrEqualTo(tester.getRect(actionFinder()).left + 0.5),
        );
      });
    }
  });

  group('without actions', () {
    testWidgets('gives the title the width up to the right gutter', (
      tester,
    ) async {
      await _show(tester, width: 800);
      final oneLine = tester.getRect(_in(_title));

      await _show(tester, width: oneLine.width + 6 + 20 + 20);

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_in(_title)).height, closeTo(oneLine.height, 0.5));
    });

    testWidgets('shows no button', (tester) async {
      await _show(tester);

      expect(
        find.descendant(
          of: find.byType(DetailAppBar),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
        findsNothing,
      );
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with a text action', (tester) async {
      await _show(
        tester,
        subtitle: _subtitle,
        actions: [DetailBarAction.text(label: 'Ubah', onPressed: () {})],
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an icon action and a back button', (
      tester,
    ) async {
      await _show(
        tester,
        subtitle: _subtitle,
        canPop: true,
        actions: [
          DetailBarAction.icon(
            icon: Icons.share,
            tooltip: 'Bagikan',
            onPressed: () {},
          ),
        ],
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a long text action at 200 percent', (
      tester,
    ) async {
      await _show(
        tester,
        width: 600,
        scale: 2,
        subtitle: _subtitle,
        actions: [
          DetailBarAction.text(label: 'Selesai dan tutup', onPressed: () {}),
        ],
      );

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
