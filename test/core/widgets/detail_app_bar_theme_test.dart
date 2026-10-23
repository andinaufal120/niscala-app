import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';

import '../../helpers/layout.dart';

const _title = 'Rincian keluhan dari penyewa kamar';
const _subtitle = 'Kamar 08 · Budi Santoso Wijayakusuma';

/// The app theme with other title and subtitle styles, as a change to the
/// shared text styles would make.
ThemeData _theme({
  required double titleSize,
  required double subtitleSize,
  required double subtitleSpacing,
}) {
  final base = buildTheme();
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge!.copyWith(fontSize: titleSize),
      bodySmall: base.textTheme.bodySmall!.copyWith(
        fontSize: subtitleSize,
        letterSpacing: subtitleSpacing,
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle!.copyWith(
        fontSize: titleSize,
      ),
    ),
  );
}

Future<void> _show(
  WidgetTester tester, {
  required ThemeData theme,
  required double scale,
  List<DetailBarAction>? actions,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        appBar: DetailAppBar(
          title: _title,
          subtitle: _subtitle,
          actions: actions,
          showBack: false,
        ),
        body: const SizedBox.expand(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _in(String text) =>
    find.descendant(of: find.byType(DetailAppBar), matching: find.text(text));

void main() {
  setUpAll(loadAppFont);

  final themes = <String, ThemeData Function()>{
    'larger title and subtitle with wide letter spacing': () =>
        _theme(titleSize: 24, subtitleSize: 16, subtitleSpacing: 1.5),
    'smaller title and subtitle without letter spacing': () =>
        _theme(titleSize: 14, subtitleSize: 10, subtitleSpacing: 0),
    'the app theme': buildTheme,
  };

  for (final entry in themes.entries) {
    for (final scale in [1.0, 2.0]) {
      for (final withAction in [false, true]) {
        final name =
            '${entry.key} at ${(scale * 100).round()} percent text '
            '${withAction ? 'with' : 'without'} an action';

        testWidgets('measures the height it lays out for $name', (
          tester,
        ) async {
          await _show(
            tester,
            theme: entry.value(),
            scale: scale,
            actions: withAction
                ? [DetailBarAction.text(label: 'Ubah', onPressed: () {})]
                : null,
          );

          final bar = tester.getRect(find.byType(DetailAppBar));
          final first = tester.getRect(_in(_title));
          final last = tester.getRect(_in(_subtitle));
          final block = last.bottom - first.top;
          expect(tester.takeException(), isNull);
          expect(bar.height, closeTo(math.max(56, block + 16), 1));
          expect(
            tester
                .widget<DetailAppBar>(find.byType(DetailAppBar))
                .preferredSize
                .height,
            closeTo(bar.height, 0.5),
          );
        });

        testWidgets('clips and ellipsizes nothing for $name', (tester) async {
          await _show(
            tester,
            theme: entry.value(),
            scale: scale,
            actions: withAction
                ? [DetailBarAction.text(label: 'Ubah', onPressed: () {})]
                : null,
          );

          final bar = tester.getRect(find.byType(DetailAppBar));
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(_in(_title)).top,
            greaterThanOrEqualTo(bar.top),
          );
          expect(
            tester.getRect(_in(_subtitle)).bottom,
            lessThanOrEqualTo(bar.bottom),
          );
          for (final text in [_title, _subtitle]) {
            final widget = tester.widget<Text>(_in(text));
            expect(widget.overflow, isNot(TextOverflow.ellipsis));
            expect(widget.maxLines, isNull);
            expect(
              tester.renderObject<RenderParagraph>(_in(text)).didExceedMaxLines,
              isFalse,
            );
          }
        });
      }
    }
  }
}
