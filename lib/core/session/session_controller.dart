import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/auth_http_client.dart';
import 'package:niscala/core/api/http_providers.dart';
import 'package:niscala/core/session/secure_session_store.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala_api/api.dart';

sealed class SessionState {
  const SessionState();
}

/// The stored session has not been read yet.
class SessionLoading extends SessionState {
  const SessionLoading();
}

class SignedOut extends SessionState {
  const SignedOut();
}

class SignedIn extends SessionState {
  const SignedIn({required this.role, required this.emailVerified});

  final UserRole role;
  final bool emailVerified;
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => const SecureSessionStore(),
);

/// Exchanges a refresh token for a new token pair. It uses a client without
/// authentication, so a failing refresh cannot trigger another refresh.
final refreshTokensProvider = Provider<Future<AuthTokens> Function(String)>((
  ref,
) {
  final api = AuthApi(
    ApiClient(basePath: ref.watch(apiBaseUrlProvider))
      ..client = ref.watch(httpClientProvider),
  );
  return (refreshToken) async {
    try {
      final tokens = await api.refreshTokens(
        RefreshInput(refreshToken: refreshToken),
      );
      return tokens!;
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  };
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// The role of the signed-in user, or null when no one is signed in.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return switch (ref.watch(sessionControllerProvider)) {
    SignedIn(:final role) => role,
    _ => null,
  };
});

class SessionController extends Notifier<SessionState> implements TokenSource {
  StoredSession? _session;
  Future<bool>? _refreshing;

  @override
  SessionState build() => const SessionLoading();

  SessionStore get _store => ref.read(sessionStoreProvider);

  @override
  String? get accessToken => _session?.accessToken;

  Future<void> restore() async {
    _session = await _store.read();
    state = _stateFor(_session);
  }

  Future<void> signIn(AuthSession session) async {
    final stored = StoredSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: session.account.role,
      emailVerified: session.account.emailVerified,
    );
    await _store.write(stored);
    _session = stored;
    state = _stateFor(stored);
  }

  Future<void> markEmailVerified() async {
    final stored = _session?.copyWith(emailVerified: true);
    if (stored == null) return;
    await _store.write(stored);
    _session = stored;
    state = _stateFor(stored);
  }

  Future<void> signOut() async {
    _session = null;
    state = const SignedOut();
    await _store.clear();
  }

  @override
  void expire() => unawaited(signOut());

  /// Gets a new token pair. Concurrent calls share one request. Any failure
  /// ends the session.
  @override
  Future<bool> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final current = _session;
    if (current == null) return false;
    try {
      final tokens = await ref.read(refreshTokensProvider)(
        current.refreshToken,
      );
      final stored = current.copyWith(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await _store.write(stored);
      _session = stored;
      return true;
    } on Object {
      await signOut();
      return false;
    }
  }

  SessionState _stateFor(StoredSession? session) => session == null
      ? const SignedOut()
      : SignedIn(role: session.role, emailVerified: session.emailVerified);
}
