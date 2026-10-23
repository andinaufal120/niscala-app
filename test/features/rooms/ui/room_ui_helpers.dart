import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart'
    as flutter_test
    show testWidgets;
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../properties/ui/property_ui_helpers.dart';

export '../../properties/ui/property_ui_helpers.dart';

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [rooms] behind the room screens and [properties] behind the
/// property name shown in their headers.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow.
Future<void> pumpRoomApp(
  WidgetTester tester,
  FakeRoomRepository rooms, {
  FakePropertyRepository? properties,
  UserRole role = UserRole.owner,
  String path = '/properti/p1/kamar',
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    properties: properties ?? propertiesWithMelati(),
    rooms: rooms,
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

/// A property repository holding the property `p1`, named Kos Melati.
FakePropertyRepository propertiesWithMelati({bool editable = true}) =>
    FakePropertyRepository(
      properties: [
        makeProperty(id: 'p1', name: 'Kos Melati', editable: editable),
      ],
    );

/// An occupied room with a lease that has an end date.
Room occupiedRoom({
  String id = 'r1',
  String number = '08',
  int baseRate = 800000,
  int rent = 750000,
  String tenantName = 'Budi Santoso',
  DateTime? startDate,
  DateTime? endDate,
  num? lengthM = 3.5,
  num? widthM = 4,
  List<String> facilities = const ['ac', 'kasur'],
  bool editable = true,
}) => makeRoom(
  id: id,
  number: number,
  baseRate: baseRate,
  lease: makeRoomLease(
    tenantName: tenantName,
    rent: rent,
    startDate: startDate ?? DateTime.utc(2026, 1, 1),
    endDate: endDate ?? DateTime.utc(2026, 12, 31),
  ),
  lengthM: lengthM,
  widthM: widthM,
  facilities: facilities,
  editable: editable,
);

/// A vacant room without dimensions or facilities unless given.
Room vacantRoom({
  String id = 'r2',
  String number = '09',
  int baseRate = 650000,
  num? lengthM,
  num? widthM,
  List<String> facilities = const [],
  bool editable = true,
}) => makeRoom(
  id: id,
  number: number,
  baseRate: baseRate,
  lengthM: lengthM,
  widthM: widthM,
  facilities: facilities,
  editable: editable,
);

/// A status badge with the text [label].
Finder statusBadge(String label) =>
    find.descendant(of: find.byType(StatusBadge), matching: find.text(label));

/// The filter chip with the text [label], whatever Material chip it is.
Finder filterChip(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate(
    (widget) => widget is ChoiceChip || widget is FilterChip,
  ),
);

/// Text inside the app bar.
Finder inAppBar(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

/// A widget test with semantics on for its whole body. The handle is released
/// before the test ends, as flutter_test requires.
void testWidgetsWithSemantics(
  String description,
  Future<void> Function(WidgetTester tester) body,
) => flutter_test.testWidgets(description, (tester) async {
  final handle = tester.ensureSemantics();
  try {
    await body(tester);
  } finally {
    handle.dispose();
  }
});

/// Expects the chip [label] to expose [selected] to assistive technology.
void expectChipSelected(
  WidgetTester tester,
  String label, {
  required bool selected,
}) {
  final handle = tester.ensureSemantics();
  try {
    expect(
      tester.getSemantics(filterChip(label)),
      isSemantics(hasSelectedState: true, isSelected: selected),
    );
  } finally {
    handle.dispose();
  }
}

/// Expects the chip [label] to be at least 48 dp square.
void expectChipTargetSize(WidgetTester tester, String label) {
  final handle = tester.ensureSemantics();
  try {
    final rect = tester.getSemantics(filterChip(label)).rect;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

/// The remove button of the chosen facility [tag]. Needs semantics on.
Finder removeFacilityButton(String tag) =>
    find.bySemanticsLabel('Hapus fasilitas $tag').first;

/// Expects the target of the remove button of [tag] to be at least 48 dp.
void expectRemoveTargetSize(WidgetTester tester, String tag) {
  final handle = tester.ensureSemantics();
  try {
    final rect = tester.getSemantics(removeFacilityButton(tag)).rect;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}
