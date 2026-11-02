import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala_api/api.dart';

import '../../features/notifications/ui/notification_ui_helpers.dart';
import '../../helpers/fakes.dart';

export '../../features/notifications/ui/notification_ui_helpers.dart';

/// Shows the app with [push] and [repo] behind it and lets it settle.
///
/// Without [store] the app starts signed out. A [store] that holds a session
/// starts the app signed in.
Future<void> pumpPushApp(
  WidgetTester tester, {
  required FakePushMessaging push,
  required FakeNotificationRepository repo,
  SessionStore? store,
  bool settle = true,
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      store: store ?? InMemorySessionStore(),
      notifications: repo,
      push: push,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A loading indicator animates forever, so the app never settles.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Signs in as a user of [role] after the app started.
Future<void> signInAs(
  WidgetTester tester,
  UserRole role, {
  bool emailVerified = true,
}) async {
  await containerOf(tester)
      .read(sessionControllerProvider.notifier)
      .signIn(authSessionFor(role, emailVerified: emailVerified));
  await tester.pumpAndSettle();
}

Future<void> signOutNow(WidgetTester tester) async {
  await containerOf(tester).read(sessionControllerProvider.notifier).signOut();
  await tester.pumpAndSettle();
}

Future<void> verifyEmailNow(WidgetTester tester) async {
  await containerOf(tester)
      .read(sessionControllerProvider.notifier)
      .markEmailVerified();
  await tester.pumpAndSettle();
}

/// A notification of the right shape for any role: an unread bill notice.
Notification pushedNotification(String id) =>
    makeNotification(id: id, rentBill: makeNotificationRentBill());

/// Every plain text shown on the screen, in tree order.
List<String> shownTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null) text.data!,
];
