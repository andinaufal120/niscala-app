import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../properties/ui/property_ui_helpers.dart';

export '../../properties/ui/property_ui_helpers.dart';

/// The Akun tab root of [role].
String accountPath(UserRole role) =>
    role == UserRole.tenant ? '/penyewa/akun' : '/akun';

/// The active devices page of [role].
String sessionsPath(UserRole role) => '${accountPath(role)}/perangkat';

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [accounts] behind the account and device screens.
///
/// Without [path] the Akun tab of the role opens. With [settle] false only a
/// few frames are pumped, so a held gate keeps the screen in its loading
/// state. With [largeText] the display is 360 x 640 dp at text scale 2.0 and
/// the test fails on any overflow.
Future<void> pumpAccountApp(
  WidgetTester tester,
  FakeAccountRepository accounts, {
  UserRole role = UserRole.owner,
  String? path,
  FakeLeaseRepository? leases,
  Future<void> Function()? logout,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    accounts: accounts,
    leases: leases ?? FakeLeaseRepository(lease: makeCurrentLease()),
    logout: logout,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, path ?? accountPath(role));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}
