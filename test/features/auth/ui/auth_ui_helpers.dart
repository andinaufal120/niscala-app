import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

/// The text field whose label is [label].
Finder field(String label) => find.widgetWithText(TextField, label);

TextField textField(WidgetTester tester, String label) =>
    tester.widget<TextField>(field(label));

/// The `errorText` shown by the field labelled [label].
String? fieldError(WidgetTester tester, String label) =>
    textField(tester, label).decoration?.errorText;

/// The button that contains the text [label].
Finder buttonLabelled(String label) =>
    find.ancestor(of: find.text(label), matching: anyButton());

/// The button that shows the in-flight progress indicator.
Finder busyButton() => find.ancestor(
  of: find.byType(CircularProgressIndicator),
  matching: anyButton(),
);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(NiscalaApp)));

String currentPath(WidgetTester tester) =>
    containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void goTo(WidgetTester tester, String path) =>
    containerOf(tester).read(routerProvider).go(path);

/// A tall display, so that long forms need no scrolling in tests.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Scrolls to [finder] when needed, taps it and lets the UI settle.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps and pumps one frame only, for states that never settle because a
/// progress indicator is animating.
Future<void> tapAndPump(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
}

/// Types [text] into the field labelled [label].
Future<void> type(WidgetTester tester, String label, String text) async {
  await tester.enterText(field(label), text);
  await tester.pump();
}

/// Checks the authentication rules of a credential field: selection and paste
/// stay on, the autofill hint is set and the field sits in an `AutofillGroup`.
void expectCredentialField(WidgetTester tester, String label, String hint) {
  final input = textField(tester, label);
  expect(input.decoration?.labelText, label);
  expect(input.enableInteractiveSelection, isNot(false));
  expect(input.autofillHints, contains(hint));
  expect(
    find.ancestor(of: field(label), matching: find.byType(AutofillGroup)),
    findsOneWidget,
  );
}

/// Expects the text [text] to be exposed as a live region.
void expectLiveRegion(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    expect(
      tester.getSemantics(find.text(text)),
      isSemantics(isLiveRegion: true),
    );
  } finally {
    handle.dispose();
  }
}

/// Expects the show-password checkbox to be a labelled checkbox with the
/// given state and a target of at least 48 dp.
void expectShowPasswordCheckbox(WidgetTester tester, {required bool checked}) {
  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(find.text('Tampilkan kata sandi'));
    expect(
      node,
      isSemantics(
        label: 'Tampilkan kata sandi',
        hasCheckedState: true,
        isChecked: checked,
      ),
    );
    expect(node.rect.height, greaterThanOrEqualTo(48));
    expect(node.rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

/// Expects the in-flight button state: a progress indicator labelled
/// 'Memproses' inside a disabled button.
void expectBusy(WidgetTester tester) {
  final handle = tester.ensureSemantics();
  try {
    expect(busyButton(), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(busyButton()).onPressed, isNull);
    expect(find.bySemanticsLabel('Memproses'), findsAtLeastNWidgets(1));
  } finally {
    handle.dispose();
  }
}

/// Shows the sign in screen with [auth] behind it.
Future<InMemorySessionStore> pumpLogin(
  WidgetTester tester,
  FakeAuthRepository auth, {
  Future<void> Function()? logout,
}) async {
  useTallScreen(tester);
  final store = InMemorySessionStore();
  await tester.pumpWidget(
    buildTestApp(store: store, auth: auth, logout: logout),
  );
  await tester.pumpAndSettle();
  return store;
}

/// Shows the sign up screen with [auth] behind it.
Future<InMemorySessionStore> pumpRegister(
  WidgetTester tester,
  FakeAuthRepository auth,
) async {
  final store = await pumpLogin(tester, auth);
  goTo(tester, '/daftar');
  await tester.pumpAndSettle();
  return store;
}

/// Shows the email verification screen for a signed-in, unverified user.
///
/// With [settle] false, only a few frames are pumped, so a held
/// `accountGate` keeps the screen in its loading state.
Future<InMemorySessionStore> pumpVerify(
  WidgetTester tester,
  FakeAuthRepository auth, {
  UserRole role = UserRole.owner,
  Future<void> Function()? logout,
  bool settle = true,
}) async {
  useTallScreen(tester);
  final store = InMemorySessionStore(
    storedSession(role: role, emailVerified: false),
  );
  await tester.pumpWidget(
    buildTestApp(store: store, auth: auth, logout: logout),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  return store;
}
