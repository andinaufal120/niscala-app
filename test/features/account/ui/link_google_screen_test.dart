import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'account_ui_helpers.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _title = 'Hubungkan Google';
const _introHeading = 'Masuk lebih cepat dengan Google';
const _pickLabel = 'Pilih akun Google';
const _doneHeading = 'Google terhubung';
const _backToAccount = 'Kembali ke Akun';
const _cancelled = 'Penghubungan dibatalkan. Akun tidak berubah.';

const _alreadyRegistered =
    'Akun Google ini sudah terhubung ke akun Niscala lain. '
    'Pilih akun Google yang berbeda.';
const _alreadyLinked = 'Akun ini sudah terhubung ke Google.';
const _passwordLoginRequired =
    'Masuk dengan email dan kata sandi dulu sebelum menghubungkan Google.';
const _emailUnverified = 'Email akun Google ini belum terverifikasi.';
const _tokenInvalid = 'Masuk dengan Google gagal. Coba lagi.';
const _googleUnavailable = 'Masuk dengan Google belum tersedia.';

const _accountEmail = 'andi@example.com';
const _linkedEmail = 'andi.google@gmail.com';

String _pagePath(UserRole role) => '${accountPath(role)}/hubungkan-google';

/// An account that signs in with a password and has no Google linked.
FakeAccountRepository _passwordOnly({
  UserRole role = UserRole.owner,
  String email = _accountEmail,
}) => FakeAccountRepository(
  account: makeAccount(role: role, email: email),
)..linkedGoogleEmail = _linkedEmail;

Future<void> _open(
  WidgetTester tester,
  FakeAccountRepository repo,
  FakeGoogleIdentity google, {
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  await pumpAccountApp(
    tester,
    repo,
    role: role,
    path: _pagePath(role),
    google: google,
    largeText: largeText,
  );
  expect(currentPath(tester), _pagePath(role));
}

/// Scrolls to the button, taps it and settles. Not for a state that holds a
/// request in flight.
Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(buttonLabelled(label));
  await tester.pump();
  await tester.tap(buttonLabelled(label));
  await tester.pumpAndSettle();
}

/// Taps the button and pumps one frame, for a request held in flight.
Future<void> _tapInFlight(WidgetTester tester, String label) async {
  await tester.ensureVisible(buttonLabelled(label));
  await tester.pump();
  await tester.tap(buttonLabelled(label));
  await tester.pump();
}

Future<void> _pick(WidgetTester tester) => _tapButton(tester, _pickLabel);

Future<void> _complete(
  WidgetTester tester,
  FakeAccountRepository repo,
  FakeGoogleIdentity google, {
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  await _open(tester, repo, google, role: role, largeText: largeText);
  await _pick(tester);
  expect(find.text(_doneHeading), findsOneWidget);
}

/// The calls of the repository other than the profile and device loads that
/// the account screens make by themselves.
List<String> _calls(FakeAccountRepository repo) =>
    repo.calls.where((c) => c != 'me' && c != 'sessions').toList();

Finder _snackBar() => find.byType(SnackBar);

/// A `Text` or `RichText` that shows [value].
Finder _textShowing(String value) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(value),
  description: 'text showing "$value"',
);

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

/// Expects the pick button to be unusable: disabled, or replaced while a
/// request is in flight.
void _expectPickBlocked(WidgetTester tester) {
  final button = buttonLabelled(_pickLabel);
  if (button.evaluate().isNotEmpty) {
    expect(_enabled(tester, button), isFalse);
  }
}

void _expectIntro(WidgetTester tester) {
  expect(find.text(_introHeading), findsOneWidget);
  expect(buttonLabelled(_pickLabel), findsOneWidget);
  expect(find.text(_doneHeading), findsNothing);
}

