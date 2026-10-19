import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niscala/core/widgets/labeled_field.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/semantics.dart';

/// The kinds of field a [LabeledField] wraps.
enum _Kind { text, dropdown, date }

const _label = 'Nama lengkap';

Widget _field(
  _Kind kind, {
  String label = _label,
  bool? required = true,
  String? helper,
  String? error,
}) {
  final child = switch (kind) {
    _Kind.text => TextFormField(
      key: const Key('field'),
      validator: (_) => error,
      autovalidateMode: AutovalidateMode.always,
    ),
    _Kind.dropdown => DropdownButtonFormField<String>(
      key: const Key('field'),
      items: const [
        DropdownMenuItem(value: 'budi', child: Text('Budi')),
        DropdownMenuItem(value: 'sari', child: Text('Sari')),
      ],
      onChanged: (_) {},
      validator: (_) => error,
      autovalidateMode: AutovalidateMode.always,
    ),
    _Kind.date => TextFormField(
      key: const Key('field'),
      readOnly: true,
      onTap: () {},
      initialValue: '19 Okt 2026',
      validator: (_) => error,
      autovalidateMode: AutovalidateMode.always,
    ),
  };
  return LabeledField(
    label: label,
    required: required,
    helper: helper,
    child: child,
  );
}

Widget _screen(Widget field) => themedApp(
  Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(child: field),
    ),
  ),
);

/// The spans of [text] with the style each one is drawn in.
List<({String text, TextStyle style})> _styledSpans(
  WidgetTester tester,
  Finder finder,
) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final result = <({String text, TextStyle style})>[];
  void visit(InlineSpan span, TextStyle inherited) {
    final style = inherited.merge(span.style);
    if (span is TextSpan && span.text != null) {
      result.add((text: span.text!, style: style));
    }
    span.visitDirectChildren((child) {
      visit(child, style);
      return true;
    });
  }

  visit(paragraph.text, const TextStyle());
  return result;
}

