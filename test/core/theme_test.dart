import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';

import '../helpers/contrast.dart';

const _white = Color(0xFFFFFFFF);
const _primary = Color(0xFF0E5E52);
const _ground = Color(0xFFF3F5F4);
const _text = Color(0xFF15211E);
const _textMuted = Color(0xFF50605B);
const _divider = Color(0xFFDCE3E0);
const _controlBorder = Color(0xFFC9D3CF);
const _fieldBorder = Color(0xFFA9B6B1);
const _danger = Color(0xFF9A3412);

const _selected = <WidgetState>{WidgetState.selected};

RoundedRectangleBorder _rounded(ShapeBorder? shape) {
  expect(shape, isA<RoundedRectangleBorder>());
  return shape! as RoundedRectangleBorder;
}

void _expectRadius(ShapeBorder? shape, double radius) {
  final border = _rounded(shape);
  expect(border.borderRadius, BorderRadius.circular(radius));
}

void _expectTopRadius(ShapeBorder? shape, double radius) {
  final border = _rounded(shape);
  expect(
    border.borderRadius,
    BorderRadius.vertical(top: Radius.circular(radius)),
  );
}

void _expectOutline(InputBorder? border, {Color? color, double? width}) {
  expect(border, isA<OutlineInputBorder>());
  final outline = border! as OutlineInputBorder;
  expect(outline.borderRadius, BorderRadius.circular(12));
  if (color != null) expect(outline.borderSide.color, color);
  if (width != null) expect(outline.borderSide.width, width);
}

