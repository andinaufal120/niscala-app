import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/action_footer.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _white = Color(0xFFFFFFFF);
const _divider = Color(0xFFDCE3E0);

Widget _screen({
  VoidCallback? onPrimary,
  VoidCallback? onSecondary,
  bool withSecondary = false,
  String primaryLabel = 'Simpan',
}) => themedApp(
  Scaffold(
    body: const Center(child: Text('Isi layar')),
    bottomNavigationBar: ActionFooter(
      primary: FilledButton(
        onPressed: onPrimary ?? () {},
        child: Text(primaryLabel),
      ),
      secondary: withSecondary
          ? OutlinedButton(
              onPressed: onSecondary ?? () {},
              child: const Text('Batal'),
            )
          : null,
    ),
  ),
);

bool _hasWidget(WidgetTester tester, bool Function(Widget) test) => find
    .descendant(
      of: find.byType(ActionFooter),
      matching: find.byWidgetPredicate(test),
    )
    .evaluate()
    .isNotEmpty;

bool _hasTopDivider(WidgetTester tester) => _hasWidget(tester, (widget) {
  if (widget is Divider) {
    return widget.color == null || widget.color == _divider;
  }
  if (widget is DecoratedBox) {
    final decoration = widget.decoration;
    if (decoration is BoxDecoration && decoration.border != null) {
      final top = decoration.border!.dimensions.resolve(TextDirection.ltr).top;
      return top == 1 && (decoration.border as Border).top.color == _divider;
    }
  }
  return false;
});

void main() {
  group('content', () {
    testWidgets('shows the primary action', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('shows no secondary action when none is given', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('shows the secondary action when one is given', (tester) async {
      await tester.pumpWidget(_screen(withSecondary: true));

      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('passes taps to the primary action', (tester) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(
        _screen(
          onPrimary: () => primary++,
          onSecondary: () => secondary++,
          withSecondary: true,
        ),
      );

      await tester.tap(find.text('Simpan'));

      expect(primary, 1);
      expect(secondary, 0);
    });

    testWidgets('passes taps to the secondary action', (tester) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(
        _screen(
          onPrimary: () => primary++,
          onSecondary: () => secondary++,
          withSecondary: true,
        ),
      );

      await tester.tap(find.text('Batal'));

      expect(primary, 0);
      expect(secondary, 1);
    });
  });

  group('look', () {
    testWidgets('is pinned to the bottom of the screen', (tester) async {
      await tester.pumpWidget(_screen());

      final height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(tester.getRect(find.byType(ActionFooter)).bottom, height);
    });

    testWidgets('stretches over the full width of the screen', (tester) async {
      await tester.pumpWidget(_screen());

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getSize(find.byType(ActionFooter)).width, width);
    });

    testWidgets('is white', (tester) async {
      await tester.pumpWidget(_screen());

      expect(
        _hasWidget(tester, (widget) {
          if (widget is ColoredBox) return widget.color == _white;
          if (widget is Material) return widget.color == _white;
          if (widget is DecoratedBox) {
            final decoration = widget.decoration;
            return decoration is BoxDecoration && decoration.color == _white;
          }
          return false;
        }),
        isTrue,
      );
    });

    testWidgets('has a 1 px divider on top', (tester) async {
      await tester.pumpWidget(_screen());

      expect(_hasTopDivider(tester), isTrue);
    });

    testWidgets('pads the action 20 sideways', (tester) async {
      await tester.pumpWidget(_screen());

      final footer = tester.getRect(find.byType(ActionFooter));
      final button = tester.getRect(find.byType(FilledButton));
      expect(button.left - footer.left, 20);
      expect(footer.right - button.right, 20);
    });

    testWidgets('pads the action 12 on top and 18 below', (tester) async {
      await tester.pumpWidget(_screen());

      final footer = tester.getRect(find.byType(ActionFooter));
      final button = tester.getRect(find.byType(FilledButton));
      // The divider may or may not take part of the top padding.
      expect(button.top - footer.top, inInclusiveRange(12, 13));
      expect(footer.bottom - button.bottom, 18);
    });

    testWidgets('keeps every action at least 48 by 48 dp', (tester) async {
      await tester.pumpWidget(_screen(withSecondary: true));

      for (final type in [FilledButton, OutlinedButton]) {
        final size = tester.getSize(find.byType(type));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('keeps the secondary action clear of the primary one', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(withSecondary: true));

      final primary = tester.getRect(find.byType(FilledButton));
      final secondary = tester.getRect(find.byType(OutlinedButton));
      expect(primary.overlaps(secondary), isFalse);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with one action', (tester) async {
      await tester.pumpWidget(_screen());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with two actions', (tester) async {
      await tester.pumpWidget(_screen(withSecondary: true));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits one action at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        _screen(primaryLabel: 'Simpan perubahan data kamar'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ActionFooter), findsOneWidget);
    });

    testWidgets('fits two actions at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        _screen(
          withSecondary: true,
          primaryLabel: 'Simpan perubahan data kamar',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
