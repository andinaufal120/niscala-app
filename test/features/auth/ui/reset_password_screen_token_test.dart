import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/ui/reset_password_screen.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';
import 'link_screen_helpers.dart';

const _link = 'Tautan atur ulang (wajib)';
const _password = 'Kata sandi baru (wajib)';
const _confirm = 'Konfirmasi kata sandi baru (wajib)';

const _linkCodes = [
  'PASSWORD_RESET_NOT_FOUND',
  'PASSWORD_RESET_USED',
  'PASSWORD_RESET_EXPIRED',
];

ApiFailure _failureOf(String code) =>
    ApiFailure(code: code, statusCode: code.endsWith('NOT_FOUND') ? 404 : 409);

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('reset password screen with a token', () {
    testWidgets('checks the token at once, only once', (tester) async {
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(auth.passwordResetPreviews, ['tok-1']);
    });

    testWidgets('shows a loading state while the token is checked', (
      tester,
    ) async {
      auth.previewPasswordResetGate = Completer<void>();
      addTearDown(() {
        if (!auth.previewPasswordResetGate!.isCompleted) {
          auth.previewPasswordResetGate!.complete();
        }
      });

      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
        settle: false,
      );

      expect(auth.passwordResetPreviews, ['tok-1']);
      expectInFlight();
      expect(field(_password), findsNothing);
    });

    testWidgets('goes straight to the new password form without a paste step', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
      );

      expect(find.text('Untuk akun budi@example.com'), findsOneWidget);
      expect(field(_password), findsOneWidget);
      expect(field(_confirm), findsOneWidget);
      expect(field(_link), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
    });

    testWidgets('saves the new password with the token of the link', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
      );

      await type(tester, _password, 'kopi tubruk pagi');
      await type(tester, _confirm, 'kopi tubruk pagi');
      await tapVisible(tester, buttonLabelled('Simpan Kata Sandi'));

      expect(auth.passwordResets, [
        (token: 'tok-1', newPassword: 'kopi tubruk pagi'),
      ]);
      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
    });

    for (final code in _linkCodes) {
      testWidgets('$code shows its message, the paste field and a new link '
          'button', (tester) async {
        auth.previewPasswordResetFailure = _failureOf(code);

        await pumpLinkScreen(
          tester,
          const ResetPasswordScreen(token: 'tok-1'),
          auth: auth,
        );

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(field(_link), findsOneWidget);
        expect(buttonLabelled('Lanjut'), findsOneWidget);
        expect(buttonLabelled('Minta Tautan Baru'), findsOneWidget);
        expect(field(_password), findsNothing);
      });
    }

    testWidgets('a network failure shows its message and lets the user retry '
        'by pasting the link', (tester) async {
      auth.previewPasswordResetFailure = const ApiFailure.network();
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
      );

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Minta Tautan Baru'), findsNothing);

      auth.previewPasswordResetFailure = null;
      await type(
        tester,
        _link,
        'https://niscala.example/password-reset?token=tok-1',
      );
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(auth.passwordResetPreviews, ['tok-1', 'tok-1']);
      expect(field(_password), findsOneWidget);
    });

    testWidgets('an empty token behaves like no token', (tester) async {
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: ''),
        auth: auth,
      );

      expect(field(_link), findsOneWidget);
      expect(auth.passwordResetPreviews, isEmpty);
    });
  });

  group('reset password screen without a token', () {
    testWidgets('shows the paste step and checks nothing', (tester) async {
      await pumpLinkScreen(tester, const ResetPasswordScreen(), auth: auth);

      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(auth.passwordResetPreviews, isEmpty);
    });
  });

  group('accessibility of the reset password screen opened from a link', () {
    testWidgets('meets the guidelines while loading', (tester) async {
      auth.previewPasswordResetGate = Completer<void>();
      addTearDown(() {
        if (!auth.previewPasswordResetGate!.isCompleted) {
          auth.previewPasswordResetGate!.complete();
        }
      });
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
        settle: false,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the form', (tester) async {
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error', (tester) async {
      auth.previewPasswordResetFailure = _failureOf('PASSWORD_RESET_EXPIRED');
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('does not overflow at large text with the form', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at large text with an error', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = _failureOf('PASSWORD_RESET_EXPIRED');
      await pumpLinkScreen(
        tester,
        const ResetPasswordScreen(token: 'tok-1'),
        auth: auth,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
