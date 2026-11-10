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
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
import 'account_ui_helpers.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _title = 'Tambah kata sandi';
const _introHeading = 'Konfirmasi dulu bahwa ini Anda';
const _googleLabel = 'Lanjutkan dengan Google';
const _passwordLabel = 'Kata sandi (wajib)';
const _confirmLabel = 'Konfirmasi kata sandi (wajib)';
const _submitLabel = 'Simpan kata sandi';
const _toggleLabel = 'Tampilkan kata sandi';
const _helper =
    'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa aturan huruf '
    'atau simbol khusus.';
const _doneHeading = 'Kata sandi ditambahkan';
const _backToAccount = 'Kembali ke Akun';

const _mismatchOfConfirmation = 'Konfirmasi tidak sama dengan kata sandi.';
const _tooShort = 'Kata sandi minimal 8 karakter.';
const _tooLong = 'Kata sandi maksimal 128 karakter.';
const _googleMismatch =
    'Akun Google yang dipilih berbeda dari akun yang terhubung.';
const _googleInvalid = 'Masuk dengan Google gagal. Coba lagi.';
const _alreadySet = 'Akun ini sudah punya kata sandi.';
const _notLinked = 'Akun ini belum terhubung ke Google.';
const _googleUnavailable = 'Masuk dengan Google belum tersedia.';

const _strengthHint = 'Kekuatan kata sandi akan muncul saat Anda mengetik.';
const _guessable = 'Kekuatan: Lemah · mudah ditebak';
const _weakShort = 'Kekuatan: Lemah · terlalu pendek';
const _fair = 'Kekuatan: Cukup · tambah panjangnya agar lebih aman';
const _strong = 'Kekuatan: Kuat · sudah aman';
const _veryStrong = 'Kekuatan: Sangat kuat · sangat sulit ditebak';

const _googleEmail = 'andi.google@gmail.com';
const _secret = 'teh manis sore hari';

String _pagePath(UserRole role) => '${accountPath(role)}/tambah-kata-sandi';

/// An account that signs in with Google only.
FakeAccountRepository _googleOnly({
  UserRole role = UserRole.owner,
  String name = 'Andi Pengguna',
  String email = 'andi@example.com',
}) => FakeAccountRepository(
  account: makeAccount(
    role: role,
    name: name,
    email: email,
    hasPassword: false,
    googleEmail: _googleEmail,
  ),
);

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

Future<void> _continueWithGoogle(WidgetTester tester) =>
    _tapButton(tester, _googleLabel);

Future<void> _openForm(
  WidgetTester tester,
  FakeAccountRepository repo,
  FakeGoogleIdentity google, {
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  await _open(tester, repo, google, role: role, largeText: largeText);
  await _continueWithGoogle(tester);
  expect(field(_passwordLabel), findsOneWidget);
}

Future<void> _fill(
  WidgetTester tester, {
  String password = _secret,
  String? confirm,
}) async {
  await type(tester, _passwordLabel, password);
  await type(tester, _confirmLabel, confirm ?? password);
}

Future<void> _submit(WidgetTester tester) => _tapButton(tester, _submitLabel);

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String password = _secret,
  String? confirm,
}) async {
  await _fill(tester, password: password, confirm: confirm);
  await _submit(tester);
}

Future<void> _complete(
  WidgetTester tester,
  FakeAccountRepository repo,
  FakeGoogleIdentity google, {
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  await _openForm(tester, repo, google, role: role, largeText: largeText);
  await _fillAndSubmit(tester);
  expect(find.text(_doneHeading), findsOneWidget);
}

/// The calls of the repository other than the profile and device loads that
/// the account screens make by themselves.
List<String> _calls(FakeAccountRepository repo) =>
    repo.calls.where((c) => c != 'me' && c != 'sessions').toList();

Finder _snackBar() => find.byType(SnackBar);

/// A `Text` or `RichText` that shows [value], so that the typed text of an
/// editable field does not match.
Finder _textShowing(String value) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(value),
  description: 'text showing "$value"',
);

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

/// Expects the Google button to be unusable: disabled, or replaced while a
/// request is in flight.
void _expectGoogleBlocked(WidgetTester tester) {
  final button = buttonLabelled(_googleLabel);
  if (button.evaluate().isNotEmpty) {
    expect(_enabled(tester, button), isFalse);
  }
}

String _typed(WidgetTester tester, String label) =>
    tester.widget<TextField>(fieldLabeled(label)).controller!.text;

void _expectTypedKept(
  WidgetTester tester, {
  String password = _secret,
  String? confirm,
}) {
  expect(_typed(tester, _passwordLabel), password);
  expect(_typed(tester, _confirmLabel), confirm ?? password);
}

void _expectNoFieldErrors(WidgetTester tester) {
  for (final label in [_passwordLabel, _confirmLabel]) {
    expect(fieldError(tester, label), isNull, reason: label);
  }
}

/// Expects the intro step: its heading and the Google button, and none of the
/// form.
void _expectIntro(WidgetTester tester) {
  expect(find.text(_introHeading), findsOneWidget);
  expect(buttonLabelled(_googleLabel), findsOneWidget);
  expect(field(_passwordLabel), findsNothing);
  expect(field(_confirmLabel), findsNothing);
  expect(buttonLabelled(_submitLabel), findsNothing);
}

