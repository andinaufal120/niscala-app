import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/ui/confirm_email_change_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'auth_ui_helpers.dart';

const _link = 'Tautan konfirmasi (wajib)';
const _tokenLink = 'https://niscala.app/email-change?token=abc';
const _invalidLink = 'Tautan tidak valid.';

const _failureCodes = {
  'EMAIL_CHANGE_NOT_FOUND': 404,
  'EMAIL_CHANGE_USED': 409,
  'EMAIL_CHANGE_EXPIRED': 409,
  'EMAIL_ALREADY_REGISTERED': 409,
};

Future<void> pumpConfirm(WidgetTester tester, FakeAuthRepository auth) async {
  await pumpLogin(tester, auth);
  goTo(tester, '/konfirmasi-email-baru');
  await tester.pumpAndSettle();
}

Future<void> pumpConfirmAtLargeText(
  WidgetTester tester,
  FakeAuthRepository auth,
) async {
  await pumpAtLargeText(tester, buildTestApp(auth: auth));
  await tester.pumpAndSettle();
  goTo(tester, '/konfirmasi-email-baru');
  await tester.pumpAndSettle();
}

Future<void> confirmWith(WidgetTester tester, String link) async {
  await type(tester, _link, link);
  await tapVisible(tester, buttonLabelled('Konfirmasi'));
}

