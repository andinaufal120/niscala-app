import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/push/push_messaging.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
import 'package:niscala_api/api.dart';

/// Whether [session] may receive pushes: a signed-in user with a verified email
/// who is not an Admin.
bool _receivesPush(SessionState session) => switch (session) {
  SignedIn(:final role, :final emailVerified) =>
    emailVerified && role != UserRole.admin,
  _ => false,
};

/// Connects the push messages to the app. The app watches it for its whole run.
///
/// * The permission is requested once per app run, when a session may first
///   receive pushes. The token of the device is registered once per session,
///   and again for each new token. A failed registration is retried only at the
///   next token refresh or the next session.
/// * A push that the user opens, or the push that started the app, opens its
///   notification. A push that arrives while no session may receive pushes is
///   dropped and never applied later.
/// * A push that arrives while the app is open refreshes the notification list.
final pushCoordinatorProvider = Provider<void>((ref) {
  final push = ref.watch(pushMessagingProvider);
  final initial = push.initialOpened();
  final registered = <String>{};
  Future<bool>? permission;
  var generation = 0;
  var startupHandled = false;

  bool receives() => _receivesPush(ref.read(sessionControllerProvider));

  void open(PushOpened opened) {
    final id = opened.notificationId;
    if (!receives() || id == null || id.isEmpty) return;
    final base = accountTabPath(ref.read(currentRoleProvider));
    // push keeps the page that was open below the notification, so Kembali
    // returns to it.
    ref
        .read(routerProvider)
        .push('$base/notifikasi/${Uri.encodeComponent(id)}');
  }

  /// Registers [refreshed], or the token of the device when it is null. It
  /// stops at every step where the session has ended or changed.
  Future<void> registerToken({String? refreshed}) async {
    if (!receives()) return;
    final current = generation;
    bool stillCurrent() => current == generation && receives();
    final granted = await (permission ??= push.requestPermission());
    if (!granted || !stillCurrent()) return;
    final token = refreshed ?? await push.token();
    if (token == null || registered.contains(token) || !stillCurrent()) return;
    try {
      await ref.read(notificationRepositoryProvider).registerPushToken(token);
    } on ApiFailure {
      // Silent on purpose: the next token refresh or the next session tries
      // again.
    }
    if (current == generation) registered.add(token);
  }

  final tokenSub = push.onTokenRefresh.listen((token) {
    unawaited(registerToken(refreshed: token));
  });
  final foregroundSub = push.onForegroundMessage.listen((_) {
    if (receives()) ref.invalidate(notificationListProvider);
  });
  final openSub = push.onOpened.listen(open);
  ref.onDispose(tokenSub.cancel);
  ref.onDispose(foregroundSub.cancel);
  ref.onDispose(openSub.cancel);

  ref.listen(sessionControllerProvider, (previous, next) {
    if (next is SessionLoading) return;
    if (!startupHandled) {
      // The first state that is not loading decides the push that started the
      // app, and that push is never read again.
      startupHandled = true;
      if (_receivesPush(next)) {
        unawaited(
          initial.then((opened) {
            if (opened != null) open(opened);
          }),
        );
      }
    }
    if (next is SignedIn && previous is! SignedIn) {
      generation++;
      registered.clear();
    }
    if (_receivesPush(next) && (previous == null || !_receivesPush(previous))) {
      unawaited(registerToken());
    }
  }, fireImmediately: true);
});
