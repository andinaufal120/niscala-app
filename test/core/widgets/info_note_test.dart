import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/info_note.dart';

import '../../helpers/a11y.dart';
import '../../helpers/contrast.dart';
import '../../helpers/fakes.dart';
import '../../helpers/semantics.dart';

const _primarySoft = Color(0xFFDDEEEA);
const _text = 'Keluhan Anda akan diklasifikasi otomatis.';

Widget _screen({String text = _text, IconData icon = Icons.info_outline}) =>
    themedApp(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: InfoNote(text: text, icon: icon),
        ),
      ),
    );

bool _paintsSoftBackground() => find
    .descendant(
      of: find.byType(InfoNote),
      matching: find.byWidgetPredicate((widget) {
        if (widget is ColoredBox) return widget.color == _primarySoft;
        if (widget is Material) return widget.color == _primarySoft;
        if (widget is DecoratedBox) {
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == _primarySoft;
        }
        return false;
      }),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  group('content', () {
    testWidgets('shows the text', (tester) async {
      await tester.pumpWidget(_screen());

      expect(find.text(_text), findsOneWidget);
    });

    testWidgets('shows the icon it is given', (tester) async {
      await tester.pumpWidget(_screen(icon: Icons.lightbulb_outline));

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('puts the icon before the text', (tester) async {
      await tester.pumpWidget(_screen());

      final icon = tester.getRect(find.byIcon(Icons.info_outline));
      final text = tester.getRect(find.text(_text));
      expect(icon.right, lessThanOrEqualTo(text.left));
    });

    testWidgets('paints the soft primary background', (tester) async {
      await tester.pumpWidget(_screen());

      expect(_paintsSoftBackground(), isTrue);
    });

    testWidgets('keeps the text readable on the background', (tester) async {
      await tester.pumpWidget(_screen());

      final color =
          tester.widget<Text>(find.text(_text)).style?.color ??
          DefaultTextStyle.of(tester.element(find.text(_text))).style.color!;
      expect(contrastRatio(color, _primarySoft), greaterThanOrEqualTo(4.5));
    });
  });

  group('semantics', () {
    testWidgets('reads the text once and nothing else', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen());

        final nodes = nodesAnnouncing(tester, _text);
        expect(nodes, hasLength(1));
        expect(nodes.single.label, _text);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('gives the decorative icon no label', (tester) async {
      await tester.pumpWidget(_screen());

      expect(
        tester.widget<Icon>(find.byIcon(Icons.info_outline)).semanticLabel,
        isNull,
      );
    });

    testWidgets('excludes the decorative icon from semantics', (tester) async {
      await tester.pumpWidget(_screen());

      expect(
        find.ancestor(
          of: find.byIcon(Icons.info_outline),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('is not a button', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen());

        expect(
          tester.getSemantics(find.text(_text)),
          isNot(isSemantics(isButton: true)),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines', (tester) async {
      await tester.pumpWidget(_screen());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits long text at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        _screen(
          text:
              'Keluhan Anda akan dibaca pengelola kos dan diklasifikasi '
              'secara otomatis untuk menentukan tingkat urgensinya.',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(InfoNote), findsOneWidget);
    });

    testWidgets('keeps all of its text on screen at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(tester, _screen());

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getRect(find.byType(InfoNote)).right,
        lessThanOrEqualTo(width),
      );
      expect(tester.getRect(find.text(_text)).right, lessThanOrEqualTo(width));
    });
  });
}
