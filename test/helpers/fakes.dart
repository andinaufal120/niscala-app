import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/app.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala_api/api.dart';

/// A [SessionStore] that keeps the session in memory.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this.stored]);

  StoredSession? stored;

  @override
  Future<StoredSession?> read() async => stored;

  @override
  Future<void> write(StoredSession session) async => stored = session;

  @override
  Future<void> clear() async => stored = null;
}

/// A [SessionStore] whose [read] never completes, to hold the app in its
/// loading state.
class NeverReadySessionStore implements SessionStore {
  @override
  Future<StoredSession?> read() => Completer<StoredSession?>().future;

  @override
  Future<void> write(StoredSession session) async {}

  @override
  Future<void> clear() async {}
}

StoredSession storedSession({
  UserRole role = UserRole.owner,
  bool emailVerified = true,
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) => StoredSession(
  accessToken: accessToken,
  refreshToken: refreshToken,
  role: role,
  emailVerified: emailVerified,
);

AuthSession authSessionFor(
  UserRole role, {
  bool emailVerified = true,
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
}) => AuthSession(
  accessToken: accessToken,
  refreshToken: refreshToken,
  expiresIn: 900,
  tokenType: AuthSessionTokenTypeEnum.bearer,
  account: Account(
    email: 'budi@example.com',
    emailVerified: emailVerified,
    googleEmail: null,
    hasPassword: true,
    id: 'account-1',
    name: 'Budi',
    role: role,
  ),
);

AuthTokens authTokens({
  String accessToken = 'access-2',
  String refreshToken = 'refresh-2',
}) => AuthTokens(
  accessToken: accessToken,
  refreshToken: refreshToken,
  expiresIn: 900,
  tokenType: AuthTokensTokenTypeEnum.bearer,
);

/// A refresh function that always fails, for tests that must not refresh.
Future<AuthTokens> failingRefresh(String refreshToken) =>
    Future<AuthTokens>.error(Exception('refresh must not be called'));

/// An [AuthRepository] that records its calls and answers from fields.
///
/// Set a `*Failure` field to make that method throw. Set [gate] to hold every
/// call of login, register, send and confirm in flight until it completes, and
/// [accountGate] to do the same for [getMyAccount].
class FakeAuthRepository implements AuthRepository {
  final logins = <({String email, String password})>[];
  final registrations = <({String name, String email, String password})>[];
  final confirmations = <String>[];
  var accountLoads = 0;
  var verificationRequests = 0;

  AuthSession loginResult = authSessionFor(UserRole.owner);
  AuthSession registerResult = authSessionFor(
    UserRole.owner,
    emailVerified: false,
  );
  Account accountResult = authSessionFor(
    UserRole.owner,
    emailVerified: false,
  ).account;
  DateTime resendAvailableAt = DateTime.utc(2026, 10, 18, 12);
  Account confirmResult = authSessionFor(UserRole.owner).account;

  ApiFailure? loginFailure;
  ApiFailure? registerFailure;
  ApiFailure? accountFailure;
  ApiFailure? sendFailure;
  ApiFailure? confirmFailure;

  Completer<void>? gate;
  Completer<void>? accountGate;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    logins.add((email: email, password: password));
    await gate?.future;
    if (loginFailure != null) throw loginFailure!;
    return loginResult;
  }

  @override
  Future<AuthSession> registerOwner({
    required String name,
    required String email,
    required String password,
  }) async {
    registrations.add((name: name, email: email, password: password));
    await gate?.future;
    if (registerFailure != null) throw registerFailure!;
    return registerResult;
  }

  @override
  Future<Account> getMyAccount() async {
    accountLoads++;
    await accountGate?.future;
    if (accountFailure != null) throw accountFailure!;
    return accountResult;
  }

  @override
  Future<DateTime> sendEmailVerification() async {
    verificationRequests++;
    await gate?.future;
    if (sendFailure != null) throw sendFailure!;
    return resendAvailableAt;
  }

  @override
  Future<Account> confirmEmail(String code) async {
    confirmations.add(code);
    await gate?.future;
    if (confirmFailure != null) throw confirmFailure!;
    return confirmResult;
  }
}

/// The whole app with a fake session store and no network.
Widget buildTestApp({
  SessionStore? store,
  Future<AuthTokens> Function(String refreshToken)? refresh,
  Future<void> Function()? logout,
  AuthRepository? auth,
}) {
  return ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(store ?? InMemorySessionStore()),
      refreshTokensProvider.overrideWithValue(refresh ?? failingRefresh),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      if (logout != null) logoutProvider.overrideWithValue(logout),
    ],
    child: const NiscalaApp(),
  );
}

/// Matches any Material button (the base type is abstract, so `byType` cannot).
Finder anyButton() =>
    find.byWidgetPredicate((widget) => widget is ButtonStyleButton);

/// Wraps [child] in a themed [MaterialApp] without any provider.
Widget themedApp(Widget child) => MaterialApp(theme: buildTheme(), home: child);
