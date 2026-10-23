import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/placeholder_screen.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Widget screen() => themedApp(const PlaceholderScreen(title: 'Keluhan'));

void main() {
  testWidgets('shows the title in the app bar', (tester) async {
    await tester.pumpWidget(screen());

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Keluhan')),
      findsOneWidget,
    );
  });

  testWidgets('says the feature is not available yet', (tester) async {
    await tester.pumpWidget(screen());

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Fitur ini belum tersedia'), findsOneWidget);
  });

  testWidgets('meets accessibility guidelines', (tester) async {
    await tester.pumpWidget(screen());

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(tester, screen());

    expect(tester.takeException(), isNull);
  });
}
