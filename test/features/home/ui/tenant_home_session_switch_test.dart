import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/api/health_repository.dart';
import 'package:niscala/core/api/http_providers.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala/core/push/push_messaging.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/home/ui/tenant_home_screen.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fake_backend.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import '../../auth/ui/auth_ui_helpers.dart';

const _firstDescription = 'Keran air di kamar mandi bocor sejak kemarin.';

/// The whole app whose repositories are the real ones, talking to [backend].
Widget _appOn(FakeBackend backend, InMemorySessionStore store) {
  return ProviderScope(
    overrides: [
      httpClientProvider.overrideWithValue(backend.client),
      sessionStoreProvider.overrideWithValue(store),
      refreshTokensProvider.overrideWithValue(failingRefresh),
      healthRepositoryProvider.overrideWithValue(FakeHealthRepository()),
      pushMessagingProvider.overrideWithValue(FakePushMessaging()),
      googleIdentityProvider.overrideWithValue(FakeGoogleIdentity()),
      imageChooserProvider.overrideWithValue(FakeImageChooser()),
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      invitationSharerProvider.overrideWithValue((text) async {}),
    ],
    child: const NiscalaApp(),
  );
}

void main() {
  setUpAll(loadAppFont);

  late FakeBackend backend;

  Future<void> openFirstTenantHome(WidgetTester tester) async {
    backend = FakeBackend([
      BackendUser(
        tokenPrefix: 'first-tenant',
        account: makeBackendAccount(
          UserRole.tenant,
          name: 'Siti Rahayu',
          id: 'a-1',
        ),
        complaints: [makeComplaintSummary(description: _firstDescription)],
        leases: [makeCurrentLease()],
      ),
      BackendUser(
        tokenPrefix: 'second-tenant',
        account: makeBackendAccount(
          UserRole.tenant,
          name: 'Dewi Lestari',
          id: 'a-2',
        ),
        leases: [makeCurrentLease()],
      ),
    ]);
    useTallScreen(tester);
    await tester.pumpWidget(
      _appOn(
        backend,
        InMemorySessionStore(
          storedSession(role: UserRole.tenant, accessToken: 'first-tenant-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    goTo(tester, '/penyewa/beranda');
    await tester.pumpAndSettle();
  }

  Future<void> switchToSecondTenant(WidgetTester tester) async {
    final session = containerOf(tester)
        .read(sessionControllerProvider.notifier);
    await session.signOut();
    await tester.pumpAndSettle();
    await session.signIn(
      authSessionFor(
        UserRole.tenant,
        accessToken: 'second-tenant-1',
        refreshToken: 'second-tenant-refresh-1',
      ),
    );
    await tester.pumpAndSettle();
    goTo(tester, '/penyewa/beranda');
    await tester.pumpAndSettle();
  }

  testWidgets('shows the latest complaint of the signed-in tenant', (
    tester,
  ) async {
    await openFirstTenantHome(tester);

    expect(find.byType(TenantHomeScreen), findsOneWidget);
    expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
    expect(find.text(_firstDescription), findsOneWidget);
    expect(find.textContaining('Belum ada keluhan'), findsNothing);
    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('shows no complaint of the previous tenant after another tenant '
      'signs in', (tester) async {
    await openFirstTenantHome(tester);

    await switchToSecondTenant(tester);

    expect(find.byType(TenantHomeScreen), findsOneWidget);
    expect(find.text(_firstDescription), findsNothing);
    expect(find.text('Keluhan saya'), findsOneWidget);
    expect(find.textContaining('Belum ada keluhan'), findsOneWidget);
    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('greets the tenant who signed in last', (tester) async {
    await openFirstTenantHome(tester);

    await switchToSecondTenant(tester);

    expect(find.text('Halo, Dewi Lestari'), findsOneWidget);
    expect(find.textContaining('Siti'), findsNothing);
  });

  testWidgets('asks the backend again for the new tenant with the new '
      'token', (tester) async {
    await openFirstTenantHome(tester);
    expect(backend.tokensOf('/complaints'), ['first-tenant-1']);

    await switchToSecondTenant(tester);

    expect(backend.tokensOf('/complaints'), [
      'first-tenant-1',
      'second-tenant-1',
    ]);
  });

  testWidgets('sends no request without a token while the tenant signs out '
      'and another signs in', (tester) async {
    await openFirstTenantHome(tester);

    await switchToSecondTenant(tester);

    expect(backend.requests.where((r) => r.token == null), isEmpty);
  });

  testWidgets('sends no request when the tenant signs out', (tester) async {
    await openFirstTenantHome(tester);
    final requestsBefore = backend.requests.length;

    await containerOf(tester)
        .read(sessionControllerProvider.notifier)
        .signOut();
    await tester.pumpAndSettle();

    expect(backend.requests, hasLength(requestsBefore));
  });

  testWidgets('shows the complaint again when the first tenant signs back '
      'in', (tester) async {
    await openFirstTenantHome(tester);
    await switchToSecondTenant(tester);

    final session = containerOf(tester)
        .read(sessionControllerProvider.notifier);
    await session.signOut();
    await tester.pumpAndSettle();
    await session.signIn(
      authSessionFor(
        UserRole.tenant,
        accessToken: 'first-tenant-2',
        refreshToken: 'first-tenant-refresh-2',
      ),
    );
    await tester.pumpAndSettle();
    goTo(tester, '/penyewa/beranda');
    await tester.pumpAndSettle();

    expect(find.text(_firstDescription), findsOneWidget);
    expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
  });
}
