import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics.dart';

/// The semantics nodes a screen reader can reach that announce [label] and
/// offer the tap action. The caller must hold a semantics handle from
/// [WidgetTester.ensureSemantics].
List<SemanticsNode> tappableNodesAnnouncing(
  WidgetTester tester,
  String label,
) => nodesAnnouncing(tester, label)
    .where((node) => node.getSemanticsData().hasAction(SemanticsAction.tap))
    .toList();

/// Performs the tap action, as TalkBack or Switch Access would, on the one
/// semantics node that announces [label], and waits for the date picker dialog
/// to open. Fails when no node, or more than one, announces [label] with a tap
/// action, or when no [DatePickerDialog] appears.
Future<void> openDatePickerThroughSemantics(
  WidgetTester tester,
  String label,
) async {
  final handle = tester.ensureSemantics();
  try {
    final nodes = tappableNodesAnnouncing(tester, label);
    expect(
      nodes,
      hasLength(1),
      reason: 'exactly one node announcing "$label" must offer the tap action',
    );
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      nodes.single.id,
      SemanticsAction.tap,
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  } finally {
    handle.dispose();
  }
}
