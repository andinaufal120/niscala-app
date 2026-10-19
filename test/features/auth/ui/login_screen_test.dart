import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/register_owner_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
import 'auth_ui_helpers.dart';

const _email = 'Email (wajib)';
const _password = 'Kata sandi (wajib)';

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String email = 'budi@example.com',
  String password = 'rahasia panjang',
}) async {
  await typeInto(tester, _email, email);
  await typeInto(tester, _password, password);
  await tapVisible(tester, buttonLabelled('Masuk'));
}

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('content', () {
    testWidgets('shows the heading, subtitle, fields, toggle and buttons', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Masuk ke Niscala'), findsOneWidget);
      expect(find.text('Kelola Kost Tanpa Ribet'), findsOneWidget);
      expect(fieldLabeled(_email), findsOneWidget);
      expect(fieldLabeled(_password), findsOneWidget);
      expect(find.text('Tampilkan kata sandi'), findsOneWidget);
      expect(buttonLabelled('Masuk'), findsOneWidget);
      expect(find.text('Pemilik kost baru?'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
    });

    testWidgets('has no Google button and no forgotten password link yet', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(find.textContaining('Google'), findsNothing);
      expect(find.textContaining('Lupa'), findsNothing);
    });

    testWidgets('shows no error and no banner before the first submit', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(labeledFieldError(tester, _email), isNull);
      expect(labeledFieldError(tester, _password), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(auth.logins, isEmpty);
    });

    testWidgets('starts with the password hidden and the toggle off', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(labeledTextField(tester, _password).obscureText, isTrue);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(labeledTextField(tester, _email).obscureText, isFalse);
    });
  });

  group('show password', () {
    testWidgets('toggling the checkbox reveals and hides the password', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _password).obscureText, isFalse);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _password).obscureText, isTrue);
    });

    testWidgets('keeps the typed password when toggled', (tester) async {
      await pumpLogin(tester, auth);
      await typeInto(tester, _password, 'rahasia panjang');

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();

      expect(find.text('rahasia panjang'), findsOneWidget);
    });

    testWidgets('is a labelled checkbox of at least 48 dp', (tester) async {
      await pumpLogin(tester, auth);
      expectShowPasswordCheckbox(tester, checked: false);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();
      expectShowPasswordCheckbox(tester, checked: true);
    });
  });

  group('validation', () {
    testWidgets('an empty form names both fields and sends nothing', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(labeledFieldError(tester, _email), 'Masukkan email.');
      expect(labeledFieldError(tester, _password), 'Masukkan kata sandi.');
      expect(auth.logins, isEmpty);
    });

    testWidgets('a blank email counts as empty', (tester) async {
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester, email: '   ');

      expect(labeledFieldError(tester, _email), 'Masukkan email.');
      expect(auth.logins, isEmpty);
    });

    for (final bad in [
      'budi',
      'budi@',
      'budi@example',
      '@example.com',
      'a b@c.d',
    ]) {
      testWidgets('rejects the email "$bad" without a request', (tester) async {
        await pumpLogin(tester, auth);

        await fillAndSubmit(tester, email: bad);

        expect(labeledFieldError(tester, _email), 'Format email tidak valid.');
        expect(labeledFieldError(tester, _password), isNull);
        expect(auth.logins, isEmpty);
      });
    }

    testWidgets('an empty password is the only error when the email is fine', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester, password: '');

      expect(labeledFieldError(tester, _email), isNull);
      expect(labeledFieldError(tester, _password), 'Masukkan kata sandi.');
      expect(auth.logins, isEmpty);
    });

    testWidgets('errors disappear once the form is valid and resubmitted', (
      tester,
    ) async {
      await pumpLogin(tester, auth);
      await tapVisible(tester, buttonLabelled('Masuk'));

      await fillAndSubmit(tester);

      expect(auth.logins, hasLength(1));
      expect(find.text('Masukkan email.'), findsNothing);
      expect(find.text('Masukkan kata sandi.'), findsNothing);
    });
  });

  group('submit', () {
    testWidgets('sends the trimmed email and the untouched password', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await fillAndSubmit(
        tester,
        email: '  budi@example.com  ',
        password: ' rahasia panjang ',
      );

      expect(auth.logins, hasLength(1));
      expect(auth.logins.single.email, 'budi@example.com');
      expect(auth.logins.single.password, ' rahasia panjang ');
    });

    testWidgets(
      'a verified owner lands on the home tab of the management shell',
      (tester) async {
        final store = await pumpLogin(tester, auth);

        await fillAndSubmit(tester);

        expect(currentPath(tester), '/beranda');
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(store.stored?.role, UserRole.owner);
        expect(store.stored?.emailVerified, isTrue);
        expect(store.stored?.accessToken, auth.loginResult.accessToken);
        final session = containerOf(tester).read(sessionControllerProvider);
        expect(session, isA<SignedIn>());
      },
    );

    testWidgets('a verified tenant lands on the tenant home', (tester) async {
      auth.loginResult = authSessionFor(UserRole.tenant);
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester);

      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('an unverified owner is taken to email verification', (
      tester,
    ) async {
      auth.loginResult = authSessionFor(UserRole.owner, emailVerified: false);
      final store = await pumpLogin(tester, auth);

      await fillAndSubmit(tester);

      expect(currentPath(tester), '/verifikasi-email');
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(store.stored?.emailVerified, isFalse);
    });

    testWidgets('the Daftar link opens the sign up screen', (tester) async {
      await pumpLogin(tester, auth);

      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/daftar');
      expect(find.byType(RegisterOwnerScreen), findsOneWidget);
    });
  });

  group('failures', () {
    final cases = {
      'INVALID_CREDENTIALS': errorMessage('INVALID_CREDENTIALS'),
      'TOO_MANY_LOGIN_ATTEMPTS': errorMessage('TOO_MANY_LOGIN_ATTEMPTS'),
      'NETWORK_ERROR': errorMessage('NETWORK_ERROR'),
      'INTERNAL_ERROR': errorMessage('INTERNAL_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };

    for (final entry in cases.entries) {
      testWidgets('shows the banner for ${entry.key}', (tester) async {
        auth.loginFailure = ApiFailure(code: entry.key);
        await pumpLogin(tester, auth);

        await fillAndSubmit(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(currentPath(tester), '/masuk');
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    }

    testWidgets('never shows the English message of the API', (tester) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester);

      expect(find.textContaining('Invalid'), findsNothing);
      expect(find.textContaining('INVALID_CREDENTIALS'), findsNothing);
    });

    testWidgets('keeps the banner on screen until the next submit', (
      tester,
    ) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth);
      await fillAndSubmit(tester);
      final message = errorMessage('INVALID_CREDENTIALS');

      await tester.pump(const Duration(seconds: 30));
      expect(find.text(message), findsOneWidget);

      await typeInto(tester, _password, 'diubah');
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('exposes the banner as a live region', (tester) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester);

      expectLiveRegion(tester, errorMessage('INVALID_CREDENTIALS'));
    });

    testWidgets('removes the banner while the next request is in flight', (
      tester,
    ) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth);
      await fillAndSubmit(tester);
      auth.gate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Masuk'));

      expect(find.text(errorMessage('INVALID_CREDENTIALS')), findsNothing);
      expect(auth.logins, hasLength(2));
    });

    testWidgets(
      'lets the user try again with the same values after a failure',
      (tester) async {
        auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
        await pumpLogin(tester, auth);
        await fillAndSubmit(tester);
        auth.loginFailure = null;

        await tapVisible(tester, buttonLabelled('Masuk'));

        expect(auth.logins, hasLength(2));
        expect(auth.logins.last.email, 'budi@example.com');
        expect(currentPath(tester), '/beranda');
      },
    );

    testWidgets('keeps the typed email after a failure', (tester) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester);

      expect(find.text('budi@example.com'), findsOneWidget);
    });
  });

  group('while a request is in flight', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpLogin(tester, auth);

      await typeInto(tester, _email, 'budi@example.com');
      await typeInto(tester, _password, 'rahasia panjang');
      await tapAndPump(tester, buttonLabelled('Masuk'));

      expectBusy(tester);
      expect(find.text('Masuk'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      auth.gate = Completer<void>();
      await pumpLogin(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await typeInto(tester, _password, 'rahasia panjang');
      final button = buttonLabelled('Masuk');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.logins, hasLength(1));
    });

    testWidgets('restores the button when the request fails', (tester) async {
      auth.gate = Completer<void>();
      auth.loginFailure = const ApiFailure(code: 'NETWORK_ERROR');
      await pumpLogin(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await typeInto(tester, _password, 'rahasia panjang');
      await tapAndPump(tester, buttonLabelled('Masuk'));

      auth.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled('Masuk')).onPressed,
        isNotNull,
      );
    });
  });

  group('authentication rules', () {
    testWidgets('the email field keeps paste on and offers email autofill', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expectLabeledCredentialField(tester, _email, AutofillHints.email);
    });

    testWidgets(
      'the password field keeps paste on and offers password autofill',
      (tester) async {
        await pumpLogin(tester, auth);

        expectLabeledCredentialField(tester, _password, AutofillHints.password);
      },
    );

    testWidgets('both fields share one autofill group', (tester) async {
      await pumpLogin(tester, auth);

      final groups = find.byType(AutofillGroup);
      expect(
        find.descendant(of: groups.first, matching: fieldLabeled(_email)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: groups.first, matching: fieldLabeled(_password)),
        findsOneWidget,
      );
    });
  });

  group('structure', () {
    testWidgets('wraps both fields in a LabeledField with the marker', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(labeledField(_email), findsOneWidget);
      expect(labeledField(_password), findsOneWidget);
      expect(find.text(_email), findsOneWidget);
      expect(find.text(_password), findsOneWidget);
    });

    testWidgets('draws no label inside any field', (tester) async {
      await pumpLogin(tester, auth);

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts each label above its field', (tester) async {
      await pumpLogin(tester, auth);

      for (final label in [_email, _password]) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top));
      }
    });

    testWidgets('reads each field label once, on the field', (tester) async {
      await pumpLogin(tester, auth);

      expectFieldNode(tester, _email);
      expectFieldNode(tester, _password);
    });

    testWidgets('keeps a field error on the field node', (tester) async {
      await pumpLogin(tester, auth);
      await tapVisible(tester, buttonLabelled('Masuk'));

      expectFieldNode(tester, _email, error: 'Masukkan email.');
      expectFieldNode(tester, _password, error: 'Masukkan kata sandi.');
    });

    testWidgets('keeps the format error on the email field node', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await fillAndSubmit(tester, email: 'budi');

      expectFieldNode(tester, _email, error: 'Format email tidak valid.');
    });

    testWidgets('tapping a label focuses its field', (tester) async {
      await pumpLogin(tester, auth);

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

    testWidgets('shows the N logo tile above the heading', (tester) async {
      await pumpLogin(tester, auth);

      expect(find.text('N'), findsOneWidget);
      final logo = tester.getRect(find.text('N'));
      final heading = tester.getRect(find.text('Masuk ke Niscala'));
      expect(logo.bottom, lessThanOrEqualTo(heading.top));
    });

    testWidgets('keeps the logo tile out of the semantics tree', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      final handle = tester.ensureSemantics();
      try {
        final labels = allSemanticsNodes(tester).map((n) => n.label);
        expect(labels, isNot(contains('N')));
        expect(find.bySemanticsLabel('N'), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the heading is a semantic header', (tester) async {
      await pumpLogin(tester, auth);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Masuk ke Niscala')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the invitation note above its activation link', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      const note =
          'Penyewa dan pengelola kost mengaktifkan akun lewat tautan undangan '
          'dari pemilik kost.';
      expect(find.text(note), findsOneWidget);
      expect(find.text('Aktifkan dengan tautan undangan'), findsOneWidget);
      final submit = tester.getRect(buttonLabelled('Masuk'));
      final noteRect = tester.getRect(find.text(note));
      final link = tester.getRect(find.text('Aktifkan dengan tautan undangan'));
      expect(noteRect.top, greaterThanOrEqualTo(submit.bottom));
      expect(link.top, greaterThanOrEqualTo(noteRect.bottom - 1));
    });

    testWidgets('pins the invitation note and link near the bottom', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      final link = tester.getRect(find.text('Aktifkan dengan tautan undangan'));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(link.bottom, greaterThan(screen.height * 0.9));
    });

    testWidgets('the activation link opens the activation screen', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await tapVisible(tester, find.text('Aktifkan dengan tautan undangan'));

      expect(currentPath(tester), '/aktivasi');
    });

    testWidgets('the activation link is a labelled button of 48 dp', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(
          find.text('Aktifkan dengan tautan undangan'),
        );
        expect(
          node,
          isSemantics(
            label: 'Aktifkan dengan tautan undangan',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('still reaches the activation link at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Aktifkan dengan tautan undangan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Aktifkan dengan tautan undangan'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines in the initial state', (tester) async {
      await pumpLogin(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with field errors', (tester) async {
      await pumpLogin(tester, auth);
      await tapVisible(tester, buttonLabelled('Masuk'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a banner', (tester) async {
      auth.loginFailure = const ApiFailure(code: 'INVALID_CREDENTIALS');
      await pumpLogin(tester, auth);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while a request is in flight', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpLogin(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await typeInto(tester, _password, 'rahasia panjang');
      await tapAndPump(tester, buttonLabelled('Masuk'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the password shown', (tester) async {
      await pumpLogin(tester, auth);
      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('every tappable control is at least 48 dp', (tester) async {
      await pumpLogin(tester, auth);

      final count = anyButton().evaluate().length;
      expect(count, greaterThanOrEqualTo(1));
      for (var i = 0; i < count; i++) {
        final size = tester.getSize(anyButton().at(i));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      final handle = tester.ensureSemantics();
      final link = tester.getSemantics(find.text('Daftar')).rect;
      handle.dispose();
      expect(link.height, greaterThanOrEqualTo(48));
    });

    testWidgets('fits at large text size in the initial state', (tester) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('fits at large text size with errors and a banner', (
      tester,
    ) async {
      auth.loginFailure = const ApiFailure(code: 'TOO_MANY_LOGIN_ATTEMPTS');
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();

      await tapVisible(tester, buttonLabelled('Masuk'));
      expect(tester.takeException(), isNull);

      await typeInto(tester, _email, 'budi@example.com');
      await typeInto(tester, _password, 'rahasia panjang');
      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(
        find.text(errorMessage('TOO_MANY_LOGIN_ATTEMPTS')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size while a request is in flight', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();
      await typeInto(tester, _email, 'budi@example.com');
      await typeInto(tester, _password, 'rahasia panjang');

      await tester.scrollUntilVisible(
        buttonLabelled('Masuk'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tapAndPump(tester, buttonLabelled('Masuk'));

      expect(tester.takeException(), isNull);
      expect(busyButton(), findsOneWidget);
    });
  });
}
