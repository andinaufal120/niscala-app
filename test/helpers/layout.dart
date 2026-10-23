import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';

/// Loads the bundled font, because the default test font is far wider than the
/// real one and would make every row wrap.
Future<void> loadAppFont() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/PlusJakartaSans-$weight.ttf')
        .readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Shrinks the display to 360 x 640 dp at the normal text scale, after a pump
/// helper has shown the screen on a tall display.
Future<void> useNarrowScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpAndSettle();
}

/// The width of the display in logical pixels.
double screenWidth(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

/// Scrollables that scroll sideways.
Finder horizontalScrollables() => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable &&
      (widget.axisDirection == AxisDirection.left ||
          widget.axisDirection == AxisDirection.right),
);

/// Expects every chip named in [labels] to sit on one line, inside one and the
/// same horizontally scrolling row, and in no [Wrap].
void expectSingleScrollingRow(
  WidgetTester tester,
  Finder Function(String label) chip,
  List<String> labels,
) {
  final rows = <Element>{};
  double? top;
  for (final label in labels) {
    final finder = chip(label);
    expect(finder, findsOneWidget, reason: 'chip "$label"');
    expect(
      find.ancestor(of: finder, matching: find.byType(Wrap)),
      findsNothing,
      reason: 'chip "$label" must not sit in a Wrap',
    );
    final row = find.ancestor(of: finder, matching: horizontalScrollables());
    expect(
      row,
      findsOneWidget,
      reason: 'chip "$label" must sit in a horizontal scroll view',
    );
    rows.add(row.evaluate().single);
    final y = tester.getTopLeft(finder).dy;
    top ??= y;
    expect(y, closeTo(top, 0.5), reason: 'chip "$label" is on another line');
  }
  expect(rows, hasLength(1), reason: 'the chips must share one scrolling row');
}

/// Expects the scrolling row holding [chip] to be wider than its viewport.
void expectRowScrolls(WidgetTester tester, Finder chip) {
  final state = tester.state<ScrollableState>(
    find.ancestor(of: chip, matching: horizontalScrollables()),
  );
  expect(state.position.maxScrollExtent, greaterThan(0));
}

/// The widgets between [child] and the nearest scroll view above it, nearest
/// first.
List<Widget> _wrappersOf(Finder child) {
  final widgets = <Widget>[];
  child.evaluate().first.visitAncestorElements((element) {
    if (element.widget is Scrollable) return false;
    widgets.add(element.widget);
    return true;
  });
  return widgets;
}

Color? _decorationColor(Decoration? decoration) => switch (decoration) {
  BoxDecoration(:final color) => color,
  ShapeDecoration(:final color) => color,
  _ => null,
};

BorderRadiusGeometry? _decorationRadius(Decoration? decoration) =>
    switch (decoration) {
      BoxDecoration(:final borderRadius) => borderRadius,
      ShapeDecoration(:final shape) when shape is RoundedRectangleBorder =>
        shape.borderRadius,
      _ => null,
    };

BorderSide? _decorationSide(Decoration? decoration) => switch (decoration) {
  BoxDecoration(:final border) when border is Border => border.top,
  ShapeDecoration(:final shape) when shape is OutlinedBorder => shape.side,
  _ => null,
};

/// Whether some widget around [child] paints a background of [color].
bool hasFillAround(Finder child, Color color) => _wrappersOf(child).any(
  (widget) => switch (widget) {
    Material(color: final fill) => fill == color,
    DecoratedBox(:final decoration) => _decorationColor(decoration) == color,
    ColoredBox(color: final fill) => fill == color,
    Ink(:final decoration) => _decorationColor(decoration) == color,
    _ => false,
  },
);

/// Whether one widget around [child] paints a background of [color] with
/// corners rounded by [radius].
bool hasRoundedFillAround(Finder child, Color color, double radius) {
  final expected = BorderRadius.circular(radius);
  return _wrappersOf(child).any(
    (widget) => switch (widget) {
      Material(color: final fill, :final shape) =>
        fill == color &&
            shape is RoundedRectangleBorder &&
            shape.borderRadius == expected,
      DecoratedBox(:final decoration) =>
        _decorationColor(decoration) == color &&
            _decorationRadius(decoration) == expected,
      Ink(:final decoration) =>
        _decorationColor(decoration) == color &&
            _decorationRadius(decoration) == expected,
      _ => false,
    },
  );
}

