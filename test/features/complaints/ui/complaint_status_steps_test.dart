import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';

const _labels = {
  ComplaintStatus.new_: 'Baru',
  ComplaintStatus.inProgress: 'Diproses',
  ComplaintStatus.done: 'Selesai',
};

Widget _steps(ComplaintStatus status) => themedApp(
  Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: ComplaintStatusSteps(status: status),
    ),
  ),
);

Finder get _root => find.byType(ComplaintStatusSteps);

Finder _label(String text) =>
    find.descendant(of: _root, matching: find.text(text));

/// The coloured bars of the steps: thin filled boxes, left to right.
List<({Rect rect, Color color})> _segments(WidgetTester tester) {
  final found = <({Rect rect, Color color})>[];
  final boxes = find.descendant(
    of: _root,
    matching: find.byWidgetPredicate(
      (w) => w is ColoredBox || w is DecoratedBox,
    ),
  );
  for (final element in boxes.evaluate()) {
    final widget = element.widget;
    final color = switch (widget) {
      ColoredBox(:final color) => color,
      DecoratedBox(decoration: BoxDecoration(:final color)) => color,
      _ => null,
    };
    if (color == null) continue;
    final rect = tester.getRect(find.byElementPredicate((e) => e == element));
    if (rect.height >= 2 && rect.height <= 12 && rect.width >= 20) {
      found.add((rect: rect, color: color));
    }
  }
  found.sort((a, b) => a.rect.left.compareTo(b.rect.left));
  return found;
}

void main() {
  setUpAll(loadAppFont);

  group('labels', () {
    for (final status in ComplaintStatus.values) {
      testWidgets('shows Baru, Diproses and Selesai for $status', (
        tester,
      ) async {
        await tester.pumpWidget(_steps(status));

        for (final label in _labels.values) {
          expect(_label(label), findsOneWidget, reason: label);
        }
      });
    }

    testWidgets('puts the labels left to right on one line under the bars', (
      tester,
    ) async {
      await tester.pumpWidget(_steps(ComplaintStatus.new_));

      final rects = [for (final l in _labels.values) tester.getRect(_label(l))];
      expect(rects[0].right, lessThanOrEqualTo(rects[1].left));
      expect(rects[1].right, lessThanOrEqualTo(rects[2].left));
      expect(rects[1].top, closeTo(rects[0].top, 1));
      expect(rects[2].top, closeTo(rects[0].top, 1));
      final bars = _segments(tester);
      expect(rects[0].top, greaterThanOrEqualTo(bars.first.rect.bottom));
    });

    for (final status in ComplaintStatus.values) {
      testWidgets('writes only the current label bold for $status', (
        tester,
      ) async {
        await tester.pumpWidget(_steps(status));

        final current = styleOf(tester, _label(_labels[status]!)).fontWeight!;
        expect(current.value, greaterThanOrEqualTo(FontWeight.w700.value));
        for (final entry in _labels.entries) {
          if (entry.key == status) continue;
          final other = styleOf(tester, _label(entry.value)).fontWeight;
          expect(
            (other ?? FontWeight.w400).value,
            lessThan(FontWeight.w700.value),
            reason: '${entry.value} is not current',
          );
        }
      });
    }
  });

  group('segments', () {
    for (final status in ComplaintStatus.values) {
      final filled = ComplaintStatus.values.indexOf(status) + 1;
      testWidgets('fills $filled of 3 segments for $status', (tester) async {
        await tester.pumpWidget(_steps(status));

        final bars = _segments(tester);
        expect(bars, hasLength(3));
        expect(bars[0].rect.top, closeTo(bars[1].rect.top, 0.5));
        expect(bars[2].rect.top, closeTo(bars[1].rect.top, 0.5));
        expect(bars[0].rect.right, lessThanOrEqualTo(bars[1].rect.left));
        expect(bars[1].rect.right, lessThanOrEqualTo(bars[2].rect.left));

        final fill = bars.first.color;
        for (var i = 0; i < 3; i++) {
          if (i < filled) {
            expect(bars[i].color, fill, reason: 'segment $i is filled');
          } else {
            expect(bars[i].color, isNot(fill), reason: 'segment $i is empty');
          }
        }
        if (filled < 3) {
          expect(
            bars[filled].color,
            bars.last.color,
            reason: 'empty segments share one colour',
          );
        }
      });
    }

    testWidgets('each label sits under its own segment', (tester) async {
      await tester.pumpWidget(_steps(ComplaintStatus.inProgress));

      final bars = _segments(tester);
      final labels = [
        for (final l in _labels.values) tester.getRect(_label(l)),
      ];
      for (var i = 0; i < 3; i++) {
        expect(labels[i].left, greaterThanOrEqualTo(bars[i].rect.left - 1));
        expect(labels[i].left, lessThan(bars[i].rect.right));
      }
    });
  });

  group('semantics', () {
    for (final entry in _labels.entries) {
      testWidgets('is one node labelled Status: ${entry.value}', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_steps(entry.key));

          expect(
            tester.getSemantics(_root),
            isSemantics(label: 'Status: ${entry.value}'),
          );
          expect(find.bySemanticsLabel(RegExp(r'^Status: ')), findsOneWidget);
          for (final label in _labels.values) {
            expect(
              find.bySemanticsLabel(label),
              findsNothing,
              reason: '$label is not read on its own',
            );
          }
        } finally {
          handle.dispose();
        }
      });
    }
  });

  group('accessibility', () {
    testWidgets('meets the guidelines', (tester) async {
      await tester.pumpWidget(_steps(ComplaintStatus.inProgress));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(tester, _steps(ComplaintStatus.inProgress));

      expect(tester.takeException(), isNull);
      for (final label in _labels.values) {
        expect(_label(label), findsOneWidget);
      }
      final bars = _segments(tester);
      expect(bars, hasLength(3));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final label in _labels.values) {
        final rect = tester.getRect(_label(label));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(screen.width));
      }
    });
  });
}
