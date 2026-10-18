import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../auth/ui/auth_ui_helpers.dart';

export '../../auth/ui/auth_ui_helpers.dart';

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [repo] behind the property screens.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow.
Future<void> pumpPropertyApp(
  WidgetTester tester,
  FakePropertyRepository repo, {
  UserRole role = UserRole.owner,
  String path = '/properti',
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    properties: repo,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, path);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Finder appBarTitle(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

Finder snackBar(String text) => find.widgetWithText(SnackBar, text);

/// Expects a progress indicator that TalkBack announces as 'Memuat'.
void expectLoading(WidgetTester tester) {
  final handle = tester.ensureSemantics();
  try {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Memuat'), findsAtLeastNWidgets(1));
  } finally {
    handle.dispose();
  }
}

/// Expects the app bar back button, labelled 'Kembali'.
Finder backButton() => find.byTooltip('Kembali');

Future<void> pressBack(WidgetTester tester) async {
  await tester.tap(backButton());
  await tester.pumpAndSettle();
}

/// Expects the tap target of the text [label] to be at least 48 dp square.
void expectTargetSize(WidgetTester tester, String label) {
  final handle = tester.ensureSemantics();
  try {
    final rect = tester.getSemantics(find.text(label)).rect;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

/// The semantics label of the node that contains the text [text].
String semanticsLabelOf(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    return tester.getSemantics(find.text(text)).label;
  } finally {
    handle.dispose();
  }
}

final bankAccount = BankAccount(
  bankName: 'BCA',
  accountNumber: '1234567890',
  accountHolderName: 'Budi Santoso',
);

final managerSari = ManagerRef(id: 'm1', name: 'Sari');
final managerDewi = ManagerRef(id: 'm2', name: 'Dewi');
