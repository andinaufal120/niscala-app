import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/features/auth/ui/forgot_password_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/reset_password_screen.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'auth_ui_helpers.dart';

const _link = 'Tautan atur ulang (wajib)';
const _password = 'Kata sandi baru (wajib)';
const _confirm = 'Konfirmasi kata sandi baru (wajib)';

const _tokenLink = 'https://niscala.app/password-reset?token=abc';
const _goodPassword = 'kopi tubruk pagi';

const _linkHelper = 'Tempel tautan atur ulang dari email Anda.';
const _passwordHelper =
    'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa aturan huruf '
    'atau simbol khusus.';
const _invalidLink = 'Tautan tidak valid.';

const _strengthHint = 'Kekuatan kata sandi akan muncul saat Anda mengetik.';
const _tooShort = 'Kekuatan: Lemah · terlalu pendek';
const _guessable = 'Kekuatan: Lemah · mudah ditebak';
const _veryStrong = 'Kekuatan: Sangat kuat · sangat sulit ditebak';

const _linkCodes = [
  'PASSWORD_RESET_NOT_FOUND',
  'PASSWORD_RESET_USED',
  'PASSWORD_RESET_EXPIRED',
];

Future<void> pumpReset(WidgetTester tester, FakeAuthRepository auth) async {
  await pumpLogin(tester, auth);
  goTo(tester, '/atur-ulang-kata-sandi');
  await tester.pumpAndSettle();
}

Future<void> pumpResetAtLargeText(
  WidgetTester tester,
  FakeAuthRepository auth,
) async {
  await pumpAtLargeText(tester, buildTestApp(auth: auth));
  await tester.pumpAndSettle();
  goTo(tester, '/atur-ulang-kata-sandi');
  await tester.pumpAndSettle();
}

Future<void> continueWith(WidgetTester tester, String link) async {
  await type(tester, _link, link);
  await tapVisible(tester, buttonLabelled('Lanjut'));
}

/// Shows the new password form of a valid link.
Future<void> pumpForm(WidgetTester tester, FakeAuthRepository auth) async {
  await pumpReset(tester, auth);
  await continueWith(tester, _tokenLink);
}

Future<void> fill(
  WidgetTester tester, {
  String password = _goodPassword,
  String? confirm,
}) async {
  await type(tester, _password, password);
  await type(tester, _confirm, confirm ?? password);
}

Future<void> submit(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled('Simpan Kata Sandi'));

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String password = _goodPassword,
  String? confirm,
}) async {
  await fill(tester, password: password, confirm: confirm);
  await submit(tester);
}

