import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/shell/account_screen.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Widget screen({Future<void> Function()? logout}) => ProviderScope(
  overrides: [logoutProvider.overrideWithValue(logout ?? () async {})],
  child: themedApp(const AccountScreen()),
);

void main() {
  testWidgets('shows the title and the Keluar button', (tester) async {
    await tester.pumpWidget(screen());

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Akun')),
      findsOneWidget,
    );
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('calls the logout function once when Keluar is pressed', (
    tester,
  ) async {
    var logouts = 0;
    await tester.pumpWidget(screen(logout: () async => logouts++));

    await tester.tap(find.text('Keluar'));
    await tester.pump();

    expect(logouts, 1);
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
