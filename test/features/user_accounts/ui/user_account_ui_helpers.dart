import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../rooms/ui/room_ui_helpers.dart';

export '../../rooms/ui/room_ui_helpers.dart';

/// Five accounts: Budi Santoso (tenant, active), Siti Pemilik (owner, active),
/// Agus Wijaya (manager, inactive), Rina Admin (admin, active) and Hendra
/// Kusuma (tenant, deleted). Hendra is left out of the default list.
List<UserAccount> sampleUserAccounts() => [
  makeUserAccount(),
  makeUserAccount(
    id: 'u2',
    name: 'Siti Pemilik',
    email: 'siti@example.com',
    role: UserRole.owner,
  ),
  makeUserAccount(
    id: 'u3',
    name: 'Agus Wijaya',
    email: 'agus@kos.test',
    role: UserRole.manager,
    status: UserAccountStatus.inactive,
  ),
  makeUserAccount(
    id: 'u4',
    name: 'Rina Admin',
    email: 'rina@niscala.test',
    role: UserRole.admin,
  ),
  makeUserAccount(
    id: 'u5',
    name: 'Hendra Kusuma',
    email: 'hendra@example.com',
    status: UserAccountStatus.deleted,
  ),
];

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [accounts] behind the user account screens.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow. [logout] replaces
/// the logout of the app. [me] is the account of the signed-in user; without it
/// that account has the id `account-1`, which none of the listed accounts has.
Future<void> pumpUserAccountApp(
  WidgetTester tester,
  FakeUserAccountRepository accounts, {
  UserRole role = UserRole.admin,
  String path = '/admin',
  bool settle = true,
  bool largeText = false,
  Future<void> Function()? logout,
  FakeAccountRepository? me,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    userAccounts: accounts,
    accounts: me,
    logout: logout,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  Future<void> advance() async {
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  await advance();
  goTo(tester, path);
  await advance();
}

/// The card of the account row whose name is [name].
Finder accountRow(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

/// The label of the checkbox that includes deleted accounts.
const deletedCheckboxLabel = 'Tampilkan akun yang dihapus';

/// Expects the checkbox that includes deleted accounts to be a checkbox with
/// the state [checked] and a target of at least 48 dp.
void expectDeletedCheckbox(WidgetTester tester, {required bool checked}) {
  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(find.text(deletedCheckboxLabel));
    expect(node, isSemantics(hasCheckedState: true, isChecked: checked));
    expect(node.label, startsWith(deletedCheckboxLabel));
    expect(node.rect.height, greaterThanOrEqualTo(48));
    expect(node.rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}