bool _hasFocusInside(Type fieldType) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  var inside = false;
  context.visitAncestorElements((element) {
    if (element.widget.runtimeType == fieldType) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside || context.widget.runtimeType == fieldType;
}

void main() {
  group('visible label', () {
    for (final kind in _Kind.values) {
      testWidgets('shows the label with (wajib) for a required $kind field', (
        tester,
      ) async {
        await tester.pumpWidget(_screen(_field(kind)));

        expect(find.text('$_label (wajib)'), findsOneWidget);
      });

      testWidgets(
        'shows the label with (opsional) for an optional $kind field',
        (tester) async {
          await tester.pumpWidget(_screen(_field(kind, required: false)));

          expect(find.text('$_label (opsional)'), findsOneWidget);
          expect(find.textContaining('(wajib)'), findsNothing);
        },
      );

      testWidgets('shows only the label when $kind is neither', (tester) async {
        await tester.pumpWidget(_screen(_field(kind, required: null)));

        expect(find.text(_label), findsOneWidget);
        expect(find.textContaining('('), findsNothing);
      });
    }

    testWidgets('puts the label above the field', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));

      final label = tester.getRect(find.text('$_label (wajib)'));
      final field = tester.getRect(find.byKey(const Key('field')));
      expect(label.bottom, lessThanOrEqualTo(field.top));
      expect(label.left, closeTo(field.left, 0.5));
    });

    testWidgets('writes the label 14 bold and the marker lighter', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));

      final spans = _styledSpans(tester, find.text('$_label (wajib)'));
      final name = spans.firstWhere((s) => s.text.contains(_label));
      final marker = spans.firstWhere((s) => s.text.contains('(wajib)'));

      expect(name.style.fontSize, 14);
      expect(name.style.fontWeight, FontWeight.w700);
      expect(marker.style.fontWeight!.value, lessThan(FontWeight.w700.value));
    });

    testWidgets('writes the optional marker lighter too', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.text, required: false)));

      final spans = _styledSpans(tester, find.text('$_label (opsional)'));
      final marker = spans.firstWhere((s) => s.text.contains('(opsional)'));

      expect(marker.style.fontWeight!.value, lessThan(FontWeight.w700.value));
    });

    testWidgets('shows no floating label inside the field', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));

      expect(find.text('$_label (wajib)'), findsOneWidget);
      expect(find.text(_label), findsNothing);
    });

    testWidgets('shows the helper text under the field', (tester) async {
      await tester.pumpWidget(
        _screen(_field(_Kind.text, helper: 'Contoh: 0812 3456 7890')),
      );

      expect(find.text('Contoh: 0812 3456 7890'), findsOneWidget);
      final helper = tester.getRect(find.text('Contoh: 0812 3456 7890'));
      final field = tester.getRect(find.byKey(const Key('field')));
      expect(helper.top, greaterThanOrEqualTo(field.bottom));
    });

    testWidgets('shows no helper when none is given', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));

      expect(find.textContaining('Contoh'), findsNothing);
    });
  });

  group('semantics', () {
    for (final kind in _Kind.values) {
      testWidgets('reads the $kind label once, on the field', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_screen(_field(kind)));

          final nodes = nodesAnnouncing(tester, _label);
          expect(nodes, hasLength(1));
          expect(announced(nodes.single), contains('$_label (wajib)'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('reads the optional $kind marker once, on the field', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_screen(_field(kind, required: false)));

          final nodes = nodesAnnouncing(tester, _label);
          expect(nodes, hasLength(1));
          expect(announced(nodes.single), contains('$_label (opsional)'));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('reads a $kind field with no marker as the bare label', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_screen(_field(kind, required: null)));

          final nodes = nodesAnnouncing(tester, _label);
          expect(nodes, hasLength(1));
          expect(nodes.single.label, startsWith(_label));
          expect(announced(nodes.single), isNot(contains('(')));
        } finally {
          handle.dispose();
        }
      });
    }

    for (final kind in [_Kind.text, _Kind.date]) {
      testWidgets('the $kind field node is a text field labelled in full', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_screen(_field(kind)));

          final node = tester.getSemantics(find.byKey(const Key('field')));
          expect(
            node,
            isSemantics(label: '$_label (wajib)', isTextField: true),
          );
        } finally {
          handle.dispose();
        }
      });
    }

    testWidgets('the visible label is not a separate semantics node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen(_field(_Kind.text)));

        final labelled = allSemanticsNodes(tester).where(
          (node) => node.label == '$_label (wajib)' || node.label == _label,
        );
        expect(labelled, hasLength(1));
        expect(labelled.single, isSemantics(isTextField: true));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('finds the field by its full label', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_screen(_field(_Kind.text)));

        expect(find.bySemanticsLabel('$_label (wajib)'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('keeps the error text on the field node', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _screen(_field(_Kind.text, error: 'Nama lengkap harus diisi.')),
        );
        await tester.pump();

        expect(find.text('Nama lengkap harus diisi.'), findsOneWidget);
        final node = tester.getSemantics(find.byKey(const Key('field')));
        expect(announced(node), contains('$_label (wajib)'));
        expect(announced(node), contains('Nama lengkap harus diisi.'));
        expect(
          nodesAnnouncing(tester, 'Nama lengkap harus diisi.'),
          hasLength(1),
        );
      } finally {
        handle.dispose();
      }
    });

    for (final kind in [_Kind.dropdown, _Kind.date]) {
      testWidgets('keeps the error text on the $kind field node', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _screen(_field(kind, error: 'Pilihan tidak valid.')),
          );
          await tester.pump();

          final nodes = nodesAnnouncing(tester, 'Pilihan tidak valid.');
          expect(nodes, hasLength(1));
          expect(announced(nodes.single), contains('$_label (wajib)'));
        } finally {
          handle.dispose();
        }
      });
    }

    testWidgets('keeps the helper text on the field node', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _screen(_field(_Kind.text, helper: 'Contoh: 0812 3456 7890')),
        );

        final nodes = nodesAnnouncing(tester, 'Contoh: 0812 3456 7890');
        expect(nodes, hasLength(1));
        expect(announced(nodes.single), contains('$_label (wajib)'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('adds nothing to the tap targets of the screen', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('tapping the label', () {
    testWidgets('focuses a text field', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );

      await tester.tap(find.text('$_label (wajib)'));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('focuses a read-only date field without opening it', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        themedApp(
          Scaffold(
            body: LabeledField(
              label: 'Tanggal masuk',
              required: true,
              child: TextField(readOnly: true, onTap: () => opened++),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tanggal masuk (wajib)'));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(opened, 0);
    });

    testWidgets('focuses a dropdown', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.dropdown)));

      await tester.tap(find.text('$_label (wajib)'));
      await tester.pump();

      expect(_hasFocusInside(DropdownButtonFormField<String>), isTrue);
    });

    testWidgets('does not change the field value', (tester) async {
      final controller = TextEditingController(text: 'Budi');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        themedApp(
          Scaffold(
            body: LabeledField(
              label: _label,
              required: true,
              child: TextField(controller: controller),
            ),
          ),
        ),
      );

      await tester.tap(find.text('$_label (wajib)'));
      await tester.pump();

      expect(controller.text, 'Budi');
    });

    testWidgets('moves focus from another field to the tapped one', (
      tester,
    ) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        themedApp(
          Scaffold(
            body: Column(
              children: [
                LabeledField(
                  label: 'Satu',
                  required: true,
                  child: TextField(focusNode: first),
                ),
                LabeledField(
                  label: 'Dua',
                  required: true,
                  child: TextField(focusNode: second),
                ),
              ],
            ),
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();

      await tester.tap(find.text('Dua (wajib)'));
      await tester.pump();

      expect(second.hasFocus, isTrue);
      expect(first.hasFocus, isFalse);
    });
  });

  group('error display', () {
    testWidgets('shows the error text of the wrapped field', (tester) async {
      await tester.pumpWidget(
        _screen(_field(_Kind.text, error: 'Nama lengkap harus diisi.')),
      );
      await tester.pump();

      expect(find.text('Nama lengkap harus diisi.'), findsOneWidget);
    });

    testWidgets('shows no error text when the field is valid', (tester) async {
      await tester.pumpWidget(_screen(_field(_Kind.text)));
      await tester.pump();

      expect(find.textContaining('harus'), findsNothing);
    });
  });

  group('large text', () {
    for (final kind in _Kind.values) {
      testWidgets('fits a $kind field at large text size', (tester) async {
        await pumpAtLargeText(
          tester,
          _screen(
            _field(
              kind,
              label: 'Nama lengkap sesuai kartu identitas pemilik kamar',
              helper: 'Tulis seperti yang tertera pada kartu identitas Anda',
              error: 'Nama lengkap harus diisi sebelum menyimpan.',
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('keeps the field at least 48 dp tall at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(tester, _screen(_field(_Kind.text)));

      expect(
        tester.getSize(find.byKey(const Key('field'))).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  testWidgets('meets accessibility guidelines for every field kind', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Form(
              child: Column(
                children: [
                  for (final kind in _Kind.values)
                    _field(
                      kind,
                      label: 'Bidang ${kind.name}',
                      helper: 'Petunjuk ${kind.name}',
                      error: 'Galat ${kind.name}',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectMeetsA11yGuidelines(tester);
  });
}
