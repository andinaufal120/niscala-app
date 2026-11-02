import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/account/data/account_repository.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Widget screen({Future<void> Function()? logout}) => ProviderScope(
  overrides: [
    logoutProvider.overrideWithValue(logout ?? () async {}),
    accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
  ],
  child: themedApp(const AccountScreen()),
);

void main() {
  testWidgets('shows the title in a ScreenHeader and the Keluar button', (
    tester,
  ) async {
    await tester.pumpWidget(screen());

    expect(
      find.descendant(
        of: find.byType(ScreenHeader),
        matching: find.text('Akun'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('Keluar is a full-width DangerButton of at least 48 dp', (
    tester,
  ) async {
    await tester.pumpWidget(screen());

    final danger = find.byType(DangerButton);
    expect(danger, findsOneWidget);
    expect(
      find.descendant(of: danger, matching: find.text('Keluar')),
      findsOneWidget,
    );
    final rect = tester.getRect(
      find.descendant(of: danger, matching: find.byType(OutlinedButton)),
    );
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(width - 48));
    expect(rect.left, closeTo(width - rect.right, 0.5));
    expect(rect.left, greaterThan(0));
  });

  testWidgets('Keluar sits under the header', (tester) async {
    await tester.pumpWidget(screen());

    expect(
      tester.getTopLeft(find.byType(DangerButton)).dy,
      greaterThanOrEqualTo(tester.getRect(find.byType(ScreenHeader)).bottom),
    );
  });

  testWidgets('tapping the DangerButton signs out once', (tester) async {
    var logouts = 0;
    await tester.pumpWidget(screen(logout: () async => logouts++));

    await tester.tap(find.byType(DangerButton));
    await tester.pump();

    expect(logouts, 1);
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