ApiFailure _failureOf(String code) =>
    ApiFailure(code: code, statusCode: _failureCodes[code] ?? 500);

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('entry from the sign in screen', () {
    testWidgets('the sign in screen offers Konfirmasi email baru', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      expect(buttonLabelled('Konfirmasi email baru'), findsOneWidget);
    });

    testWidgets('the link opens the confirmation screen', (tester) async {
      await pumpLogin(tester, auth);

      await tapVisible(tester, buttonLabelled('Konfirmasi email baru'));

      expect(currentPath(tester), '/konfirmasi-email-baru');
      expect(find.byType(ConfirmEmailChangeScreen), findsOneWidget);
    });

    testWidgets('the link on the sign in screen is at least 48 dp', (
      tester,
    ) async {
      await pumpLogin(tester, auth);

      final size = tester.getSize(buttonLabelled('Konfirmasi email baru'));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('content', () {
    testWidgets('shows the title, the labelled link field and the button', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);

      expect(find.byType(ConfirmEmailChangeScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Konfirmasi email baru'),
        ),
        findsOneWidget,
      );
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Konfirmasi'), findsOneWidget);
      expect(fieldError(tester, _link), isNull);
      expect(find.text('Email diperbarui'), findsNothing);
      expect(auth.emailChangeConfirmations, isEmpty);
    });

    testWidgets('keeps paste enabled and uses the url keyboard', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);

      expect(textField(tester, _link).enableInteractiveSelection, isNot(false));
      expect(textField(tester, _link).keyboardType, TextInputType.url);
      expect(textField(tester, _link).autocorrect, isFalse);
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('reading the link', () {
    testWidgets('sends the token of a pasted link', (tester) async {
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(auth.emailChangeConfirmations, ['abc']);
    });

    testWidgets('trims the link and ignores the other parts of it', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);

      await confirmWith(
        tester,
        '  https://niscala.app/email-change?utm=wa&token=abc#top \n',
      );

      expect(auth.emailChangeConfirmations, ['abc']);
    });

    testWidgets('decodes a percent-encoded token', (tester) async {
      await pumpConfirm(tester, auth);

      await confirmWith(tester, 'https://niscala.app/email-change?token=a%2Bb');

      expect(auth.emailChangeConfirmations, ['a+b']);
    });

    testWidgets('sends a pasted bare token as it is', (tester) async {
      await pumpConfirm(tester, auth);

      await confirmWith(tester, 'Ab_9-Zz');

      expect(auth.emailChangeConfirmations, ['Ab_9-Zz']);
    });

    testWidgets('an empty link is an error and sends nothing', (tester) async {
      await pumpConfirm(tester, auth);

      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      expect(fieldError(tester, _link), _invalidLink);
      expect(auth.emailChangeConfirmations, isEmpty);
    });

    testWidgets('a blank link counts as empty', (tester) async {
      await pumpConfirm(tester, auth);

      await confirmWith(tester, '   \n ');

      expect(fieldError(tester, _link), _invalidLink);
      expect(auth.emailChangeConfirmations, isEmpty);
    });

    for (final bad in [
      'https://niscala.app/email-change',
      'https://niscala.app/email-change?other=1',
      'https://niscala.app/email-change?token=',
      'https://niscala.app/email-change/abc',
      '///',
    ]) {
      testWidgets('the text "$bad" is an error and sends nothing', (
        tester,
      ) async {
        await pumpConfirm(tester, auth);

        await confirmWith(tester, bad);

        expect(fieldError(tester, _link), _invalidLink);
        expect(auth.emailChangeConfirmations, isEmpty);
        expect(find.text('Email diperbarui'), findsNothing);
      });
    }

    testWidgets('the field error goes away on the next valid attempt', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);
      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      await confirmWith(tester, _tokenLink);

      expect(find.text(_invalidLink), findsNothing);
      expect(auth.emailChangeConfirmations, ['abc']);
    });

    testWidgets('keeps the field error on the field node', (tester) async {
      await pumpConfirm(tester, auth);
      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      expectFieldNode(tester, _link, error: _invalidLink);
    });
  });

  group('success', () {
    testWidgets('shows the result and replaces the form', (tester) async {
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(field(_link), findsNothing);
      expect(buttonLabelled('Konfirmasi'), findsNothing);
      expect(buttonLabelled('Masuk'), findsOneWidget);
    });

    testWidgets('confirms once', (tester) async {
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(auth.emailChangeConfirmations, hasLength(1));
    });

    testWidgets('the title is a semantic header', (tester) async {
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Email diperbarui')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('stays on screen and is not a snack bar', (tester) async {
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the sign in button opens the sign in screen', (tester) async {
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);

      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('does not sign in automatically', (tester) async {
      final store = await pumpLogin(tester, auth);
      goTo(tester, '/konfirmasi-email-baru');
      await tester.pumpAndSettle();
      await confirmWith(tester, _tokenLink);

      await tapVisible(tester, buttonLabelled('Masuk'));

      expect(auth.logins, isEmpty);
      expect(store.stored, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
    });
  });

  group('failures', () {
    for (final code in _failureCodes.keys) {
      testWidgets('$code shows its message and keeps the form', (tester) async {
        auth.confirmEmailChangeFailure = _failureOf(code);
        await pumpConfirm(tester, auth);

        await confirmWith(tester, _tokenLink);

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
        expect(field(_link), findsOneWidget);
        expect(buttonLabelled('Konfirmasi'), findsOneWidget);
        expect(find.text('Email diperbarui'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(currentPath(tester), '/konfirmasi-email-baru');
      });

      testWidgets('$code never shows the code or the English text', (
        tester,
      ) async {
        auth.confirmEmailChangeFailure = _failureOf(code);
        await pumpConfirm(tester, auth);

        await confirmWith(tester, _tokenLink);

        expect(find.textContaining('EMAIL_'), findsNothing);
        expect(find.textContaining('expired'), findsNothing);
        expect(find.textContaining('not found'), findsNothing);
      });

      testWidgets('$code stays and is a live region', (tester) async {
        auth.confirmEmailChangeFailure = _failureOf(code);
        await pumpConfirm(tester, auth);
        await confirmWith(tester, _tokenLink);

        await tester.pump(const Duration(seconds: 30));

        final message = messageOfCode(code);
        expect(find.text(message), findsOneWidget);
        expectLiveRegion(tester, message);
      });
    }

    testWidgets('a network failure shows its message', (tester) async {
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Email diperbarui'), findsNothing);
    });

    testWidgets('a server failure shows its message', (tester) async {
      auth.confirmEmailChangeFailure = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('an unknown error code shows the generic message', (
      tester,
    ) async {
      auth.confirmEmailChangeFailure = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('keeps the pasted link after a failure', (tester) async {
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpConfirm(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(find.text(_tokenLink), findsOneWidget);
    });

    testWidgets('the message goes away when the next attempt starts', (
      tester,
    ) async {
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);
      auth.confirmEmailChangeGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Konfirmasi'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(auth.emailChangeConfirmations, hasLength(2));
    });

    testWidgets('the user can retry after a network failure', (tester) async {
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);
      auth.confirmEmailChangeFailure = null;

      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      expect(auth.emailChangeConfirmations, ['abc', 'abc']);
      expect(find.text('Email diperbarui'), findsOneWidget);
    });

    testWidgets('a corrected link after a failure confirms', (tester) async {
      auth.confirmEmailChangeFailure = _failureOf('EMAIL_CHANGE_USED');
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);
      auth.confirmEmailChangeFailure = null;

      await confirmWith(tester, 'https://niscala.app/email-change?token=xyz');

      expect(auth.emailChangeConfirmations, ['abc', 'xyz']);
      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(find.text(messageOfCode('EMAIL_CHANGE_USED')), findsNothing);
    });

    testWidgets('an invalid link after a failure clears the old message', (
      tester,
    ) async {
      auth.confirmEmailChangeFailure = _failureOf('EMAIL_CHANGE_USED');
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);

      await confirmWith(tester, '///');

      expect(fieldError(tester, _link), _invalidLink);
      expect(auth.emailChangeConfirmations, hasLength(1));
    });
  });

  group('while the link is being confirmed', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      auth.confirmEmailChangeGate = Completer<void>();
      await pumpConfirm(tester, auth);
      await type(tester, _link, _tokenLink);

      await tapAndPump(tester, buttonLabelled('Konfirmasi'));

      expectBusy(tester);
      expect(find.text('Konfirmasi'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      await pumpConfirm(tester, auth);
      await type(tester, _link, _tokenLink);
      final button = buttonLabelled('Konfirmasi');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.emailChangeConfirmations, hasLength(1));
    });

    testWidgets('an invalid link does not start a request', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      await pumpConfirm(tester, auth);

      await tapAndPump(tester, buttonLabelled('Konfirmasi'));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(auth.emailChangeConfirmations, isEmpty);
    });

    testWidgets('shows the result once the request completes', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      await pumpConfirm(tester, auth);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Konfirmasi'));

      auth.confirmEmailChangeGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpConfirm(tester, auth);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Konfirmasi'));

      auth.confirmEmailChangeGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(buttonLabelled('Konfirmasi'))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('structure', () {
    testWidgets('wraps the link field in a LabeledField with its marker', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);

      expect(labeledField(_link), findsOneWidget);
      expect(find.text(_link), findsOneWidget);
      expectNoDecorationLabels(tester);
    });

    testWidgets('puts the label above the field', (tester) async {
      await pumpConfirm(tester, auth);

      final text = tester.getRect(find.text(_link));
      final input = tester.getRect(fieldLabeled(_link));
      expect(text.bottom, lessThanOrEqualTo(input.top));
    });

    testWidgets('reads the link label once, on the field', (tester) async {
      await pumpConfirm(tester, auth);

      expectFieldNode(tester, _link);
    });

    testWidgets('tapping the label focuses the field', (tester) async {
      await pumpConfirm(tester, auth);

      await tester.tap(find.text(_link));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_link),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('uses a white app bar before and after the result', (
      tester,
    ) async {
      await pumpConfirm(tester, auth);
      expectWhiteAppBar(tester);

      await confirmWith(tester, _tokenLink);
      expectWhiteAppBar(tester);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines on the empty form', (tester) async {
      await pumpConfirm(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a link field error', (tester) async {
      await pumpConfirm(tester, auth);
      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      await expectMeetsA11yGuidelines(tester);
    });

    for (final code in _failureCodes.keys) {
      testWidgets('meets the guidelines with $code', (tester) async {
        auth.confirmEmailChangeFailure = _failureOf(code);
        await pumpConfirm(tester, auth);
        await confirmWith(tester, _tokenLink);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines with a network failure', (tester) async {
      auth.confirmEmailChangeFailure = const ApiFailure.network();
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while confirming', (tester) async {
      auth.confirmEmailChangeGate = Completer<void>();
      await pumpConfirm(tester, auth);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Konfirmasi'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on the result', (tester) async {
      await pumpConfirm(tester, auth);
      await confirmWith(tester, _tokenLink);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the buttons are at least 48 dp', (tester) async {
      await pumpConfirm(tester, auth);
      expect(
        tester.getSize(buttonLabelled('Konfirmasi')).height,
        greaterThanOrEqualTo(48),
      );

      await confirmWith(tester, _tokenLink);
      final size = tester.getSize(buttonLabelled('Masuk'));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('fits at large text size on the empty form', (tester) async {
      await pumpConfirmAtLargeText(tester, auth);

      expect(find.byType(ConfirmEmailChangeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a link error', (tester) async {
      await pumpConfirmAtLargeText(tester, auth);

      await tapVisible(tester, buttonLabelled('Konfirmasi'));

      expect(fieldError(tester, _link), isNotNull);
      expect(tester.takeException(), isNull);
    });

    for (final code in _failureCodes.keys) {
      testWidgets('fits at large text size with $code', (tester) async {
        auth.confirmEmailChangeFailure = _failureOf(code);
        await pumpConfirmAtLargeText(tester, auth);

        await confirmWith(tester, _tokenLink);

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fits at large text size on the result', (tester) async {
      await pumpConfirmAtLargeText(tester, auth);

      await confirmWith(tester, _tokenLink);

      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(buttonLabelled('Masuk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
