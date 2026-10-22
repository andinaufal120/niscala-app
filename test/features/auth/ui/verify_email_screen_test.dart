import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'auth_ui_helpers.dart';

const _code = 'Kode verifikasi (wajib)';
const _sentToEmail = 'Kode dikirim ke budi@example.com. Kode berlaku 10 menit.';
const _sentToUnknown = 'Kode dikirim ke email Anda. Kode berlaku 10 menit.';

/// Every text span of [span] that has text of its own, depth first.
Iterable<TextSpan> _leafSpans(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  if (span.text case final text? when text.isNotEmpty) yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _leafSpans(child);
  }
}

Future<void> verifyWith(WidgetTester tester, String code) async {
  await type(tester, _code, code);
  await tapVisible(tester, buttonLabelled('Verifikasi'));
}

Finder appBarTitle(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('content', () {
    testWidgets('shows the title, heading, hint, field and buttons', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(appBarTitle('Verifikasi email'), findsOneWidget);
      expect(find.text('Masukkan kode 6 digit'), findsOneWidget);
      expect(field(_code), findsOneWidget);
      expect(buttonLabelled('Kirim ulang'), findsOneWidget);
      expect(buttonLabelled('Verifikasi'), findsOneWidget);
      expect(buttonLabelled('Keluar'), findsOneWidget);
      expect(find.text('Belum menerima kode?'), findsOneWidget);
      expect(
        find.text('Tidak menemukan email? Periksa folder spam.'),
        findsOneWidget,
      );
    });

    testWidgets('names the email the code was sent to', (tester) async {
      await pumpVerify(tester, auth);

      expect(auth.accountLoads, 1);
      expect(find.text(_sentToEmail), findsOneWidget);
      expect(find.text(_sentToUnknown), findsNothing);
    });

    testWidgets('uses the account email of the API, whatever it is', (
      tester,
    ) async {
      auth.accountResult = Account(
        email: 'siti@kost.id',
        emailVerified: false,
        googleEmail: null,
        hasPassword: true,
        id: 'account-2',
        name: 'Siti',
        role: UserRole.owner,
      );
      await pumpVerify(tester, auth);

      expect(
        find.text('Kode dikirim ke siti@kost.id. Kode berlaku 10 menit.'),
        findsOneWidget,
      );
    });

    testWidgets('has no back button', (tester) async {
      await pumpVerify(tester, auth);

      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byTooltip('Kembali'), findsNothing);
    });

    testWidgets('starts the title at the screen gutter, not after a back '
        'button slot', (tester) async {
      await pumpVerify(tester, auth);

      expect(
        tester.getTopLeft(appBarTitle('Verifikasi email')).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets('starts the title at the gutter at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(
        tester,
        buildTestApp(
          store: InMemorySessionStore(
            storedSession(role: UserRole.owner, emailVerified: false),
          ),
          auth: auth,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(appBarTitle('Verifikasi email')).dx,
        closeTo(NiscalaSpacing.gutter, 0.5),
      );
    });

    testWidgets('shows no error and no banner at first', (tester) async {
      await pumpVerify(tester, auth);

      expect(fieldError(tester, _code), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(auth.confirmations, isEmpty);
      expect(auth.verificationRequests, 0);
    });
  });

  group('loading the email', () {
    testWidgets('shows the general sentence while loading and still works', (
      tester,
    ) async {
      auth.accountGate = Completer<void>();
      await pumpVerify(tester, auth, settle: false);

      expect(find.text(_sentToUnknown), findsOneWidget);
      expect(field(_code), findsOneWidget);

      await verifyWith(tester, '123456');
      expect(auth.confirmations, ['123456']);
    });

    testWidgets('swaps in the email when it arrives', (tester) async {
      auth.accountGate = Completer<void>();
      await pumpVerify(tester, auth, settle: false);

      auth.accountGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(_sentToEmail), findsOneWidget);
      expect(find.text(_sentToUnknown), findsNothing);
    });

    testWidgets('falls back to the general sentence when loading fails', (
      tester,
    ) async {
      auth.accountFailure = const ApiFailure.network();
      await pumpVerify(tester, auth);

      expect(find.text(_sentToUnknown), findsOneWidget);
      expect(find.text(_sentToEmail), findsNothing);
    });

    testWidgets('still verifies after loading the email failed', (
      tester,
    ) async {
      auth.accountFailure = const ApiFailure.network();
      await pumpVerify(tester, auth);

      await verifyWith(tester, '123456');

      expect(auth.confirmations, ['123456']);
      expect(currentPath(tester), '/beranda');
    });

    testWidgets('still resends after loading the email failed', (tester) async {
      auth.accountFailure = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpVerify(tester, auth);

      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      expect(auth.verificationRequests, 1);
    });
  });

  group('validation', () {
    testWidgets('an empty code is rejected without a request', (tester) async {
      await pumpVerify(tester, auth);

      await tapVisible(tester, buttonLabelled('Verifikasi'));

      expect(fieldError(tester, _code), 'Masukkan 6 digit kode.');
      expect(auth.confirmations, isEmpty);
    });

    testWidgets('a code shorter than 6 digits is rejected', (tester) async {
      await pumpVerify(tester, auth);

      await verifyWith(tester, '12345');

      expect(fieldError(tester, _code), 'Masukkan 6 digit kode.');
      expect(auth.confirmations, isEmpty);
    });

    testWidgets('a code with letters is rejected', (tester) async {
      await pumpVerify(tester, auth);

      await verifyWith(tester, 'abcdef');

      expect(fieldError(tester, _code), 'Masukkan 6 digit kode.');
      expect(auth.confirmations, isEmpty);
    });

    testWidgets('the error disappears once a valid code is submitted', (
      tester,
    ) async {
      await pumpVerify(tester, auth);
      await verifyWith(tester, '123');

      await verifyWith(tester, '123456');

      expect(auth.confirmations, ['123456']);
      expect(find.text('Masukkan 6 digit kode.'), findsNothing);
    });
  });

  group('verifying', () {
    testWidgets('sends the code and marks the email verified', (tester) async {
      final store = await pumpVerify(tester, auth);

      await verifyWith(tester, '123456');

      expect(auth.confirmations, ['123456']);
      expect(store.stored?.emailVerified, isTrue);
      final session = containerOf(tester).read(sessionControllerProvider);
      expect(session, isA<SignedIn>());
      expect((session as SignedIn).emailVerified, isTrue);
    });

    testWidgets('an owner moves on to the management home', (tester) async {
      await pumpVerify(tester, auth);

      await verifyWith(tester, '123456');

      expect(currentPath(tester), '/beranda');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(VerifyEmailScreen), findsNothing);
    });

    testWidgets('a manager moves on to the management home', (tester) async {
      await pumpVerify(tester, auth, role: UserRole.manager);

      await verifyWith(tester, '123456');

      expect(currentPath(tester), '/beranda');
    });

    testWidgets('a tenant moves on to the tenant home', (tester) async {
      await pumpVerify(tester, auth, role: UserRole.tenant);

      await verifyWith(tester, '123456');

      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('an already verified email counts as success', (tester) async {
      auth.confirmFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_VERIFIED',
        statusCode: 409,
      );
      final store = await pumpVerify(tester, auth);

      await verifyWith(tester, '123456');

      expect(store.stored?.emailVerified, isTrue);
      expect(currentPath(tester), '/beranda');
      expect(find.text(errorMessage('EMAIL_ALREADY_VERIFIED')), findsNothing);
    });
  });

  group('verification failures', () {
    for (final code in [
      'VERIFICATION_CODE_INVALID',
      'VERIFICATION_CODE_EXPIRED',
    ]) {
      testWidgets('$code is shown on the code field', (tester) async {
        auth.confirmFailure = ApiFailure(code: code, statusCode: 400);
        final store = await pumpVerify(tester, auth);

        await verifyWith(tester, '123456');

        expect(fieldError(tester, _code), errorMessage(code));
        expect(find.text(errorMessage(code)), findsOneWidget);
        expect(currentPath(tester), '/verifikasi-email');
        expect(store.stored?.emailVerified, isFalse);
      });
    }

    for (final code in ['NETWORK_ERROR', 'INTERNAL_ERROR', 'SOMETHING_NEW']) {
      testWidgets('$code is shown in a banner', (tester) async {
        auth.confirmFailure = ApiFailure(code: code);
        await pumpVerify(tester, auth);

        await verifyWith(tester, '123456');

        expect(find.text(errorMessage(code)), findsOneWidget);
        expect(fieldError(tester, _code), isNull);
        expect(find.byType(SnackBar), findsNothing);
        expect(currentPath(tester), '/verifikasi-email');
      });
    }

    testWidgets('the banner stays and is a live region', (tester) async {
      auth.confirmFailure = const ApiFailure.network();
      await pumpVerify(tester, auth);
      await verifyWith(tester, '123456');

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, errorMessage('NETWORK_ERROR'));
    });

    testWidgets('the banner goes away when the next request starts', (
      tester,
    ) async {
      auth.confirmFailure = const ApiFailure.network();
      await pumpVerify(tester, auth);
      await verifyWith(tester, '123456');
      auth.gate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Verifikasi'));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expect(auth.confirmations, hasLength(2));
    });

    testWidgets('the user can retry with a new code after a wrong one', (
      tester,
    ) async {
      auth.confirmFailure = const ApiFailure(
        code: 'VERIFICATION_CODE_INVALID',
        statusCode: 400,
      );
      await pumpVerify(tester, auth);
      await verifyWith(tester, '000000');
      auth.confirmFailure = null;

      await verifyWith(tester, '123456');

      expect(auth.confirmations, ['000000', '123456']);
      expect(currentPath(tester), '/beranda');
    });
  });

  group('resending', () {
    testWidgets('requests a new code and confirms in visible text', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      expect(auth.verificationRequests, 1);
      expect(find.text('Kode baru dikirim.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(currentPath(tester), '/verifikasi-email');
    });

    testWidgets('does not mention a new code before the user asks for one', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      expect(find.text('Kode baru dikirim.'), findsNothing);
    });

    testWidgets('the confirmation stays on screen', (tester) async {
      await pumpVerify(tester, auth);
      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      await tester.pump(const Duration(seconds: 30));

      expect(find.text('Kode baru dikirim.'), findsOneWidget);
    });

    testWidgets('a too-soon request shows the mapped message in a banner', (
      tester,
    ) async {
      auth.sendFailure = const ApiFailure(
        code: 'VERIFICATION_CODE_TOO_SOON',
        statusCode: 429,
      );
      await pumpVerify(tester, auth);

      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      expect(
        find.text(errorMessage('VERIFICATION_CODE_TOO_SOON')),
        findsOneWidget,
      );
      expect(find.text('Kode baru dikirim.'), findsNothing);
      expect(fieldError(tester, _code), isNull);
    });

    for (final code in ['NETWORK_ERROR', 'INTERNAL_ERROR', 'SOMETHING_NEW']) {
      testWidgets('$code shows its message in a banner', (tester) async {
        auth.sendFailure = ApiFailure(code: code);
        await pumpVerify(tester, auth);

        await tapVisible(tester, buttonLabelled('Kirim ulang'));

        expect(find.text(errorMessage(code)), findsOneWidget);
        expect(find.text('Kode baru dikirim.'), findsNothing);
      });
    }

    testWidgets('does not verify or leave the screen', (tester) async {
      await pumpVerify(tester, auth);

      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      expect(auth.confirmations, isEmpty);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });
  });

  group('signing out', () {
    testWidgets('Keluar calls the logout and returns to the sign in screen', (
      tester,
    ) async {
      var logouts = 0;
      late ProviderContainer container;
      await pumpVerify(
        tester,
        auth,
        logout: () async {
          logouts++;
          await container.read(sessionControllerProvider.notifier).signOut();
        },
      );
      container = containerOf(tester);

      await tapVisible(tester, buttonLabelled('Keluar'));

      expect(logouts, 1);
      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(VerifyEmailScreen), findsNothing);
    });

    testWidgets('Keluar does not verify or resend', (tester) async {
      late ProviderContainer container;
      await pumpVerify(
        tester,
        auth,
        logout: () async {
          await container.read(sessionControllerProvider.notifier).signOut();
        },
      );
      container = containerOf(tester);

      await tapVisible(tester, buttonLabelled('Keluar'));

      expect(auth.confirmations, isEmpty);
      expect(auth.verificationRequests, 0);
    });
  });

  group('while a request is in flight', () {
    testWidgets(
      'verifying disables the button and shows a labelled indicator',
      (tester) async {
        auth.gate = Completer<void>();
        await pumpVerify(tester, auth);
        await type(tester, _code, '123456');

        await tapAndPump(tester, buttonLabelled('Verifikasi'));

        expectBusy(tester);
      },
    );

    testWidgets('a double tap on Verifikasi sends one request', (tester) async {
      auth.gate = Completer<void>();
      await pumpVerify(tester, auth);
      await type(tester, _code, '123456');
      final button = buttonLabelled('Verifikasi');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(auth.confirmations, hasLength(1));
    });

    testWidgets('restores the button when verifying fails', (tester) async {
      auth.gate = Completer<void>();
      auth.confirmFailure = const ApiFailure.network();
      await pumpVerify(tester, auth);
      await type(tester, _code, '123456');
      await tapAndPump(tester, buttonLabelled('Verifikasi'));

      auth.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(buttonLabelled('Verifikasi'))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('authentication rules', () {
    testWidgets('the code field offers the one-time code autofill hint', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      expect(
        textField(tester, _code).autofillHints,
        contains(AutofillHints.oneTimeCode),
      );
      expect(labeledField(_code), findsOneWidget);
      expect(textField(tester, _code).decoration?.labelText, isNull);
      expect(textField(tester, _code).enableInteractiveSelection, isNot(false));
      expect(
        find.ancestor(of: field(_code), matching: find.byType(AutofillGroup)),
        findsOneWidget,
      );
    });
  });

  group('structure', () {
    testWidgets('wraps the code field in a LabeledField with its marker', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      expect(labeledField(_code), findsOneWidget);
      expect(find.text(_code), findsOneWidget);
    });

    testWidgets('draws no label inside the code field', (tester) async {
      await pumpVerify(tester, auth);

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts the label above the code field', (tester) async {
      await pumpVerify(tester, auth);

      final text = tester.getRect(find.text(_code));
      final input = tester.getRect(fieldLabeled(_code));
      expect(text.bottom, lessThanOrEqualTo(input.top));
    });

    testWidgets('reads the code label once, on the field node', (tester) async {
      await pumpVerify(tester, auth);

      expectFieldNode(tester, _code);
    });

    testWidgets('keeps the code error on the field node', (tester) async {
      await pumpVerify(tester, auth);
      await tapVisible(tester, buttonLabelled('Verifikasi'));

      expectFieldNode(tester, _code, error: 'Masukkan 6 digit kode.');
    });

    testWidgets('tapping the label focuses the code field', (tester) async {
      await pumpVerify(tester, auth);

      await tester.tap(find.text(_code));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_code),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('shows the code large and letter-spaced', (tester) async {
      await pumpVerify(tester, auth);

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_code),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.style.fontSize, greaterThanOrEqualTo(24));
      expect(editable.style.fontWeight?.value, greaterThanOrEqualTo(700));
      expect(editable.style.letterSpacing, greaterThan(0));
    });

    testWidgets('shows the email in bold inside the sentence', (tester) async {
      await pumpVerify(tester, auth);

      final text = tester.widget<Text>(
        find.textContaining('Kode dikirim ke budi@example.com'),
      );
      final root = text.textSpan ?? TextSpan(text: text.data);
      final email = _leafSpans(root)
          .singleWhere((span) => span.text == 'budi@example.com');
      expect(email.style?.fontWeight?.value, greaterThanOrEqualTo(700));
    });

    testWidgets('shows a resend row with an outlined button of 48 dp', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      final prompt = tester.getRect(find.text('Belum menerima kode?'));
      final resend = buttonLabelled('Kirim ulang');
      expect(
        find.ancestor(
          of: find.text('Kirim ulang'),
          matching: find.byType(OutlinedButton),
        ),
        findsOneWidget,
      );
      final button = tester.getRect(resend);
      expect(prompt.top, lessThan(button.bottom));
      expect(button.top, lessThan(prompt.bottom));
      expect(button.height, greaterThanOrEqualTo(48));
      expect(button.width, greaterThanOrEqualTo(48));
    });

    testWidgets('puts the resend button at the right edge of the row', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final button = tester.getRect(buttonLabelled('Kirim ulang'));
      expect(button.right, closeTo(width - 20, 1));
    });

    testWidgets('puts the prompt at the left of the resend row', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      final prompt = tester.getRect(find.text('Belum menerima kode?'));
      final button = tester.getRect(buttonLabelled('Kirim ulang'));
      expect(prompt.left, closeTo(20, 1));
      expect(prompt.right, lessThanOrEqualTo(button.left));
      expect(prompt.center.dy, greaterThanOrEqualTo(button.top));
      expect(prompt.center.dy, lessThanOrEqualTo(button.bottom));
    });

    testWidgets('puts the spam folder hint below the resend row', (
      tester,
    ) async {
      await pumpVerify(tester, auth);

      final prompt = tester.getRect(find.text('Belum menerima kode?'));
      final button = tester.getRect(buttonLabelled('Kirim ulang'));
      final hint = tester.getRect(
        find.text('Tidak menemukan email? Periksa folder spam.'),
      );
      expect(hint.top, greaterThanOrEqualTo(button.bottom - 1));
      expect(hint.top, greaterThanOrEqualTo(prompt.bottom - 1));
    });

    testWidgets(
      'pins the Verifikasi action in a footer outside any scroll view',
      (tester) async {
        await pumpVerify(tester, auth);

        expectPinnedFooter(tester, 'Verifikasi');
      },
    );

    testWidgets('keeps the footer action pinned with an error', (tester) async {
      await pumpVerify(tester, auth);
      await tapVisible(tester, buttonLabelled('Verifikasi'));

      expectPinnedFooter(tester, 'Verifikasi');
    });

    testWidgets('keeps the footer button on screen at large text size', (
      tester,
    ) async {
      await pumpAtLargeText(
        tester,
        buildTestApp(
          store: InMemorySessionStore(storedSession(emailVerified: false)),
          auth: auth,
        ),
      );
      await tester.pumpAndSettle();

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
        tester.getRect(buttonLabelled('Verifikasi')).bottom,
        lessThanOrEqualTo(screen.height),
      );
      expectFooterAtBottom(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses a white app bar with the title', (tester) async {
      await pumpVerify(tester, auth);

      expectWhiteAppBar(tester);
      expect(appBarTitle('Verifikasi email'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines in the initial state', (tester) async {
      await pumpVerify(tester, auth);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the email is loading', (
      tester,
    ) async {
      auth.accountGate = Completer<void>();
      await pumpVerify(tester, auth, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a field error', (tester) async {
      await pumpVerify(tester, auth);
      await tapVisible(tester, buttonLabelled('Verifikasi'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error for a wrong code', (
      tester,
    ) async {
      auth.confirmFailure = const ApiFailure(code: 'VERIFICATION_CODE_INVALID');
      await pumpVerify(tester, auth);
      await verifyWith(tester, '123456');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a banner', (tester) async {
      auth.confirmFailure = const ApiFailure.network();
      await pumpVerify(tester, auth);
      await verifyWith(tester, '123456');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines after a new code was sent', (
      tester,
    ) async {
      await pumpVerify(tester, auth);
      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while a request is in flight', (
      tester,
    ) async {
      auth.gate = Completer<void>();
      await pumpVerify(tester, auth);
      await type(tester, _code, '123456');
      await tapAndPump(tester, buttonLabelled('Verifikasi'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the new code confirmation is exposed as a live region', (
      tester,
    ) async {
      await pumpVerify(tester, auth);
      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      expectLiveRegion(tester, 'Kode baru dikirim.');
    });

    testWidgets('every button is at least 48 dp', (tester) async {
      await pumpVerify(tester, auth);

      final count = anyButton().evaluate().length;
      expect(count, greaterThanOrEqualTo(3));
      for (var i = 0; i < count; i++) {
        final size = tester.getSize(anyButton().at(i));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    Future<void> pumpLarge(WidgetTester tester) async {
      await pumpAtLargeText(
        tester,
        buildTestApp(
          store: InMemorySessionStore(storedSession(emailVerified: false)),
          auth: auth,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('fits at large text size in the initial state', (tester) async {
      await pumpLarge(tester);

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a field error', (tester) async {
      await pumpLarge(tester);

      await tapVisible(tester, buttonLabelled('Verifikasi'));

      expect(fieldError(tester, _code), 'Masukkan 6 digit kode.');
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a banner', (tester) async {
      auth.confirmFailure = const ApiFailure.network();
      await pumpLarge(tester);
      await type(tester, _code, '123456');

      await tapVisible(tester, buttonLabelled('Verifikasi'));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size after a new code was sent', (
      tester,
    ) async {
      await pumpLarge(tester);

      await tapVisible(tester, buttonLabelled('Kirim ulang'));

      expect(find.text('Kode baru dikirim.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
