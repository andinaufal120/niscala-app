import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/push/push_messaging.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import 'push_test_helpers.dart';

void main() {
  late FakeNotificationRepository repo;

  setUp(() {
    repo = FakeNotificationRepository(
      notifications: [pushedNotification('n1'), pushedNotification('n2')],
    );
  });

  Future<FakePushMessaging> pumpSignedIn(
    WidgetTester tester,
    UserRole role, {
    PushOpened? initial,
    bool emailVerified = true,
  }) async {
    final push = FakePushMessaging(initial: initial);
    await pumpPushApp(
      tester,
      push: push,
      repo: repo,
      store: InMemorySessionStore(
        storedSession(role: role, emailVerified: emailVerified),
      ),
    );
    return push;
  }

  group('a push opened while the app is in the background', () {
    testWidgets('opens the notification of a tenant', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);
      expect(currentPath(tester), '/penyewa/beranda');

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/penyewa/akun/notifikasi/n1');
    });

    testWidgets('opens the notification of an owner', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.owner);
      expect(currentPath(tester), '/beranda');

      push.open(
        const PushOpened(notificationId: 'n1', type: 'receiptUploaded'),
      );
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/akun/notifikasi/n1');
    });

    testWidgets('opens the notification of a manager', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.manager);

      push.open(
        const PushOpened(notificationId: 'n2', type: 'complaintSubmitted'),
      );
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/akun/notifikasi/n2');
    });

    testWidgets('marks the notification read when it opens', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);
      expect(repo.unreadCount, 2);

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('markRead:n1'));
      expect(repo.calls, isNot(contains('markRead:n2')));
      expect(repo.unreadCount, 1);
    });

    testWidgets('opens the notification whatever its type is', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.owner);

      push.open(
        const PushOpened(notificationId: 'n1', type: 'aTypeFromANewerApi'),
      );
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/akun/notifikasi/n1');
    });

    testWidgets('opens the notification of a later push too', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();
      push.open(const PushOpened(notificationId: 'n2', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/penyewa/akun/notifikasi/n2');
      expect(repo.calls, contains('markRead:n1'));
      expect(repo.calls, contains('markRead:n2'));
    });

    testWidgets('opens it from another screen than the home screen', (
      tester,
    ) async {
      final push = await pumpSignedIn(tester, UserRole.owner);
      goTo(tester, '/properti');
      await tester.pumpAndSettle();

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/akun/notifikasi/n1');
    });

    testWidgets('lets the user go back from the opened notification', (
      tester,
    ) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);
      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(tester.takeException(), isNull);
      expect(pushedPath(tester), isNot('/penyewa/akun/notifikasi/n1'));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('shows a notification that meets the accessibility '
        'guidelines', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('does nothing for a push without a notification id', (
      tester,
    ) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);

      push.open(const PushOpened(type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does nothing for a push with an empty notification id', (
      tester,
    ) async {
      final push = await pumpSignedIn(tester, UserRole.owner);

      push.open(const PushOpened(notificationId: '', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/beranda');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does nothing for a push with no data at all', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.owner);

      push.open(const PushOpened());
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/beranda');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does nothing for message data with entries that are not '
        'strings', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);

      push.open(PushOpened.fromData({'notificationId': 7, 'type': true}));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens a notification after an ignored push', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);

      push.open(const PushOpened());
      await tester.pumpAndSettle();
      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/penyewa/akun/notifikasi/n1');
    });
  });

  group('a push opened without a session to show it to', () {
    testWidgets('while signed out shows nothing', (tester) async {
      final push = FakePushMessaging(currentToken: 'token-1');
      await pumpPushApp(tester, push: push, repo: repo);
      expect(currentPath(tester), '/masuk');

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/masuk');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('while signed out is dropped, so a later sign in lands on the '
        'home screen', (tester) async {
      final push = FakePushMessaging();
      await pumpPushApp(tester, push: push, repo: repo);
      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      await signInAs(tester, UserRole.tenant);

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('while the session is loading is dropped, so a later sign in '
        'lands on the home screen', (tester) async {
      final push = FakePushMessaging();
      await pumpPushApp(
        tester,
        push: push,
        repo: repo,
        store: NeverReadySessionStore(),
        settle: false,
      );
      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(currentPath(tester), '/memuat');

      await signInAs(tester, UserRole.owner);

      expect(pushedPath(tester), '/beranda');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('after the user signed out shows nothing to the next user', (
      tester,
    ) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);
      await signOutNow(tester);

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();
      await signInAs(tester, UserRole.owner);

      expect(pushedPath(tester), '/beranda');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('of an admin is ignored', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.admin);
      expect(currentPath(tester), '/admin');

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('of a user whose email is not verified is ignored', (
      tester,
    ) async {
      final push = await pumpSignedIn(
        tester,
        UserRole.tenant,
        emailVerified: false,
      );
      expect(currentPath(tester), '/verifikasi-email');

      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/verifikasi-email');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('of a user whose email is not verified is dropped, so '
        'verifying lands on the home screen', (tester) async {
      final push = await pumpSignedIn(
        tester,
        UserRole.tenant,
        emailVerified: false,
      );
      push.open(const PushOpened(notificationId: 'n1', type: 'billIssued'));
      await tester.pumpAndSettle();

      await verifyEmailNow(tester);

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
    });
  });

  group('the push that started the app', () {
    testWidgets('opens the notification of a tenant once the session is '
        'restored', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.tenant,
        initial: const PushOpened(notificationId: 'n1', type: 'billIssued'),
      );

      expect(pushedPath(tester), '/penyewa/akun/notifikasi/n1');
      expect(repo.calls, contains('markRead:n1'));
      expect(repo.unreadCount, 1);
    });

    testWidgets('opens the notification of an owner', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.owner,
        initial: const PushOpened(
          notificationId: 'n2',
          type: 'receiptUploaded',
        ),
      );

      expect(pushedPath(tester), '/akun/notifikasi/n2');
      expect(repo.calls, contains('markRead:n2'));
    });

    testWidgets('opens the notification of a manager', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.manager,
        initial: const PushOpened(notificationId: 'n1', type: 'billIssued'),
      );

      expect(pushedPath(tester), '/akun/notifikasi/n1');
    });

    testWidgets('is opened once only', (tester) async {
      final push = await pumpSignedIn(
        tester,
        UserRole.tenant,
        initial: const PushOpened(notificationId: 'n1', type: 'billIssued'),
      );
      expect(pushedPath(tester), '/penyewa/akun/notifikasi/n1');

      await signOutNow(tester);
      await signInAs(tester, UserRole.owner);

      expect(push.initialOpenedReads, lessThanOrEqualTo(1));
      expect(pushedPath(tester), '/beranda');
    });

    testWidgets('is ignored without a notification id', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.tenant,
        initial: const PushOpened(type: 'billIssued'),
      );

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is ignored for an admin', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.admin,
        initial: const PushOpened(notificationId: 'n1', type: 'billIssued'),
      );

      expect(currentPath(tester), '/admin');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('is ignored while the email is not verified', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.owner,
        emailVerified: false,
        initial: const PushOpened(notificationId: 'n1', type: 'billIssued'),
      );

      expect(currentPath(tester), '/verifikasi-email');

      await verifyEmailNow(tester);

      expect(pushedPath(tester), '/beranda');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('is ignored when no one is signed in, also after a later '
        'sign in', (tester) async {
      final push = FakePushMessaging(
        initial: const PushOpened(notificationId: 'n1', type: 'billIssued'),
      );
      await pumpPushApp(tester, push: push, repo: repo);
      expect(currentPath(tester), '/masuk');

      await signInAs(tester, UserRole.tenant);

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('does not open anything when the app was not started by a '
        'push', (tester) async {
      await pumpSignedIn(tester, UserRole.tenant);

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
    });
  });

  group('a message that arrives while the app is open', () {
    testWidgets('refreshes the notification list that is shown', (
      tester,
    ) async {
      final push = await pumpSignedIn(tester, UserRole.owner);
      goTo(tester, '/akun/notifikasi');
      await tester.pumpAndSettle();
      final before = repo.listCalls;
      expect(before, greaterThan(0));
      expect(unreadDots(), findsNWidgets(2));

      repo.add(pushedNotification('n3'));
      push.receiveForeground();
      await tester.pumpAndSettle();

      expect(repo.listCalls, before + 1);
      expect(unreadDots(), findsNWidgets(3));
    });

    testWidgets('does not navigate', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.owner);
      goTo(tester, '/akun/notifikasi');
      await tester.pumpAndSettle();

      push.receiveForeground();
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/akun/notifikasi');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('does not navigate from another screen', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);

      push.receiveForeground();
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/penyewa/beranda');
      expect(repo.markReadCalls, 0);
    });

    testWidgets('lets the list show the new notification when it opens '
        'later', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);
      goTo(tester, '/penyewa/akun/notifikasi');
      await tester.pumpAndSettle();
      expect(unreadDots(), findsNWidgets(2));
      goTo(tester, '/penyewa/beranda');
      await tester.pumpAndSettle();

      repo.add(pushedNotification('n3'));
      push.receiveForeground();
      await tester.pumpAndSettle();
      goTo(tester, '/penyewa/akun/notifikasi');
      await tester.pumpAndSettle();

      expect(unreadDots(), findsNWidgets(3));
    });

    testWidgets('refreshes the list at every message', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.owner);
      goTo(tester, '/akun/notifikasi');
      await tester.pumpAndSettle();
      final before = repo.listCalls;

      push.receiveForeground();
      await tester.pumpAndSettle();
      push.receiveForeground();
      await tester.pumpAndSettle();

      expect(repo.listCalls, before + 2);
    });

    testWidgets('is ignored while signed out', (tester) async {
      final push = FakePushMessaging();
      await pumpPushApp(tester, push: push, repo: repo);

      push.receiveForeground();
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/masuk');
      expect(repo.listCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows no error when the refresh fails', (tester) async {
      final push = await pumpSignedIn(tester, UserRole.tenant);
      repo.listScript.always = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );

      push.receiveForeground();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(pushedPath(tester), '/penyewa/beranda');
    });
  });
}
