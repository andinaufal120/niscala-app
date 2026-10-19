import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

/// Loads the bundled font, because the default test font is far wider than
/// the real one and would make every label wrap.
Future<void> _loadFont() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/PlusJakartaSans-$weight.ttf')
        .readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFont);

  for (final scale in [1.0, 1.15]) {
    testWidgets(
      'the longest tab label stays on one line at text scale $scale on a '
      '360 dp wide screen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3.0;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        try {
          await tester.pumpWidget(
            buildTestApp(
              store: InMemorySessionStore(storedSession(role: UserRole.owner)),
            ),
          );
          await tester.pumpAndSettle();

          final label = find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Pembayaran'),
          );
          final style =
              tester.widget<Text>(label).style ??
              DefaultTextStyle.of(tester.element(label)).style;
          final oneLine = (style.fontSize ?? 10) * scale * 1.6;
          expect(tester.getSize(label).height, lessThan(oneLine));
        } finally {
          tester.view.reset();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        }
      },
    );
  }
}
