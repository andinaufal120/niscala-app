import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/labeled_field.dart';

import 'semantics.dart';

/// The text a [LabeledField] shows (and speaks) as its label, with the
/// "(wajib)" or "(opsional)" marker when it has one.
String fullLabelOf(LabeledField field) => switch (field.required) {
  true => '${field.label} (wajib)',
  false => '${field.label} (opsional)',
  null => field.label,
};

/// The [LabeledField] whose full label, marker included, is [label], such as
/// 'Email (wajib)'.
Finder labeledField(String label) => find.byWidgetPredicate(
  (widget) => widget is LabeledField && fullLabelOf(widget) == label,
  description: 'LabeledField labelled "$label"',
);

/// The editable field wrapped by the [LabeledField] labelled [label]: a
/// `TextField` (also a read-only date field) or a dropdown.
Finder fieldLabeled(String label) => find.descendant(
  of: labeledField(label),
  matching: find.byWidgetPredicate(
    (widget) => widget is TextField || widget is DropdownButtonFormField,
    description: 'editable field',
  ),
);

/// The `TextField` labelled [label].
TextField labeledTextField(WidgetTester tester, String label) =>
    tester.widget<TextField>(fieldLabeled(label));

/// The error text shown by the field labelled [label].
String? labeledFieldError(WidgetTester tester, String label) => tester
    .widget<InputDecorator>(
      find.descendant(
        of: labeledField(label),
        matching: find.byType(InputDecorator),
      ),
    )
    .decoration
    .errorText;

/// Types [text] into the field labelled [label].
Future<void> typeInto(WidgetTester tester, String label, String text) async {
  await tester.enterText(fieldLabeled(label), text);
  await tester.pump();
}

/// Expects that no field on screen draws its label inside the decoration: the
/// label sits above the field, in a [LabeledField].
void expectNoDecorationLabels(WidgetTester tester) {
  final decorators = find.byType(InputDecorator);
  expect(decorators, findsWidgets);
  for (final decorator in tester.widgetList<InputDecorator>(decorators)) {
    expect(decorator.decoration.labelText, isNull);
    expect(decorator.decoration.label, isNull);
  }
}

/// Expects the field labelled [label] to be one semantics node that announces
/// the label once, and the [error] on that same node when given.
void expectFieldNode(WidgetTester tester, String label, {String? error}) {
  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(fieldLabeled(label));
    expect(announced(node), contains(label));
    expect(nodesAnnouncing(tester, label), hasLength(1));
    if (error != null) {
      expect(announced(node), contains(error));
    }
  } finally {
    handle.dispose();
  }
}

/// Expects the credential field labelled [label] to keep selection and paste
/// on, to offer the autofill [hint] and to sit in an `AutofillGroup`.
void expectLabeledCredentialField(
  WidgetTester tester,
  String label,
  String hint,
) {
  expect(labeledField(label), findsOneWidget);
  final input = labeledTextField(tester, label);
  expect(input.decoration?.labelText, isNull);
  expect(input.enableInteractiveSelection, isNot(false));
  expect(input.autofillHints, contains(hint));
  expect(
    find.ancestor(
      of: fieldLabeled(label),
      matching: find.byType(AutofillGroup),
    ),
    findsOneWidget,
  );
}
