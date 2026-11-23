import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/ui/confirm_email_change_screen.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';
import 'link_screen_helpers.dart';

const _link = 'Tautan konfirmasi (wajib)';
const _failure = ApiFailure(code: 'EMAIL_CHANGE_NOT_FOUND', statusCode: 404);

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('confirm email change screen with a token', () {
    testWidgets('confirms the token at once, only once', (tester) async {
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(auth.emailChangeConfirmations, ['tok-1']);
    });

    testWidgets('shows a loading state while it confirms', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      addTearDown(() {
        if (!auth.confirmEmailChangeGate!.isCompleted) {
          auth.confirmEmailChangeGate!.complete();
        }
      });

      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
        settle: false,
      );

      expectInFlight();
      expect(find.text('Email diperbarui'), findsNothing);
    });

    testWidgets('shows the result without a paste step', (tester) async {
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
      );

      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(buttonLabelled('Masuk'), findsOneWidget);
      expect(field(_link), findsNothing);
      expect(buttonLabelled('Konfirmasi'), findsNothing);
    });

    testWidgets('a rejected token shows its message and the paste field', (
      tester,
    ) async {
      auth.confirmEmailChangeFailure = _failure;

      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
      );

      expect(
        find.text(messageOfCode('EMAIL_CHANGE_NOT_FOUND')),
        findsOneWidget,
      );
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Konfirmasi'), findsOneWidget);
      expect(find.text('Email diperbarui'), findsNothing);
      expect(auth.emailChangeConfirmations, ['tok-1']);
    });

    testWidgets('a network failure shows its message and lets the user retry '
        'by pasting the link', (tester) async {
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
      );

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(field(_link), findsOneWidget);

      auth.confirmEmailChangeFailure = null;
      await type(
        tester,
        _link,
        'https://niscala.example/email-change?token=tok-2',
      );
      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      expect(auth.emailChangeConfirmations, ['tok-1', 'tok-2']);
      expect(find.text('Email diperbarui'), findsOneWidget);
    });

    testWidgets('an empty token behaves like no token', (tester) async {
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: ''),
        auth: auth,
      );

      expect(field(_link), findsOneWidget);
      expect(auth.emailChangeConfirmations, isEmpty);
    });
  });

  group('confirm email change screen without a token', () {
    testWidgets('shows the paste step and confirms nothing', (tester) async {
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(),
        auth: auth,
      );

      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Konfirmasi'), findsOneWidget);
      expect(auth.emailChangeConfirmations, isEmpty);
    });
  });

  group('accessibility of the email change screen opened from a link', () {
    testWidgets('meets the guidelines while loading', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      addTearDown(() {
        if (!auth.confirmEmailChangeGate!.isCompleted) {
          auth.confirmEmailChangeGate!.complete();
        }
      });
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
        settle: false,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the result', (tester) async {
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error', (tester) async {
      auth.confirmEmailChangeFailure = _failure;
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('does not overflow at large text with an error', (
      tester,
    ) async {
      auth.confirmEmailChangeFailure = _failure;
      await pumpLinkScreen(
        tester,
        const ConfirmEmailChangeScreen(token: 'tok-1'),
        auth: auth,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
