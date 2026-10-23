import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final theme = buildTheme();
  final scheme = theme.colorScheme;

  test('uses Material 3 and the Plus Jakarta Sans font', () {
    expect(theme.useMaterial3, isTrue);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'PlusJakartaSans');
  });

  test('uses the brand colours', () {
    expect(scheme.primary, const Color(0xFF0E5E52));
    expect(scheme.onPrimary, const Color(0xFFFFFFFF));
    expect(scheme.surface, const Color(0xFFF3F5F4));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF3F5F4));
    expect(scheme.error, const Color(0xFF9A3412));
    expect(scheme.onSurface, const Color(0xFF15211E));
  });

  group('text contrast is at least 4.5 to 1', () {
    test('onPrimary on primary', () {
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onSurface on surface', () {
      expect(
        contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onError on error', () {
      expect(contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(4.5));
    });

    test('primary on surface', () {
      expect(
        contrast(scheme.primary, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('error on surface', () {
      expect(contrast(scheme.error, scheme.surface), greaterThanOrEqualTo(4.5));
    });
  });

  test('text fields use an outlined border', () {
    expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
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
}
