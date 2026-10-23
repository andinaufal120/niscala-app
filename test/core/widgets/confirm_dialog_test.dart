import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

class DialogOutcome {
  bool? result;
  bool answered = false;
}

Widget host(DialogOutcome out) => themedApp(
  Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () async {
            out.result = await showConfirmDialog(
              context,
              title: 'Hapus properti',
              message: 'Properti akan dihapus.',
              confirmLabel: 'Hapus',
            );
            out.answered = true;
          },
          child: const Text('Buka'),
        ),
      ),
    ),
  ),
);

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('Buka'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, message and both buttons', (tester) async {
    await tester.pumpWidget(host(DialogOutcome()));

    await open(tester);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Hapus properti'), findsOneWidget);
    expect(find.text('Properti akan dihapus.'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
  });

  testWidgets('returns true when the confirm button is pressed', (
    tester,
  ) async {
    final out = DialogOutcome();
    await tester.pumpWidget(host(out));
    await open(tester);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(out.result, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('returns false when Batal is pressed', (tester) async {
    final out = DialogOutcome();
    await tester.pumpWidget(host(out));
    await open(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(out.result, isFalse);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('returns false when dismissed by tapping outside', (
    tester,
  ) async {
    final out = DialogOutcome();
    await tester.pumpWidget(host(out));
    await open(tester);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(out.answered, isTrue);
    expect(out.result, isFalse);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('both buttons are at least 48 by 48 dp', (tester) async {
    await tester.pumpWidget(host(DialogOutcome()));
    await open(tester);

    for (final label in ['Batal', 'Hapus']) {
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: anyButton()),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('meets accessibility guidelines', (tester) async {
    await tester.pumpWidget(host(DialogOutcome()));
    await open(tester);

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(tester, host(DialogOutcome()));
    await open(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Hapus properti'), findsOneWidget);
  });
}
