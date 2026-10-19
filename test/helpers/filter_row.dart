import 'package:flutter_test/flutter_test.dart';

import '../features/rooms/ui/room_ui_helpers.dart';
import 'layout.dart';

/// Defines the tests every list with filter chips shares: the chips sit in one
/// horizontally scrolling row, keep their targets and selected state, and stay
/// reachable at large text.
///
/// [pump] shows the screen with its chips; [labels] lists the chips left to
/// right, [selected] is the one chosen at first and [last] the one furthest
/// right. With [overflowsAtLargeText] the row must be wider than the screen at
/// text scale 2.0.
void defineFilterRowTests({
  required Future<void> Function(WidgetTester tester, {bool largeText}) pump,
  required List<String> labels,
  required String selected,
  required String last,
  required bool overflowsAtLargeText,
}) {
  group('filter row', () {
    setUpAll(loadAppFont);

    testWidgets('keeps every chip on one line of a scrolling row at 360 dp', (
      tester,
    ) async {
      await pump(tester);
      await useNarrowScreen(tester);

      expectSingleScrollingRow(tester, filterChip, labels);
    });

    testWidgets('keeps a 48 dp target and the selected state of each chip', (
      tester,
    ) async {
      await pump(tester);
      await useNarrowScreen(tester);

      for (final label in labels) {
        expectChipTargetSize(tester, label);
        expectChipSelected(tester, label, selected: label == selected);
      }
    });

    testWidgets('scrolls instead of wrapping at 200 % text', (tester) async {
      await pump(tester, largeText: true);

      expect(tester.takeException(), isNull);
      expectSingleScrollingRow(tester, filterChip, labels);
      if (overflowsAtLargeText) {
        expectRowScrolls(tester, filterChip(labels.first));
      }
    });

    testWidgets('keeps a 48 dp target on each chip at 200 % text', (
      tester,
    ) async {
      await pump(tester, largeText: true);

      for (final label in labels) {
        await tester.ensureVisible(filterChip(label));
        await tester.pumpAndSettle();
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('a chip scrolled into view at 200 % text can be tapped', (
      tester,
    ) async {
      await pump(tester, largeText: true);

      await tester.ensureVisible(filterChip(last));
      await tester.pumpAndSettle();
      await tester.tap(filterChip(last));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectChipSelected(tester, last, selected: true);
      if (last != selected) {
        await tester.ensureVisible(filterChip(selected));
        await tester.pumpAndSettle();
        expectChipSelected(tester, selected, selected: false);
      }
    });
  });
}
