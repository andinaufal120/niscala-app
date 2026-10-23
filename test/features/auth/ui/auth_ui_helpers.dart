import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';

import 'package:niscala/core/widgets/labeled_field.dart';

/// The field named [label]: a text field inside a labelled field whose label,
/// marker included, is [label], or one that still draws [label] inside its
/// decoration (screens not moved to the labelled field yet).
Finder field(String label) => find.byElementPredicate((element) {
  final widget = element.widget;
  if (widget is! TextField) return false;
  if (widget.decoration?.labelText == label) return true;
  var labelled = false;
  element.visitAncestorElements((ancestor) {
    final candidate = ancestor.widget;
    if (candidate is LabeledField && fullLabelOf(candidate) == label) {
      labelled = true;
      return false;
    }
    return true;
  });
  return labelled;
}, description: 'text field named "$label"');

/// The `TextField` named [label].
TextField textField(WidgetTester tester, String label) =>
    tester.widget<TextField>(field(label));

/// The error shown by the field named [label].
String? fieldError(WidgetTester tester, String label) {
  if (labeledField(label).evaluate().isNotEmpty) {
    return labeledFieldError(tester, label);
  }
  return textField(tester, label).decoration?.errorText;
}

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

/// Checks the authentication rules of a credential field: the label sits in a
/// [LabeledField] (not in the decoration), selection and paste stay on, the
/// autofill hint is set and the field sits in an `AutofillGroup`.
void expectCredentialField(WidgetTester tester, String label, String hint) =>
    expectLabeledCredentialField(tester, label, hint);

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

/// Expects the primary action [label] to sit in an `ActionFooter` that is
/// outside every scrollable, with the button inside the footer, and the footer
/// to sit at the bottom of the screen.
void expectPinnedFooter(WidgetTester tester, String label) {
  final footer = find.byType(ActionFooter);
  expect(footer, findsOneWidget);
  expect(
    find.ancestor(of: footer, matching: find.byType(Scrollable)),
    findsNothing,
  );
  expect(
    find.descendant(of: footer, matching: buttonLabelled(label)),
    findsOneWidget,
  );
  expectFooterAtBottom(tester);
}

/// Expects the `ActionFooter` to sit directly above a `NavigationBar` when one
/// is shown, and at the bottom of the screen otherwise.
void expectFooterAtBottom(WidgetTester tester) {
  final footer = tester.getRect(find.byType(ActionFooter));
  final navigation = find.byType(NavigationBar);
  final bottom = navigation.evaluate().isEmpty
      ? (tester.view.physicalSize / tester.view.devicePixelRatio).height
      : tester.getRect(navigation).top;
  expect(footer.bottom, closeTo(bottom, 1));
}

/// Expects the app bar to use the white surface colour of the design.
void expectWhiteAppBar(WidgetTester tester) {
  final appBar = tester.widget<AppBar>(find.byType(AppBar));
  final theme = Theme.of(tester.element(find.byType(AppBar)));
  expect(
    appBar.backgroundColor ??
        theme.appBarTheme.backgroundColor ??
        theme.colorScheme.surface,
    NiscalaColors.surface,
  );
}

/// Expects the detail app bar: white, and not tinted when content scrolls
/// under it.
void expectDetailAppBar(WidgetTester tester) {
  expectWhiteAppBar(tester);
  final appBar = tester.widget<AppBar>(find.byType(AppBar));
  final theme = Theme.of(tester.element(find.byType(AppBar)));
  expect(
    appBar.scrolledUnderElevation ?? theme.appBarTheme.scrolledUnderElevation,
    0,
  );
}

/// The `SectionCard` whose heading is [title].
Finder sectionCardOf(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SectionCard));

/// Expects [title] to be the heading of a `SectionCard`, announced as a header.
void expectSectionCard(WidgetTester tester, String title) {
  expect(sectionCardOf(title), findsOneWidget);
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(find.text(title)), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

/// Expects every `Card` matched by [card] to take the design's look from the
/// theme: no elevation, a 16 dp radius and a 1 dp divider border.
void expectCardLook(WidgetTester tester, Finder card) {
  final count = card.evaluate().length;
  expect(count, greaterThan(0));
  for (var i = 0; i < count; i++) {
    final finder = card.at(i);
    final widget = tester.widget<Card>(finder);
    final theme = Theme.of(tester.element(finder)).cardTheme;
    expect(widget.elevation ?? theme.elevation, 0);
    final shape = widget.shape ?? theme.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    final rounded = shape! as RoundedRectangleBorder;
    expect(rounded.borderRadius, BorderRadius.circular(16));
    expect(rounded.side, const BorderSide(color: NiscalaColors.divider));
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