void main() {
  final theme = buildTheme();
  final scheme = theme.colorScheme;

  test('uses Material 3 and the Plus Jakarta Sans font', () {
    expect(theme.useMaterial3, isTrue);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'PlusJakartaSans');
  });

  test('uses the brand colours', () {
    expect(scheme.primary, _primary);
    expect(scheme.onPrimary, _white);
    expect(theme.scaffoldBackgroundColor, _ground);
    expect(scheme.error, _danger);
    expect(scheme.onSurface, _text);
  });

  group('text contrast is at least 4.5 to 1', () {
    test('onPrimary on primary', () {
      expect(
        contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onSurface on surface', () {
      expect(
        contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onSurface on the scaffold background', () {
      expect(
        contrastRatio(scheme.onSurface, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onError on error', () {
      expect(
        contrastRatio(scheme.onError, scheme.error),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('primary on surface', () {
      expect(
        contrastRatio(scheme.primary, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('error on surface', () {
      expect(
        contrastRatio(scheme.error, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('body text', () {
    test('is 14 to 15 regular with a line height of 1.5', () {
      final body = theme.textTheme.bodyMedium!;

      expect(body.fontSize, inInclusiveRange(14, 15));
      expect(body.fontWeight, FontWeight.w400);
      expect(body.height, 1.5);
    });
  });

  group('app bar', () {
    final bar = theme.appBarTheme;

    test('is white without a scroll tint', () {
      expect(bar.backgroundColor, _white);
      expect(bar.surfaceTintColor, Colors.transparent);
      expect(bar.scrolledUnderElevation, 0);
      expect(bar.elevation ?? 0, 0);
    });

    test('has a 1 px bottom divider', () {
      expect(bar.shape, isA<Border>());
      final border = bar.shape! as Border;
      expect(border.bottom.color, _divider);
      expect(border.bottom.width, 1);
      expect(border.top, BorderSide.none);
    });

    test('titles are 17 bold, text coloured and left aligned', () {
      expect(bar.titleTextStyle?.fontSize, 17);
      expect(bar.titleTextStyle?.fontWeight, FontWeight.w700);
      expect(bar.titleTextStyle?.color, _text);
      expect(bar.centerTitle, isFalse);
    });

    testWidgets('renders a white bar with a left aligned title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(appBar: AppBar(title: const Text('Judul'))),
        ),
      );

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, _white);
      expect(tester.getTopLeft(find.text('Judul')).dx, lessThan(100));
      final style = DefaultTextStyle.of(tester.element(find.text('Judul')));
      expect(style.style.fontSize, 17);
      expect(style.style.fontWeight, FontWeight.w700);
    });
  });

  group('filled button', () {
    final style = theme.filledButtonTheme.style!;

    test('is primary with white text', () {
      expect(style.backgroundColor?.resolve({}), _primary);
      expect(style.foregroundColor?.resolve({}), _white);
    });

    test('has radius 12 and 15 bold text', () {
      _expectRadius(style.shape?.resolve({}), 12);
      expect(style.textStyle?.resolve({})?.fontSize, 15);
      expect(style.textStyle?.resolve({})?.fontWeight, FontWeight.w700);
    });

    test('is at least 48 by 48 dp', () {
      expect(style.minimumSize?.resolve({}), const Size(48, 48));
    });

    testWidgets('grows past the minimum height instead of clipping', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Simpan perubahan kamar ini sekarang'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FilledButton)).height, greaterThan(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is 48 dp tall with a short label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: FilledButton(onPressed: () {}, child: const Text('Ok')),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('outlined button', () {
    final style = theme.outlinedButtonTheme.style!;

    test('is white with a control border and text coloured label', () {
      expect(style.backgroundColor?.resolve({}), _white);
      expect(style.foregroundColor?.resolve({}), _text);
      expect(style.side?.resolve({})?.color, _controlBorder);
    });

    test('has radius 12 and 14 semi-bold text', () {
      _expectRadius(style.shape?.resolve({}), 12);
      expect(style.textStyle?.resolve({})?.fontSize, 14);
      expect(style.textStyle?.resolve({})?.fontWeight, FontWeight.w600);
    });

    test('is at least 48 by 48 dp', () {
      expect(style.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('text button', () {
    final style = theme.textButtonTheme.style!;

    test('is primary coloured with 13 to 14 semi-bold text', () {
      expect(style.foregroundColor?.resolve({}), _primary);
      expect(style.textStyle?.resolve({})?.fontSize, inInclusiveRange(13, 14));
      expect(style.textStyle?.resolve({})?.fontWeight, FontWeight.w600);
    });

    test('is at least 48 by 48 dp', () {
      expect(style.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('buttons are at least 48 by 48 dp', () {
    final styles = {
      'filled': theme.filledButtonTheme.style,
      'elevated': theme.elevatedButtonTheme.style,
      'outlined': theme.outlinedButtonTheme.style,
      'text': theme.textButtonTheme.style,
    };
    for (final entry in styles.entries) {
      test('${entry.key} button', () {
        final size = entry.value?.minimumSize?.resolve({});
        expect(size, isNotNull);
        expect(size!.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      });
    }
  });

  group('input decoration', () {
    final input = theme.inputDecorationTheme;

    test('text fields use an outlined border', () {
      expect(input.border, isA<OutlineInputBorder>());
    });

    test('fields are filled white', () {
      expect(input.filled, isTrue);
      expect(input.fillColor, _white);
    });

    test('the border has radius 12 and the field border colour', () {
      _expectOutline(input.border);
      _expectOutline(input.enabledBorder ?? input.border, color: _fieldBorder);
    });

    test('the focused border is a primary outline', () {
      _expectOutline(input.focusedBorder, color: _primary);
    });

    test('the error border is a 2 px danger outline', () {
      _expectOutline(input.errorBorder, color: _danger, width: 2);
    });

    test('helper text is 12 and muted', () {
      expect(input.helperStyle?.fontSize, 12);
      expect(input.helperStyle?.color, _textMuted);
    });

    test('error text is 12 semi-bold and danger coloured', () {
      expect(input.errorStyle?.fontSize, 12);
      expect(input.errorStyle?.fontWeight, FontWeight.w600);
      expect(input.errorStyle?.color, _danger);
    });
  });

  group('card', () {
    final card = theme.cardTheme;

    test('is white and flat without a margin', () {
      expect(card.color, _white);
      expect(card.elevation, 0);
      expect(card.margin, EdgeInsets.zero);
    });

    test('has radius 16 and a 1 px divider border', () {
      final shape = _rounded(card.shape);

      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, _divider);
      expect(shape.side.width, 1);
    });

    testWidgets('renders white with the divider border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Card(child: Text('Isi'))),
        ),
      );

      final material = tester.widget<Material>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first,
      );
      expect(material.color, _white);
      expect(material.elevation, 0);
      final shape = _rounded(material.shape);
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, _divider);
    });
  });

  test('dividers use the divider colour', () {
    expect(theme.dividerTheme.color, _divider);
  });

  group('dialogs and sheets', () {
    test('dialogs have radius 24 and an 18 extra-bold title', () {
      _expectRadius(theme.dialogTheme.shape, 24);
      expect(theme.dialogTheme.titleTextStyle?.fontSize, 18);
      expect(theme.dialogTheme.titleTextStyle?.fontWeight, FontWeight.w800);
    });

    test('bottom sheets round their top corners by 24', () {
      _expectTopRadius(theme.bottomSheetTheme.shape, 24);
    });
  });

  group('filter chip', () {
    final chip = theme.chipTheme;

    test('is a pill without a checkmark', () {
      expect(chip.shape, isA<StadiumBorder>());
      expect(chip.showCheckmark, isFalse);
    });

    test('is a primary fill when selected and white when not', () {
      expect(chip.selectedColor, _primary);
      expect(chip.backgroundColor, _white);
    });

    test('has a control border when not selected', () {
      expect(chip.side?.color, _controlBorder);
    });

    testWidgets('keeps a 48 dp hit area', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: FilterChip(
                label: const Text('Semua'),
                selected: false,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(FilterChip)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('shows white text on a primary fill when selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: FilterChip(
                label: const Text('Semua'),
                selected: true,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_chipFill(tester), _primary);
      final style = DefaultTextStyle.of(tester.element(find.text('Semua')));
      expect(style.style.color, _white);
    });

    testWidgets('shows a white fill when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: FilterChip(
                label: const Text('Semua'),
                selected: false,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_chipFill(tester), _white);
    });
  });

  group('checkbox', () {
    final box = theme.checkboxTheme;

    test('has radius 4', () {
      _expectRadius(box.shape, 4);
    });

    test('is primary when checked', () {
      expect(box.fillColor?.resolve(_selected), _primary);
    });
  });

  group('navigation bar', () {
    final nav = theme.navigationBarTheme;

    test('is white with no indicator pill', () {
      expect(nav.backgroundColor, _white);
      expect(nav.indicatorColor, Colors.transparent);
    });

    test('labels are 11 semi-bold and muted', () {
      final style = nav.labelTextStyle?.resolve({});

      expect(style?.fontSize, 11);
      expect(style?.fontWeight, FontWeight.w600);
      expect(style?.color, _textMuted);
    });

    test('the selected label is 11 bold and primary', () {
      final style = nav.labelTextStyle?.resolve(_selected);

      expect(style?.fontSize, 11);
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.color, _primary);
    });

    test('the selected icon is primary and the others muted', () {
      expect(nav.iconTheme?.resolve(_selected)?.color, _primary);
      expect(nav.iconTheme?.resolve({})?.color, _textMuted);
    });

    test('label and icon colours have at least 4.5 to 1 on white', () {
      expect(contrastRatio(_textMuted, _white), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(_primary, _white), greaterThanOrEqualTo(4.5));
    });
  });
}

/// The fill painted by the chip's `Ink`, which is where Flutter draws it
/// (the chip's `Material` itself has no colour).
Color? _chipFill(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(of: find.byType(FilterChip), matching: find.byType(Ink)),
  );
  final decoration = ink.decoration;
  return decoration is ShapeDecoration ? decoration.color : null;
}
