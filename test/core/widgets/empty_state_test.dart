import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/empty_state.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Widget screen({String? actionLabel, VoidCallback? onAction}) => themedApp(
  Scaffold(
    body: EmptyState(
      message: 'Belum ada properti',
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  ),
);

void main() {
  testWidgets('shows the message', (tester) async {
    await tester.pumpWidget(screen());

    expect(find.text('Belum ada properti'), findsOneWidget);
  });

  testWidgets('shows no button without an action', (tester) async {
    await tester.pumpWidget(screen());

    expect(find.text('Belum ada properti'), findsOneWidget);
    expect(anyButton(), findsNothing);
  });

  testWidgets('shows no button when only the label is given', (tester) async {
    await tester.pumpWidget(screen(actionLabel: 'Tambah properti'));

    expect(find.text('Belum ada properti'), findsOneWidget);
    expect(anyButton(), findsNothing);
    expect(find.text('Tambah properti'), findsNothing);
  });

  testWidgets('shows no button when only the callback is given', (
    tester,
  ) async {
    await tester.pumpWidget(screen(onAction: () {}));

    expect(find.text('Belum ada properti'), findsOneWidget);
    expect(anyButton(), findsNothing);
  });

  testWidgets('shows a button that runs the action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      screen(actionLabel: 'Tambah properti', onAction: () => taps++),
    );

    expect(anyButton(), findsOneWidget);
    await tester.tap(find.text('Tambah properti'));

    expect(taps, 1);
  });

  testWidgets('action button is at least 48 by 48 dp', (tester) async {
    await tester.pumpWidget(
      screen(actionLabel: 'Tambah properti', onAction: () {}),
    );

    final size = tester.getSize(anyButton());
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('meets accessibility guidelines without an action', (
    tester,
  ) async {
    await tester.pumpWidget(screen());

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('meets accessibility guidelines with an action', (tester) async {
    await tester.pumpWidget(
      screen(actionLabel: 'Tambah properti', onAction: () {}),
    );

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(
      tester,
      screen(actionLabel: 'Tambah properti', onAction: () {}),
    );

    expect(tester.takeException(), isNull);
  });
}
