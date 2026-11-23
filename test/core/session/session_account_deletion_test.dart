import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

Matcher signedOutAfterDeletion() =>
    isA<SignedOut>().having((s) => s.accountDeleted, 'accountDeleted', true);

Matcher signedOutNormally() =>
    isA<SignedOut>().having((s) => s.accountDeleted, 'accountDeleted', false);

void main() {
  late InMemorySessionStore store;
  late List<String> refreshInputs;
  late ProviderContainer container;

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);
  SessionState state() => container.read(sessionControllerProvider);

  Future<void> start([StoredSession? initial]) async {
    store = InMemorySessionStore(initial);
    refreshInputs = [];
    container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        refreshTokensProvider.overrideWithValue((token) {
          refreshInputs.add(token);
          return Future.value(authTokens());
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionControllerProvider);
    await controller().restore();
  }

  group('SignedOut', () {
    test('does not mark the account as deleted by default', () {
      expect(const SignedOut().accountDeleted, isFalse);
    });

    test('can mark the account as deleted', () {
      expect(const SignedOut(accountDeleted: true).accountDeleted, isTrue);
    });
  });

  group('endAfterAccountDeletion', () {
    test('signs out and marks the account as deleted', () async {
      await start(storedSession());

      await controller().endAfterAccountDeletion();

      expect(state(), signedOutAfterDeletion());
    });

    test('clears the stored session', () async {
      await start(storedSession());

      await controller().endAfterAccountDeletion();

      expect(store.stored, isNull);
      expect(controller().accessToken, isNull);
    });

    for (final role in [UserRole.owner, UserRole.manager, UserRole.tenant]) {
      test('works for a $role', () async {
        await start(storedSession(role: role));

        await controller().endAfterAccountDeletion();

        expect(state(), signedOutAfterDeletion());
        expect(store.stored, isNull);
      });
    }

    test('does not use the refresh token', () async {
      await start(storedSession());

      await controller().endAfterAccountDeletion();

      expect(refreshInputs, isEmpty);
    });

    test('leaves no session to refresh', () async {
      await start(storedSession());
      await controller().endAfterAccountDeletion();

      final refreshed = await controller().refresh();

      expect(refreshed, isFalse);
      expect(refreshInputs, isEmpty);
      expect(state(), signedOutAfterDeletion());
    });

    test('does not mark a later sign in as deleted', () async {
      await start(storedSession());
      await controller().endAfterAccountDeletion();

      await controller().signIn(authSessionFor(UserRole.tenant));

      expect(state(), isA<SignedIn>());
    });

    test('is forgotten after a later sign in and sign out', () async {
      await start(storedSession());
      await controller().endAfterAccountDeletion();
      await controller().signIn(authSessionFor(UserRole.owner));

      await controller().signOut();

      expect(state(), signedOutNormally());
    });
  });

  group('the other ways to sign out', () {
    test('signOut does not mark the account as deleted', () async {
      await start(storedSession());

      await controller().signOut();

      expect(state(), signedOutNormally());
    });

    test('expire does not mark the account as deleted', () async {
      await start(storedSession());

      controller().expire();
      await Future<void>.delayed(Duration.zero);

      expect(state(), signedOutNormally());
    });

    test('restoring without a stored session does not mark it', () async {
      await start();

      expect(state(), signedOutNormally());
    });
  });
}