void _expectHeader(WidgetTester tester, Finder finder) {
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(finder), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

void main() {
  late FakeGoogleIdentity google;

  setUp(() {
    google = FakeGoogleIdentity(token: 'token-1');
  });

  group('the page', () {
    for (final role in _roles) {
      testWidgets('is titled Hubungkan Google for a $role', (tester) async {
        await _open(tester, _passwordOnly(role: role), google, role: role);

        expect(appBarTitle(_title), findsOneWidget);
      });
    }

    testWidgets('uses the white detail app bar with a back button', (
      tester,
    ) async {
      await _open(tester, _passwordOnly(), google);

      expect(find.byType(DetailAppBar), findsOneWidget);
      expectDetailAppBar(tester);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('announces the title as a header', (tester) async {
      await _open(tester, _passwordOnly(), google);

      _expectHeader(tester, appBarTitle(_title));
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester, _passwordOnly(), google);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('is reached from the Hubungkan action of Akun', (tester) async {
      await pumpAccountApp(tester, _passwordOnly(), google: google);

      await tester.tap(find.text('Hubungkan'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), _pagePath(UserRole.owner));
      _expectIntro(tester);
    });

    testWidgets('Kembali returns to the account tab without a request', (
      tester,
    ) async {
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(repo.linkGoogleCalls, 0);
      expect(google.requests, 0);
      expect(find.text('Belum terhubung'), findsOneWidget);
    });

    testWidgets('never prints null or an English term', (tester) async {
      await _open(tester, _passwordOnly(), google);

      expect(find.textContaining('null'), findsNothing);
      for (final english in ['Link', 'Connect', 'Choose', 'Account']) {
        expect(find.textContaining(english), findsNothing);
      }
    });
  });

  group('the intro', () {
    testWidgets('invites the user to pick a Google account', (tester) async {
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      _expectIntro(tester);
      expect(google.requests, 0);
      expect(repo.linkGoogleCalls, 0);
      expect(_calls(repo), isEmpty);
    });

    testWidgets('announces its heading as a header', (tester) async {
      await _open(tester, _passwordOnly(), google);

      _expectHeader(tester, find.text(_introHeading));
    });

    testWidgets('says the Niscala account email stays the same', (
      tester,
    ) async {
      await _open(tester, _passwordOnly(), google);

      expect(_textShowing(_accountEmail), findsOneWidget);
    });

    testWidgets('names the email of the account that was loaded', (
      tester,
    ) async {
      await _open(
        tester,
        _passwordOnly(email: 'siti.pemilik@example.com'),
        google,
      );

      expect(_textShowing('siti.pemilik@example.com'), findsOneWidget);
      expect(_textShowing(_accountEmail), findsNothing);
    });

    testWidgets('does not say Google can be disconnected', (tester) async {
      await _open(tester, _passwordOnly(), google);

      for (final word in [
        'putus',
        'Putus',
        'lepas',
        'Lepas',
        'hapus',
        'Hapus',
        'dilepas',
      ]) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    });

    testWidgets('the pick button is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await _open(tester, _passwordOnly(), google);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text(_pickLabel));
        expect(
          node,
          isSemantics(label: _pickLabel, isButton: true, hasTapAction: true),
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows no cancel notice and no message at first', (
      tester,
    ) async {
      await _open(tester, _passwordOnly(), google);

      expect(find.text(_cancelled), findsNothing);
      expect(_snackBar(), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('picking a Google account', () {
    testWidgets('sends the ID token of the chosen account once', (
      tester,
    ) async {
      google.token = 'token-abc';
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await _pick(tester);

      expect(google.requests, 1);
      expect(repo.googleLinks, ['token-abc']);
      expect(_calls(repo), ['linkGoogle']);
    });

    testWidgets('sends nothing else with the token', (tester) async {
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await _pick(tester);

      expect(repo.addLocalPasswordCalls, 0);
      expect(repo.changePasswordCalls, 0);
      expect(repo.endOthersCalls, 0);
    });

    testWidgets('does not ask for the token before the button is pressed', (
      tester,
    ) async {
      await _open(tester, _passwordOnly(), google);
      await tester.pump(const Duration(seconds: 5));

      expect(google.requests, 0);
    });
  });

  group('cancelling the Google chooser', () {
    testWidgets('sends nothing and says the account did not change', (
      tester,
    ) async {
      google.token = null;
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await _pick(tester);

      expect(google.requests, 1);
      expect(repo.linkGoogleCalls, 0);
      expect(find.text(_cancelled), findsOneWidget);
      _expectIntro(tester);
      expect(currentPath(tester), _pagePath(UserRole.owner));
    });

    testWidgets('does not show an error or leave the page', (tester) async {
      google.token = null;
      await _open(tester, _passwordOnly(), google);

      await _pick(tester);

      expect(find.text(genericErrorMessage), findsNothing);
      expect(find.text(_tokenInvalid), findsNothing);
      expect(_snackBar(), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('keeps the pick button usable', (tester) async {
      google.token = null;
      await _open(tester, _passwordOnly(), google);

      await _pick(tester);

      expect(_enabled(tester, buttonLabelled(_pickLabel)), isTrue);
    });

    testWidgets('stays on screen as a live region', (tester) async {
      google.token = null;
      await _open(tester, _passwordOnly(), google);
      await _pick(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_cancelled), findsOneWidget);
      expectLiveRegion(tester, _cancelled);
    });

    testWidgets('lets the user pick again and finish', (tester) async {
      google.token = null;
      final repo = _passwordOnly();
      await _open(tester, repo, google);
      await _pick(tester);
      google.token = 'token-2';

      await _pick(tester);

      expect(google.requests, 2);
      expect(repo.googleLinks, ['token-2']);
      expect(find.text(_doneHeading), findsOneWidget);
      expect(find.text(_cancelled), findsNothing);
    });

    testWidgets('the notice goes away when the next pick starts', (
      tester,
    ) async {
      google.token = null;
      await _open(tester, _passwordOnly(), google);
      await _pick(tester);
      google.gate = Completer<void>();

      await _tapInFlight(tester, _pickLabel);

      expect(find.text(_cancelled), findsNothing);
      google.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('cancelling twice shows the notice once', (tester) async {
      google.token = null;
      await _open(tester, _passwordOnly(), google);
      await _pick(tester);

      await _pick(tester);

      expect(find.text(_cancelled), findsOneWidget);
      expect(google.requests, 2);
    });
  });

  group('when the Google ID token cannot be obtained', () {
    testWidgets('shows that Google sign-in is not available', (tester) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await _pick(tester);

      expect(find.text(_googleUnavailable), findsOneWidget);
      expect(repo.linkGoogleCalls, 0);
      _expectIntro(tester);
      expect(_enabled(tester, buttonLabelled(_pickLabel)), isTrue);
    });

    testWidgets('shows the generic message for any other error', (
      tester,
    ) async {
      google.failure = Exception('plugin broke');
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await _pick(tester);

      expect(find.text(genericErrorMessage), findsOneWidget);
      expect(find.textContaining('plugin broke'), findsNothing);
      expect(repo.linkGoogleCalls, 0);
      expect(find.text(_cancelled), findsNothing);
    });

    testWidgets('lets the user try again', (tester) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      final repo = _passwordOnly();
      await _open(tester, repo, google);
      await _pick(tester);
      google.failure = null;

      await _pick(tester);

      expect(find.text(_googleUnavailable), findsNothing);
      expect(repo.googleLinks, hasLength(1));
      expect(find.text(_doneHeading), findsOneWidget);
    });
  });

  group('while a request is in flight', () {
    testWidgets('waiting for the chooser asks once on a second tap', (
      tester,
    ) async {
      google.gate = Completer<void>();
      final repo = _passwordOnly();
      await _open(tester, repo, google);

      await _tapInFlight(tester, _pickLabel);
      if (buttonLabelled(_pickLabel).evaluate().isNotEmpty) {
        await tester.tap(buttonLabelled(_pickLabel), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      _expectPickBlocked(tester);
      google.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.googleLinks, hasLength(1));
      expect(find.text(_doneHeading), findsOneWidget);
    });

    testWidgets('waiting for the server sends one request on a second tap', (
      tester,
    ) async {
      final repo = _passwordOnly()..linkGoogleScript.gate = Completer<void>();
      await _open(tester, repo, google);

      await _tapInFlight(tester, _pickLabel);
      if (buttonLabelled(_pickLabel).evaluate().isNotEmpty) {
        await tester.tap(buttonLabelled(_pickLabel), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      expect(repo.linkGoogleCalls, 1);
      _expectPickBlocked(tester);
      repo.linkGoogleScript.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.linkGoogleCalls, 1);
    });

    testWidgets('keeps the intro until the server answers', (tester) async {
      final repo = _passwordOnly()..linkGoogleScript.gate = Completer<void>();
      await _open(tester, repo, google);

      await _tapInFlight(tester, _pickLabel);
      await tester.pump(const Duration(seconds: 5));

      expect(find.text(_doneHeading), findsNothing);
      expect(currentPath(tester), _pagePath(UserRole.owner));
      repo.linkGoogleScript.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(_doneHeading), findsOneWidget);
    });

    testWidgets('restores the pick button when the request fails', (
      tester,
    ) async {
      final repo = _passwordOnly()
        ..linkGoogleScript.always = const ApiFailure.network()
        ..linkGoogleScript.gate = Completer<void>();
      await _open(tester, repo, google);
      await _tapInFlight(tester, _pickLabel);

      repo.linkGoogleScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, buttonLabelled(_pickLabel)), isTrue);
    });

    testWidgets('restores the pick button when the chooser fails', (
      tester,
    ) async {
      google.gate = Completer<void>();
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _open(tester, _passwordOnly(), google);
      await _tapInFlight(tester, _pickLabel);

      google.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, buttonLabelled(_pickLabel)), isTrue);
    });
  });

  group('failures from the server', () {
    final cases = <String, ({ApiFailure failure, String message})>{
      'GOOGLE_ACCOUNT_ALREADY_REGISTERED': (
        failure: const ApiFailure(
          code: 'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
          statusCode: 409,
        ),
        message: _alreadyRegistered,
      ),
      'GOOGLE_ALREADY_LINKED': (
        failure: const ApiFailure(
          code: 'GOOGLE_ALREADY_LINKED',
          statusCode: 409,
        ),
        message: _alreadyLinked,
      ),
      'PASSWORD_LOGIN_REQUIRED': (
        failure: const ApiFailure(
          code: 'PASSWORD_LOGIN_REQUIRED',
          statusCode: 403,
        ),
        message: _passwordLoginRequired,
      ),
      'GOOGLE_EMAIL_UNVERIFIED': (
        failure: const ApiFailure(
          code: 'GOOGLE_EMAIL_UNVERIFIED',
          statusCode: 403,
        ),
        message: _emailUnverified,
      ),
      'GOOGLE_TOKEN_INVALID': (
        failure: const ApiFailure(
          code: 'GOOGLE_TOKEN_INVALID',
          statusCode: 401,
        ),
        message: _tokenInvalid,
      ),
      'TOO_MANY_ATTEMPTS': (
        failure: const ApiFailure(code: 'TOO_MANY_ATTEMPTS', statusCode: 429),
        message: messageOfCode('TOO_MANY_ATTEMPTS'),
      ),
      'NETWORK_ERROR': (
        failure: const ApiFailure.network(),
        message: messageOfCode('NETWORK_ERROR'),
      ),
      'INTERNAL_ERROR': (
        failure: const ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500),
        message: messageOfCode('INTERNAL_ERROR'),
      ),
      'FORBIDDEN': (
        failure: const ApiFailure(code: 'FORBIDDEN', statusCode: 403),
        message: messageOfCode('FORBIDDEN'),
      ),
      'SOMETHING_NEW': (
        failure: const ApiFailure(code: 'SOMETHING_NEW'),
        message: genericErrorMessage,
      ),
    };

    for (final entry in cases.entries) {
      final message = entry.value.message;

      testWidgets('${entry.key} shows its message and no result', (
        tester,
      ) async {
        final repo = _passwordOnly()
          ..linkGoogleScript.always = entry.value.failure;
        await _open(tester, repo, google);

        await _pick(tester);

        expect(find.text(message), findsOneWidget);
        expect(find.text(_doneHeading), findsNothing);
        expect(find.text(_cancelled), findsNothing);
        expect(_snackBar(), findsNothing);
        expect(find.textContaining(entry.key), findsNothing);
        expect(currentPath(tester), _pagePath(UserRole.owner));
        expect(repo.googleLinks, ['token-1']);
      });

      testWidgets('${entry.key} message stays on screen as a live region', (
        tester,
      ) async {
        final repo = _passwordOnly()
          ..linkGoogleScript.always = entry.value.failure;
        await _open(tester, repo, google);
        await _pick(tester);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(message), findsOneWidget);
        expectLiveRegion(tester, message);
      });

      testWidgets('${entry.key} leaves the page in place and not busy', (
        tester,
      ) async {
        final repo = _passwordOnly()
          ..linkGoogleScript.always = entry.value.failure;
        await _open(tester, repo, google);

        await _pick(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(_introHeading), findsOneWidget);
      });
    }

    for (final code in [
      'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
      'GOOGLE_EMAIL_UNVERIFIED',
      'GOOGLE_TOKEN_INVALID',
      'NETWORK_ERROR',
      'INTERNAL_ERROR',
    ]) {
      testWidgets('$code lets the user pick another account', (tester) async {
        final repo = _passwordOnly()
          ..linkGoogleScript.queue.add(cases[code]!.failure);
        await _open(tester, repo, google);
        await _pick(tester);
        expect(_enabled(tester, buttonLabelled(_pickLabel)), isTrue);
        google.token = 'token-2';

        await _pick(tester);

        expect(repo.googleLinks, ['token-1', 'token-2']);
        expect(find.text(_doneHeading), findsOneWidget);
        expect(find.text(cases[code]!.message), findsNothing);
      });

      testWidgets('$code message goes away when the next pick starts', (
        tester,
      ) async {
        final repo = _passwordOnly()
          ..linkGoogleScript.queue.add(cases[code]!.failure);
        await _open(tester, repo, google);
        await _pick(tester);
        repo.linkGoogleScript.gate = Completer<void>();

        await _tapInFlight(tester, _pickLabel);

        expect(find.text(cases[code]!.message), findsNothing);
        repo.linkGoogleScript.gate!.complete();
        await tester.pumpAndSettle();
      });
    }

    testWidgets('the already registered message differs from the sign-up one', (
      tester,
    ) async {
      final repo = _passwordOnly()
        ..linkGoogleScript.always =
            cases['GOOGLE_ACCOUNT_ALREADY_REGISTERED']!.failure;
      await _open(tester, repo, google);

      await _pick(tester);

      expect(
        find.text('Akun Google ini sudah terdaftar. Masuk dengan Google.'),
        findsNothing,
      );
      expect(find.text(_alreadyRegistered), findsOneWidget);
    });

    testWidgets('a failure after a cancel replaces the cancel notice', (
      tester,
    ) async {
      google.token = null;
      final repo = _passwordOnly()
        ..linkGoogleScript.always = const ApiFailure.network();
      await _open(tester, repo, google);
      await _pick(tester);
      google.token = 'token-2';

      await _pick(tester);

      expect(find.text(_cancelled), findsNothing);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
    });
  });

  group('the done state', () {
    for (final role in _roles) {
      testWidgets('shows the result and the way back for a $role', (
        tester,
      ) async {
        final repo = _passwordOnly(role: role);
        await _complete(tester, repo, google, role: role);

        expect(find.text(_doneHeading), findsOneWidget);
        expect(buttonLabelled(_backToAccount), findsOneWidget);
        expect(currentPath(tester), _pagePath(role));
        expect(_calls(repo), ['linkGoogle']);
      });

      testWidgets('Kembali ke Akun returns a $role to Akun, which shows '
          'Google as linked', (tester) async {
        final repo = _passwordOnly(role: role);
        await _complete(tester, repo, google, role: role);

        await _tapButton(tester, _backToAccount);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(_textShowing('Terhubung'), findsOneWidget);
        expect(_textShowing(_linkedEmail), findsOneWidget);
        expect(find.text('Belum terhubung'), findsNothing);
        expect(find.text('Hubungkan'), findsNothing);
        expect(find.text('Diatur'), findsOneWidget);
        expect(repo.meCalls, greaterThanOrEqualTo(2));
      });

      testWidgets('Kembali in the app bar also returns a $role to Akun with '
          'Google shown as linked', (tester) async {
        final repo = _passwordOnly(role: role);
        await pumpAccountApp(tester, repo, role: role, google: google);
        await tester.tap(find.text('Hubungkan'));
        await tester.pumpAndSettle();
        await _pick(tester);

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(_textShowing('Terhubung'), findsOneWidget);
        expect(find.text('Belum terhubung'), findsNothing);
      });
    }

    testWidgets('shows the linked Google email', (tester) async {
      await _complete(tester, _passwordOnly(), google);

      expect(_textShowing(_linkedEmail), findsAtLeastNWidgets(1));
    });

    testWidgets('shows the Google email the API returned', (tester) async {
      final repo = _passwordOnly()
        ..linkedGoogleEmail = 'siti.pemilik@gmail.com';
      await _complete(tester, repo, google);

      expect(_textShowing('siti.pemilik@gmail.com'), findsAtLeastNWidgets(1));
      expect(_textShowing(_linkedEmail), findsNothing);
    });

    testWidgets('leaves the intro behind', (tester) async {
      await _complete(tester, _passwordOnly(), google);

      expect(find.text(_introHeading), findsNothing);
      expect(buttonLabelled(_pickLabel), findsNothing);
    });

    testWidgets('keeps the result on screen as a live region, not a snack '
        'bar', (tester) async {
      await _complete(tester, _passwordOnly(), google);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_doneHeading), findsOneWidget);
      expect(_snackBar(), findsNothing);
      expectLiveRegion(tester, _doneHeading);
    });

    testWidgets('the way back is a button of at least 48 dp', (tester) async {
      await _complete(tester, _passwordOnly(), google);

      final rect = tester.getRect(buttonLabelled(_backToAccount));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
    });

    testWidgets('keeps the bottom navigation covered', (tester) async {
      await _complete(tester, _passwordOnly(), google);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('does not say Google can be disconnected', (tester) async {
      await _complete(tester, _passwordOnly(), google);

      for (final word in ['putus', 'Putus', 'lepas', 'Lepas', 'hapus']) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    });

    testWidgets('does not print the token', (tester) async {
      final printed = <String>[];
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      try {
        await runZoned(
          () => _complete(tester, _passwordOnly(), google),
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => printed.add(line),
          ),
        );
      } finally {
        debugPrint = previous;
      }

      for (final line in printed) {
        expect(line, isNot(contains('token-1')));
      }
    });
  });

  group('accessibility', () {
    final states =
        <String, Future<void> Function(WidgetTester tester, bool largeText)>{
          'the intro': (tester, largeText) =>
              _open(tester, _passwordOnly(), google, largeText: largeText),
          'the intro after cancelling': (tester, largeText) async {
            google.token = null;
            await _open(tester, _passwordOnly(), google, largeText: largeText);
            await _pick(tester);
            expect(find.text(_cancelled), findsOneWidget);
          },
          'the intro with Google unavailable': (tester, largeText) async {
            google.failure = const ApiFailure(
              code: 'GOOGLE_SIGN_IN_UNAVAILABLE',
            );
            await _open(tester, _passwordOnly(), google, largeText: largeText);
            await _pick(tester);
            expect(find.text(_googleUnavailable), findsOneWidget);
          },
          'the intro waiting for Google': (tester, largeText) async {
            google.gate = Completer<void>();
            await _open(tester, _passwordOnly(), google, largeText: largeText);
            await _tapInFlight(tester, _pickLabel);
            expect(google.requests, 1);
          },
          'the intro waiting for the server': (tester, largeText) async {
            final repo = _passwordOnly()
              ..linkGoogleScript.gate = Completer<void>();
            await _open(tester, repo, google, largeText: largeText);
            await _tapInFlight(tester, _pickLabel);
            expect(repo.linkGoogleCalls, 1);
          },
          'the intro with an account linked elsewhere':
              (tester, largeText) async {
                final repo = _passwordOnly()
                  ..linkGoogleScript.always = const ApiFailure(
                    code: 'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
                    statusCode: 409,
                  );
                await _open(tester, repo, google, largeText: largeText);
                await _pick(tester);
                expect(find.text(_alreadyRegistered), findsOneWidget);
              },
          'the intro with an account already linked':
              (tester, largeText) async {
                final repo = _passwordOnly()
                  ..linkGoogleScript.always = const ApiFailure(
                    code: 'GOOGLE_ALREADY_LINKED',
                    statusCode: 409,
                  );
                await _open(tester, repo, google, largeText: largeText);
                await _pick(tester);
                expect(find.text(_alreadyLinked), findsOneWidget);
              },
          'the intro when a password login is required':
              (tester, largeText) async {
                final repo = _passwordOnly()
                  ..linkGoogleScript.always = const ApiFailure(
                    code: 'PASSWORD_LOGIN_REQUIRED',
                    statusCode: 403,
                  );
                await _open(tester, repo, google, largeText: largeText);
                await _pick(tester);
                expect(find.text(_passwordLoginRequired), findsOneWidget);
              },
          'the intro with a network failure': (tester, largeText) async {
            final repo = _passwordOnly()
              ..linkGoogleScript.always = const ApiFailure.network();
            await _open(tester, repo, google, largeText: largeText);
            await _pick(tester);
            expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
          },
          'the done state': (tester, largeText) =>
              _complete(tester, _passwordOnly(), google, largeText: largeText),
          'the account tab after linking Google': (tester, largeText) async {
            await _complete(
              tester,
              _passwordOnly(),
              google,
              largeText: largeText,
            );
            await _tapButton(tester, _backToAccount);
            expect(_textShowing('Terhubung'), findsOneWidget);
          },
        };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines in ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size in ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
      });
    }

    for (final role in [UserRole.manager, UserRole.tenant]) {
      testWidgets('meets the guidelines on the intro and the done state for '
          'a $role', (tester) async {
        final repo = _passwordOnly(role: role);
        await _open(tester, repo, google, role: role);
        await expectMeetsA11yGuidelines(tester);

        await _pick(tester);
        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size on the intro for a $role', (
        tester,
      ) async {
        await _open(
          tester,
          _passwordOnly(role: role),
          google,
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
