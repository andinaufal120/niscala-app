import 'package:flutter/material.dart';
import 'package:niscala/core/slide_page_transitions.dart';
import 'package:niscala/core/tokens.dart';

const _minimumTarget = Size(48, 48);

RoundedRectangleBorder _rounded(double radius, [BorderSide? side]) =>
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side ?? BorderSide.none,
    );

OutlineInputBorder _outline(Color color, double width) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(NiscalaRadius.control),
  borderSide: BorderSide(color: color, width: width),
);

const _fontFamily = 'PlusJakartaSans';

/// Component themes replace the text style instead of merging it into the
/// theme's, so every style names the font itself.
TextStyle _style(double size, FontWeight weight, Color color) => TextStyle(
  fontFamily: _fontFamily,
  fontSize: size,
  fontWeight: weight,
  color: color,
);

/// The title of a detail app bar. The theme and the bar both use it.
const detailTitleStyle = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: NiscalaColors.text,
);

/// The muted subtitle of a detail app bar. It keeps the letter spacing of the
/// Material body small style, which changes where the text wraps.
const detailSubtitleStyle = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: NiscalaColors.textMuted,
  height: 1.5,
  letterSpacing: 0.4,
);

/// The app theme. Every colour, type size and radius comes from the tokens;
/// status badge colours are reached through the [NiscalaTokens] extension.
ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: NiscalaColors.primary,
    onPrimary: NiscalaColors.surface,
    primaryContainer: NiscalaColors.primarySoft,
    onPrimaryContainer: NiscalaColors.primaryStrong,
    secondary: NiscalaColors.textSecondary,
    onSecondary: NiscalaColors.surface,
    secondaryContainer: NiscalaColors.neutralSoft,
    onSecondaryContainer: NiscalaColors.textSecondary,
    tertiary: NiscalaColors.onWarningSoft,
    onTertiary: NiscalaColors.surface,
    tertiaryContainer: NiscalaColors.warningSoft,
    onTertiaryContainer: NiscalaColors.onWarningSoft,
    error: NiscalaColors.danger,
    onError: NiscalaColors.surface,
    errorContainer: NiscalaColors.dangerSoft,
    onErrorContainer: NiscalaColors.onDangerSoft,
    surface: NiscalaColors.surface,
    onSurface: NiscalaColors.text,
    onSurfaceVariant: NiscalaColors.textMuted,
    outline: NiscalaColors.fieldBorder,
    outlineVariant: NiscalaColors.divider,
    surfaceContainerHighest: NiscalaColors.neutralSoft,
  );

  const text = NiscalaColors.text;
  final textTheme = TextTheme(
    headlineSmall: _style(22, FontWeight.w800, text),
    titleLarge: detailTitleStyle,
    titleMedium: _style(15, FontWeight.w700, text),
    titleSmall: _style(14, FontWeight.w700, text),
    bodyLarge: _style(15, FontWeight.w400, text).copyWith(height: 1.5),
    bodyMedium: _style(14, FontWeight.w400, text).copyWith(height: 1.5),
    bodySmall: detailSubtitleStyle,
    labelLarge: _style(15, FontWeight.w700, text),
    labelMedium: _style(12, FontWeight.w600, NiscalaColors.textMuted),
    labelSmall: _style(11, FontWeight.w700, text),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NiscalaColors.ground,
    focusColor: NiscalaColors.focus,
    fontFamily: _fontFamily,
    textTheme: textTheme,
    extensions: const [NiscalaTokens()],
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const SlidePageTransitionsBuilder(),
      },
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const Icon(Icons.chevron_left),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: NiscalaColors.surface,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      actionsPadding: const EdgeInsets.only(right: 8),
      shape: const Border(bottom: BorderSide(color: NiscalaColors.divider)),
      titleTextStyle: detailTitleStyle,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NiscalaColors.primary,
        foregroundColor: NiscalaColors.surface,
        minimumSize: _minimumTarget,
        shape: _rounded(NiscalaRadius.control),
        textStyle: _style(15, FontWeight.w700, NiscalaColors.surface),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: _minimumTarget,
        shape: _rounded(NiscalaRadius.control),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: NiscalaColors.surface,
        foregroundColor: text,
        minimumSize: _minimumTarget,
        side: const BorderSide(color: NiscalaColors.controlBorder),
        shape: _rounded(NiscalaRadius.control),
        textStyle: _style(14, FontWeight.w600, text),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NiscalaColors.primary,
        minimumSize: _minimumTarget,
        textStyle: _style(14, FontWeight.w600, NiscalaColors.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: NiscalaColors.surface,
      border: _outline(NiscalaColors.fieldBorder, 1),
      enabledBorder: _outline(NiscalaColors.fieldBorder, 1),
      focusedBorder: _outline(NiscalaColors.primary, 2),
      errorBorder: _outline(NiscalaColors.danger, 2),
      focusedErrorBorder: _outline(NiscalaColors.danger, 2),
      helperStyle: _style(12, FontWeight.w400, NiscalaColors.textMuted),
      errorStyle: _style(12, FontWeight.w600, NiscalaColors.danger),
    ),
    cardTheme: CardThemeData(
      color: NiscalaColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _rounded(
        NiscalaRadius.card,
        const BorderSide(color: NiscalaColors.divider),
      ),
    ),
    dividerTheme: const DividerThemeData(color: NiscalaColors.divider),
    dialogTheme: DialogThemeData(
      backgroundColor: NiscalaColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: _rounded(NiscalaRadius.sheet),
      titleTextStyle: _style(18, FontWeight.w800, text),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: NiscalaColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(NiscalaRadius.sheet),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: NiscalaColors.surface,
      selectedColor: NiscalaColors.primary,
      side: const BorderSide(color: NiscalaColors.controlBorder),
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? NiscalaColors.surface
              : NiscalaColors.textSecondary,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: _rounded(4),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? NiscalaColors.primary
            : null,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NiscalaColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      labelPadding: EdgeInsets.zero,
      // Five tabs share the width, so the longest label ("Pembayaran") only
      // fits on one line at a slightly smaller, tighter size.
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) =>
            (states.contains(WidgetState.selected)
                    ? _style(10, FontWeight.w700, NiscalaColors.primary)
                    : _style(10, FontWeight.w600, NiscalaColors.textMuted))
                .copyWith(letterSpacing: -0.2),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? NiscalaColors.primary
              : NiscalaColors.textMuted,
        ),
      ),
    ),
  );
}
