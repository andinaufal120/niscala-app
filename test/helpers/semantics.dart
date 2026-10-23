import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every node a screen reader can reach in the current semantics tree, depth
/// first. The caller must hold
/// a semantics handle from [WidgetTester.ensureSemantics].
List<SemanticsNode> allSemanticsNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    // A node merged into its parent is part of the parent's announcement.
    if (!node.isMergedIntoParent) nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
  visit(owner.rootSemanticsNode!);
  return nodes;
}

/// Everything a node announces as text: label, value and hint.
String announced(SemanticsNode node) =>
    [node.label, node.value, node.hint].where((s) => s.isNotEmpty).join('\n');

/// The nodes whose announced text contains [text].
List<SemanticsNode> nodesAnnouncing(WidgetTester tester, String text) =>
    allSemanticsNodes(tester)
        .where((node) => announced(node).contains(text))
        .toList();
