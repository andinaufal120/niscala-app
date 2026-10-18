import 'package:flutter/material.dart';

const _primary = Color(0xFF0E5E52);
const _ground = Color(0xFFF3F5F4);
const _text = Color(0xFF15211E);
const _error = Color(0xFF9A3412);
const _focus = Color(0xFFF6B44B);

const _minimumTarget = Size(48, 48);

/// The app theme. Status badges take their colours from the container pairs
/// of the colour scheme, so no screen defines colours of its own.
ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: _primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6EBE6),
    onPrimaryContainer: Color(0xFF0A4A40),
    secondary: Color(0xFF2F4F7F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCE8F5),
    onSecondaryContainer: Color(0xFF1E3A5F),
    tertiary: Color(0xFF8A5A00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFCEBCB),
    onTertiaryContainer: Color(0xFF5C3600),
    error: _error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8DDD0),
    onErrorContainer: Color(0xFF7A2A06),
    surface: _ground,
    onSurface: _text,
    surfaceContainerHighest: Color(0xFFE1E6E4),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _ground,
    focusColor: _focus,
    fontFamily: 'PlusJakartaSans',
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: _minimumTarget),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: _minimumTarget),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: _minimumTarget),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: _minimumTarget),
    ),
  );
}