ApiFailure _failureOf(String code) => ApiFailure(
  code: code,
  statusCode: code == 'PASSWORD_RESET_NOT_FOUND' ? 404 : 409,
);

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('link step', () {
    testWidgets('shows the title, the labelled link field and the button', (
      tester,
    ) async {
      await pumpReset(tester, auth);

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Atur ulang kata sandi'),
        ),
        findsOneWidget,
      );
      expect(field(_link), findsOneWidget);
      expect(find.text(_linkHelper), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(field(_password), findsNothing);
      expect(field(_confirm), findsNothing);
      expect(fieldError(tester, _link), isNull);
      expect(auth.passwordResetPreviews, isEmpty);
    });

    testWidgets('keeps paste enabled and uses the url keyboard', (
      tester,
    ) async {
      await pumpReset(tester, auth);

      expect(textField(tester, _link).enableInteractiveSelection, isNot(false));
      expect(textField(tester, _link).keyboardType, TextInputType.url);
      expect(textField(tester, _link).autocorrect, isFalse);
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpReset(tester, auth);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('sends the token of a pasted link', (tester) async {
      await pumpReset(tester, auth);

      await continueWith(tester, _tokenLink);

      expect(auth.passwordResetPreviews, ['abc']);
    });

    testWidgets('trims the link and ignores the other parts of it', (
      tester,
    ) async {
      await pumpReset(tester, auth);

      await continueWith(
        tester,
        '  https://niscala.app/password-reset?utm=wa&token=abc#top \n',
      );

      expect(auth.passwordResetPreviews, ['abc']);
    });

    testWidgets('decodes a percent-encoded token', (tester) async {
      await pumpReset(tester, auth);

      await continueWith(
        tester,
        'https://niscala.app/password-reset?token=a%2Bb',
      );

      expect(auth.passwordResetPreviews, ['a+b']);
    });

    testWidgets('sends a pasted bare token as it is', (tester) async {
      await pumpReset(tester, auth);

      await continueWith(tester, 'Ab_9-Zz');

      expect(auth.passwordResetPreviews, ['Ab_9-Zz']);
    });

    testWidgets('an empty link is an error and sends nothing', (tester) async {
      await pumpReset(tester, auth);

      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(fieldError(tester, _link), _invalidLink);
      expect(auth.passwordResetPreviews, isEmpty);
    });

    testWidgets('a blank link counts as empty', (tester) async {
      await pumpReset(tester, auth);

      await continueWith(tester, '   \n ');

      expect(fieldError(tester, _link), _invalidLink);
      expect(auth.passwordResetPreviews, isEmpty);
    });

    for (final bad in [
      'https://niscala.app/password-reset',
      'https://niscala.app/password-reset?other=1',
      'https://niscala.app/password-reset?token=',
      'https://niscala.app/password-reset/abc',
      '///',
    ]) {
      testWidgets('the text "$bad" is an error and sends nothing', (
        tester,
      ) async {
        await pumpReset(tester, auth);

        await continueWith(tester, bad);

        expect(fieldError(tester, _link), _invalidLink);
        expect(auth.passwordResetPreviews, isEmpty);
        expect(field(_password), findsNothing);
      });
    }

    testWidgets('the field error goes away on the next valid attempt', (
      tester,
    ) async {
      await pumpReset(tester, auth);
      await tapVisible(tester, buttonLabelled('Lanjut'));

      await continueWith(tester, _tokenLink);

      expect(find.text(_invalidLink), findsNothing);
      expect(auth.passwordResetPreviews, ['abc']);
    });

    testWidgets('keeps the field error on the field node', (tester) async {
      await pumpReset(tester, auth);
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expectFieldNode(tester, _link, error: _invalidLink);
    });
  });

  group('link step failures', () {
    for (final code in _linkCodes) {
      testWidgets('$code shows its message and a way to request a new link', (
        tester,
      ) async {
        auth.previewPasswordResetFailure = _failureOf(code);
        await pumpReset(tester, auth);

        await continueWith(tester, _tokenLink);

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
        expect(buttonLabelled('Minta Tautan Baru'), findsOneWidget);
        expect(field(_link), findsOneWidget);
        expect(field(_password), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('$code never shows the code or the English text', (
        tester,
      ) async {
        auth.previewPasswordResetFailure = _failureOf(code);
        await pumpReset(tester, auth);

        await continueWith(tester, _tokenLink);

        expect(find.textContaining('PASSWORD_RESET'), findsNothing);
        expect(find.textContaining('expired'), findsNothing);
        expect(find.textContaining('not found'), findsNothing);
      });
    }

    testWidgets('the new link button opens the forgot password screen', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = _failureOf('PASSWORD_RESET_EXPIRED');
      await pumpReset(tester, auth);
      await continueWith(tester, _tokenLink);

      await tapVisible(tester, buttonLabelled('Minta Tautan Baru'));

      expect(currentPath(tester), '/lupa-kata-sandi');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('a network failure shows its message and no new link button', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = const ApiFailure.network();
      await pumpReset(tester, auth);

      await continueWith(tester, _tokenLink);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(buttonLabelled('Minta Tautan Baru'), findsNothing);
      expect(field(_password), findsNothing);
    });

    testWidgets('a server failure shows its message', (tester) async {
      auth.previewPasswordResetFailure = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      await pumpReset(tester, auth);

      await continueWith(tester, _tokenLink);

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('an unknown error code shows the generic message', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = const ApiFailure(
        code: 'SOMETHING_NEW',
      );
      await pumpReset(tester, auth);

      await continueWith(tester, _tokenLink);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('the message stays and is a live region', (tester) async {
      auth.previewPasswordResetFailure = _failureOf('PASSWORD_RESET_USED');
      await pumpReset(tester, auth);
      await continueWith(tester, _tokenLink);

      await tester.pump(const Duration(seconds: 30));

      final message = messageOfCode('PASSWORD_RESET_USED');
      expect(find.text(message), findsOneWidget);
      expectLiveRegion(tester, message);
    });

    testWidgets('keeps the pasted link after a failure', (tester) async {
      auth.previewPasswordResetFailure = const ApiFailure.network();
      await pumpReset(tester, auth);

      await continueWith(tester, _tokenLink);

      expect(find.text(_tokenLink), findsOneWidget);
    });

    testWidgets('the message goes away when the next check starts', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = const ApiFailure.network();
      await pumpReset(tester, auth);
      await continueWith(tester, _tokenLink);
      auth.previewPasswordResetGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Lanjut'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(auth.passwordResetPreviews, hasLength(2));
    });

    testWidgets('a corrected link after a failure opens the form', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = _failureOf('PASSWORD_RESET_USED');
      await pumpReset(tester, auth);
      await continueWith(tester, _tokenLink);
      auth.previewPasswordResetFailure = null;

      await type(tester, _link, 'https://niscala.app/password-reset?token=xyz');
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(auth.passwordResetPreviews, ['abc', 'xyz']);
      expect(field(_password), findsOneWidget);
      expect(find.text(messageOfCode('PASSWORD_RESET_USED')), findsNothing);
    });
  });

  group('while the link is being checked', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      auth.previewPasswordResetGate = Completer<void>();
      await pumpReset(tester, auth);
      await type(tester, _link, _tokenLink);

      await tapAndPump(tester, buttonLabelled('Lanjut'));

      expectBusy(tester);
      expect(find.text('Lanjut'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      auth.previewPasswordResetGate = Completer<void>();
      await pumpReset(tester, auth);
      await type(tester, _link, _tokenLink);
      final button = buttonLabelled('Lanjut');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.passwordResetPreviews, hasLength(1));
    });

    testWidgets('restores the button when the check fails', (tester) async {
      auth.previewPasswordResetGate = Completer<void>();
      auth.previewPasswordResetFailure = const ApiFailure.network();
      await pumpReset(tester, auth);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Lanjut'));

      auth.previewPasswordResetGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled('Lanjut')).onPressed,
        isNotNull,
      );
    });

    testWidgets('opens the form once the check completes', (tester) async {
      auth.previewPasswordResetGate = Completer<void>();
      await pumpReset(tester, auth);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Lanjut'));

      auth.previewPasswordResetGate!.complete();
      await tester.pumpAndSettle();

      expect(field(_password), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('new password form', () {
    testWidgets('replaces the link field and keeps the title', (tester) async {
      await pumpForm(tester, auth);

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Atur ulang kata sandi'),
        ),
        findsOneWidget,
      );
      expect(field(_link), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
      expect(field(_password), findsOneWidget);
      expect(field(_confirm), findsOneWidget);
      expect(find.text(_passwordHelper), findsOneWidget);
      expect(buttonLabelled('Simpan Kata Sandi'), findsOneWidget);
    });

    testWidgets('names the account the password is for', (tester) async {
      await pumpForm(tester, auth);

      expect(find.text('Untuk akun budi@example.com'), findsOneWidget);
    });

    testWidgets('names the email that the API returns', (tester) async {
      auth.passwordResetPreviewEmail = 'siti@example.com';
      await pumpForm(tester, auth);

      expect(find.text('Untuk akun siti@example.com'), findsOneWidget);
      expect(find.textContaining('budi@example.com'), findsNothing);
    });

    testWidgets('starts with empty fields, no errors and no request', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      expect(textField(tester, _password).controller?.text, isEmpty);
      expect(textField(tester, _confirm).controller?.text, isEmpty);
      expect(fieldError(tester, _password), isNull);
      expect(fieldError(tester, _confirm), isNull);
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('starts with both passwords hidden', (tester) async {
      await pumpForm(tester, auth);

      expect(textField(tester, _password).obscureText, isTrue);
      expect(textField(tester, _confirm).obscureText, isTrue);
    });

    testWidgets('one checkbox reveals and hides both password fields', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      expect(find.byType(Checkbox), findsOneWidget);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));
      expect(textField(tester, _password).obscureText, isFalse);
      expect(textField(tester, _confirm).obscureText, isFalse);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));
      expect(textField(tester, _password).obscureText, isTrue);
      expect(textField(tester, _confirm).obscureText, isTrue);
    });

    testWidgets('keeps the typed passwords when toggled', (tester) async {
      await pumpForm(tester, auth);
      await fill(tester);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));

      expect(textField(tester, _password).controller?.text, _goodPassword);
      expect(textField(tester, _confirm).controller?.text, _goodPassword);
    });

    testWidgets('the show password checkbox is labelled and 48 dp', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      expectShowPasswordCheckbox(tester, checked: false);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));
      expectShowPasswordCheckbox(tester, checked: true);
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
    });
  });

  group('validation', () {
    testWidgets('empty fields name both fields and send nothing', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      await submit(tester);

      expect(fieldError(tester, _password), 'Kata sandi baru wajib diisi.');
      expect(fieldError(tester, _confirm), 'Ketik ulang kata sandi baru.');
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('rejects a password shorter than 8 characters', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, password: 'x7Kqx7K');

      expect(fieldError(tester, _password), 'Kata sandi minimal 8 karakter.');
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('accepts a password of exactly 8 characters', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, password: 'x7Kqx7Kq');

      expect(auth.passwordResets, hasLength(1));
    });

    testWidgets('accepts a password of exactly 128 characters', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, password: 'x7Kq' * 32);

      expect(auth.passwordResets, hasLength(1));
    });

    testWidgets('rejects a password longer than 128 characters', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, password: '${'x7Kq' * 32}z');

      expect(
        fieldError(tester, _password),
        'Kata sandi maksimal 128 karakter.',
      );
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('asks to retype when the confirmation is empty', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      await type(tester, _password, _goodPassword);

      await submit(tester);

      expect(fieldError(tester, _confirm), 'Ketik ulang kata sandi baru.');
      expect(fieldError(tester, _password), isNull);
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('rejects a confirmation that differs from the password', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, confirm: 'kopi tubruk sore');

      expect(
        fieldError(tester, _confirm),
        'Konfirmasi tidak sama dengan kata sandi baru.',
      );
      expect(fieldError(tester, _password), isNull);
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('compares the confirmation without trimming', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, confirm: '$_goodPassword ');

      expect(
        fieldError(tester, _confirm),
        'Konfirmasi tidak sama dengan kata sandi baru.',
      );
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('errors disappear once the form is valid and resubmitted', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      await submit(tester);

      await fillAndSubmit(tester);

      expect(auth.passwordResets, hasLength(1));
      expect(find.text('Kata sandi baru wajib diisi.'), findsNothing);
      expect(find.text('Ketik ulang kata sandi baru.'), findsNothing);
    });

    testWidgets('a client side error does not leave the form', (tester) async {
      await pumpForm(tester, auth);

      await submit(tester);

      expect(field(_password), findsOneWidget);
      expect(field(_link), findsNothing);
    });
  });

  group('submit', () {
    testWidgets('sends the token of the link and the untouched password', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester, password: ' kopi tubruk pagi ');

      expect(auth.passwordResets, hasLength(1));
      expect(auth.passwordResets.single.token, 'abc');
      expect(auth.passwordResets.single.newPassword, ' kopi tubruk pagi ');
    });

    testWidgets('sends the token of a bare pasted token', (tester) async {
      await pumpReset(tester, auth);
      await continueWith(tester, 'Ab_9-Zz');

      await fillAndSubmit(tester);

      expect(auth.passwordResets.single.token, 'Ab_9-Zz');
    });

    testWidgets('previews once and resets once', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      expect(auth.passwordResetPreviews, hasLength(1));
      expect(auth.passwordResets, hasLength(1));
    });
  });

  group('success', () {
    testWidgets('shows the result and replaces the form', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
      expect(field(_password), findsNothing);
      expect(field(_confirm), findsNothing);
      expect(buttonLabelled('Simpan Kata Sandi'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('says that all devices were signed out', (tester) async {
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      expect(find.textContaining('perangkat'), findsOneWidget);
    });

    testWidgets('the title is a semantic header', (tester) async {
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Kata sandi diperbarui')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('stays on screen and is not a snack bar', (tester) async {
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the sign in button opens the sign in screen', (tester) async {
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('does not sign in automatically', (tester) async {
      final store = await pumpLogin(tester, auth);
      goTo(tester, '/atur-ulang-kata-sandi');
      await tester.pumpAndSettle();
      await continueWith(tester, _tokenLink);

      await fillAndSubmit(tester);
      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(auth.logins, isEmpty);
      expect(store.stored, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
    });
  });

  group('failures on the new password form', () {
    testWidgets('PASSWORD_TOO_COMMON is shown on the password field', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure(
        code: 'PASSWORD_TOO_COMMON',
        field: 'newPassword',
        statusCode: 422,
      );
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      expect(
        fieldError(tester, _password),
        messageOfCode('PASSWORD_TOO_COMMON'),
      );
      expect(fieldError(tester, _confirm), isNull);
      expect(find.text('Kata sandi diperbarui'), findsNothing);
      expect(field(_password), findsOneWidget);
      expectFieldNode(
        tester,
        _password,
        error: messageOfCode('PASSWORD_TOO_COMMON'),
      );
    });

    testWidgets(
      'PASSWORD_TOO_COMMON without a field still marks the password',
      (tester) async {
        auth.resetPasswordFailure = const ApiFailure(
          code: 'PASSWORD_TOO_COMMON',
        );
        await pumpForm(tester, auth);

        await fillAndSubmit(tester);

        expect(
          fieldError(tester, _password),
          messageOfCode('PASSWORD_TOO_COMMON'),
        );
      },
    );

    testWidgets('a validation failure on newPassword is shown on the field', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'newPassword',
        statusCode: 422,
      );
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      final message = errorMessageFor(auth.resetPasswordFailure!);
      expect(fieldError(tester, _password), message);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
      expect(field(_password), findsOneWidget);
    });

    testWidgets('a validation failure on another field is shown as a message', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'token',
        statusCode: 422,
      );
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      expect(
        find.text(errorMessageFor(auth.resetPasswordFailure!)),
        findsOneWidget,
      );
      expect(fieldError(tester, _password), isNull);
      expect(field(_password), findsOneWidget);
    });

    final bannerCases = {
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };
    for (final entry in bannerCases.entries) {
      testWidgets('${entry.key} is shown in a banner, not on a field', (
        tester,
      ) async {
        auth.resetPasswordFailure = ApiFailure(code: entry.key);
        await pumpForm(tester, auth);

        await fillAndSubmit(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(fieldError(tester, _password), isNull);
        expect(fieldError(tester, _confirm), isNull);
        expect(field(_password), findsOneWidget);
        expect(find.text('Kata sandi diperbarui'), findsNothing);
        expect(currentPath(tester), '/atur-ulang-kata-sandi');
      });
    }

    testWidgets('the banner stays and is a live region', (tester) async {
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('keeps what the user typed after a failure', (tester) async {
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpForm(tester, auth);

      await fillAndSubmit(tester);

      expect(textField(tester, _password).controller?.text, _goodPassword);
      expect(textField(tester, _confirm).controller?.text, _goodPassword);
      expect(find.text('Untuk akun budi@example.com'), findsOneWidget);
    });

    testWidgets('the banner goes away when the next request starts', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);
      auth.resetPasswordGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Simpan Kata Sandi'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(auth.passwordResets, hasLength(2));
    });

    testWidgets('a field error from the server goes away on the next try', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure(
        code: 'PASSWORD_TOO_COMMON',
        field: 'newPassword',
      );
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);
      auth.resetPasswordFailure = null;

      await type(tester, _password, 'x7Kqx7Kq');
      await type(tester, _confirm, 'x7Kqx7Kq');
      await submit(tester);

      expect(auth.passwordResets, hasLength(2));
      expect(auth.passwordResets.last.newPassword, 'x7Kqx7Kq');
      expect(auth.passwordResets.last.token, 'abc');
      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
    });

    testWidgets('the user can retry after a network failure', (tester) async {
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);
      auth.resetPasswordFailure = null;

      await submit(tester);

      expect(auth.passwordResets, hasLength(2));
      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
    });

    for (final code in _linkCodes) {
      testWidgets('$code shows its message and goes back to the link step', (
        tester,
      ) async {
        auth.resetPasswordFailure = _failureOf(code);
        await pumpForm(tester, auth);

        await fillAndSubmit(tester);

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(field(_link), findsOneWidget);
        expect(buttonLabelled('Lanjut'), findsOneWidget);
        expect(buttonLabelled('Minta Tautan Baru'), findsOneWidget);
        expect(field(_password), findsNothing);
        expect(buttonLabelled('Simpan Kata Sandi'), findsNothing);
        expect(find.text('Kata sandi diperbarui'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      });
    }

    testWidgets('after a link failure a new link opens the form again', (
      tester,
    ) async {
      auth.resetPasswordFailure = _failureOf('PASSWORD_RESET_EXPIRED');
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);
      auth.resetPasswordFailure = null;

      await continueWith(
        tester,
        'https://niscala.app/password-reset?token=xyz',
      );
      await fillAndSubmit(tester);

      expect(auth.passwordResetPreviews, ['abc', 'xyz']);
      expect(auth.passwordResets.last.token, 'xyz');
      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
    });

    testWidgets('after a link failure the new link button opens the request', (
      tester,
    ) async {
      auth.resetPasswordFailure = _failureOf('PASSWORD_RESET_USED');
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await tapVisible(tester, buttonLabelled('Minta Tautan Baru'));

      expect(currentPath(tester), '/lupa-kata-sandi');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });

  group('while the password is being saved', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      auth.resetPasswordGate = Completer<void>();
      await pumpForm(tester, auth);
      await fill(tester);

      await tapAndPump(tester, buttonLabelled('Simpan Kata Sandi'));

      expectBusy(tester);
      expect(find.text('Simpan Kata Sandi'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      auth.resetPasswordGate = Completer<void>();
      await pumpForm(tester, auth);
      await fill(tester);
      final button = buttonLabelled('Simpan Kata Sandi');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.passwordResets, hasLength(1));
    });

    testWidgets('an invalid form does not start a request', (tester) async {
      auth.resetPasswordGate = Completer<void>();
      await pumpForm(tester, auth);

      await tapAndPump(tester, buttonLabelled('Simpan Kata Sandi'));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(auth.passwordResets, isEmpty);
    });

    testWidgets('shows the result once the request completes', (tester) async {
      auth.resetPasswordGate = Completer<void>();
      await pumpForm(tester, auth);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Simpan Kata Sandi'));

      auth.resetPasswordGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      auth.resetPasswordGate = Completer<void>();
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpForm(tester, auth);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Simpan Kata Sandi'));

      auth.resetPasswordGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(buttonLabelled('Simpan Kata Sandi'))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('strength meter', () {
    testWidgets('invites typing while the password is empty', (tester) async {
      await pumpForm(tester, auth);

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('follows the password while typing', (tester) async {
      await pumpForm(tester, auth);

      await type(tester, _password, 'abc');
      expect(find.text(_tooShort), findsOneWidget);

      await type(tester, _password, _goodPassword);
      expect(find.text(_veryStrong), findsOneWidget);
      expect(find.textContaining('Kekuatan'), findsOneWidget);
    });

    testWidgets('flags a common password as easy to guess', (tester) async {
      await pumpForm(tester, auth);

      await type(tester, _password, 'password123');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('weakens a password that contains the email local part', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      await type(tester, _password, 'budi-kopi-tubruk');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('does not weaken a password for another account', (
      tester,
    ) async {
      auth.passwordResetPreviewEmail = 'siti@example.com';
      await pumpForm(tester, auth);

      await type(tester, _password, 'budi-kopi-tubruk');

      expect(find.text(_veryStrong), findsOneWidget);
    });

    testWidgets('announces the strength line as a live region', (tester) async {
      await pumpForm(tester, auth);
      await type(tester, _password, _goodPassword);

      expectLiveRegion(tester, _veryStrong);
    });
  });

  group('authentication rules', () {
    testWidgets('both password fields offer new password autofill', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      expectCredentialField(tester, _password, AutofillHints.newPassword);
      expectCredentialField(tester, _confirm, AutofillHints.newPassword);
    });

    testWidgets('the link field sits in an autofill group', (tester) async {
      await pumpReset(tester, auth);

      expect(
        find.ancestor(of: field(_link), matching: find.byType(AutofillGroup)),
        findsOneWidget,
      );
    });
  });

  group('structure', () {
    testWidgets('wraps the link field in a LabeledField with its marker', (
      tester,
    ) async {
      await pumpReset(tester, auth);

      expect(labeledField(_link), findsOneWidget);
      expect(find.text(_link), findsOneWidget);
      expectNoDecorationLabels(tester);
    });

    testWidgets('reads the link label once, on the field', (tester) async {
      await pumpReset(tester, auth);

      expectFieldNode(tester, _link);
    });

    testWidgets('the form wraps both fields in a LabeledField', (tester) async {
      await pumpForm(tester, auth);

      for (final label in [_password, _confirm]) {
        expect(labeledField(label), findsOneWidget);
        expect(find.text(label), findsOneWidget);
      }
      expectNoDecorationLabels(tester);
    });

    testWidgets('the form puts each label above its field', (tester) async {
      await pumpForm(tester, auth);

      for (final label in [_password, _confirm]) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top));
      }
    });

    testWidgets('the form reads each field label once, on its field', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      expectFieldNode(tester, _password);
      expectFieldNode(tester, _confirm);
    });

    testWidgets('the form keeps each field error on its field node', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      await submit(tester);

      expectFieldNode(tester, _password, error: 'Kata sandi baru wajib diisi.');
      expectFieldNode(tester, _confirm, error: 'Ketik ulang kata sandi baru.');
    });

    testWidgets('tapping a label focuses its field on the form', (
      tester,
    ) async {
      await pumpForm(tester, auth);

      await tester.tap(find.text(_password));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_password),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('uses a white app bar on every step', (tester) async {
      await pumpReset(tester, auth);
      expectWhiteAppBar(tester);

      await continueWith(tester, _tokenLink);
      expectWhiteAppBar(tester);

      await fillAndSubmit(tester);
      expectWhiteAppBar(tester);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines on the link step', (tester) async {
      await pumpReset(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a link field error', (tester) async {
      await pumpReset(tester, auth);
      await tapVisible(tester, buttonLabelled('Lanjut'));

      await expectMeetsA11yGuidelines(tester);
    });

    for (final code in _linkCodes) {
      testWidgets('meets the guidelines with $code on the link step', (
        tester,
      ) async {
        auth.previewPasswordResetFailure = _failureOf(code);
        await pumpReset(tester, auth);
        await continueWith(tester, _tokenLink);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('meets the guidelines with $code on the form', (
        tester,
      ) async {
        auth.resetPasswordFailure = _failureOf(code);
        await pumpForm(tester, auth);
        await fillAndSubmit(tester);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines with a failed check', (tester) async {
      auth.previewPasswordResetFailure = const ApiFailure.network();
      await pumpReset(tester, auth);
      await continueWith(tester, _tokenLink);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the link is being checked', (
      tester,
    ) async {
      auth.previewPasswordResetGate = Completer<void>();
      await pumpReset(tester, auth);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Lanjut'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on the form', (tester) async {
      await pumpForm(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with field errors', (tester) async {
      await pumpForm(tester, auth);
      await submit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error from the server', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure(
        code: 'PASSWORD_TOO_COMMON',
        field: 'newPassword',
      );
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a banner on the form', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the password is being saved', (
      tester,
    ) async {
      auth.resetPasswordGate = Completer<void>();
      await pumpForm(tester, auth);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Simpan Kata Sandi'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the passwords shown', (
      tester,
    ) async {
      await pumpForm(tester, auth);
      await tapVisible(tester, find.text('Tampilkan kata sandi'));

      await expectMeetsA11yGuidelines(tester);
    });

    for (final password in ['abc', _goodPassword]) {
      testWidgets('meets the guidelines with the strength of "$password"', (
        tester,
      ) async {
        await pumpForm(tester, auth);
        await type(tester, _password, password);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines on the result', (tester) async {
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the buttons of the result are at least 48 dp', (tester) async {
      await pumpForm(tester, auth);
      await fillAndSubmit(tester);

      final size = tester.getSize(buttonLabelled('Masuk'));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('fits at large text size on the link step', (tester) async {
      await pumpResetAtLargeText(tester, auth);

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a link error', (tester) async {
      await pumpResetAtLargeText(tester, auth);

      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(fieldError(tester, _link), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a message about the link', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = _failureOf('PASSWORD_RESET_EXPIRED');
      await pumpResetAtLargeText(tester, auth);

      await continueWith(tester, _tokenLink);

      expect(
        find.text(messageOfCode('PASSWORD_RESET_EXPIRED')),
        findsOneWidget,
      );
      expect(buttonLabelled('Minta Tautan Baru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size on the form', (tester) async {
      await pumpResetAtLargeText(tester, auth);
      await continueWith(tester, _tokenLink);

      expect(field(_password), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with field errors', (tester) async {
      await pumpResetAtLargeText(tester, auth);
      await continueWith(tester, _tokenLink);
      await type(tester, _password, 'abc');

      await submit(tester);

      expect(fieldError(tester, _password), isNotNull);
      expect(fieldError(tester, _confirm), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a banner on the form', (
      tester,
    ) async {
      auth.resetPasswordFailure = const ApiFailure.network();
      await pumpResetAtLargeText(tester, auth);
      await continueWith(tester, _tokenLink);
      await fill(tester);

      await submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size on the result', (tester) async {
      await pumpResetAtLargeText(tester, auth);
      await continueWith(tester, _tokenLink);
      await fill(tester);

      await submit(tester);

      expect(find.text('Kata sandi diperbarui'), findsOneWidget);
      expect(buttonLabelled('Masuk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
