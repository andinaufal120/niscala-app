import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../rooms/ui/room_ui_helpers.dart';

export '../../rooms/ui/room_ui_helpers.dart';

/// The list route of the Keluhan tab for [role].
String complaintListPath(UserRole role) =>
    role == UserRole.tenant ? '/penyewa/keluhan' : '/keluhan';

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [complaints] behind the complaint screens.
///
/// Without [path] the Keluhan list of the role opens. With [settle] false only
/// a few frames are pumped, so a held `gate` keeps the screen in its loading
/// state. With [largeText] the display is 360 x 640 dp at text scale 2.0 and
/// the test fails on any overflow.
Future<void> pumpComplaintApp(
  WidgetTester tester,
  FakeComplaintRepository complaints, {
  UserRole role = UserRole.tenant,
  String? path,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    complaints: complaints,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, path ?? complaintListPath(role));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// The disclaimer shown under AI output.
Finder aiDisclaimer() =>
    find.textContaining('Klasifikasi dibuat AI dan bisa keliru');

/// The note that replaces a withheld AI classification.
Finder subscriptionNote() => find.textContaining('langganan');

/// Vertical position of the top of [finder], to compare reading order.
double topOf(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

/// A status change at [changedAt] with an optional handling note.
ComplaintStatusChange statusChange(
  ComplaintStatus status,
  DateTime changedAt, {
  String? note,
}) => ComplaintStatusChange(
  status: status,
  changedAt: changedAt,
  handlingNote: note,
);

/// Every action button on screen. The icon button of the app bar (Kembali) is
/// navigation, not an action, so it does not count.
Finder actionButtons() => find.byWidgetPredicate(
  (widget) =>
      widget is FilledButton ||
      widget is ElevatedButton ||
      widget is OutlinedButton ||
      widget is TextButton,
);
