import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/section_card.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _white = Color(0xFFFFFFFF);
const _primary = Color(0xFF0E5E52);
const _divider = Color(0xFFDCE3E0);

Widget _screen({
  String? title,
  bool emphasis = false,
  Widget child = const Text('Isi kartu'),
}) => themedApp(
  Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SectionCard(title: title, emphasis: emphasis, child: child),
    ),
  ),
);

/// The material the card paints on: its colour, shape and elevation.
Material _material(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(Card), matching: find.byType(Material)).first,
);

void main() {
  group('plain card', () {
    testWidgets('shows its child', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.text('Isi kartu'), findsOneWidget);
    });

    testWidgets('is a white flat card', (tester) async {
      await tester.pumpWidget(_screen());

      final material = _material(tester);
      expect(material.color, _white);
      expect(material.elevation, 0);
    });

    testWidgets('has radius 16 and a 1 px divider border', (tester) async {
      await tester.pumpWidget(_screen());

      final shape = _material(tester).shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, _divider);
      expect(shape.side.width, 1);
    });

    testWidgets('shows no heading without a title', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('pads its child', (tester) async {
      await tester.pumpWidget(_screen());

      final card = tester.getRect(find.byType(Card));
      final child = tester.getRect(find.text('Isi kartu'));
      expect(child.left - card.left, inInclusiveRange(14, 16));
      expect(card.right - child.right, greaterThanOrEqualTo(14));
      expect(child.top - card.top, inInclusiveRange(14, 16));
    });

    testWidgets('stretches over the width it is given', (tester) async {
      await tester.pumpWidget(_screen());

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getSize(find.byType(SectionCard)).width, width - 40);
    });
  });

  group('title', () {
    testWidgets('shows the title above the child', (tester) async {
      await tester.pumpWidget(_screen(title: 'Data kamar'));

      expect(find.text('Data kamar'), findsOneWidget);
      expect(
        tester.getRect(find.text('Data kamar')).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('Isi kartu')).top),
      );
    });

    testWidgets('writes the title 14 bold', (tester) async {
      await tester.pumpWidget(_screen(title: 'Data kamar'));

      final style = tester.widget<Text>(find.text('Data kamar')).style;
      expect(style?.fontSize, 14);
      expect(style?.fontWeight, FontWeight.w700);
    });

    testWidgets('is a header for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen(title: 'Data kamar'));

        expect(
          tester.getSemantics(find.text('Data kamar')),
          isSemantics(label: 'Data kamar', isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('does not make the child a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen(title: 'Data kamar'));

        expect(
          tester.getSemantics(find.text('Isi kartu')),
          isNot(isSemantics(isHeader: true)),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('emphasis', () {
    testWidgets('has a 2 px primary border', (tester) async {
      await tester.pumpWidget(_screen(emphasis: true));

      final shape = _material(tester).shape! as RoundedRectangleBorder;
      expect(shape.side.color, _primary);
      expect(shape.side.width, 2);
    });

    testWidgets('keeps radius 16 and the white fill', (tester) async {
      await tester.pumpWidget(_screen(emphasis: true));

      final material = _material(tester);
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(material.color, _white);
    });

    testWidgets('keeps the title as a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _screen(title: 'Klasifikasi otomatis', emphasis: true),
        );

        expect(
          tester.getSemantics(find.text('Klasifikasi otomatis')),
          isSemantics(label: 'Klasifikasi otomatis', isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('does not apply to a card that is not emphasised', (
      tester,
    ) async {
      await tester.pumpWidget(_screen());

      final shape = _material(tester).shape! as RoundedRectangleBorder;
      expect(shape.side.color, isNot(_primary));
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with a title', (tester) async {
      await tester.pumpWidget(_screen(title: 'Data kamar'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when emphasised', (tester) async {
      await tester.pumpWidget(
        _screen(title: 'Klasifikasi otomatis', emphasis: true),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a button inside', (tester) async {
      await tester.pumpWidget(
        _screen(
          title: 'Aksi',
          child: FilledButton(onPressed: () {}, child: const Text('Simpan')),
        ),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits a long title and text at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(
        tester,
        _screen(
          title: 'Klasifikasi otomatis oleh asisten kecerdasan buatan',
          emphasis: true,
          child: const Text(
            'Keluhan ini tampaknya berkaitan dengan saluran air di kamar mandi '
            'lantai dua yang tersumbat sejak beberapa hari lalu.',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits without a title at large text size', (tester) async {
      await pumpAtLargeText(tester, _screen());

      expect(tester.takeException(), isNull);
    });
  });
}
