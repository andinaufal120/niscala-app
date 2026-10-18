import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/status_badge.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Widget allTones() => themedApp(
  Scaffold(
    body: Column(
      children: [
        for (final tone in StatusTone.values)
          StatusBadge(label: 'Label ${tone.name}', tone: tone),
      ],
    ),
  ),
);

void main() {
  testWidgets('shows the label text', (tester) async {
    await tester.pumpWidget(
      themedApp(
        const Scaffold(
          body: StatusBadge(label: 'Lunas', tone: StatusTone.success),
        ),
      ),
    );

    expect(find.text('Lunas'), findsOneWidget);
  });

  testWidgets('shows the label for every tone', (tester) async {
    await tester.pumpWidget(allTones());

    for (final tone in StatusTone.values) {
      expect(find.text('Label ${tone.name}'), findsOneWidget);
    }
  });

  testWidgets('shows the icon when one is given', (tester) async {
    await tester.pumpWidget(
      themedApp(
        const Scaffold(
          body: StatusBadge(
            label: 'Lunas',
            tone: StatusTone.success,
            icon: Icons.check_circle,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
  });

  testWidgets('shows no icon when none is given', (tester) async {
    await tester.pumpWidget(
      themedApp(
        const Scaffold(
          body: StatusBadge(label: 'Lunas', tone: StatusTone.success),
        ),
      ),
    );

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('reads as a single semantics node with the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      themedApp(
        const Scaffold(
          body: StatusBadge(
            label: 'Menunggu verifikasi',
            tone: StatusTone.warning,
            icon: Icons.schedule,
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(StatusBadge));
    expect(node.label, 'Menunggu verifikasi');
    expect(node.childrenCount, 0);
  });

  testWidgets('text contrast is at least 4.5 to 1 for every tone', (
    tester,
  ) async {
    await tester.pumpWidget(allTones());

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(tester, allTones());

    expect(tester.takeException(), isNull);
  });
}
