import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

Matcher signedIn(UserRole role, {required bool emailVerified}) =>
    isA<SignedIn>()
        .having((s) => s.role, 'role', role)
        .having((s) => s.emailVerified, 'emailVerified', emailVerified);

void main() {
  late InMemorySessionStore store;
  late List<String> refreshInputs;
  late Future<AuthTokens> Function(String) refreshImpl;
  late ProviderContainer container;

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);
  SessionState state() => container.read(sessionControllerProvider);

  /// Creates the container, reads the controller and lets any start-up work
  /// finish.
  Future<void> start([StoredSession? initial]) async {
    store = InMemorySessionStore(initial);
    refreshInputs = [];
    refreshImpl = (token) async => authTokens();
    container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        refreshTokensProvider.overrideWithValue((token) {
          refreshInputs.add(token);
          return refreshImpl(token);
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionControllerProvider);
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts in the loading state', () async {
    await start(storedSession());

    expect(state(), isA<SessionLoading>());
  });

  group('restore', () {
    test('becomes signed out when nothing is stored', () async {
      await start();

      await controller().restore();

      expect(state(), isA<SignedOut>());
      expect(controller().accessToken, isNull);
    });

    test('becomes signed in with the stored role and verification', () async {
      await start(storedSession(role: UserRole.tenant, emailVerified: false));

      await controller().restore();

      expect(state(), signedIn(UserRole.tenant, emailVerified: false));
    });

    test('exposes the stored access token', () async {
      await start(storedSession(accessToken: 'stored-access'));

      await controller().restore();

      expect(controller().accessToken, 'stored-access');
    });
  });

  group('signIn', () {
    test('stores the tokens, role and verification and signs in', () async {
      await start();
      await controller().restore();

      await controller().signIn(
        authSessionFor(
          UserRole.manager,
          emailVerified: false,
          accessToken: 'a',
          refreshToken: 'r',
        ),
      );

      expect(state(), signedIn(UserRole.manager, emailVerified: false));
      expect(store.stored?.accessToken, 'a');
      expect(store.stored?.refreshToken, 'r');
      expect(store.stored?.role, UserRole.manager);
      expect(store.stored?.emailVerified, isFalse);
      expect(controller().accessToken, 'a');
    });

    test('replaces a previously stored session', () async {
      await start(storedSession(role: UserRole.tenant));
      await controller().restore();

      await controller().signIn(authSessionFor(UserRole.owner));

      expect(state(), signedIn(UserRole.owner, emailVerified: true));
      expect(store.stored?.role, UserRole.owner);
    });
  });

  group('markEmailVerified', () {
    test('updates the store and the state and keeps the tokens', () async {
      await start(
        storedSession(
          role: UserRole.owner,
          emailVerified: false,
          accessToken: 'a',
          refreshToken: 'r',
        ),
      );
      await controller().restore();

      await controller().markEmailVerified();

      expect(state(), signedIn(UserRole.owner, emailVerified: true));
      expect(store.stored?.emailVerified, isTrue);
      expect(store.stored?.accessToken, 'a');
      expect(store.stored?.refreshToken, 'r');
      expect(store.stored?.role, UserRole.owner);
    });
  });

  group('signOut', () {
    test('clears the store and signs out', () async {
      await start(storedSession());
      await controller().restore();

      await controller().signOut();

      expect(state(), isA<SignedOut>());
      expect(store.stored, isNull);
      expect(controller().accessToken, isNull);
    });
  });

  group('expire', () {
    test('clears the session and signs out', () async {
      await start(storedSession());
      await controller().restore();

      controller().expire();
      await settle();

      expect(state(), isA<SignedOut>());
      expect(store.stored, isNull);
      expect(controller().accessToken, isNull);
    });
  });

  group('refresh', () {
    test('sends the stored refresh token and stores the new pair', () async {
      await start(
        storedSession(
          role: UserRole.tenant,
          emailVerified: true,
          accessToken: 'old-a',
          refreshToken: 'old-r',
        ),
      );
      await controller().restore();
      refreshImpl = (token) async =>
          authTokens(accessToken: 'new-a', refreshToken: 'new-r');

      final result = await controller().refresh();

      expect(result, isTrue);
      expect(refreshInputs, ['old-r']);
      expect(store.stored?.accessToken, 'new-a');
      expect(store.stored?.refreshToken, 'new-r');
      expect(store.stored?.role, UserRole.tenant);
      expect(store.stored?.emailVerified, isTrue);
      expect(controller().accessToken, 'new-a');
      expect(state(), signedIn(UserRole.tenant, emailVerified: true));
    });

    test('signs out and returns false when the API rejects it', () async {
      await start(storedSession());
      await controller().restore();
      refreshImpl = (token) => Future<AuthTokens>.error(
        const ApiFailure(code: 'REFRESH_TOKEN_INVALID', statusCode: 401),
      );

      final result = await controller().refresh();

      expect(result, isFalse);
      expect(state(), isA<SignedOut>());
      expect(store.stored, isNull);
      expect(controller().accessToken, isNull);
    });

    test('signs out and returns false on a network failure', () async {
      await start(storedSession());
      await controller().restore();
      refreshImpl = (token) =>
          Future<AuthTokens>.error(const ApiFailure.network());

      final result = await controller().refresh();

      expect(result, isFalse);
      expect(state(), isA<SignedOut>());
      expect(store.stored, isNull);
    });

    test('signs out and returns false on any other exception', () async {
      await start(storedSession());
      await controller().restore();
      refreshImpl = (token) => Future<AuthTokens>.error(StateError('boom'));

      final result = await controller().refresh();

      expect(result, isFalse);
      expect(state(), isA<SignedOut>());
      expect(store.stored, isNull);
    });

    test('shares one in-flight call between concurrent refreshes', () async {
      await start(storedSession());
      await controller().restore();
      final completer = Completer<AuthTokens>();
      refreshImpl = (token) => completer.future;

      final first = controller().refresh();
      final second = controller().refresh();
      await settle();
      completer.complete(authTokens(accessToken: 'new-a'));

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(refreshInputs, hasLength(1));
      expect(controller().accessToken, 'new-a');
    });

    test(
      'calls the API again for a refresh after the first finished',
      () async {
        await start(storedSession());
        await controller().restore();

        await controller().refresh();
        await controller().refresh();

        expect(refreshInputs, hasLength(2));
        expect(refreshInputs.last, 'refresh-2');
      },
    );
  });
}
