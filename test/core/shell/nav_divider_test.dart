import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

const _divider = Color(0xFFDCE3E0);

/// Whether [widget] paints a 1 dp divider-coloured line on its top edge.
bool _hasTopDivider(Widget widget) {
  final decoration = switch (widget) {
    DecoratedBox(:final decoration) => decoration,
    Container(:final decoration) => decoration,
    _ => null,
  };
  if (decoration is! BoxDecoration) return false;
  final border = decoration.border;
  if (border is! Border) return false;
  return border.top.color == _divider && border.top.width == 1;
}

/// The decorated boxes that wrap the navigation bar and carry the top divider.
Finder _dividerAboveNavigationBar() => find.ancestor(
  of: find.byType(NavigationBar),
  matching: find.byWidgetPredicate(_hasTopDivider),
);

Future<void> _pumpShell(WidgetTester tester, UserRole role) async {
  await tester.pumpWidget(
    buildTestApp(store: InMemorySessionStore(storedSession(role: role))),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final role in [UserRole.owner, UserRole.tenant]) {
    testWidgets('$role: a 1 dp divider-coloured line runs above the bar', (
      tester,
    ) async {
      await _pumpShell(tester, role);

      expect(_dividerAboveNavigationBar(), findsOneWidget);
    });

    testWidgets('$role: the divider sits on the top edge of the bar', (
      tester,
    ) async {
      await _pumpShell(tester, role);

      final divider = tester.getRect(_dividerAboveNavigationBar());
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(divider.top, closeTo(bar.top, 1));
      expect(divider.bottom, greaterThanOrEqualTo(bar.bottom));
    });
  }
}
