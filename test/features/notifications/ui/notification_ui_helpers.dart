import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../account/ui/account_ui_helpers.dart';

export '../../account/ui/account_ui_helpers.dart';

/// The notification list of [role].
String notificationsPath(UserRole role) => '${accountPath(role)}/notifikasi';

/// The notification settings of [role].
String notificationSettingsPath(UserRole role) =>
    '${notificationsPath(role)}/pengaturan';

/// One notification of [role].
String notificationPath(UserRole role, String id) =>
    '${notificationsPath(role)}/$id';

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [repo] behind the notification screens.
///
/// Without [path] the notification list of the role opens. With [settle] false
/// only a few frames are pumped, so a held `gate` keeps the screen in its
/// loading state. With [largeText] the display is 360 x 640 dp at text scale
/// 2.0 and the test fails on any overflow.
Future<void> pumpNotificationApp(
  WidgetTester tester,
  FakeNotificationRepository repo, {
  UserRole role = UserRole.owner,
  String? path,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    notifications: repo,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, path ?? notificationsPath(role));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// The path of the page on top. A pushed page leaves `currentConfiguration.uri`
/// at the location below it, so the last match is read, which is an imperative
/// match for a pushed page.
String pushedPath(WidgetTester tester) {
  final configuration = containerOf(tester)
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration;
  final last = configuration.last;
  return (last is ImperativeRouteMatch ? last.matches.uri : configuration.uri)
      .path;
}

/// Goes back one page of the router, as a link that was pushed does.
void popRoute(WidgetTester tester) =>
    containerOf(tester).read(routerProvider).pop();

/// The marker that an unread notification shows next to its text.
Finder unreadDots() => find.byKey(const ValueKey('unread-dot'));

/// The card of the notification row whose title is [title].
Finder notificationRow(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Card)).first;

/// The unread dot inside the row whose title is [title].
Finder unreadDotOf(String title) =>
    find.descendant(of: notificationRow(title), matching: unreadDots());

/// The spoken label of the row whose title is [title].
String rowLabel(WidgetTester tester, String title) =>
    semanticsLabelOf(tester, title);

/// The font weight a [Text] with the given content is drawn with.
FontWeight? titleWeight(WidgetTester tester, String title) {
  final finder = find.text(title);
  final text = tester.widget<Text>(finder);
  final inherited = DefaultTextStyle.of(tester.element(finder)).style;
  return inherited.merge(text.style).fontWeight;
}

/// Expects no text on screen to show a missing value or a broken join of
/// pieces: the word null, doubled or edge spaces, or a dangling separator.
void expectNoBrokenText(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data == null) continue;
    expect(data, isNot(contains('null')), reason: data);
    expect(data, isNot(contains('  ')), reason: data);
    expect(data, isNot(startsWith(' ')), reason: data);
    expect(data, isNot(endsWith(' ')), reason: data);
    expect(data, isNot(startsWith('·')), reason: data);
    expect(data, isNot(endsWith('·')), reason: data);
    expect(data, isNot(contains('· ·')), reason: data);
    expect(data, isNot(contains(' .')), reason: data);
    expect(data, isNot(contains('..')), reason: data);
    expect(data, isNot(contains('()')), reason: data);
  }
}

/// The switch tile whose title is [label].
Finder switchTile(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is SwitchListTile &&
      widget.title is Text &&
      (widget.title as Text).data == label,
  description: 'SwitchListTile titled "$label"',
);

/// Whether the switch titled [label] is on.
bool isSwitchOn(WidgetTester tester, String label) =>
    tester.widget<SwitchListTile>(switchTile(label)).value;

/// Expects the control labelled [label] to be a radio choice in the given
/// state.
void expectRadio(WidgetTester tester, String label, {required bool selected}) {
  final handle = tester.ensureSemantics();
  try {
    expect(
      tester.getSemantics(find.text(label)),
      isSemantics(hasCheckedState: true, isChecked: selected),
    );
  } finally {
    handle.dispose();
  }
}
