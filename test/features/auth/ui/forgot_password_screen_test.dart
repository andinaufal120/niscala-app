import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/ui/forgot_password_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/reset_password_screen.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'auth_ui_helpers.dart';

const _email = 'Email (wajib)';
const _loginEmail = 'Email (wajib)';
const _confirmationTitle = 'Periksa email Anda';

Future<void> pumpForgot(WidgetTester tester, FakeAuthRepository auth) async {
  await pumpLogin(tester, auth);
  goTo(tester, '/lupa-kata-sandi');
  await tester.pumpAndSettle();
}

Future<void> pumpForgotAtLargeText(
  WidgetTester tester,
  FakeAuthRepository auth,
) async {
  await pumpAtLargeText(tester, buildTestApp(auth: auth));
  await tester.pumpAndSettle();
  goTo(tester, '/lupa-kata-sandi');
  await tester.pumpAndSettle();
}

Future<void> send(
  WidgetTester tester, {
  String email = 'budi@example.com',
}) async {
  await typeInto(tester, _email, email);
  await tapVisible(tester, buttonLabelled('Kirim Tautan'));
}

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('entry from the sign in screen', () {
    testWidgets('offers the link to reset a forgotten password', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(buttonLabelled('Lupa kata sandi?'), findsOneWidget);
    });

    testWidgets('the link opens the forgot password screen', (tester) async {
      await pumpLogin(tester, auth);

      await tapVisible(tester, find.text('Lupa kata sandi?'));

      expect(currentPath(tester), '/lupa-kata-sandi');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('the link is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text('Lupa kata sandi?'));
        expect(
          node,
          isSemantics(
            label: 'Lupa kata sandi?',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('does not carry the typed email over to the next screen', (
      tester,
    ) async {
      await pumpLogin(tester, auth);
      await typeInto(tester, _loginEmail, 'budi@example.com');

      await tapVisible(tester, find.text('Lupa kata sandi?'));

      expect(textField(tester, _email).controller?.text, isEmpty);
    });

    testWidgets('opening the link signs nobody in and calls nothing', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await tapVisible(tester, find.text('Lupa kata sandi?'));

      expect(auth.logins, isEmpty);
      expect(auth.passwordResetRequests, isEmpty);
    });

    testWidgets('the link is reachable at large text size', (tester) async {
      await pumpAtLargeText(tester, buildTestApp(auth: auth));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Lupa kata sandi?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
    });
  });

  group('form', () {
    testWidgets('shows the title, the labelled email field and the button', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Lupa kata sandi'),
        ),
        findsOneWidget,
      );
      expect(field(_email), findsOneWidget);
      expect(buttonLabelled('Kirim Tautan'), findsOneWidget);
      expect(find.text(_confirmationTitle), findsNothing);
    });

    testWidgets('starts empty without errors and calls nothing', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      expect(textField(tester, _email).controller?.text, isEmpty);
      expect(fieldError(tester, _email), isNull);
      expect(auth.passwordResetRequests, isEmpty);
    });

    testWidgets('the email field uses the email keyboard', (tester) async {
      await pumpForgot(tester, auth);

      expect(
        textField(tester, _email).keyboardType,
        TextInputType.emailAddress,
      );
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpForgot(tester, auth);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('an empty email asks for the email and sends nothing', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(auth.passwordResetRequests, isEmpty);
      expect(find.text(_confirmationTitle), findsNothing);
    });

    testWidgets('a blank email counts as empty', (tester) async {
      await pumpForgot(tester, auth);

      await send(tester, email: '   ');

      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(auth.passwordResetRequests, isEmpty);
    });

    for (final bad in [
      'budi',
      'budi@',
      'budi@example',
      '@example.com',
      'a b@c.d',
    ]) {
      testWidgets('rejects the email "$bad" without a request', (tester) async {
        await pumpForgot(tester, auth);

        await send(tester, email: bad);

        expect(fieldError(tester, _email), 'Format email tidak valid.');
        expect(auth.passwordResetRequests, isEmpty);
        expect(find.text(_confirmationTitle), findsNothing);
      });
    }

    testWidgets('the field error goes away on the next valid attempt', (
      tester,
    ) async {
      await pumpForgot(tester, auth);
      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      await send(tester);

      expect(auth.passwordResetRequests, ['budi@example.com']);
      expect(find.text('Email wajib diisi.'), findsNothing);
    });
  });

  group('submit', () {
    testWidgets('sends the trimmed email', (tester) async {
      await pumpForgot(tester, auth);

      await send(tester, email: '  budi@example.com \n');

      expect(auth.passwordResetRequests, ['budi@example.com']);
    });

    testWidgets('sends one request', (tester) async {
      await pumpForgot(tester, auth);

      await send(tester);

      expect(auth.passwordResetRequests, hasLength(1));
      expect(auth.logins, isEmpty);
    });

    testWidgets('signs nobody in and stays on the public route', (
      tester,
    ) async {
      final store = await pumpLogin(tester, auth);
      goTo(tester, '/lupa-kata-sandi');
      await tester.pumpAndSettle();

      await send(tester);

      expect(currentPath(tester), '/lupa-kata-sandi');
      expect(store.stored, isNull);
    });
  });

  group('confirmation', () {
    testWidgets('replaces the form with the confirmation and keeps the title', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.text(_confirmationTitle), findsOneWidget);
      expect(field(_email), findsNothing);
      expect(buttonLabelled('Kirim Tautan'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Lupa kata sandi'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says a link was sent to a registered email for 30 minutes', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.textContaining('terdaftar'), findsOneWidget);
      expect(find.textContaining('30 menit'), findsOneWidget);
    });

    for (final entered in [
      'terdaftar@example.com',
      'tidak.dikenal@example.com',
    ]) {
      testWidgets('does not echo the entered email "$entered"', (tester) async {
        await pumpForgot(tester, auth);

        await send(tester, email: entered);

        expect(find.text(_confirmationTitle), findsOneWidget);
        expect(
          _textsOnScreen(tester).where((text) => text.contains(entered)),
          isEmpty,
        );
      });
    }

    testWidgets('does not tell whether the email is registered', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.textContaining('tidak terdaftar'), findsNothing);
      expect(find.textContaining('tidak ditemukan'), findsNothing);
    });

    testWidgets('the title is a semantic header', (tester) async {
      await pumpForgot(tester, auth);
      await send(tester);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text(_confirmationTitle)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('offers to continue with the emailed link', (tester) async {
      await pumpForgot(tester, auth);
      await send(tester);

      await tapVisible(tester, buttonLabelled('Atur ulang dengan tautan'));

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('offers a way back to the sign in screen', (tester) async {
      await pumpForgot(tester, auth);
      await send(tester);

      await tapVisible(tester, buttonLabelled('Kembali ke Masuk'));

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('the back button still returns to the sign in screen', (
      tester,
    ) async {
      await pumpForgot(tester, auth);
      await send(tester);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
    });

    testWidgets('stays on screen and is not a snack bar', (tester) async {
      await pumpForgot(tester, auth);
      await send(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_confirmationTitle), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('failures', () {
    final bannerCases = {
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };
    for (final entry in bannerCases.entries) {
      testWidgets('${entry.key} is shown in the form, not as a snack bar', (
        tester,
      ) async {
        auth.requestPasswordResetFailure = ApiFailure(code: entry.key);
        await pumpForgot(tester, auth);

        await send(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text(_confirmationTitle), findsNothing);
        expect(fieldError(tester, _email), isNull);
        expect(buttonLabelled('Kirim Tautan'), findsOneWidget);
        expect(currentPath(tester), '/lupa-kata-sandi');
      });
    }

    testWidgets('a server error with status 500 is shown in the form', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('keeps the typed email after a failure', (tester) async {
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.text('budi@example.com'), findsOneWidget);
    });

    testWidgets('the banner stays and is a live region', (tester) async {
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgot(tester, auth);
      await send(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('never shows the English text or the code of the API', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.textContaining('INTERNAL'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
    });

    testWidgets('a validation failure on email is shown on the email field', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'email',
        statusCode: 422,
      );
      await pumpForgot(tester, auth);

      await send(tester);

      expect(fieldError(tester, _email), 'Email tidak valid.');
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
      expect(find.text(_confirmationTitle), findsNothing);
      expectFieldNode(tester, _email, error: 'Email tidak valid.');
    });

    testWidgets('a validation failure without a field is shown in the form', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        statusCode: 422,
      );
      await pumpForgot(tester, auth);

      await send(tester);

      expect(find.text('Data tidak valid.'), findsOneWidget);
      expect(fieldError(tester, _email), isNull);
    });

    testWidgets('the banner goes away when the next request starts', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgot(tester, auth);
      await send(tester);
      auth.requestPasswordResetGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(auth.passwordResetRequests, hasLength(2));
    });

    testWidgets('a field error from the server goes away on the next try', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'email',
      );
      await pumpForgot(tester, auth);
      await send(tester);
      auth.requestPasswordResetFailure = null;

      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      expect(find.text('Email tidak valid.'), findsNothing);
      expect(find.text(_confirmationTitle), findsOneWidget);
    });

    testWidgets('the user can retry with the same email after a failure', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgot(tester, auth);
      await send(tester);
      auth.requestPasswordResetFailure = null;

      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      expect(auth.passwordResetRequests, [
        'budi@example.com',
        'budi@example.com',
      ]);
      expect(find.text(_confirmationTitle), findsOneWidget);
    });
  });

  group('while the request is in flight', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      auth.requestPasswordResetGate = Completer<void>();
      await pumpForgot(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');

      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      expectBusy(tester);
      expect(find.text('Kirim Tautan'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      auth.requestPasswordResetGate = Completer<void>();
      await pumpForgot(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      final button = buttonLabelled('Kirim Tautan');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.passwordResetRequests, hasLength(1));
    });

    testWidgets('an invalid email does not start a request', (tester) async {
      auth.requestPasswordResetGate = Completer<void>();
      await pumpForgot(tester, auth);

      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(auth.passwordResetRequests, isEmpty);
    });

    testWidgets('shows the confirmation once the request completes', (
      tester,
    ) async {
      auth.requestPasswordResetGate = Completer<void>();
      await pumpForgot(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      auth.requestPasswordResetGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(_confirmationTitle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      auth.requestPasswordResetGate = Completer<void>();
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgot(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      auth.requestPasswordResetGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(buttonLabelled('Kirim Tautan'))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('authentication rules', () {
    testWidgets('the email field keeps paste on and offers email autofill', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      expectCredentialField(tester, _email, AutofillHints.email);
    });
  });

  group('structure', () {
    testWidgets('wraps the email field in a LabeledField with its marker', (
      tester,
    ) async {
      await pumpForgot(tester, auth);

      expect(labeledField(_email), findsOneWidget);
      expect(find.text(_email), findsOneWidget);
    });

    testWidgets('draws no label inside the field', (tester) async {
      await pumpForgot(tester, auth);

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts the label above the field', (tester) async {
      await pumpForgot(tester, auth);

      final text = tester.getRect(find.text(_email));
      final input = tester.getRect(fieldLabeled(_email));
      expect(text.bottom, lessThanOrEqualTo(input.top));
    });

    testWidgets('reads the field label once, on the field', (tester) async {
      await pumpForgot(tester, auth);

      expectFieldNode(tester, _email);
    });

    testWidgets('keeps a field error on the field node', (tester) async {
      await pumpForgot(tester, auth);
      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      expectFieldNode(tester, _email, error: 'Email wajib diisi.');
    });

    testWidgets('keeps the format error on the field node', (tester) async {
      await pumpForgot(tester, auth);

      await send(tester, email: 'budi');

      expectFieldNode(tester, _email, error: 'Format email tidak valid.');
    });

    testWidgets('tapping the label focuses the field', (tester) async {
      await pumpForgot(tester, auth);

      await tester.tap(find.text(_email));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_email),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('uses a white app bar', (tester) async {
      await pumpForgot(tester, auth);

      expectWhiteAppBar(tester);
    });
  });

  group('accessibility', () {
    testWidgets('the sign in screen meets the guidelines with the link', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on the form', (tester) async {
      await pumpForgot(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a field error', (tester) async {
      await pumpForgot(tester, auth);
      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error from the server', (
      tester,
    ) async {
      auth.requestPasswordResetFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'email',
      );
      await pumpForgot(tester, auth);
      await send(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a banner', (tester) async {
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgot(tester, auth);
      await send(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the request is in flight', (
      tester,
    ) async {
      auth.requestPasswordResetGate = Completer<void>();
      await pumpForgot(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on the confirmation', (tester) async {
      await pumpForgot(tester, auth);
      await send(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size on the form', (tester) async {
      await pumpForgotAtLargeText(tester, auth);

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a field error', (tester) async {
      await pumpForgotAtLargeText(tester, auth);

      await tapVisible(tester, buttonLabelled('Kirim Tautan'));

      expect(fieldError(tester, _email), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a banner', (tester) async {
      auth.requestPasswordResetFailure = const ApiFailure.network();
      await pumpForgotAtLargeText(tester, auth);

      await send(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size while the request is in flight', (
      tester,
    ) async {
      auth.requestPasswordResetGate = Completer<void>();
      await pumpForgotAtLargeText(tester, auth);
      await typeInto(tester, _email, 'budi@example.com');
      await tester.scrollUntilVisible(
        buttonLabelled('Kirim Tautan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tapAndPump(tester, buttonLabelled('Kirim Tautan'));

      expect(busyButton(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size on the confirmation', (tester) async {
      await pumpForgotAtLargeText(tester, auth);

      await send(tester);

      expect(find.text(_confirmationTitle), findsOneWidget);
      expect(buttonLabelled('Atur ulang dengan tautan'), findsOneWidget);
      expect(buttonLabelled('Kembali ke Masuk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every button on the confirmation is at least 48 dp', (
      tester,
    ) async {
      await pumpForgot(tester, auth);
      await send(tester);

      for (final label in ['Atur ulang dengan tautan', 'Kembali ke Masuk']) {
        final size = tester.getSize(buttonLabelled(label));
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
      }
    });
  });
}

/// Every string drawn by a `Text` widget under the scaffold body.
List<String> _textsOnScreen(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(
    find.descendant(of: find.byType(Scaffold), matching: find.byType(Text)),
  ))
    if (text.data != null) text.data!,
];
