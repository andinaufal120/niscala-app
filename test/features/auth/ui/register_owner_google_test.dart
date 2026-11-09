import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
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
const _google = 'Daftar dengan Google';
const _divider = 'atau dengan email';

Finder _googleButton() => buttonLabelled(_google);

/// The password submit button, whether it shows its label or the progress
/// indicator.
Finder _submitButton() {
  final labelled = buttonLabelled('Daftar');
  return labelled.evaluate().isNotEmpty ? labelled : busyButton();
}

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

Future<void> _tapGoogle(WidgetTester tester) =>
    tapVisible(tester, _googleButton());

Future<void> _pumpLargeText(
  WidgetTester tester,
  FakeAuthRepository auth,
  FakeGoogleIdentity google,
) async {
  await pumpAtLargeText(tester, buildTestApp(auth: auth, google: google));
  await tester.pumpAndSettle();
  goTo(tester, '/daftar');
  await tester.pumpAndSettle();
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
      await pumpRegister(tester, auth, google: google);

      expect(find.byType(RegisterOwnerScreen), findsOneWidget);
      expect(_googleButton(), findsOneWidget);
      expect(find.text(_divider), findsOneWidget);
      expect(google.requests, 0);
      expect(auth.googleRegistrations, isEmpty);
    });

    testWidgets('puts the Google button above the divider and the fields', (
      tester,
    ) async {
      await pumpRegister(tester, auth, google: google);

      final button = tester.getRect(_googleButton());
      final divider = tester.getRect(find.text(_divider));
      final nameLabel = tester.getRect(find.text(_name));
      expect(button.bottom, lessThanOrEqualTo(divider.top));
      expect(divider.bottom, lessThanOrEqualTo(nameLabel.top));
    });

    testWidgets('keeps the email form and its button', (tester) async {
      await pumpRegister(tester, auth, google: google);

      for (final label in [_name, _email, _password, _confirm]) {
        expect(field(label), findsOneWidget);
      }
      expect(buttonLabelled('Daftar'), findsOneWidget);
    });

    testWidgets('the Google button is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await pumpRegister(tester, auth, google: google);

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
  });

  group('signing up with Google', () {
    testWidgets('sends the ID token and no name when the name is empty', (
      tester,
    ) async {
      google.token = 'token-abc';
      await pumpRegister(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(auth.googleRegistrations, hasLength(1));
      expect(auth.googleRegistrations.single.idToken, 'token-abc');
      expect(auth.googleRegistrations.single.name?.trim() ?? '', isEmpty);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('does not validate the email form', (tester) async {
      await pumpRegister(tester, auth, google: google);

      await _tapGoogle(tester);

      for (final label in [_name, _email, _password, _confirm]) {
        expect(fieldError(tester, label), isNull);
      }
      expect(auth.googleRegistrations, hasLength(1));
    });

    testWidgets('ignores a typed email and password', (tester) async {
      await pumpRegister(tester, auth, google: google);
      await type(tester, _email, 'budi');
      await type(tester, _password, 'x');

      await _tapGoogle(tester);

      expect(auth.googleRegistrations, hasLength(1));
      expect(auth.registrations, isEmpty);
      expect(fieldError(tester, _email), isNull);
      expect(fieldError(tester, _password), isNull);
    });

    testWidgets('sends the typed full name', (tester) async {
      await pumpRegister(tester, auth, google: google);
      await type(tester, _name, 'Budi Santoso');

      await _tapGoogle(tester);

      expect(auth.googleRegistrations.single.name, 'Budi Santoso');
    });

    testWidgets('sends the full name without surrounding spaces', (
      tester,
    ) async {
      await pumpRegister(tester, auth, google: google);
      await type(tester, _name, '   Budi Santoso  ');

      await _tapGoogle(tester);

      expect(auth.googleRegistrations.single.name?.trim(), 'Budi Santoso');
    });

    testWidgets('a blank name is sent as no name', (tester) async {
      await pumpRegister(tester, auth, google: google);
      await type(tester, _name, '    ');

      await _tapGoogle(tester);

      expect(auth.googleRegistrations.single.name?.trim() ?? '', isEmpty);
    });

    testWidgets('starts a verified session without email verification', (
      tester,
    ) async {
      final store = await pumpRegister(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/beranda');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(VerifyEmailScreen), findsNothing);
      expect(find.byType(RegisterOwnerScreen), findsNothing);
      expect(store.stored?.role, UserRole.owner);
      expect(store.stored?.emailVerified, isTrue);
      expect(store.stored?.accessToken, auth.googleRegisterResult.accessToken);
      expect(
        store.stored?.refreshToken,
        auth.googleRegisterResult.refreshToken,
      );
    });
  });

  group('cancelling the Google chooser', () {
    testWidgets('does nothing and shows no error', (tester) async {
      google.token = null;
      await pumpRegister(tester, auth, google: google);
      await type(tester, _name, 'Budi Santoso');

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(auth.googleRegistrations, isEmpty);
      expect(currentPath(tester), '/daftar');
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text(genericErrorMessage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, buttonLabelled('Daftar')), isTrue);
    });
  });

  group('when the Google ID token cannot be obtained', () {
    testWidgets('shows that Google sign-in is not available', (tester) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await pumpRegister(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.text('Masuk dengan Google belum tersedia.'), findsOneWidget);
      expect(auth.googleRegistrations, isEmpty);
      expect(currentPath(tester), '/daftar');
    });

    testWidgets('shows the generic message for any other error', (
      tester,
    ) async {
      google.failure = Exception('plugin broke');
      await pumpRegister(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.text(genericErrorMessage), findsOneWidget);
      expect(find.textContaining('plugin broke'), findsNothing);
    });
  });

  group('failures from the server', () {
    final cases = {
      'GOOGLE_ACCOUNT_ALREADY_REGISTERED':
          'Akun Google ini sudah terdaftar. Masuk dengan Google.',
      'EMAIL_ALREADY_REGISTERED': messageOfCode('EMAIL_ALREADY_REGISTERED'),
      'GOOGLE_EMAIL_UNVERIFIED': 'Email akun Google ini belum terverifikasi.',
      'GOOGLE_TOKEN_INVALID': 'Masuk dengan Google gagal. Coba lagi.',
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': genericErrorMessage,
    };

    for (final entry in cases.entries) {
      testWidgets('shows the message for ${entry.key}', (tester) async {
        auth.googleRegisterFailure = ApiFailure(code: entry.key);
        await pumpRegister(tester, auth, google: google);

        await _tapGoogle(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(currentPath(tester), '/daftar');
        expect(find.byType(RegisterOwnerScreen), findsOneWidget);
      });
    }

    testWidgets('never shows the code of the API', (tester) async {
      auth.googleRegisterFailure = const ApiFailure(
        code: 'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
      );
      await pumpRegister(tester, auth, google: google);

      await _tapGoogle(tester);

      expect(find.textContaining('GOOGLE_ACCOUNT'), findsNothing);
    });

    testWidgets('keeps the message on screen and announces it', (tester) async {
      auth.googleRegisterFailure = const ApiFailure(
        code: 'GOOGLE_EMAIL_UNVERIFIED',
      );
      await pumpRegister(tester, auth, google: google);
      await _tapGoogle(tester);

      await tester.pump(const Duration(seconds: 30));

      const message = 'Email akun Google ini belum terverifikasi.';
      expect(find.text(message), findsOneWidget);
      expectLiveRegion(tester, message);
    });

    testWidgets('removes the message while the next request is in flight', (
      tester,
    ) async {
      auth.googleRegisterFailure = const ApiFailure(
        code: 'GOOGLE_TOKEN_INVALID',
      );
      await pumpRegister(tester, auth, google: google);
      await _tapGoogle(tester);
      auth.googleGate = Completer<void>();

      await tapAndPump(tester, _googleButton());

      expect(find.text(messageOfCode('GOOGLE_TOKEN_INVALID')), findsNothing);
      expect(auth.googleRegistrations, hasLength(2));
    });

    testWidgets('keeps the typed name and lets the user try again', (
      tester,
    ) async {
      auth.googleRegisterFailure = const ApiFailure(code: 'NETWORK_ERROR');
      await pumpRegister(tester, auth, google: google);
      await type(tester, _name, 'Budi Santoso');
      await _tapGoogle(tester);
      expect(find.text('Budi Santoso'), findsOneWidget);
      auth.googleRegisterFailure = null;

      await _tapGoogle(tester);

      expect(auth.googleRegistrations, hasLength(2));
      expect(auth.googleRegistrations.last.name, 'Budi Santoso');
      expect(currentPath(tester), '/beranda');
    });
  });

  group('while a request is in flight', () {
    testWidgets('waiting for the Google chooser disables both actions', (
      tester,
    ) async {
      google.gate = Completer<void>();
      await pumpRegister(tester, auth, google: google);

      await tapAndPump(tester, _googleButton());

      expect(google.requests, 1);
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _submitButton()), isFalse);
      google.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('waiting for the server disables both actions', (tester) async {
      auth.googleGate = Completer<void>();
      await pumpRegister(tester, auth, google: google);

      await tapAndPump(tester, _googleButton());

      expect(auth.googleRegistrations, hasLength(1));
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _submitButton()), isFalse);
      auth.googleGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('an email sign-up in flight disables the Google button', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpRegister(tester, auth, google: google);
      await type(tester, _name, 'Budi Santoso');
      await type(tester, _email, 'budi@example.com');
      await type(tester, _password, 'kopi tubruk pagi');
      await type(tester, _confirm, 'kopi tubruk pagi');

      await tapAndPump(tester, buttonLabelled('Daftar'));

      expect(auth.registrations, hasLength(1));
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _submitButton()), isFalse);
      auth.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a second tap sends one request', (tester) async {
      auth.googleGate = Completer<void>();
      await pumpRegister(tester, auth, google: google);

      await tapAndPump(tester, _googleButton());
      if (_googleButton().evaluate().isNotEmpty) {
        await tester.tap(_googleButton(), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      expect(auth.googleRegistrations, hasLength(1));
      auth.googleGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('restores both actions when the request fails', (tester) async {
      auth.googleGate = Completer<void>();
      auth.googleRegisterFailure = const ApiFailure(code: 'NETWORK_ERROR');
      await pumpRegister(tester, auth, google: google);
      await tapAndPump(tester, _googleButton());

      auth.googleGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, buttonLabelled('Daftar')), isTrue);
    });
  });

  group('availability', () {
    testWidgets('is reachable at large text size', (tester) async {
      await _pumpLargeText(tester, auth, google);

      await tapVisible(tester, _googleButton());

      expect(tester.takeException(), isNull);
      expect(auth.googleRegistrations, hasLength(1));
    });

    testWidgets('is reachable with the keyboard open at large text size', (
      tester,
    ) async {
      await _pumpLargeText(tester, auth, google);
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tapVisible(tester, _googleButton());

      expect(tester.takeException(), isNull);
      expect(auth.googleRegistrations, hasLength(1));
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines in the initial state', (tester) async {
      await pumpRegister(tester, auth, google: google);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a Google failure message', (
      tester,
    ) async {
      auth.googleRegisterFailure = const ApiFailure(
        code: 'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
      );
      await pumpRegister(tester, auth, google: google);
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while a Google request is in flight', (
      tester,
    ) async {
      auth.googleGate = Completer<void>();
      await pumpRegister(tester, auth, google: google);
      await tapAndPump(tester, _googleButton());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size in the initial state', (tester) async {
      await _pumpLargeText(tester, auth, google);

      expect(tester.takeException(), isNull);
      expect(find.byType(RegisterOwnerScreen), findsOneWidget);
    });

    testWidgets('fits at large text size with a Google failure message', (
      tester,
    ) async {
      auth.googleRegisterFailure = const ApiFailure(
        code: 'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
      );
      await _pumpLargeText(tester, auth, google);

      await tapVisible(tester, _googleButton());

      expect(
        find.text('Akun Google ini sudah terdaftar. Masuk dengan Google.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
