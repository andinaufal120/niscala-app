import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/screen_header.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/layout.dart';

Widget _stable({String? subtitle, required bool withAction}) => themedApp(
  Scaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: 'Properti',
          subtitle: subtitle,
          action: withAction
              ? FilledButton(onPressed: () {}, child: const Text('Tambah'))
              : null,
        ),
        const SizedBox(key: Key('below'), height: 10),
      ],
    ),
  ),
);

({double height, Offset title, double below}) _measure(WidgetTester tester) => (
  height: tester.getSize(find.byType(ScreenHeader)).height,
  title: tester.getTopLeft(find.text('Properti')),
  below: tester.getTopLeft(find.byKey(const Key('below'))).dy,
);

void main() {
  setUpAll(loadAppFont);

  for (final largeText in [false, true]) {
    for (final subtitle in [null, '3 properti']) {
      testWidgets('keeps height, title position and body in place when the '
          'action comes and goes, with subtitle $subtitle at '
          '${largeText ? '200' : '100'} percent text', (tester) async {
        Future<void> show(bool withAction) async {
          final screen = _stable(subtitle: subtitle, withAction: withAction);
          if (largeText) {
            await pumpAtLargeText(tester, screen);
          } else {
            await tester.pumpWidget(screen);
          }
          await tester.pumpAndSettle();
        }

        await show(false);
        final without = _measure(tester);
        await show(true);
        final withIt = _measure(tester);

        expect(tester.takeException(), isNull);
        expect(withIt.height, closeTo(without.height, 0.5));
        expect(withIt.title.dx, closeTo(without.title.dx, 0.5));
        expect(withIt.title.dy, closeTo(without.title.dy, 0.5));
        expect(withIt.below, closeTo(without.below, 0.5));
      });
    }
  }

  for (final subtitle in [null, '3 properti']) {
    testWidgets('centres the action against the title block with subtitle '
        '$subtitle', (tester) async {
      await tester.pumpWidget(_stable(subtitle: subtitle, withAction: true));

      var block = tester.getRect(find.text('Properti'));
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