/// Whether some widget around [child] draws a visible outline.
bool hasBorderAround(Finder child) => _wrappersOf(child).any((widget) {
  final side = switch (widget) {
    Material(:final shape) when shape is OutlinedBorder => shape.side,
    DecoratedBox(:final decoration) => _decorationSide(decoration),
    Ink(:final decoration) => _decorationSide(decoration),
    _ => null,
  };
  return side != null && side.style != BorderStyle.none && side.width > 0;
});

/// The style [part] is drawn in inside the text found by [text], with the
/// styles of the enclosing spans merged in.
TextStyle styleOfPart(WidgetTester tester, Finder text, String part) {
  final rich = tester.widget<RichText>(
    find.descendant(of: text, matching: find.byType(RichText)).first,
  );
  TextStyle? found;
  void walk(InlineSpan span, TextStyle inherited) {
    if (span is! TextSpan) return;
    final style = span.style == null ? inherited : inherited.merge(span.style);
    if (found == null && (span.text ?? '').contains(part)) found = style;
    for (final child in span.children ?? const <InlineSpan>[]) {
      walk(child, style);
    }
  }

  walk(rich.text, const TextStyle());
  expect(found, isNotNull, reason: 'no span contains "$part"');
  return found!;
}

/// The style of the whole text found by [text].
TextStyle styleOf(WidgetTester tester, Finder text) {
  final rich = tester.widget<RichText>(
    find.descendant(of: text, matching: find.byType(RichText)).first,
  );
  return rich.text.style ?? const TextStyle();
}

/// The colour an icon is drawn in, from itself or from the theme around it.
Color? iconColorOf(WidgetTester tester, Finder icon) =>
    tester.widget<Icon>(icon).color ?? IconTheme.of(tester.element(icon)).color;

/// Icons that show a trash can.
final trashIcons = <IconData>{
  Icons.delete,
  Icons.delete_outline,
  Icons.delete_outlined,
  Icons.delete_forever,
  Icons.delete_forever_outlined,
};

/// Icons in [scope] that show a trash can.
Finder trashIconIn(Finder scope) => find.descendant(
  of: scope,
  matching: find.byWidgetPredicate(
    (widget) => widget is Icon && trashIcons.contains(widget.icon),
  ),
);

/// The outlined button holding the text [label], whether or not it has an
/// icon.
Finder outlinedButtonLabelled(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<OutlinedButton>(),
);

/// The text button holding the text [label], whether or not it has an icon.
Finder textButtonLabelled(String label) =>
    find.ancestor(of: find.text(label), matching: find.bySubtype<TextButton>());

/// Expects the danger action [label]: an outlined button with a trash icon in
/// the danger colour, a danger-tinted border and the width of [reference].
void expectDangerOutlinedButton(
  WidgetTester tester,
  String label, {
  required Finder reference,
}) {
  final button = outlinedButtonLabelled(label);
  expect(button, findsOneWidget, reason: '"$label" must be an OutlinedButton');

  final icon = trashIconIn(button);
  expect(icon, findsOneWidget, reason: '"$label" must show a trash icon');
  expect(iconColorOf(tester, icon), NiscalaColors.danger);
  expect(styleOf(tester, find.text(label)).color, NiscalaColors.danger);

  final widget = tester.widget<OutlinedButton>(button);
  final theme = OutlinedButtonTheme.of(tester.element(button)).style;
  final side = (widget.style?.side ?? theme?.side)?.resolve(<WidgetState>{});
  expect(side, isNotNull);
  final tint = side!.color;
  expect(tint, isNot(NiscalaColors.controlBorder));
  expect(
    tint.r - tint.g,
    greaterThan(0.05),
    reason: 'the border must be tinted with the danger colour',
  );
  expect(tint.r, greaterThan(tint.b));

  expect(
    tester.getSize(button).width,
    closeTo(tester.getSize(reference.first).width, 1),
    reason: '"$label" must be as wide as the cards',
  );
}
