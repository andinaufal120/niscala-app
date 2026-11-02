import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../tenants/ui/tenant_ui_helpers.dart';

export '../../tenants/ui/tenant_ui_helpers.dart';

/// The Owner's three properties: `p1` Kos Melati, `p2` Kos Mawar and `p3` Kos
/// Anggrek, in that order.
FakePropertyRepository ownerProperties({bool editable = true}) =>
    FakePropertyRepository(
      properties: [
        makeProperty(id: 'p1', name: 'Kos Melati', editable: editable),
        makeProperty(
          id: 'p2',
          name: 'Kos Mawar',
          address: 'Jl. Mawar 2, Bandung',
          editable: editable,
        ),
        makeProperty(
          id: 'p3',
          name: 'Kos Anggrek',
          address: 'Jl. Anggrek 3, Bandung',
          editable: editable,
        ),
      ],
    );

/// Four managers. Rina (nickname Bu Rina, not activated, Kos Melati), Agus
/// (active, Kos Melati and Kos Mawar, with email), Dewi (not activated, expired
/// invitation, Kos Melati) and Hendra (active, only Kos Mawar).
List<Manager> sampleManagers() => [
  makeManager(id: 'm1', name: 'Rina Putri', nickname: 'Bu Rina'),
  makeManager(
    id: 'm2',
    name: 'Agus Santoso',
    phone: '081377788899',
    email: 'agus@example.com',
    accountStatus: ManagerAccountStatus.active,
    properties: [
      makeManagerProperty(),
      makeManagerProperty(
        id: 'p2',
        name: 'Kos Mawar',
        address: 'Jl. Mawar 2, Bandung',
      ),
    ],
  ),
  makeManager(
    id: 'm3',
    name: 'Dewi Lestari',
    phone: '081311122233',
    invitation: makeManagerInvitation(expired: true),
  ),
  makeManager(
    id: 'm4',
    name: 'Hendra Wijaya',
    phone: '081399900011',
    email: 'hendra@example.com',
    accountStatus: ManagerAccountStatus.active,
    properties: [
      makeManagerProperty(
        id: 'p2',
        name: 'Kos Mawar',
        address: 'Jl. Mawar 2, Bandung',
      ),
    ],
  ),
];

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [managers] behind the manager screens and [properties] behind
/// the property names shown in headers and offered when assigning a manager.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow. Sharing goes to
/// [sharer].
Future<void> pumpManagerApp(
  WidgetTester tester,
  FakeManagerRepository managers, {
  FakePropertyRepository? properties,
  UserRole role = UserRole.owner,
  String path = '/properti/p1/pengelola',
  bool settle = true,
  bool largeText = false,
  ShareRecorder? sharer,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    properties: properties ?? ownerProperties(),
    managers: managers,
    invitationSharer: sharer?.call,
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

/// The checkbox tile of the property named [name] in the property group of the
/// manager form.
Finder propertyTile(String name) => find.byWidgetPredicate(
  (widget) =>
      widget is CheckboxListTile &&
      widget.title is Text &&
      (widget.title as Text).data == name,
  description: 'CheckboxListTile titled "$name"',
);

/// Whether the property named [name] is checked in the manager form.
bool isPropertyChecked(WidgetTester tester, String name) =>
    tester.widget<CheckboxListTile>(propertyTile(name)).value ?? false;

/// The names of the properties checked in the manager form.
List<String> checkedProperties(WidgetTester tester) => [
  for (final name in ['Kos Melati', 'Kos Mawar', 'Kos Anggrek'])
    if (isPropertyChecked(tester, name)) name,
];

/// The card of the manager row whose main text is [text].
Finder managerRow(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Card)).first;