/// Expects that none of [secrets] is shown as text or announced as a label or
/// hint. The value of a field is announced too unless [valueExposed] says the
/// passwords are revealed.
void _expectNoPasswordShown(
  WidgetTester tester,
  List<String> secrets, {
  bool valueExposed = false,
}) {
  for (final secret in secrets) {
    expect(_textShowing(secret), findsNothing, reason: secret);
  }
  final handle = tester.ensureSemantics();
  try {
    for (final node in allSemanticsNodes(tester)) {
      for (final secret in secrets) {
        expect(node.label, isNot(contains(secret)));
        expect(node.hint, isNot(contains(secret)));
        if (!valueExposed) {
          expect(node.value, isNot(contains(secret)));
        }
      }
    }
  } finally {
    handle.dispose();
  }
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
      testWidgets('is titled Tambah kata sandi for a $role', (tester) async {
        await _open(tester, _googleOnly(role: role), google, role: role);

        expect(appBarTitle(_title), findsOneWidget);
      });
    }

    testWidgets('uses the white detail app bar with a back button', (
      tester,
    ) async {
      await _open(tester, _googleOnly(), google);

      expect(find.byType(DetailAppBar), findsOneWidget);
      expectDetailAppBar(tester);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('announces the title as a header', (tester) async {
      await _open(tester, _googleOnly(), google);

      _expectHeader(tester, appBarTitle(_title));
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester, _googleOnly(), google);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('is reached from the Tambah action of Akun', (tester) async {
      await pumpAccountApp(tester, _googleOnly(), google: google);

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), _pagePath(UserRole.owner));
      _expectIntro(tester);
    });

    testWidgets('never prints null or an English term', (tester) async {
      await _open(tester, _googleOnly(), google);

      expect(find.textContaining('null'), findsNothing);
      for (final english in ['Password', 'Continue', 'Confirm', 'Save']) {
        expect(find.textContaining(english), findsNothing);
      }
    });
  });

  group('the intro step', () {
    testWidgets('asks the user to confirm it is them and offers Google', (
      tester,
    ) async {
      final repo = _googleOnly();
      await _open(tester, repo, google);

      _expectIntro(tester);
      expect(find.text(_toggleLabel), findsNothing);
      expect(google.requests, 0);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('shows the Google email of the account', (tester) async {
      await _open(tester, _googleOnly(), google);

      expect(_textShowing(_googleEmail), findsAtLeastNWidgets(1));
    });

    testWidgets('shows the Google email of the account that was loaded', (
      tester,
    ) async {
      final repo = FakeAccountRepository(
        account: makeAccount(
          hasPassword: false,
          googleEmail: 'siti.pemilik@gmail.com',
        ),
      );
      await _open(tester, repo, google);

      expect(_textShowing('siti.pemilik@gmail.com'), findsAtLeastNWidgets(1));
      expect(_textShowing(_googleEmail), findsNothing);
    });

    testWidgets('announces its heading as a header', (tester) async {
      await _open(tester, _googleOnly(), google);

      _expectHeader(tester, find.text(_introHeading));
    });

    testWidgets('the Google button is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await _open(tester, _googleOnly(), google);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text(_googleLabel));
        expect(
          node,
          isSemantics(label: _googleLabel, isButton: true, hasTapAction: true),
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Kembali returns to the account tab without a request', (
      tester,
    ) async {
      final repo = _googleOnly();
      await _open(tester, repo, google);

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(repo.addLocalPasswordCalls, 0);
      expect(google.requests, 0);
    });
  });

  group('continuing with Google', () {
    testWidgets('asks Google once and shows the form without sending '
        'anything', (tester) async {
      final repo = _googleOnly();
      await _open(tester, repo, google);

      await _continueWithGoogle(tester);

      expect(google.requests, 1);
      expect(field(_passwordLabel), findsOneWidget);
      expect(field(_confirmLabel), findsOneWidget);
      expect(buttonLabelled(_submitLabel), findsOneWidget);
      expect(find.text(_introHeading), findsNothing);
      expect(buttonLabelled(_googleLabel), findsNothing);
      expect(repo.addLocalPasswordCalls, 0);
      expect(_calls(repo), isEmpty);
      expect(currentPath(tester), _pagePath(UserRole.owner));
    });

    testWidgets('shows an empty form without errors', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      _expectTypedKept(tester, password: '', confirm: '');
      _expectNoFieldErrors(tester);
      expect(find.text(_googleMismatch), findsNothing);
      expect(_snackBar(), findsNothing);
    });

    testWidgets('cancelling the chooser does nothing and shows no error', (
      tester,
    ) async {
      google.token = null;
      final repo = _googleOnly();
      await _open(tester, repo, google);

      await _continueWithGoogle(tester);

      expect(google.requests, 1);
      _expectIntro(tester);
      expect(_enabled(tester, buttonLabelled(_googleLabel)), isTrue);
      expect(repo.addLocalPasswordCalls, 0);
      expect(find.text(genericErrorMessage), findsNothing);
      expect(find.text(_googleInvalid), findsNothing);
      expect(find.text(_googleMismatch), findsNothing);
      expect(_snackBar(), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the user can choose an account after cancelling', (
      tester,
    ) async {
      google.token = null;
      await _open(tester, _googleOnly(), google);
      await _continueWithGoogle(tester);
      google.token = 'token-2';

      await _continueWithGoogle(tester);

      expect(google.requests, 2);
      expect(field(_passwordLabel), findsOneWidget);
      await _fillAndSubmit(tester);
    });

    testWidgets('an unavailable Google sign-in is explained on the intro', (
      tester,
    ) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _open(tester, _googleOnly(), google);

      await _continueWithGoogle(tester);

      expect(find.text(_googleUnavailable), findsOneWidget);
      _expectIntro(tester);
      expect(_enabled(tester, buttonLabelled(_googleLabel)), isTrue);
    });

    testWidgets('any other error of the chooser shows the generic message', (
      tester,
    ) async {
      google.failure = Exception('plugin broke');
      final repo = _googleOnly();
      await _open(tester, repo, google);

      await _continueWithGoogle(tester);

      expect(find.text(genericErrorMessage), findsOneWidget);
      expect(find.textContaining('plugin broke'), findsNothing);
      _expectIntro(tester);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('the user can try again after a chooser failure', (
      tester,
    ) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _open(tester, _googleOnly(), google);
      await _continueWithGoogle(tester);
      google.failure = null;

      await _continueWithGoogle(tester);

      expect(find.text(_googleUnavailable), findsNothing);
      expect(field(_passwordLabel), findsOneWidget);
    });

    testWidgets('a second tap while the chooser is open asks once', (
      tester,
    ) async {
      google.gate = Completer<void>();
      await _open(tester, _googleOnly(), google);

      await _tapInFlight(tester, _googleLabel);
      if (buttonLabelled(_googleLabel).evaluate().isNotEmpty) {
        await tester.tap(buttonLabelled(_googleLabel), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      _expectGoogleBlocked(tester);
      google.gate!.complete();
      await tester.pumpAndSettle();
      expect(google.requests, 1);
      expect(field(_passwordLabel), findsOneWidget);
    });

    testWidgets('keeps the intro until the chooser answers', (tester) async {
      google.gate = Completer<void>();
      await _open(tester, _googleOnly(), google);

      await _tapInFlight(tester, _googleLabel);
      await tester.pump(const Duration(seconds: 5));

      expect(find.text(_introHeading), findsOneWidget);
      expect(field(_passwordLabel), findsNothing);
      google.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('restores the Google button when the chooser fails', (
      tester,
    ) async {
      google.gate = Completer<void>();
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _open(tester, _googleOnly(), google);
      await _tapInFlight(tester, _googleLabel);

      google.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, buttonLabelled(_googleLabel)), isTrue);
    });
  });

  group('the form step', () {
    testWidgets('shows the two labelled fields, the helper and the toggle', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);

      expect(field(_passwordLabel), findsOneWidget);
      expect(field(_confirmLabel), findsOneWidget);
      expect(find.text(_helper), findsOneWidget);
      expect(find.text(_toggleLabel), findsOneWidget);
      expect(buttonLabelled(_submitLabel), findsOneWidget);
    });

    testWidgets('places the password field above its confirmation', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);

      expect(
        tester.getTopLeft(fieldLabeled(_passwordLabel)).dy,
        lessThan(tester.getTopLeft(fieldLabeled(_confirmLabel)).dy),
      );
    });

    testWidgets('puts the helper with the password field', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      final helper = tester.getTopLeft(find.text(_helper)).dy;
      expect(
        helper,
        greaterThan(tester.getTopLeft(find.text(_passwordLabel)).dy),
      );
      expect(helper, lessThan(tester.getTopLeft(find.text(_confirmLabel)).dy));
    });

    testWidgets('starts with both passwords hidden', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      for (final label in [_passwordLabel, _confirmLabel]) {
        expect(labeledTextField(tester, label).obscureText, isTrue);
      }
    });

    testWidgets('offers new password autofill and keeps paste on', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);

      expectCredentialField(tester, _passwordLabel, AutofillHints.newPassword);
      expectCredentialField(tester, _confirmLabel, AutofillHints.newPassword);
    });

    testWidgets('draws no label inside the field', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts each label above its field and reads it once', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);

      for (final label in [_passwordLabel, _confirmLabel]) {
        expect(
          tester.getRect(find.text(label)).bottom,
          lessThanOrEqualTo(tester.getRect(fieldLabeled(label)).top),
        );
        expectFieldNode(tester, label);
      }
    });

    testWidgets('keeps each field error on its field node', (tester) async {
      await _openForm(tester, _googleOnly(), google);
      await _submit(tester);

      for (final label in [_passwordLabel, _confirmLabel]) {
        final error = fieldError(tester, label);
        expect(error, isNotNull, reason: label);
        expectFieldNode(tester, label, error: error);
      }
    });

    testWidgets('Kembali returns to the account tab without a request', (
      tester,
    ) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);
      await _fill(tester);

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(repo.addLocalPasswordCalls, 0);
      expect(find.text('Belum diatur'), findsOneWidget);
    });
  });

  group('show password', () {
    testWidgets('one checkbox reveals and hides both fields', (tester) async {
      await _openForm(tester, _googleOnly(), google);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      for (final label in [_passwordLabel, _confirmLabel]) {
        expect(labeledTextField(tester, label).obscureText, isFalse);
      }

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      for (final label in [_passwordLabel, _confirmLabel]) {
        expect(labeledTextField(tester, label).obscureText, isTrue);
      }
    });

    testWidgets('is a labelled checkbox of at least 48 dp', (tester) async {
      await _openForm(tester, _googleOnly(), google);
      expectShowPasswordCheckbox(tester, checked: false);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      expectShowPasswordCheckbox(tester, checked: true);
    });

    testWidgets('keeps the typed text when toggled', (tester) async {
      await _openForm(tester, _googleOnly(), google);
      await _fill(tester);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();

      _expectTypedKept(tester);
    });

    testWidgets('stays revealed after a failed request', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.always = const ApiFailure.network();
      await _openForm(tester, repo, google);
      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();

      await _fillAndSubmit(tester);

      for (final label in [_passwordLabel, _confirmLabel]) {
        expect(labeledTextField(tester, label).obscureText, isFalse);
      }
    });
  });

  group('strength hint', () {
    testWidgets('invites typing while the password is empty', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('follows the password while typing', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      await type(tester, _passwordLabel, 'abc');
      expect(find.text(_weakShort), findsOneWidget);

      await type(tester, _passwordLabel, 'kopi tubruk');
      expect(find.text(_fair), findsOneWidget);

      await type(tester, _passwordLabel, 'kopi tubruk pa');
      expect(find.text(_strong), findsOneWidget);

      await type(tester, _passwordLabel, 'kopi tubruk pagi');
      expect(find.text(_veryStrong), findsOneWidget);
    });

    testWidgets('ignores the confirmation', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      await type(tester, _confirmLabel, 'kopi tubruk pagi');

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('shows a single strength line at a time', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      await type(tester, _passwordLabel, 'kopi tubruk pagi');

      expect(find.textContaining('Kekuatan'), findsOneWidget);
    });

    testWidgets('flags a common password as easy to guess', (tester) async {
      await _openForm(tester, _googleOnly(), google);

      await type(tester, _passwordLabel, 'password123');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('goes back to the invitation when the password is cleared', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);
      await type(tester, _passwordLabel, 'kopi tubruk pagi');

      await type(tester, _passwordLabel, '');

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('weakens a password that contains the name of the account', (
      tester,
    ) async {
      final repo = _googleOnly(
        name: 'Budi Santoso',
        email: 'sarip@example.com',
      );
      await _openForm(tester, repo, google);

      await type(tester, _passwordLabel, 'kopi tubruk pagi');
      expect(find.text(_veryStrong), findsOneWidget);

      await type(tester, _passwordLabel, 'budi-kopi-tubruk');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('weakens a password that contains the email of the account', (
      tester,
    ) async {
      final repo = _googleOnly(
        name: 'Budi Santoso',
        email: 'sarip@example.com',
      );
      await _openForm(tester, repo, google);

      await type(tester, _passwordLabel, 'sarip-kopi-tubruk');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('announces the strength line as a live region', (tester) async {
      await _openForm(tester, _googleOnly(), google);
      await type(tester, _passwordLabel, 'kopi tubruk pagi');

      expectLiveRegion(tester, _veryStrong);
    });

    testWidgets('exposes only the strength text, not the bars, to semantics', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);
      await type(tester, _passwordLabel, 'kopi tubruk pagi');
      final handle = tester.ensureSemantics();

      expect(find.bySemanticsLabel(RegExp('Kekuatan')), findsOneWidget);
      handle.dispose();
    });
  });

  group('validation', () {
    testWidgets('an empty form shows an error on both fields and sends '
        'nothing', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _submit(tester);

      for (final label in [_passwordLabel, _confirmLabel]) {
        final error = fieldError(tester, label);
        expect(error, isNotNull, reason: label);
        expect(error, isNotEmpty, reason: label);
        expect(find.text(error!), findsAtLeastNWidgets(1));
      }
      expect(repo.addLocalPasswordCalls, 0);
      expect(find.text(_doneHeading), findsNothing);
      expect(currentPath(tester), _pagePath(UserRole.owner));
    });

    testWidgets('an empty confirmation is the only error', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, confirm: '');

      expect(fieldError(tester, _passwordLabel), isNull);
      expect(fieldError(tester, _confirmLabel), isNotNull);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('an empty password is an error and sends nothing', (
      tester,
    ) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, password: '', confirm: '');

      expect(fieldError(tester, _passwordLabel), isNotNull);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('a password of 7 characters is too short', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, password: 'abcdefg');

      expect(fieldError(tester, _passwordLabel), _tooShort);
      expect(fieldError(tester, _confirmLabel), isNull);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('a password of 8 characters is sent', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, password: 'kopi1234');

      expect(repo.addLocalPasswordCalls, 1);
    });

    testWidgets('a password of 128 characters is sent', (tester) async {
      final repo = _googleOnly();
      final long = 'kopi tubruk pagi ' * 8;
      final password = long.substring(0, 128);
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, password: password);

      expect(repo.localPasswordAdditions.single.password, password);
    });

    testWidgets('a password of 129 characters is too long', (tester) async {
      final repo = _googleOnly();
      final password = ('kopi tubruk pagi ' * 8).substring(0, 129);
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, password: password);

      expect(fieldError(tester, _passwordLabel), _tooLong);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('a confirmation that differs is an error next to the '
        'confirmation', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, confirm: 'teh manis sore hari ini');

      expect(fieldError(tester, _confirmLabel), _mismatchOfConfirmation);
      expect(fieldError(tester, _passwordLabel), isNull);
      expect(find.text(_mismatchOfConfirmation), findsOneWidget);
      expect(repo.addLocalPasswordCalls, 0);
      _expectTypedKept(tester, confirm: 'teh manis sore hari ini');
    });

    testWidgets('compares the confirmation without trimming', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, confirm: '$_secret ');

      expect(fieldError(tester, _confirmLabel), _mismatchOfConfirmation);
      expect(repo.addLocalPasswordCalls, 0);
    });

    testWidgets('a mismatch is a field error, not a message at the form', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);

      await _fillAndSubmit(tester, confirm: 'lain sekali');

      expect(_snackBar(), findsNothing);
      expect(find.text(_mismatchOfConfirmation), findsOneWidget);
      expectFieldNode(tester, _confirmLabel, error: _mismatchOfConfirmation);
    });

    testWidgets('does not ask Google again after a validation error', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);

      await _fillAndSubmit(tester, confirm: 'lain sekali');

      expect(google.requests, 1);
      expect(field(_passwordLabel), findsOneWidget);
    });

    testWidgets('a corrected confirmation is sent after a mismatch', (
      tester,
    ) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);
      await _fillAndSubmit(tester, confirm: 'lain sekali');

      await type(tester, _confirmLabel, _secret);
      await _submit(tester);

      expect(repo.localPasswordAdditions, [
        (googleIdToken: 'token-1', password: _secret),
      ]);
      expect(find.text(_mismatchOfConfirmation), findsNothing);
    });
  });

  group('submit', () {
    testWidgets('sends the token from the intro and the password untrimmed, '
        'once', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester, password: '  teh manis sore  ');

      expect(repo.localPasswordAdditions, [
        (googleIdToken: 'token-1', password: '  teh manis sore  '),
      ]);
      expect(google.requests, 1);
    });

    testWidgets('does not send the confirmation as a separate value', (
      tester,
    ) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester);

      expect(repo.localPasswordAdditions.single.password, _secret);
    });

    testWidgets('sends only the one addition and nothing else', (tester) async {
      final repo = _googleOnly();
      await _openForm(tester, repo, google);

      await _fillAndSubmit(tester);

      expect(_calls(repo), ['addLocalPassword']);
      expect(repo.endOthersCalls, 0);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('uses the token of the latest successful chooser', (
      tester,
    ) async {
      google.token = null;
      final repo = _googleOnly();
      await _open(tester, repo, google);
      await _continueWithGoogle(tester);
      google.token = 'token-late';
      await _continueWithGoogle(tester);

      await _fillAndSubmit(tester);

      expect(repo.localPasswordAdditions.single.googleIdToken, 'token-late');
    });
  });

  group('while a request is in flight', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.gate = Completer<void>();
      await _openForm(tester, repo, google);
      await _fill(tester);

      await _tapInFlight(tester, _submitLabel);

      expectBusy(tester);
      expect(find.text(_submitLabel), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.gate = Completer<void>();
      await _openForm(tester, repo, google);
      await _fill(tester);

      await _tapInFlight(tester, _submitLabel);
      if (buttonLabelled(_submitLabel).evaluate().isNotEmpty) {
        await tester.tap(buttonLabelled(_submitLabel), warnIfMissed: false);
        await tester.pump();
      }
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.addLocalPasswordCalls, 1);
    });

    testWidgets('keeps the typed values while busy', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.gate = Completer<void>();
      await _openForm(tester, repo, google);
      await _fill(tester);

      await _tapInFlight(tester, _submitLabel);

      _expectTypedKept(tester);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.always = const ApiFailure.network()
        ..addLocalPasswordScript.gate = Completer<void>();
      await _openForm(tester, repo, google);
      await _fill(tester);
      await _tapInFlight(tester, _submitLabel);

      repo.addLocalPasswordScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, buttonLabelled(_submitLabel)), isTrue);
    });

    testWidgets('does not show the result until the request answers', (
      tester,
    ) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.gate = Completer<void>();
      await _openForm(tester, repo, google);
      await _fill(tester);

      await _tapInFlight(tester, _submitLabel);
      await tester.pump(const Duration(seconds: 5));

      expect(find.text(_doneHeading), findsNothing);
      expect(currentPath(tester), _pagePath(UserRole.owner));
      repo.addLocalPasswordScript.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(_doneHeading), findsOneWidget);
    });
  });

  group('failures on the password field', () {
    final cases = <String, ApiFailure>{
      'PASSWORD_TOO_COMMON': const ApiFailure(
        code: 'PASSWORD_TOO_COMMON',
        field: 'password',
        statusCode: 422,
      ),
      'VALIDATION_FAILED': const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'password',
        statusCode: 422,
      ),
    };

    for (final entry in cases.entries) {
      final message = errorMessageFor(entry.value);

      testWidgets('${entry.key} is shown on the password field only', (
        tester,
      ) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        expect(fieldError(tester, _passwordLabel), message);
        expect(fieldError(tester, _confirmLabel), isNull);
        expect(find.text(message), findsOneWidget);
        expect(_snackBar(), findsNothing);
        expect(currentPath(tester), _pagePath(UserRole.owner));
        expect(find.text(_doneHeading), findsNothing);
      });

      testWidgets('${entry.key} is exposed on the field node', (tester) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        expectFieldNode(tester, _passwordLabel, error: message);
      });

      testWidgets('${entry.key} keeps what the user typed', (tester) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        _expectTypedKept(tester);
      });

      testWidgets('${entry.key} leaves the button usable and the form in '
          'place', (tester) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(_enabled(tester, buttonLabelled(_submitLabel)), isTrue);
        expect(buttonLabelled(_googleLabel), findsNothing);
      });

      testWidgets('${entry.key} stays on screen', (tester) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);

        await tester.pump(const Duration(seconds: 10));

        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('a corrected password is sent on the next try with the same '
        'token', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.queue.add(
          const ApiFailure(
            code: 'PASSWORD_TOO_COMMON',
            field: 'password',
            statusCode: 422,
          ),
        );
      await _openForm(tester, repo, google);
      await _fillAndSubmit(tester, password: 'password123');

      await _fillAndSubmit(tester);

      expect(repo.localPasswordAdditions, [
        (googleIdToken: 'token-1', password: 'password123'),
        (googleIdToken: 'token-1', password: _secret),
      ]);
      expect(find.text(_doneHeading), findsOneWidget);
      expect(google.requests, 1);
    });

    testWidgets('a field error goes away when the request starts again', (
      tester,
    ) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.queue.add(
          const ApiFailure(
            code: 'PASSWORD_TOO_COMMON',
            field: 'password',
            statusCode: 422,
          ),
        );
      await _openForm(tester, repo, google);
      await _fillAndSubmit(tester);
      repo.addLocalPasswordScript.gate = Completer<void>();

      await _tapInFlight(tester, _submitLabel);

      expect(find.text(messageOfCode('PASSWORD_TOO_COMMON')), findsNothing);
      expect(repo.addLocalPasswordCalls, 2);
      repo.addLocalPasswordScript.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('failures at the form', () {
    final cases = <String, ApiFailure>{
      'TOO_MANY_ATTEMPTS': const ApiFailure(
        code: 'TOO_MANY_ATTEMPTS',
        statusCode: 429,
      ),
      'NETWORK_ERROR': const ApiFailure.network(),
      'INTERNAL_ERROR': const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      ),
      'FORBIDDEN': const ApiFailure(code: 'FORBIDDEN', statusCode: 403),
      'SOMETHING_NEW': const ApiFailure(code: 'SOMETHING_NEW'),
    };

    for (final entry in cases.entries) {
      final message = messageOfCode(entry.key);

      testWidgets('${entry.key} is a message at the form, not on a field', (
        tester,
      ) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        expect(find.text(message), findsOneWidget);
        expect(_snackBar(), findsNothing);
        _expectNoFieldErrors(tester);
        expect(currentPath(tester), _pagePath(UserRole.owner));
        expect(find.text(_doneHeading), findsNothing);
      });

      testWidgets('${entry.key} stays on screen as a live region', (
        tester,
      ) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(message), findsOneWidget);
        expectLiveRegion(tester, message);
      });

      testWidgets('${entry.key} keeps what the user typed and allows a retry '
          'with the same token', (tester) async {
        final repo = _googleOnly()..addLocalPasswordScript.always = entry.value;
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);

        _expectTypedKept(tester);
        await _submit(tester);

        expect(repo.addLocalPasswordCalls, 2);
        expect(repo.localPasswordAdditions.last, (
          googleIdToken: 'token-1',
          password: _secret,
        ));
        expect(google.requests, 1);
      });
    }

    testWidgets('the message goes away when the next request starts', (
      tester,
    ) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.always = const ApiFailure.network();
      await _openForm(tester, repo, google);
      await _fillAndSubmit(tester);
      repo.addLocalPasswordScript.gate = Completer<void>();

      await _tapInFlight(tester, _submitLabel);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      repo.addLocalPasswordScript.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a retry that succeeds shows the done state', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.queue.add(const ApiFailure.network());
      await _openForm(tester, repo, google);
      await _fillAndSubmit(tester);

      await _submit(tester);

      expect(repo.addLocalPasswordCalls, 2);
      expect(find.text(_doneHeading), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });
  });

  group('failures that send the user back to Google', () {
    final cases = <String, String>{
      'GOOGLE_ACCOUNT_MISMATCH': _googleMismatch,
      'GOOGLE_TOKEN_INVALID': _googleInvalid,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} shows its message on the intro again', (
        tester,
      ) async {
        final repo = _googleOnly()
          ..addLocalPasswordScript.always = ApiFailure(code: entry.key);
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        expect(find.text(entry.value), findsOneWidget);
        _expectIntro(tester);
        expect(_enabled(tester, buttonLabelled(_googleLabel)), isTrue);
        expect(find.text(_doneHeading), findsNothing);
        expect(_snackBar(), findsNothing);
        expect(find.textContaining(entry.key), findsNothing);
        expect(currentPath(tester), _pagePath(UserRole.owner));
      });

      testWidgets('${entry.key} message is a live region that stays', (
        tester,
      ) async {
        final repo = _googleOnly()
          ..addLocalPasswordScript.always = ApiFailure(code: entry.key);
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(entry.value), findsOneWidget);
        expectLiveRegion(tester, entry.value);
      });

      testWidgets('${entry.key} lets the user choose an account again and '
          'finish', (tester) async {
        final repo = _googleOnly()
          ..addLocalPasswordScript.queue.add(ApiFailure(code: entry.key));
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);
        google.token = 'token-2';

        await _continueWithGoogle(tester);
        expect(find.text(entry.value), findsNothing);
        await _fillAndSubmit(tester);

        expect(google.requests, 2);
        expect(repo.localPasswordAdditions.map((a) => a.googleIdToken), [
          'token-1',
          'token-2',
        ]);
        expect(find.text(_doneHeading), findsOneWidget);
      });

      testWidgets('${entry.key} message goes away when the next chooser '
          'starts', (tester) async {
        final repo = _googleOnly()
          ..addLocalPasswordScript.always = ApiFailure(code: entry.key);
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);
        google.gate = Completer<void>();

        await _tapInFlight(tester, _googleLabel);

        expect(find.text(entry.value), findsNothing);
        google.gate!.complete();
        await tester.pumpAndSettle();
      });
    }

    testWidgets('the user who cancels the chooser after a mismatch stays on '
        'the intro', (tester) async {
      final repo = _googleOnly()
        ..addLocalPasswordScript.queue.add(
          const ApiFailure(code: 'GOOGLE_ACCOUNT_MISMATCH'),
        );
      await _openForm(tester, repo, google);
      await _fillAndSubmit(tester);
      google.token = null;

      await _continueWithGoogle(tester);

      _expectIntro(tester);
      expect(repo.addLocalPasswordCalls, 1);
    });
  });

  group('failures that say why the password cannot be added', () {
    final cases = <String, String>{
      'PASSWORD_ALREADY_SET': _alreadySet,
      'GOOGLE_NOT_LINKED': _notLinked,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} shows its message once', (tester) async {
        final repo = _googleOnly()
          ..addLocalPasswordScript.always = ApiFailure(code: entry.key);
        await _openForm(tester, repo, google);

        await _fillAndSubmit(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(_doneHeading), findsNothing);
        expect(_snackBar(), findsNothing);
        expect(find.textContaining(entry.key), findsNothing);
        expect(currentPath(tester), _pagePath(UserRole.owner));
      });

      testWidgets('${entry.key} message stays on screen as a live region', (
        tester,
      ) async {
        final repo = _googleOnly()
          ..addLocalPasswordScript.always = ApiFailure(code: entry.key);
        await _openForm(tester, repo, google);
        await _fillAndSubmit(tester);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(entry.value), findsOneWidget);
        expectLiveRegion(tester, entry.value);
      });
    }
  });

  group('the done state', () {
    for (final role in _roles) {
      testWidgets('shows the confirmation and the way back for a $role', (
        tester,
      ) async {
        final repo = _googleOnly(role: role);
        await _complete(tester, repo, google, role: role);

        expect(find.text(_doneHeading), findsOneWidget);
        expect(buttonLabelled(_backToAccount), findsOneWidget);
        expect(currentPath(tester), _pagePath(role));
        expect(_calls(repo), ['addLocalPassword']);
      });

      testWidgets('Kembali ke Akun returns a $role to Akun, which shows the '
          'password as set', (tester) async {
        final repo = _googleOnly(role: role);
        await _complete(tester, repo, google, role: role);

        await _tapButton(tester, _backToAccount);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Diatur'), findsOneWidget);
        expect(find.text('Ubah'), findsOneWidget);
        expect(find.text('Belum diatur'), findsNothing);
        expect(find.text('Tambah'), findsNothing);
        expect(repo.meCalls, greaterThanOrEqualTo(2));
      });

      testWidgets('Kembali in the app bar also returns a $role to Akun with '
          'the password shown as set', (tester) async {
        final repo = _googleOnly(role: role);
        await pumpAccountApp(tester, repo, role: role, google: google);
        await tester.tap(find.text('Tambah'));
        await tester.pumpAndSettle();
        await _continueWithGoogle(tester);
        await _fillAndSubmit(tester);

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.text('Diatur'), findsOneWidget);
        expect(find.text('Belum diatur'), findsNothing);
      });
    }

    testWidgets('leaves the form and the intro behind', (tester) async {
      await _complete(tester, _googleOnly(), google);

      _expectNoFormLeft(tester);
    });

    testWidgets('keeps the confirmation on screen as a live region, not a '
        'snack bar', (tester) async {
      await _complete(tester, _googleOnly(), google);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_doneHeading), findsOneWidget);
      expect(_snackBar(), findsNothing);
      expectLiveRegion(tester, _doneHeading);
    });

    testWidgets('does not show the password', (tester) async {
      await _complete(tester, _googleOnly(), google);

      _expectNoPasswordShown(tester, [_secret]);
    });

    testWidgets('the way back is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await _complete(tester, _googleOnly(), google);

      final rect = tester.getRect(buttonLabelled(_backToAccount));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
    });

    testWidgets('keeps the bottom navigation covered', (tester) async {
      await _complete(tester, _googleOnly(), google);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('does not end any device', (tester) async {
      final repo = _googleOnly();
      await _complete(tester, repo, google);

      expect(repo.endCalls, 0);
      expect(repo.endOthersCalls, 0);
    });
  });

  group('the password', () {
    testWidgets('is not announced while hidden, in any state', (tester) async {
      const secrets = [_secret];
      final repo = _googleOnly()
        ..addLocalPasswordScript.queue.addAll(const [
          ApiFailure(
            code: 'PASSWORD_TOO_COMMON',
            field: 'password',
            statusCode: 422,
          ),
          ApiFailure(code: 'TOO_MANY_ATTEMPTS', statusCode: 429),
        ]);
      await _openForm(tester, repo, google);
      _expectNoPasswordShown(tester, secrets);

      await _fill(tester);
      _expectNoPasswordShown(tester, secrets);

      await _submit(tester);
      _expectNoPasswordShown(tester, secrets);

      await _submit(tester);
      _expectNoPasswordShown(tester, secrets);
    });

    testWidgets('is not a label or hint, nor text, when revealed', (
      tester,
    ) async {
      await _openForm(tester, _googleOnly(), google);
      await _fill(tester);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();

      _expectNoPasswordShown(tester, [_secret], valueExposed: true);
    });

    testWidgets('is not printed, whatever the outcome', (tester) async {
      final printed = <String>[];
      final previous = debugPrint;
      final repo = _googleOnly()
        ..addLocalPasswordScript.queue.add(
          const ApiFailure(
            code: 'PASSWORD_TOO_COMMON',
            field: 'password',
            statusCode: 422,
          ),
        );

      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      try {
        await runZoned(
          () async {
            await _openForm(tester, repo, google);
            await _fillAndSubmit(tester);
            await _submit(tester);
          },
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => printed.add(line),
          ),
        );
      } finally {
        debugPrint = previous;
      }

      expect(find.text(_doneHeading), findsOneWidget);
      for (final line in printed) {
        expect(line, isNot(contains(_secret)));
        expect(line, isNot(contains('token-1')));
      }
    });
  });

  group('accessibility', () {
    final states =
        <String, Future<void> Function(WidgetTester tester, bool largeText)>{
          'the intro': (tester, largeText) =>
              _open(tester, _googleOnly(), google, largeText: largeText),
          'the intro waiting for Google': (tester, largeText) async {
            google.gate = Completer<void>();
            await _open(tester, _googleOnly(), google, largeText: largeText);
            await _tapInFlight(tester, _googleLabel);
            expect(google.requests, 1);
          },
          'the intro with Google unavailable': (tester, largeText) async {
            google.failure = const ApiFailure(
              code: 'GOOGLE_SIGN_IN_UNAVAILABLE',
            );
            await _open(tester, _googleOnly(), google, largeText: largeText);
            await _continueWithGoogle(tester);
            expect(find.text(_googleUnavailable), findsOneWidget);
          },
          'the intro after a Google mismatch': (tester, largeText) async {
            final repo = _googleOnly()
              ..addLocalPasswordScript.always = const ApiFailure(
                code: 'GOOGLE_ACCOUNT_MISMATCH',
              );
            await _openForm(tester, repo, google, largeText: largeText);
            await _fillAndSubmit(tester);
            expect(find.text(_googleMismatch), findsOneWidget);
          },
          'the intro after an invalid Google token': (tester, largeText) async {
            final repo = _googleOnly()
              ..addLocalPasswordScript.always = const ApiFailure(
                code: 'GOOGLE_TOKEN_INVALID',
              );
            await _openForm(tester, repo, google, largeText: largeText);
            await _fillAndSubmit(tester);
            expect(find.text(_googleInvalid), findsOneWidget);
          },
          'the empty form': (tester, largeText) =>
              _openForm(tester, _googleOnly(), google, largeText: largeText),
          'the form with a typed password': (tester, largeText) async {
            await _openForm(
              tester,
              _googleOnly(),
              google,
              largeText: largeText,
            );
            await _fill(tester, password: 'budi');
            expect(find.text(_weakShort), findsOneWidget);
          },
          'the form with a revealed password': (tester, largeText) async {
            await _openForm(
              tester,
              _googleOnly(),
              google,
              largeText: largeText,
            );
            await _fill(tester);
            await tester.tap(find.text(_toggleLabel));
            await tester.pumpAndSettle();
            expect(
              labeledTextField(tester, _passwordLabel).obscureText,
              isFalse,
            );
          },
          'the form with empty fields flagged': (tester, largeText) async {
            await _openForm(
              tester,
              _googleOnly(),
              google,
              largeText: largeText,
            );
            await _submit(tester);
            expect(fieldError(tester, _passwordLabel), isNotNull);
            expect(fieldError(tester, _confirmLabel), isNotNull);
          },
          'the form with a mismatch': (tester, largeText) async {
            await _openForm(
              tester,
              _googleOnly(),
              google,
              largeText: largeText,
            );
            await _fillAndSubmit(tester, confirm: 'lain sekali');
            expect(fieldError(tester, _confirmLabel), _mismatchOfConfirmation);
          },
          'the form with a too common password': (tester, largeText) async {
            final repo = _googleOnly()
              ..addLocalPasswordScript.always = const ApiFailure(
                code: 'PASSWORD_TOO_COMMON',
                field: 'password',
                statusCode: 422,
              );
            await _openForm(tester, repo, google, largeText: largeText);
            await _fillAndSubmit(tester);
            expect(
              fieldError(tester, _passwordLabel),
              messageOfCode('PASSWORD_TOO_COMMON'),
            );
          },
          'the form with a message at the form': (tester, largeText) async {
            final repo = _googleOnly()
              ..addLocalPasswordScript.always = const ApiFailure.network();
            await _openForm(tester, repo, google, largeText: largeText);
            await _fillAndSubmit(tester);
            expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
          },
          'the form after the account already has a password':
              (tester, largeText) async {
                final repo = _googleOnly()
                  ..addLocalPasswordScript.always = const ApiFailure(
                    code: 'PASSWORD_ALREADY_SET',
                  );
                await _openForm(tester, repo, google, largeText: largeText);
                await _fillAndSubmit(tester);
                expect(find.text(_alreadySet), findsOneWidget);
              },
          'the form while busy': (tester, largeText) async {
            final repo = _googleOnly()
              ..addLocalPasswordScript.gate = Completer<void>();
            await _openForm(tester, repo, google, largeText: largeText);
            await _fill(tester);
            await _tapInFlight(tester, _submitLabel);
            expectBusy(tester);
          },
          'the done state': (tester, largeText) =>
              _complete(tester, _googleOnly(), google, largeText: largeText),
          'the account tab after adding the password':
              (tester, largeText) async {
                await _complete(
                  tester,
                  _googleOnly(),
                  google,
                  largeText: largeText,
                );
                await _tapButton(tester, _backToAccount);
                expect(find.text('Diatur'), findsOneWidget);
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
      testWidgets('meets the guidelines on the intro, form and done state '
          'for a $role', (tester) async {
        final repo = _googleOnly(role: role);
        await _open(tester, repo, google, role: role);
        await expectMeetsA11yGuidelines(tester);

        await _continueWithGoogle(tester);
        await expectMeetsA11yGuidelines(tester);

        await _fillAndSubmit(tester);
        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size on the intro and form for a '
          '$role', (tester) async {
        await _openForm(
          tester,
          _googleOnly(role: role),
          google,
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}

void _expectNoFormLeft(WidgetTester tester) {
  expect(field(_passwordLabel), findsNothing);
  expect(field(_confirmLabel), findsNothing);
  expect(buttonLabelled(_submitLabel), findsNothing);
  expect(buttonLabelled(_googleLabel), findsNothing);
  expect(find.text(_introHeading), findsNothing);
}
