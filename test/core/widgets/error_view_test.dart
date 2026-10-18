import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/error_view.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

Widget screen({VoidCallback? onRetry}) => themedApp(
  Scaffold(
    body: ErrorView(
      message: 'Tidak dapat terhubung ke server.',
      onRetry: onRetry ?? () {},
    ),
  ),
);

void main() {
  testWidgets('shows the message and the retry button', (tester) async {
    await tester.pumpWidget(screen());

    expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('calls onRetry when the button is pressed', (tester) async {
    var retries = 0;
    await tester.pumpWidget(screen(onRetry: () => retries++));

    await tester.tap(find.text('Coba lagi'));

    expect(retries, 1);
  });

  testWidgets('retry button is at least 48 by 48 dp', (tester) async {
    await tester.pumpWidget(screen());

    final size = tester.getSize(find.byType(ButtonStyleButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
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
