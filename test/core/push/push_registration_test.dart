import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import 'push_test_helpers.dart';

void main() {
  late FakePushMessaging push;
  late FakeNotificationRepository repo;

  setUp(() {
    push = FakePushMessaging(currentToken: 'token-1');
    repo = FakeNotificationRepository();
  });

  group('when a session starts', () {
    for (final role in [UserRole.owner, UserRole.manager, UserRole.tenant]) {
      testWidgets(
        'registers the token of a restored ${role.value} session once',
        (tester) async {
          await pumpPushApp(
            tester,
            push: push,
            repo: repo,
            store: InMemorySessionStore(storedSession(role: role)),
          );

          expect(push.permissionRequests, 1);
          expect(push.tokenReads, 1);
          expect(repo.registeredTokens, ['token-1']);
        },
      );

      testWidgets('registers the token when a ${role.value} signs in', (
        tester,
      ) async {
        await pumpPushApp(tester, push: push, repo: repo);
        expect(repo.registeredTokens, isEmpty);

        await signInAs(tester, role);

        expect(push.permissionRequests, 1);
        expect(push.tokenReads, 1);
        expect(repo.registeredTokens, ['token-1']);
      });
    }

    testWidgets('reads no token and registers nothing when the permission is '
        'denied', (tester) async {
      push.permissionGranted = false;

      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      expect(push.permissionRequests, 1);
      expect(push.tokenReads, 0);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('registers nothing when the device has no token', (
      tester,
    ) async {
      push.currentToken = null;

      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      expect(push.permissionRequests, 1);
      expect(push.tokenReads, 1);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('does not ask for the permission again when the app '
        'rebuilds or the user moves between screens', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      goTo(tester, '/properti');
      await tester.pumpAndSettle();
      goTo(tester, '/akun');
      await tester.pumpAndSettle();
      goTo(tester, '/beranda');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5));

      expect(push.permissionRequests, 1);
      expect(push.tokenReads, 1);
      expect(repo.registeredTokens, ['token-1']);
    });

    testWidgets('does not register again when a verified session is marked '
        'verified again', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      await verifyEmailNow(tester);

      expect(repo.registeredTokens, ['token-1']);
    });
  });

  group('sessions that register nothing', () {
    testWidgets('an admin session asks for no permission and registers '
        'nothing', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(role: UserRole.admin)),
      );

      expect(push.permissionRequests, 0);
      expect(push.tokenReads, 0);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('an admin who signs in registers nothing', (tester) async {
      await pumpPushApp(tester, push: push, repo: repo);

      await signInAs(tester, UserRole.admin);

      expect(push.permissionRequests, 0);
      expect(push.tokenReads, 0);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('a token refresh of an admin session registers nothing', (
      tester,
    ) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(role: UserRole.admin)),
      );

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('a signed out app asks for no permission and registers '
        'nothing', (tester) async {
      await pumpPushApp(tester, push: push, repo: repo);

      expect(push.permissionRequests, 0);
      expect(push.tokenReads, 0);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('a token refresh while signed out registers nothing', (
      tester,
    ) async {
      await pumpPushApp(tester, push: push, repo: repo);

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('an app that is still restoring the session asks for no '
        'permission and registers nothing', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: NeverReadySessionStore(),
        settle: false,
      );

      expect(currentPath(tester), '/memuat');
      expect(push.permissionRequests, 0);
      expect(push.tokenReads, 0);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('an email that is not verified yet asks for no permission '
        'and registers nothing', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(emailVerified: false)),
      );

      expect(currentPath(tester), '/verifikasi-email');
      expect(push.permissionRequests, 0);
      expect(push.tokenReads, 0);
      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('a token refresh while the email is not verified registers '
        'nothing', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(emailVerified: false)),
      );

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, isEmpty);
    });

    testWidgets('registers once the email gets verified', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(emailVerified: false)),
      );

      await verifyEmailNow(tester);

      expect(push.permissionRequests, 1);
      expect(repo.registeredTokens, ['token-1']);
    });

    testWidgets('registers when a user signs in with a verified email after '
        'an unverified one signed out', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(emailVerified: false)),
      );

      await signOutNow(tester);
      await signInAs(tester, UserRole.tenant);

      expect(repo.registeredTokens, ['token-1']);
    });
  });

  group('token refresh', () {
    testWidgets('registers the new token', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-1', 'token-2']);
    });

    testWidgets('registers each new token once', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
      );

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();
      push.refreshTokenTo('token-3');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-1', 'token-2', 'token-3']);
    });

    testWidgets('does not register a token again that the session registered '
        'already', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      push.refreshTokenTo('token-1');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-1']);
    });

    testWidgets('registers the first token that arrives when the device had '
        'none at start', (tester) async {
      push.currentToken = null;
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-2']);
    });

    testWidgets('registers nothing after the user signed out', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );
      await signOutNow(tester);

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-1']);
    });
  });

  group('another session', () {
    testWidgets('registers again when another user signs in after a sign '
        'out', (tester) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(role: UserRole.owner)),
      );
      expect(repo.registeredTokens, ['token-1']);

      await signOutNow(tester);
      expect(repo.registeredTokens, ['token-1']);

      await signInAs(tester, UserRole.tenant);

      expect(repo.registeredTokens, ['token-1', 'token-1']);
    });

    testWidgets('registers once for each session, however long it lasts', (
      tester,
    ) async {
      await pumpPushApp(tester, push: push, repo: repo);

      await signInAs(tester, UserRole.manager);
      await tester.pump(const Duration(minutes: 5));
      await signOutNow(tester);
      await signInAs(tester, UserRole.owner);
      await tester.pump(const Duration(minutes: 5));

      expect(repo.registeredTokens, ['token-1', 'token-1']);
    });

    testWidgets('registers the current token for the next session', (
      tester,
    ) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );
      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();
      await signOutNow(tester);

      await signInAs(tester, UserRole.tenant);

      expect(repo.registeredTokens, ['token-1', 'token-2', 'token-2']);
    });

    testWidgets('does not register when the next user is an admin', (
      tester,
    ) async {
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );
      await signOutNow(tester);

      await signInAs(tester, UserRole.admin);

      expect(repo.registeredTokens, ['token-1']);
    });
  });

  group('a failing registration', () {
    testWidgets('shows nothing and leaves the app working', (tester) async {
      repo.registerPushTokenScript.always = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );

      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      expect(repo.registeredTokens, ['token-1']);
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(MaterialBanner), findsNothing);
      expect(currentPath(tester), '/beranda');

      goTo(tester, '/akun');
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/akun');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows nothing when the network is down', (tester) async {
      repo.registerPushTokenScript.always = const ApiFailure(
        code: 'NETWORK_ERROR',
      );

      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('is not retried in a loop', (tester) async {
      repo.registerPushTokenScript.always = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );

      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );
      await tester.pump(const Duration(minutes: 30));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(hours: 2));

      expect(repo.registerPushTokenCalls, 1);
    });

    testWidgets('is retried when the token refreshes', (tester) async {
      repo.registerPushTokenScript.queue.add(
        const ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500),
      );
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );
      expect(repo.registeredTokens, ['token-1']);

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-1', 'token-2']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('is retried when the next session starts', (tester) async {
      repo.registerPushTokenScript.queue.add(
        const ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500),
      );
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );
      expect(repo.registeredTokens, ['token-1']);

      await signOutNow(tester);
      await signInAs(tester, UserRole.owner);

      expect(repo.registeredTokens, ['token-1', 'token-1']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not stop later refreshes from registering', (
      tester,
    ) async {
      repo.registerPushTokenScript.queue
        ..add(const ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500))
        ..add(const ApiFailure(code: 'NETWORK_ERROR'));
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: InMemorySessionStore(storedSession()),
      );

      push.refreshTokenTo('token-2');
      await tester.pumpAndSettle();
      push.refreshTokenTo('token-3');
      await tester.pumpAndSettle();

      expect(repo.registeredTokens, ['token-1', 'token-2', 'token-3']);
      expect(tester.takeException(), isNull);
    });
  });

  group('screens', () {
    Future<List<String>> akunTexts(
      WidgetTester tester,
      UserRole role, {
      required String? token,
      ApiFailure? failure,
    }) async {
      final fakePush = FakePushMessaging(currentToken: token);
      final fakeRepo = FakeNotificationRepository();
      if (failure != null) fakeRepo.registerPushTokenScript.always = failure;
      await pumpPushApp(
        tester,
        push: fakePush,
        repo: fakeRepo,
        store: InMemorySessionStore(storedSession(role: role)),
      );
      goTo(tester, role == UserRole.tenant ? '/penyewa/akun' : '/akun');
      await tester.pumpAndSettle();
      final texts = shownTexts(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      return texts;
    }

    for (final role in [UserRole.owner, UserRole.tenant]) {
      testWidgets('the Akun screen of a ${role.value} shows the same texts '
          'with and without a registered token', (tester) async {
        final without = await akunTexts(tester, role, token: null);
        final registered = await akunTexts(tester, role, token: 'token-1');

        expect(without, isNotEmpty);
        expect(registered, without);
      });

      testWidgets('the Akun screen of a ${role.value} shows the same texts '
          'when the registration failed', (tester) async {
        final without = await akunTexts(tester, role, token: null);
        final failed = await akunTexts(
          tester,
          role,
          token: 'token-1',
          failure: const ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500),
        );

        expect(failed, without);
      });

      testWidgets('the Akun screen of a ${role.value} meets the accessibility '
          'guidelines after the registration', (tester) async {
        await pumpPushApp(
          tester,
          push: push,
          repo: repo,
          store: InMemorySessionStore(storedSession(role: role)),
        );
        goTo(tester, role == UserRole.tenant ? '/penyewa/akun' : '/akun');
        await tester.pumpAndSettle();

        expect(repo.registeredTokens, ['token-1']);
        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('the Akun screen of a ${role.value} meets the accessibility '
          'guidelines after a failed registration', (tester) async {
        repo.registerPushTokenScript.always = const ApiFailure(
          code: 'INTERNAL_ERROR',
          statusCode: 500,
        );
        await pumpPushApp(
          tester,
          push: push,
          repo: repo,
          store: InMemorySessionStore(storedSession(role: role)),
        );
        goTo(tester, role == UserRole.tenant ? '/penyewa/akun' : '/akun');
        await tester.pumpAndSettle();

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('the Akun screen of a ${role.value} fits at large text after '
          'the registration', (tester) async {
        await pumpAtLargeText(
          tester,
          buildTestApp(
            store: InMemorySessionStore(storedSession(role: role)),
            notifications: repo,
            push: push,
          ),
        );
        await tester.pumpAndSettle();
        goTo(tester, role == UserRole.tenant ? '/penyewa/akun' : '/akun');
        await tester.pumpAndSettle();

        expect(repo.registeredTokens, ['token-1']);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
