import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the accessibility guidelines every screen must satisfy: labelled tap
/// targets, 48 x 48 dp targets and text contrast.
Future<void> expectMeetsA11yGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  } finally {
    handle.dispose();
  }
}

/// Pumps [screen] on a 360 x 640 dp display at text scale 2.0. A RenderFlex
/// overflow is reported as an error and fails the test.
Future<void> pumpAtLargeText(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(screen);
}
