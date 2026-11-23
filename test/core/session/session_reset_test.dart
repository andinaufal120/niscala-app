import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/http_providers.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/fakes.dart';

const _ownerToken = 'owner-access';
const _tenantToken = 'tenant-access';

void main() {
  late FakeBackend backend;
  late BackendUser owner;
  late BackendUser tenant;
  late ProviderContainer container;

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);

  Future<void> signInAs(UserRole role, String accessToken) =>
      controller().signIn(
        authSessionFor(
          role,
          accessToken: accessToken,
          refreshToken: '$accessToken-refresh',
        ),
      );

  /// Starts signed out, with the real repositories talking to [backend].
  Future<void> start() async {
    owner = BackendUser(
      tokenPrefix: _ownerToken,
      account: makeBackendAccount(
        UserRole.owner,
        name: 'Siti Pemilik',
        id: 'a-owner',
      ),
      complaints: [
        makeComplaintSummary(
          id: 'c-owner',
          description: 'Atap kamar bocor.',
          tenantName: 'Penyewa Lama',
        ),
      ],
      properties: [makePropertySummary(id: 'p-owner', name: 'Kos Pemilik')],
    );
    tenant = BackendUser(
      tokenPrefix: _tenantToken,
      account: makeBackendAccount(
        UserRole.tenant,
        name: 'Andi Penyewa',
        id: 'a-tnt',
      ),
      leases: [makeCurrentLease(propertyName: 'Kos Penyewa')],
    );
    backend = FakeBackend([owner, tenant]);
    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(backend.client),
        sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
        refreshTokensProvider.overrideWithValue(
          (token) async => authTokens(
            accessToken: '$_ownerToken-2',
            refreshToken: '$_ownerToken-refresh-2',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await controller().restore();
  }

  Future<List<ComplaintSummary>> complaints() =>
      container.read(complaintListProvider.future);
  Future<List<PropertySummary>> properties() =>
      container.read(propertyListProvider.future);
  Future<List<CurrentLease>> leases() =>
      container.read(myLeasesProvider.future);
  Future<Account> account() => container.read(myAccountProvider.future);

  group('after another user signs in', () {
    test('the complaints are those of the new user', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      expect((await complaints()).map((c) => c.id), ['c-owner']);

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      expect(await complaints(), isEmpty);
    });

    test('the properties are those of the new user', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      expect((await properties()).map((p) => p.id), ['p-owner']);

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      expect(await properties(), isEmpty);
    });

    test('the leases are those of the new user', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      expect(await leases(), isEmpty);

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      final items = await leases();
      expect(items, hasLength(1));
      expect(items.single.property.name, 'Kos Penyewa');
    });

    test('the account is that of the new user', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      expect((await account()).name, 'Siti Pemilik');

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      final me = await account();
      expect(me.name, 'Andi Penyewa');
      expect(me.role, UserRole.tenant);
    });

    test('each request is sent with the token of the user it is for', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await complaints();
      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);
      await complaints();

      expect(backend.tokensOf('/complaints'), [_ownerToken, _tenantToken]);
    });

    test('nothing of the previous user remains in any loaded value', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await complaints();
      await properties();
      await account();

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      expect(await complaints(), isEmpty);
      expect(await properties(), isEmpty);
      expect((await account()).id, 'a-tnt');
    });

    test('a value is fetched again for the new user', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await complaints();
      await properties();
      await account();
      expect(backend.requestsTo('/complaints'), 1);
      expect(backend.requestsTo('/properties'), 1);
      expect(backend.requestsTo('/me'), 1);

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);
      await complaints();
      await properties();
      await account();

      expect(backend.requestsTo('/complaints'), 2);
      expect(backend.requestsTo('/properties'), 2);
      expect(backend.requestsTo('/me'), 2);
    });

    test('a value that depends on a repository is fetched again', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await complaints();
      final before = container.read(complaintRepositoryProvider);

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      expect(container.read(complaintRepositoryProvider), isNot(same(before)));
    });
  });

  group('when the user signs out', () {
    test('a provider that is still listened to sends no request', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      container.listen(complaintListProvider, (previous, next) {});
      container.listen(propertyListProvider, (previous, next) {});
      await complaints();
      await properties();
      final requestsBefore = backend.requests.length;

      await controller().signOut();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(backend.requests, hasLength(requestsBefore));
      expect(backend.requests.where((r) => r.token == null), isEmpty);
    });

    test('a provider that is still listened to is loaded for the next user '
        'with the next token', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      container.listen(complaintListProvider, (previous, next) {});
      await complaints();

      await controller().signOut();
      await signInAs(UserRole.tenant, _tenantToken);

      expect(await complaints(), isEmpty);
      expect(backend.tokensOf('/complaints'), [_ownerToken, _tenantToken]);
    });
  });

  group('after the same user signs in again', () {
    test('the values start empty and are fetched again', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      expect((await complaints()).map((c) => c.id), ['c-owner']);
      expect(backend.requestsTo('/complaints'), 1);

      await controller().signOut();
      owner.complaints = [];
      await signInAs(UserRole.owner, _ownerToken);

      expect(await complaints(), isEmpty);
      expect(backend.requestsTo('/complaints'), 2);
    });

    test('the account is fetched again', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await account();

      await controller().signOut();
      await signInAs(UserRole.owner, _ownerToken);
      await account();

      expect(backend.requestsTo('/me'), 2);
    });
  });

  group('while the session continues', () {
    test('a token refresh does not fetch a loaded value again', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      final first = await complaints();
      await properties();
      final requestsBefore = backend.requests.length;

      expect(await controller().refresh(), isTrue);
      final second = await complaints();
      await properties();

      expect(second, same(first));
      expect(backend.requests, hasLength(requestsBefore));
      expect(backend.requestsTo('/complaints'), 1);
      expect(backend.requestsTo('/properties'), 1);
    });

    test('a token refresh keeps the repositories', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      final before = container.read(complaintRepositoryProvider);

      await controller().refresh();

      expect(container.read(complaintRepositoryProvider), same(before));
    });

    test('requests after a token refresh carry the new token', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await controller().refresh();
      container.invalidate(complaintListProvider);

      await complaints();

      expect(backend.tokensOf('/complaints'), ['$_ownerToken-2']);
    });

    test('verifying the email does not fetch a loaded value again', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      final first = await complaints();

      await controller().markEmailVerified();
      final second = await complaints();

      expect(second, same(first));
      expect(backend.requestsTo('/complaints'), 1);
    });

    test('reading a loaded value again does not send a request', () async {
      await start();
      await signInAs(UserRole.owner, _ownerToken);
      await complaints();
      await complaints();

      expect(backend.requestsTo('/complaints'), 1);
    });
  });
}
