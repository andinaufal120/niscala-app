import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../rooms/ui/room_ui_helpers.dart';

export '../../rooms/ui/room_ui_helpers.dart';

const subscriptionPath = '/akun/langganan';

/// The downgrade page for [plan] (`free` or `basic`).
String downgradePath(String plan) => '$subscriptionPath/turunkan?paket=$plan';

/// Shows the app signed in as [role] and opens [path] on top of the home route,
/// with [subscriptions] behind the subscription screens, [properties] behind the
/// property list of the downgrade page and [rooms] behind its room list.
///
/// With [settle] false only a few frames are pumped, so a held gate keeps the
/// screen in its loading state. With [largeText] the display is 360 x 640 dp at
/// text scale 2.0 and the test fails on any overflow.
Future<void> pumpSubscriptionApp(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions, {
  UserRole role = UserRole.owner,
  String path = subscriptionPath,
  FakePropertyRepository? properties,
  FakeRoomRepository? rooms,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    subscriptions: subscriptions,
    properties: properties ?? ownerPropertiesForPlans(),
    rooms: rooms ?? FakeRoomRepository(),
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

/// The Owner's four properties: `p1` Kos Melati (12 rooms), `p2` Kos Mawar (8),
/// `p3` Kos Anggrek (5) and `p4` Kos Dahlia (3).
FakePropertyRepository ownerPropertiesForPlans() => FakePropertyRepository(
  properties: [
    makeProperty(id: 'p1', name: 'Kos Melati', roomCount: 12),
    makeProperty(id: 'p2', name: 'Kos Mawar', roomCount: 8),
    makeProperty(id: 'p3', name: 'Kos Anggrek', roomCount: 5),
    makeProperty(id: 'p4', name: 'Kos Dahlia', roomCount: 3),
  ],
);

/// The first [count] properties of [ownerPropertiesForPlans].
FakePropertyRepository firstOwnerProperties(int count) =>
    FakePropertyRepository(
      properties: ownerPropertiesForPlans().properties.take(count).toList(),
    );

/// [count] rooms numbered [base] + 1, [base] + 2 and so on in property
/// [propertyId] with ids `<propertyId>-r1`, `<propertyId>-r2` and so on. The odd
/// ones are occupied.
List<Room> roomsOf(String propertyId, int count, {int base = 100}) => [
  for (var i = 1; i <= count; i++)
    makeRoom(
      id: '$propertyId-r$i',
      propertyId: propertyId,
      number: '${base + i}',
      lease: i.isOdd ? makeRoomLease() : null,
    ),
];

Uri currentUri(WidgetTester tester) =>
    containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri;

/// The bottom sheet of the order summary.
Finder orderSheet() => find.byType(BottomSheet);

/// [finder] inside the order summary sheet.
Finder inSheet(Finder finder) =>
    find.descendant(of: orderSheet(), matching: finder);

/// Expects [text] to be announced as a heading.
void expectHeading(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(find.text(text)), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

/// Taps [finder], scrolling to it first, and lets the UI settle.
Future<void> tap(WidgetTester tester, Finder finder) =>
    tapVisible(tester, finder);

/// The checkbox tile that contains the text [label].
Finder tileOf(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(CheckboxListTile),
);

bool isChecked(WidgetTester tester, String label) =>
    tester.widget<CheckboxListTile>(tileOf(label)).value ?? false;

/// Makes the checkbox of [label] checked or unchecked, tapping it only when it
/// is in the other state.
Future<void> setChecked(WidgetTester tester, String label, bool checked) async {
  if (isChecked(tester, label) == checked) return;
  await tapVisible(tester, tileOf(label));
}

/// Checks exactly the checkboxes of [labelsToCheck] among [all].
Future<void> checkOnly(
  WidgetTester tester,
  List<String> all,
  List<String> labelsToCheck,
) async {
  for (final label in all) {
    await setChecked(tester, label, labelsToCheck.contains(label));
  }
}

const propertyNames = ['Kos Melati', 'Kos Mawar', 'Kos Anggrek', 'Kos Dahlia'];

/// The room labels `Kamar 101, terisi` and so on of [count] rooms made by
/// [roomsOf] with the same [base].
List<String> roomLabels(int count, {int base = 100}) => [
  for (var i = 1; i <= count; i++)
    'Kamar ${base + i}, ${i.isOdd ? 'terisi' : 'kosong'}',
];

/// The ids of the first [count] rooms made by [roomsOf] for [propertyId].
List<String> roomIds(String propertyId, int count) => [
  for (var i = 1; i <= count; i++) '$propertyId-r$i',
];
