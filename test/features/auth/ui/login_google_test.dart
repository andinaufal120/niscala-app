import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';

const _email = 'Email (wajib)';
const _password = 'Kata sandi (wajib)';
const _google = 'Masuk dengan Google';
const _divider = 'atau dengan email';
const _notRegistered =
    'Akun Google ini belum terdaftar. Daftar atau aktifkan akun lewat tautan '
    'undangan dulu.';

Finder _googleButton() => buttonLabelled(_google);

/// The password submit button, whether it shows its label or the progress
/// indicator.
Finder _submitButton() {
  final labelled = buttonLabelled('Masuk');
  return labelled.evaluate().isNotEmpty ? labelled : busyButton();
}

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

Future<void> _tapGoogle(WidgetTester tester) =>
    tapVisible(tester, _googleButton());

Future<void> _fillPasswordForm(WidgetTester tester) async {
  await type(tester, _email, 'budi@example.com');
  await type(tester, _password, 'rahasia panjang');
}

void main() {
  late FakeAuthRepository auth;
  late FakeGoogleIdentity google;

  setUp(() {
    auth = FakeAuthRepository();
    google = FakeGoogleIdentity();
  });

  group('content', () {
    testWidgets('offers the Google button and the email divider', (
      tester,
    ) async {
      await pumpLogin(tester, auth, google: google);

      expect(_googleButton(), findsOneWidget);
      expect(find.text(_divider), findsOneWidget);
      expect(google.requests, 0);
      expect(auth.googleLogins, isEmpty);
    });

    testWidgets('puts the Google button above the divider and the form', (
      tester,
    ) async {
      await pumpLogin(tester, auth, google: google);

      final button = tester.getRect(_googleButton());
      final divider = tester.getRect(find.text(_divider));
      final emailLabel = tester.getRect(find.text(_email));
      expect(button.bottom, lessThanOrEqualTo(divider.top));
      expect(divider.bottom, lessThanOrEqualTo(emailLabel.top));
    });

    testWidgets('keeps the password button and the other entry points', (
      tester,
    ) async {
      await pumpLogin(tester, auth, google: google);

      expect(buttonLabelled('Masuk'), findsOneWidget);
      expect(buttonLabelled('Lupa kata sandi?'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(buttonLabelled('Aktifkan dengan tautan undangan'), findsOneWidget);
    });

    testWidgets('the Google button is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await pumpLogin(tester, auth, google: google);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text(_google));
        expect(
          node,
          isSemantics(label: _google, isButton: true, hasTapAction: true),
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the divider text is not a tappable control', (tester) async {
      await pumpLogin(tester, auth, google: google);

      expect(buttonLabelled(_divider), findsNothing);
    });
  });

  group('signing in with Google', () {
    testWidgets('sends the ID token of the chosen account', (tester) async {
      google.token = 'token-abc';
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(auth.googleLogins, ['token-abc']);
      expect(auth.logins, isEmpty);
    });

    testWidgets('needs no email or password', (tester) async {
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(auth.googleLogins, hasLength(1));
      expect(find.text('Masukkan email.'), findsNothing);
      expect(find.text('Masukkan kata sandi.'), findsNothing);
    });

    testWidgets('ignores what is typed in the email form', (tester) async {
      await pumpLogin(tester, auth, google: google);
      await type(tester, _email, 'budi');

      await _tapGoogle(tester);

      expect(auth.googleLogins, hasLength(1));
      expect(find.text('Format email tidak valid.'), findsNothing);
      expect(auth.logins, isEmpty);
    });

    testWidgets('a verified owner lands on the home tab of the shell', (
      tester,
    ) async {
      final store = await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/beranda');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(store.stored?.role, UserRole.owner);
      expect(store.stored?.emailVerified, isTrue);
      expect(store.stored?.accessToken, auth.googleLoginResult.accessToken);
      expect(store.stored?.refreshToken, auth.googleLoginResult.refreshToken);
      expect(
        containerOf(tester).read(sessionControllerProvider),
        isA<SignedIn>(),
      );
    });

    testWidgets('a tenant lands on the tenant home', (tester) async {
      auth.googleLoginResult = authSessionFor(UserRole.tenant);
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('a manager lands on the management home', (tester) async {
      auth.googleLoginResult = authSessionFor(UserRole.manager);
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/beranda');
    });

    testWidgets('an admin lands on the admin screen', (tester) async {
      auth.googleLoginResult = authSessionFor(UserRole.admin);
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/admin');
    });

    testWidgets('a session without a verified email is routed like password '
        'login', (tester) async {
      auth.googleLoginResult = authSessionFor(
        UserRole.owner,
        emailVerified: false,
      );
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/verifikasi-email');
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });
  });

  group('cancelling the Google chooser', () {
    testWidgets('does nothing and shows no error', (tester) async {
      google.token = null;
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(auth.googleLogins, isEmpty);
      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(messageOfCode('GOOGLE_TOKEN_INVALID')), findsNothing);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsNothing);
      expect(find.text(genericErrorMessage), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('leaves both sign-in buttons usable', (tester) async {
      google.token = null;
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, buttonLabelled('Masuk')), isTrue);
    });

    testWidgets('lets the user try again', (tester) async {
      google.token = null;
      await pumpLogin(tester, auth, google: google);
      await _tapGoogle(tester);
      google.token = 'token-2';

      await _tapGoogle(tester);

      expect(google.requests, 2);
      expect(auth.googleLogins, ['token-2']);
      expect(currentPath(tester), '/beranda');
    });
  });

  group('when the Google ID token cannot be obtained', () {
    testWidgets('shows that Google sign-in is not available', (tester) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.text('Masuk dengan Google belum tersedia.'), findsOneWidget);
      expect(auth.googleLogins, isEmpty);
      expect(currentPath(tester), '/masuk');
    });

    testWidgets('shows the generic message for any other error', (
      tester,
    ) async {
      google.failure = Exception('plugin broke');
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.text(genericErrorMessage), findsOneWidget);
      expect(find.textContaining('plugin broke'), findsNothing);
      expect(auth.googleLogins, isEmpty);
    });

    testWidgets('restores both buttons', (tester) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, buttonLabelled('Masuk')), isTrue);
    });
  });

  group('failures from the server', () {
    final cases = {
      'GOOGLE_TOKEN_INVALID': 'Masuk dengan Google gagal. Coba lagi.',
      'INVALID_CREDENTIALS': _notRegistered,
      'ACCOUNT_INACTIVE': 'Akun ini dinonaktifkan. Hubungi admin.',
      'TOO_MANY_LOGIN_ATTEMPTS': messageOfCode('TOO_MANY_LOGIN_ATTEMPTS'),
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': genericErrorMessage,
    };

    for (final entry in cases.entries) {
      testWidgets('shows the banner for ${entry.key}', (tester) async {
        auth.googleLoginFailure = ApiFailure(code: entry.key);
        await pumpLogin(tester, auth, google: google);

        await _tapGoogle(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(currentPath(tester), '/masuk');
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    }

    testWidgets('an unknown Google account does not get the password wording', (
      tester,
    ) async {
      auth.googleLoginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.text(messageOfCode('INVALID_CREDENTIALS')), findsNothing);
    });

    testWidgets('a wrong password still gets the password wording', (
      tester,
    ) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth, google: google);
      await _fillPasswordForm(tester);

      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
      expect(find.text(_notRegistered), findsNothing);
    });

    testWidgets('a deactivated account is explained on password login too', (
      tester,
    ) async {
      auth.loginFailure = const ApiFailure(code: 'ACCOUNT_INACTIVE');
      await pumpLogin(tester, auth, google: google);
      await _fillPasswordForm(tester);

      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(
        find.text('Akun ini dinonaktifkan. Hubungi admin.'),
        findsOneWidget,
      );
    });

    testWidgets('never shows the English text or the code of the API', (
      tester,
    ) async {
      auth.googleLoginFailure = const ApiFailure(code: 'GOOGLE_TOKEN_INVALID');
      await pumpLogin(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.textContaining('GOOGLE_TOKEN_INVALID'), findsNothing);
      expect(find.textContaining('Invalid'), findsNothing);
    });

    testWidgets('keeps the banner until the next request and announces it', (
      tester,
    ) async {
      auth.googleLoginFailure = const ApiFailure(code: 'GOOGLE_TOKEN_INVALID');
      await pumpLogin(tester, auth, google: google);
      await _tapGoogle(tester);
      const message = 'Masuk dengan Google gagal. Coba lagi.';

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(message), findsOneWidget);
      expectLiveRegion(tester, message);
    });

    testWidgets('removes the banner while the next request is in flight', (
      tester,
    ) async {
      auth.googleLoginFailure = const ApiFailure(code: 'GOOGLE_TOKEN_INVALID');
      await pumpLogin(tester, auth, google: google);
      await _tapGoogle(tester);
      auth.googleGate = Completer<void>();

      await tapAndPump(tester, _googleButton());

      expect(find.text(messageOfCode('GOOGLE_TOKEN_INVALID')), findsNothing);
      expect(auth.googleLogins, hasLength(2));
    });

    testWidgets('lets the user try again after a failure', (tester) async {
      auth.googleLoginFailure = const ApiFailure(code: 'NETWORK_ERROR');
      await pumpLogin(tester, auth, google: google);
      await _tapGoogle(tester);
      auth.googleLoginFailure = null;

      await _tapGoogle(tester);

      expect(auth.googleLogins, hasLength(2));
      expect(currentPath(tester), '/beranda');
    });

    testWidgets('keeps the typed email after a failure', (tester) async {
      auth.googleLoginFailure = const ApiFailure(code: 'GOOGLE_TOKEN_INVALID');
      await pumpLogin(tester, auth, google: google);
      await type(tester, _email, 'budi@example.com');

      await _tapGoogle(tester);

      expect(find.text('budi@example.com'), findsOneWidget);
    });
  });

  group('while a request is in flight', () {
    testWidgets('waiting for the Google chooser disables both actions', (
      tester,
    ) async {
      google.gate = Completer<void>();
      await pumpLogin(tester, auth, google: google);

      await tapAndPump(tester, _googleButton());

      expect(google.requests, 1);
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _submitButton()), isFalse);
      google.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('waiting for the server disables both actions', (tester) async {
      auth.googleGate = Completer<void>();
      await pumpLogin(tester, auth, google: google);

      await tapAndPump(tester, _googleButton());

      expect(auth.googleLogins, hasLength(1));
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _submitButton()), isFalse);
      auth.googleGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a password login in flight disables the Google button', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpLogin(tester, auth, google: google);
      await _fillPasswordForm(tester);

      await tapAndPump(tester, buttonLabelled('Masuk'));

      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _submitButton()), isFalse);
      auth.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a second tap sends one request', (tester) async {
      auth.googleGate = Completer<void>();
      await pumpLogin(tester, auth, google: google);

      await tapAndPump(tester, _googleButton());
      if (_googleButton().evaluate().isNotEmpty) {
        await tester.tap(_googleButton(), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      expect(auth.googleLogins, hasLength(1));
      auth.googleGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('restores both actions when the request fails', (tester) async {
      auth.googleGate = Completer<void>();
      auth.googleLoginFailure = const ApiFailure(code: 'NETWORK_ERROR');
      await pumpLogin(tester, auth, google: google);
      await tapAndPump(tester, _googleButton());

      auth.googleGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, buttonLabelled('Masuk')), isTrue);
    });
  });

  group('availability', () {
    testWidgets('is reachable at large text size', (tester) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth, google: google));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        _googleButton(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_googleButton());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(auth.googleLogins, hasLength(1));
    });

    testWidgets('is reachable with the keyboard open at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth, google: google));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        _googleButton(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_googleButton());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(auth.googleLogins, hasLength(1));
    });

    testWidgets('is still offered after a password login failure', (
      tester,
    ) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth, google: google);
      await _fillPasswordForm(tester);
      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(_googleButton(), findsOneWidget);
      expect(_enabled(tester, _googleButton()), isTrue);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines in the initial state', (tester) async {
      await pumpLogin(tester, auth, google: google);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a Google failure banner', (
      tester,
    ) async {
      auth.googleLoginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth, google: google);
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an unavailable banner', (
      tester,
    ) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await pumpLogin(tester, auth, google: google);
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while a Google request is in flight', (
      tester,
    ) async {
      auth.googleGate = Completer<void>();
      await pumpLogin(tester, auth, google: google);
      await tapAndPump(tester, _googleButton());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size in the initial state', (tester) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth, google: google));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('fits at large text size with a Google failure banner', (
      tester,
    ) async {
      auth.googleLoginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpAtLargeText(tester, buildTestApp(auth: auth, google: google));
      await tester.pumpAndSettle();

      await tapVisible(tester, _googleButton());

      expect(find.text(_notRegistered), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size while a request is in flight', (
      tester,
    ) async {
      auth.googleGate = Completer<void>();
      await pumpAtLargeText(tester, buildTestApp(auth: auth, google: google));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _googleButton(),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tapAndPump(tester, _googleButton());

      expect(tester.takeException(), isNull);
    });
  });
}
