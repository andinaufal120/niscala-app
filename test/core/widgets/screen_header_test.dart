import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/screen_header.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _white = Color(0xFFFFFFFF);
const _textMuted = Color(0xFF50605B);

Widget _screen({
  String title = 'Properti',
  String? subtitle,
  Widget? action,
  double textScale = 1,
}) => themedApp(
  Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: title, subtitle: subtitle, action: action),
          ],
        ),
      ),
    ),
  ),
);

Widget _addButton({VoidCallback? onPressed}) =>
    FilledButton(onPressed: onPressed ?? () {}, child: const Text('Tambah'));

bool _paintsWhite(WidgetTester tester) {
  final scope = find.descendant(
    of: find.byType(ScreenHeader),
    matching: find.byWidgetPredicate((widget) {
      if (widget is ColoredBox) return widget.color == _white;
      if (widget is DecoratedBox) {
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.color == _white;
      }
      if (widget is Material) return widget.color == _white;
      return false;
    }),
  );
  return scope.evaluate().isNotEmpty;
}

void main() {
  group('title', () {
    testWidgets('shows the title', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.text('Properti'), findsOneWidget);
    });

    testWidgets('writes the title 22 extra-bold', (tester) async {
      await tester.pumpWidget(_screen());

      final style = tester.widget<Text>(find.text('Properti')).style;
      expect(style?.fontSize, 22);
      expect(style?.fontWeight, FontWeight.w800);
    });

    testWidgets('is a header for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen());

        expect(
          tester.getSemantics(find.text('Properti')),
          isSemantics(label: 'Properti', isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('follows the title it is given', (tester) async {
      await tester.pumpWidget(_screen(title: 'Keluhan'));

      expect(find.text('Keluhan'), findsOneWidget);
      expect(find.text('Properti'), findsNothing);
    });

    testWidgets('sits on a white background', (tester) async {
      await tester.pumpWidget(_screen());

      expect(_paintsWhite(tester), isTrue);
    });

    testWidgets('stretches over the full width of the screen', (tester) async {
      await tester.pumpWidget(_screen());

      expect(
        tester.getSize(find.byType(ScreenHeader)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });
  });

  group('subtitle', () {
    testWidgets('shows the subtitle under the title', (tester) async {
      await tester.pumpWidget(_screen(subtitle: '3 properti'));

      expect(find.text('3 properti'), findsOneWidget);
      final title = tester.getRect(find.text('Properti'));
      final subtitle = tester.getRect(find.text('3 properti'));
      expect(subtitle.top, greaterThanOrEqualTo(title.bottom));
    });

    testWidgets('writes the subtitle muted', (tester) async {
      await tester.pumpWidget(_screen(subtitle: '3 properti'));

      expect(
        tester.widget<Text>(find.text('3 properti')).style?.color,
        _textMuted,
      );
    });

    testWidgets('shows no subtitle when none is given', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('is not a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen(subtitle: '3 properti'));

        expect(
          tester.getSemantics(find.text('3 properti')),
          isNot(isSemantics(isHeader: true)),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('trailing action', () {
    testWidgets('shows the action', (tester) async {
      await tester.pumpWidget(_screen(action: _addButton()));

      expect(find.text('Tambah'), findsOneWidget);
    });

    testWidgets('shows no action when none is given', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('passes taps to the action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _screen(action: _addButton(onPressed: () => taps++)),
      );

      await tester.tap(find.text('Tambah'));

      expect(taps, 1);
    });

    testWidgets('puts the action after the title', (tester) async {
      await tester.pumpWidget(_screen(action: _addButton()));

      final title = tester.getRect(find.text('Properti'));
      final action = tester.getRect(find.byType(FilledButton));
      expect(action.left, greaterThanOrEqualTo(title.right));
    });

    testWidgets('keeps the action inside the screen', (tester) async {
      await tester.pumpWidget(_screen(action: _addButton()));

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getRect(find.byType(FilledButton)).right,
        lessThanOrEqualTo(width),
      );
    });

    testWidgets('keeps the action at least 48 by 48 dp', (tester) async {
      await tester.pumpWidget(_screen(action: _addButton()));

      final size = tester.getSize(find.byType(FilledButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('keeps an icon button action at least 48 by 48 dp', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          action: IconButton(
            onPressed: () {},
            tooltip: 'Tambah properti',
            icon: const Icon(Icons.add),
          ),
        ),
      );

      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('text scale', () {
    testWidgets('grows with the text scale', (tester) async {
      await tester.pumpWidget(_screen(subtitle: '3 properti'));
      final normal = tester.getSize(find.byType(ScreenHeader)).height;

      await tester.pumpWidget(_screen(subtitle: '3 properti', textScale: 2));
      final large = tester.getSize(find.byType(ScreenHeader)).height;

      expect(large, greaterThan(normal));
    });

    testWidgets('fits a long title, subtitle and action at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(
        tester,
        _screen(
          title: 'Daftar keluhan dari seluruh penyewa kos',
          subtitle: 'Kos Melati Indah, Jalan Kenanga Nomor 12, Sleman',
          action: _addButton(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tambah'), findsOneWidget);
    });

    testWidgets('fits a title alone at large text size', (tester) async {
      await pumpAtLargeText(tester, _screen());

      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with title only', (tester) async {
      await tester.pumpWidget(_screen());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with subtitle and action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(subtitle: '3 properti', action: _addButton()),
      );

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
