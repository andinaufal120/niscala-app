import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemorySessionStore store;
  late Future<AuthTokens> Function(String) refreshImpl;
  late ProviderContainer container;

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);
  int generation() => container.read(sessionGenerationProvider);

  ProviderContainer newContainer([StoredSession? initial]) {
    store = InMemorySessionStore(initial);
    refreshImpl = (token) async => authTokens();
    final created = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        refreshTokensProvider.overrideWithValue((token) => refreshImpl(token)),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  /// Creates the container and restores [initial] as the stored session.
  Future<void> start([StoredSession? initial]) async {
    container = newContainer(initial);
    await controller().restore();
  }

  test('starts at the same value in every container', () {
    final first = newContainer().read(sessionGenerationProvider);
    final second = newContainer().read(sessionGenerationProvider);

    expect(first, second);
  });

  test('stays put while the stored session is restored', () async {
    container = newContainer(storedSession());
    final before = generation();

    await controller().restore();

    expect(generation(), before);
  });

  test('stays put when nothing is stored on restore', () async {
    container = newContainer();
    final before = generation();

    await controller().restore();

    expect(generation(), before);
  });

  test('rises when a user signs in', () async {
    await start();
    final before = generation();

    await controller().signIn(authSessionFor(UserRole.owner));

    expect(generation(), greaterThan(before));
  });

  test('stays put when a user signs out', () async {
    await start(storedSession());
    final before = generation();

    await controller().signOut();

    expect(generation(), before);
  });

  test('does not notify a listener when a user signs out', () async {
    await start(storedSession());
    var notified = 0;
    container.listen<int>(sessionGenerationProvider, (previous, next) {
      notified++;
    });

    await controller().signOut();

    expect(notified, 0);
  });

  test('rises again when a user signs in after signing out', () async {
    await start();
    await controller().signIn(authSessionFor(UserRole.owner));
    await controller().signOut();
    final afterSignOut = generation();

    await controller().signIn(authSessionFor(UserRole.tenant));

    expect(generation(), greaterThan(afterSignOut));
  });

  test('rises on every sign in, also of the same user', () async {
    await start();
    final seen = <int>[generation()];

    for (var i = 0; i < 3; i++) {
      await controller().signIn(authSessionFor(UserRole.owner));
      seen.add(generation());
      await controller().signOut();
      expect(generation(), seen.last);
    }

    expect(seen.toSet(), hasLength(seen.length));
    expect(seen, orderedEquals([...seen]..sort()));
  });

  test('stays put when the session expires', () async {
    await start(storedSession());
    final before = generation();

    controller().expire();
    await Future<void>.delayed(Duration.zero);

    expect(generation(), before);
  });

  test('notifies a listener on sign in only', () async {
    await start();
    final seen = <int>[];
    container.listen<int>(
      sessionGenerationProvider,
      (previous, next) => seen.add(next),
    );

    await controller().signIn(authSessionFor(UserRole.owner));
    await controller().signOut();
    await controller().signIn(authSessionFor(UserRole.tenant));

    expect(seen, hasLength(2));
    expect(seen.first, lessThan(seen.last));
  });

  test('is raised and the tokens are stored before the signed in state is '
      'published', () async {
    await start();
    final before = generation();
    final seenWhenPublished = <({int generation, String? token})>[];
    container.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next is SignedIn) {
        seenWhenPublished.add((
          generation: generation(),
          token: controller().accessToken,
        ));
      }
    });

    await controller().signIn(authSessionFor(UserRole.owner, accessToken: 'a'));

    expect(seenWhenPublished, hasLength(1));
    expect(seenWhenPublished.single.generation, greaterThan(before));
    expect(seenWhenPublished.single.token, 'a');
  });

  group('refresh', () {
    test('stays put when it succeeds', () async {
      await start(storedSession());
      final before = generation();

      final result = await controller().refresh();

      expect(result, isTrue);
      expect(generation(), before);
    });

    test('does not notify a listener when it succeeds', () async {
      await start(storedSession());
      var notified = 0;
      container.listen(sessionGenerationProvider, (previous, next) {
        notified++;
      });

      await controller().refresh();

      expect(notified, 0);
    });

    test('stays put when it fails and ends the session', () async {
      await start(storedSession());
      final before = generation();
      refreshImpl = (token) => Future<AuthTokens>.error(
        const ApiFailure(code: 'REFRESH_TOKEN_INVALID', statusCode: 401),
      );

      final result = await controller().refresh();

      expect(result, isFalse);
      expect(generation(), before);
    });
  });

  group('markEmailVerified', () {
    test('stays put', () async {
      await start(storedSession(emailVerified: false));
      final before = generation();

      await controller().markEmailVerified();

      expect(generation(), before);
    });

    test('does not notify a listener', () async {
      await start(storedSession(emailVerified: false));
      var notified = 0;
      container.listen(sessionGenerationProvider, (previous, next) {
        notified++;
      });

      await controller().markEmailVerified();

      expect(notified, 0);
    });
  });
}
