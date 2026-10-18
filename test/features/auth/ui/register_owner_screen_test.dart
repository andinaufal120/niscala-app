import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/register_owner_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';

const _name = 'Nama lengkap (wajib)';
const _email = 'Email (wajib)';
const _password = 'Kata sandi (wajib)';
const _confirm = 'Konfirmasi kata sandi (wajib)';

const _strengthHint = 'Kekuatan kata sandi akan muncul saat Anda mengetik.';
const _tooShort = 'Kekuatan: Lemah · terlalu pendek';
const _guessable = 'Kekuatan: Lemah · mudah ditebak';
const _fair = 'Kekuatan: Cukup · tambah panjangnya agar lebih aman';
const _strong = 'Kekuatan: Kuat · sudah aman';
const _veryStrong = 'Kekuatan: Sangat kuat · sangat sulit ditebak';

Future<void> fill(
  WidgetTester tester, {
  String name = 'Budi Santoso',
  String email = 'budi@example.com',
  String password = 'kopi tubruk pagi',
  String? confirm,
}) async {
  await type(tester, _name, name);
  await type(tester, _email, email);
  await type(tester, _password, password);
  await type(tester, _confirm, confirm ?? password);
}

Future<void> submit(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled('Daftar'));

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String name = 'Budi Santoso',
  String email = 'budi@example.com',
  String password = 'kopi tubruk pagi',
  String? confirm,
}) async {
  await fill(
    tester,
    name: name,
    email: email,
    password: password,
    confirm: confirm,
  );
  await submit(tester);
}

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('content', () {
    testWidgets('shows the title, fields, helpers, toggle and button', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      expect(find.byType(RegisterOwnerScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Daftar sebagai Pemilik Kost'),
        ),
        findsOneWidget,
      );
      expect(field(_name), findsOneWidget);
      expect(field(_email), findsOneWidget);
      expect(field(_password), findsOneWidget);
      expect(field(_confirm), findsOneWidget);
      expect(
        find.text(
          'Kode verifikasi dikirim ke email ini. Email juga dipakai untuk '
          'mengatur ulang kata sandi.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa aturan '
          'huruf atau simbol khusus.',
        ),
        findsOneWidget,
      );
      expect(find.text(_strengthHint), findsOneWidget);
      expect(find.text('Tampilkan kata sandi'), findsOneWidget);
      expect(buttonLabelled('Daftar'), findsOneWidget);
    });

    testWidgets('shows no error and no banner before the first submit', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      for (final label in [_name, _email, _password, _confirm]) {
        expect(fieldError(tester, label), isNull);
      }
      expect(find.byType(SnackBar), findsNothing);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('starts with both passwords hidden', (tester) async {
      await pumpRegister(tester, auth);

      expect(textField(tester, _password).obscureText, isTrue);
      expect(textField(tester, _confirm).obscureText, isTrue);
      expect(textField(tester, _name).obscureText, isFalse);
      expect(textField(tester, _email).obscureText, isFalse);
    });

    testWidgets('goes back to the sign in screen with the back button', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      final handle = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('Kembali ke halaman masuk').first);
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('show password', () {
    testWidgets('one checkbox reveals and hides both password fields', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();
      expect(textField(tester, _password).obscureText, isFalse);
      expect(textField(tester, _confirm).obscureText, isFalse);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();
      expect(textField(tester, _password).obscureText, isTrue);
      expect(textField(tester, _confirm).obscureText, isTrue);
    });

    testWidgets('is a labelled checkbox of at least 48 dp', (tester) async {
      await pumpRegister(tester, auth);
      expectShowPasswordCheckbox(tester, checked: false);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();
      expectShowPasswordCheckbox(tester, checked: true);
    });
  });

  group('validation', () {
    testWidgets('an empty form names every field and sends nothing', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      await submit(tester);

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(fieldError(tester, _password), 'Kata sandi minimal 8 karakter.');
      expect(fieldError(tester, _confirm), 'Ketik ulang kata sandi.');
      expect(auth.registrations, isEmpty);
    });

    for (final bad in [
      'budi',
      'budi@',
      'budi@example',
      '@example.com',
      'a b@c.d',
    ]) {
      testWidgets('rejects the email "$bad" without a request', (tester) async {
        await pumpRegister(tester, auth);

        await fillAndSubmit(tester, email: bad);

        expect(fieldError(tester, _email), 'Format email tidak valid.');
        expect(auth.registrations, isEmpty);
      });
    }

    testWidgets('rejects a password shorter than 8 characters', (tester) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, password: 'x7Kqx7K');

      expect(fieldError(tester, _password), 'Kata sandi minimal 8 karakter.');
      expect(auth.registrations, isEmpty);
    });

    testWidgets('accepts a password of exactly 8 characters', (tester) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, password: 'x7Kqx7Kq');

      expect(fieldError(tester, _password), isNull);
      expect(auth.registrations, hasLength(1));
    });

    testWidgets('accepts a password of exactly 128 characters', (tester) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, password: 'x7Kq' * 32);

      expect(auth.registrations, hasLength(1));
      expect(auth.registrations.single.password, 'x7Kq' * 32);
    });

    testWidgets('rejects a password longer than 128 characters', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, password: '${'x7Kq' * 32}z');

      expect(
        fieldError(tester, _password),
        'Kata sandi maksimal 128 karakter.',
      );
      expect(auth.registrations, isEmpty);
    });

    testWidgets('asks to retype when the confirmation is empty', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      await fill(tester);
      await type(tester, _confirm, '');
      await submit(tester);

      expect(fieldError(tester, _confirm), 'Ketik ulang kata sandi.');
      expect(fieldError(tester, _password), isNull);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('rejects a confirmation that differs from the password', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, confirm: 'kopi tubruk sore');

      expect(
        fieldError(tester, _confirm),
        'Konfirmasi tidak sama dengan kata sandi.',
      );
      expect(auth.registrations, isEmpty);
    });

    testWidgets('compares the confirmation without trimming', (tester) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, confirm: 'kopi tubruk pagi ');

      expect(
        fieldError(tester, _confirm),
        'Konfirmasi tidak sama dengan kata sandi.',
      );
      expect(auth.registrations, isEmpty);
    });

    testWidgets('an empty name is the only error when the rest is fine', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester, name: '');

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(fieldError(tester, _email), isNull);
      expect(fieldError(tester, _password), isNull);
      expect(fieldError(tester, _confirm), isNull);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('errors disappear once the form is valid and resubmitted', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await submit(tester);

      await fillAndSubmit(tester);

      expect(auth.registrations, hasLength(1));
      expect(find.text('Nama wajib diisi.'), findsNothing);
    });
  });

  group('submit', () {
    testWidgets('sends the trimmed name and email and the untouched password', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      await fillAndSubmit(
        tester,
        name: '  Budi Santoso ',
        email: ' budi@example.com  ',
        password: ' kopi tubruk pagi ',
      );

      expect(auth.registrations, hasLength(1));
      expect(auth.registrations.single.name, 'Budi Santoso');
      expect(auth.registrations.single.email, 'budi@example.com');
      expect(auth.registrations.single.password, ' kopi tubruk pagi ');
    });

    testWidgets('signs in and shows email verification for the new account', (
      tester,
    ) async {
      final store = await pumpRegister(tester, auth);

      await fillAndSubmit(tester);

      expect(currentPath(tester), '/verifikasi-email');
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.byType(RegisterOwnerScreen), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(store.stored?.role, UserRole.owner);
      expect(store.stored?.emailVerified, isFalse);
      expect(store.stored?.accessToken, auth.registerResult.accessToken);
    });
  });

  group('failures', () {
    testWidgets('EMAIL_ALREADY_REGISTERED is shown on the email field', (
      tester,
    ) async {
      auth.registerFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_REGISTERED',
        field: 'email',
        statusCode: 409,
      );
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester);

      expect(
        fieldError(tester, _email),
        errorMessage('EMAIL_ALREADY_REGISTERED'),
      );
      expect(
        find.text(errorMessage('EMAIL_ALREADY_REGISTERED')),
        findsOneWidget,
      );
      expect(find.byType(RegisterOwnerScreen), findsOneWidget);
    });

    testWidgets(
      'EMAIL_ALREADY_REGISTERED without a field still marks the email',
      (tester) async {
        auth.registerFailure = const ApiFailure(
          code: 'EMAIL_ALREADY_REGISTERED',
        );
        await pumpRegister(tester, auth);

        await fillAndSubmit(tester);

        expect(
          fieldError(tester, _email),
          errorMessage('EMAIL_ALREADY_REGISTERED'),
        );
        expect(
          find.text(errorMessage('EMAIL_ALREADY_REGISTERED')),
          findsOneWidget,
        );
      },
    );

    testWidgets('PASSWORD_TOO_COMMON is shown on the password field', (
      tester,
    ) async {
      auth.registerFailure = const ApiFailure(
        code: 'PASSWORD_TOO_COMMON',
        field: 'password',
      );
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester);

      expect(
        fieldError(tester, _password),
        errorMessage('PASSWORD_TOO_COMMON'),
      );
      expect(fieldError(tester, _email), isNull);
      expect(find.text(errorMessage('PASSWORD_TOO_COMMON')), findsOneWidget);
    });

    testWidgets(
      'PASSWORD_TOO_COMMON without a field still marks the password',
      (tester) async {
        auth.registerFailure = const ApiFailure(code: 'PASSWORD_TOO_COMMON');
        await pumpRegister(tester, auth);

        await fillAndSubmit(tester);

        expect(
          fieldError(tester, _password),
          errorMessage('PASSWORD_TOO_COMMON'),
        );
      },
    );

    final fieldCases = {'name': _name, 'email': _email, 'password': _password};
    for (final entry in fieldCases.entries) {
      testWidgets(
        'a failure for the ${entry.key} field is shown on that field',
        (tester) async {
          auth.registerFailure = ApiFailure(
            code: 'VALIDATION_FAILED',
            field: entry.key,
            statusCode: 422,
          );
          await pumpRegister(tester, auth);

          await fillAndSubmit(tester);

          expect(
            fieldError(tester, entry.value),
            errorMessage('VALIDATION_FAILED'),
          );
          for (final other in fieldCases.entries.where(
            (e) => e.key != entry.key,
          )) {
            expect(fieldError(tester, other.value), isNull);
          }
        },
      );
    }

    final bannerCases = {
      'NETWORK_ERROR': errorMessage('NETWORK_ERROR'),
      'INTERNAL_ERROR': errorMessage('INTERNAL_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };
    for (final entry in bannerCases.entries) {
      testWidgets('${entry.key} is shown in a banner, not on a field', (
        tester,
      ) async {
        auth.registerFailure = ApiFailure(code: entry.key);
        await pumpRegister(tester, auth);

        await fillAndSubmit(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        for (final label in [_name, _email, _password, _confirm]) {
          expect(fieldError(tester, label), isNull);
        }
        expect(currentPath(tester), '/daftar');
      });
    }

    testWidgets('the banner stays and is a live region', (tester) async {
      auth.registerFailure = const ApiFailure.network();
      await pumpRegister(tester, auth);
      await fillAndSubmit(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, errorMessage('NETWORK_ERROR'));
    });

    testWidgets('the banner goes away when the next request starts', (
      tester,
    ) async {
      auth.registerFailure = const ApiFailure.network();
      await pumpRegister(tester, auth);
      await fillAndSubmit(tester);
      auth.gate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Daftar'));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expect(auth.registrations, hasLength(2));
    });

    testWidgets('the user can fix the email and register again', (
      tester,
    ) async {
      auth.registerFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_REGISTERED',
        field: 'email',
      );
      await pumpRegister(tester, auth);
      await fillAndSubmit(tester);
      auth.registerFailure = null;

      await type(tester, _email, 'budi.baru@example.com');
      await submit(tester);

      expect(auth.registrations, hasLength(2));
      expect(auth.registrations.last.email, 'budi.baru@example.com');
      expect(currentPath(tester), '/verifikasi-email');
    });

    testWidgets('keeps what the user typed after a failure', (tester) async {
      auth.registerFailure = const ApiFailure.network();
      await pumpRegister(tester, auth);

      await fillAndSubmit(tester);

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
    });
  });

  group('while a request is in flight', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpRegister(tester, auth);
      await fill(tester);

      await tapAndPump(tester, buttonLabelled('Daftar'));

      expectBusy(tester);
      expect(find.text('Daftar'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      auth.gate = Completer<void>();
      await pumpRegister(tester, auth);
      await fill(tester);
      final button = buttonLabelled('Daftar');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.registrations, hasLength(1));
    });

    testWidgets('restores the button when the request fails', (tester) async {
      auth.gate = Completer<void>();
      auth.registerFailure = const ApiFailure.network();
      await pumpRegister(tester, auth);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Daftar'));

      auth.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled('Daftar')).onPressed,
        isNotNull,
      );
    });
  });

  group('strength meter', () {
    testWidgets('invites typing while the password is empty', (tester) async {
      await pumpRegister(tester, auth);

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('follows the password while typing', (tester) async {
      await pumpRegister(tester, auth);

      await type(tester, _password, 'abc');
      expect(find.text(_tooShort), findsOneWidget);

      await type(tester, _password, 'kopi tubruk');
      expect(find.text(_fair), findsOneWidget);

      await type(tester, _password, 'kopi tubruk pa');
      expect(find.text(_strong), findsOneWidget);

      await type(tester, _password, 'kopi tubruk pagi');
      expect(find.text(_veryStrong), findsOneWidget);
    });

    testWidgets('shows a single strength line at a time', (tester) async {
      await pumpRegister(tester, auth);

      await type(tester, _password, 'kopi tubruk pagi');

      expect(find.textContaining('Kekuatan'), findsOneWidget);
    });

    testWidgets('flags a common password as easy to guess', (tester) async {
      await pumpRegister(tester, auth);

      await type(tester, _password, 'password123');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('goes back to the invitation when the password is cleared', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await type(tester, _password, 'kopi tubruk pagi');

      await type(tester, _password, '');

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('weakens when the password contains the typed name', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await type(tester, _password, 'budi-kopi-tubruk');
      expect(find.text(_veryStrong), findsOneWidget);

      await type(tester, _name, 'Budi Santoso');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('recovers when the name changes to something else', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await type(tester, _name, 'Budi Santoso');
      await type(tester, _password, 'budi-kopi-tubruk');
      expect(find.text(_guessable), findsOneWidget);

      await type(tester, _name, 'Siti Aminah');

      expect(find.text(_veryStrong), findsOneWidget);
    });

    testWidgets('weakens when the password contains the email local part', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await type(tester, _password, 'xx-andi.naufal-9');
      expect(find.text(_veryStrong), findsOneWidget);

      await type(tester, _email, 'andi.naufal@example.com');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('announces the strength line as a live region', (tester) async {
      await pumpRegister(tester, auth);
      await type(tester, _password, 'kopi tubruk pagi');

      expectLiveRegion(tester, _veryStrong);
    });

    testWidgets('exposes only the strength text, not the bars, to semantics', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await type(tester, _password, 'kopi tubruk pagi');
      final handle = tester.ensureSemantics();

      expect(find.bySemanticsLabel(RegExp('Kekuatan')), findsOneWidget);
      handle.dispose();
    });
  });

  group('authentication rules', () {
    testWidgets('the name field offers the name autofill hint', (tester) async {
      await pumpRegister(tester, auth);

      expect(
        textField(tester, _name).autofillHints,
        contains(AutofillHints.name),
      );
      expect(textField(tester, _name).decoration?.labelText, _name);
    });

    testWidgets('the email field keeps paste on and offers email autofill', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      expectCredentialField(tester, _email, AutofillHints.email);
    });

    testWidgets('both password fields offer new password autofill', (
      tester,
    ) async {
      await pumpRegister(tester, auth);

      expectCredentialField(tester, _password, AutofillHints.newPassword);
      expectCredentialField(tester, _confirm, AutofillHints.newPassword);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines in the initial state', (tester) async {
      await pumpRegister(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with field errors', (tester) async {
      await pumpRegister(tester, auth);
      await submit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with errors from the server', (
      tester,
    ) async {
      auth.registerFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_REGISTERED',
        field: 'email',
      );
      await pumpRegister(tester, auth);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a banner', (tester) async {
      auth.registerFailure = const ApiFailure.network();
      await pumpRegister(tester, auth);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while a request is in flight', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpRegister(tester, auth);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Daftar'));

      await expectMeetsA11yGuidelines(tester);
    });

    for (final password in [
      'abc',
      'kopi tubruk',
      'kopi tubruk pa',
      'kopi tubruk pagi',
    ]) {
      testWidgets('meets the guidelines with the strength of "$password"', (
        tester,
      ) async {
        await pumpRegister(tester, auth);
        await type(tester, _password, password);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines with the passwords shown', (
      tester,
    ) async {
      await pumpRegister(tester, auth);
      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size in the initial state', (tester) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();
      goTo(tester, '/daftar');
      await tester.pumpAndSettle();

      expect(find.byType(RegisterOwnerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with errors and a strength line', (
      tester,
    ) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();
      goTo(tester, '/daftar');
      await tester.pumpAndSettle();

      await type(tester, _password, 'abc');
      await tapVisible(tester, buttonLabelled('Daftar'));

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a banner', (tester) async {
      auth.registerFailure = const ApiFailure.network();
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();
      goTo(tester, '/daftar');
      await tester.pumpAndSettle();
      await fill(tester);

      await tapVisible(tester, buttonLabelled('Daftar'));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
