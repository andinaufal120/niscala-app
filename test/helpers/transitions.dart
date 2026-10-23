import 'package:flutter_test/flutter_test.dart';

/// The width of the display in logical pixels.
double displayWidth(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

/// The left edge of [page] on screen, including every transform above it.
double leftOf(WidgetTester tester, Finder page) {
  expect(page, findsOneWidget);
  return tester.getTopLeft(page).dx;
}

/// The width [page] is drawn at on screen, including every transform above it.
/// A page that is only moved keeps its width; a page that is scaled does not.
double drawnWidth(WidgetTester tester, Finder page) =>
    tester.getTopRight(page).dx - tester.getTopLeft(page).dx;

/// Expects [page] to be mid-slide: moved sideways by part of the display width,
/// still on screen, and not scaled.
void expectMidSlide(WidgetTester tester, Finder page) {
  final left = leftOf(tester, page);
  final width = displayWidth(tester);
  expect(left, greaterThan(0), reason: 'the page must be off its resting x');
  expect(left, lessThan(width), reason: 'the page must still be on screen');
  expect(
    drawnWidth(tester, page),
    closeTo(width, 1),
    reason: 'the page must slide, not scale',
  );
}

/// Expects [page] to sit at its resting place.
void expectAtRest(WidgetTester tester, Finder page) {
  expect(leftOf(tester, page), closeTo(0, 0.01));
}

/// Turns on the platform setting that asks for no animations, for one test.
void useReducedMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
