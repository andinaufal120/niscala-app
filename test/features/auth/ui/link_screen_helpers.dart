import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';

/// Shows [screen] as the only route of a router, with the given fakes behind
/// it, the way the router builds a screen for a link.
///
/// With [settle] false only two frames are pumped, so a held gate keeps the
/// screen in its loading state (a progress indicator never settles).
Future<void> pumpLinkScreen(
  WidgetTester tester,
  Widget screen, {
  FakeInvitationRepository? invitations,
  FakeAuthRepository? auth,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = ProviderScope(
    overrides: [
      sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      invitationRepositoryProvider.overrideWithValue(
        invitations ?? FakeInvitationRepository(),
      ),
    ],
    child: MaterialApp.router(
      theme: buildTheme(),
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (context, state) => screen)],
      ),
    ),
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Expects a progress indicator on screen.
void expectInFlight() {
  expect(find.byType(CircularProgressIndicator), findsWidgets);
}
