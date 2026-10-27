import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
import 'account_ui_helpers.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _current = 'Kata sandi saat ini (wajib)';
const _new = 'Kata sandi baru (wajib)';
const _confirm = 'Konfirmasi kata sandi baru (wajib)';

const _submitLabel = 'Simpan kata sandi';
const _toggleLabel = 'Tampilkan kata sandi';
const _helper =
    'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa aturan huruf '
    'atau simbol khusus.';

const _currentPassword = 'kopi tubruk pagi';
const _newPassword = 'teh manis sore hari';

const _mismatch = 'Konfirmasi tidak sama dengan kata sandi baru.';
const _plainConfirmation = 'Kata sandi diperbarui.';
const _combinedConfirmation =
    'Kata sandi diperbarui. Perangkat lain telah dikeluarkan.';
const _dialogTitle = 'Kata sandi berhasil diubah';
const _endOthersLabel = 'Keluarkan perangkat lain';
const _stayLabel = 'Tetap masuk';

const _strengthHint = 'Kekuatan kata sandi akan muncul saat Anda mengetik.';
const _guessable = 'Kekuatan: Lemah · mudah ditebak';
const _tooShort = 'Kekuatan: Lemah · terlalu pendek';
const _fair = 'Kekuatan: Cukup · tambah panjangnya agar lebih aman';
const _strong = 'Kekuatan: Kuat · sudah aman';
const _veryStrong = 'Kekuatan: Sangat kuat · sangat sulit ditebak';

String _pagePath(UserRole role) => '${accountPath(role)}/kata-sandi';

/// An account with other devices, so a change offers to end them.
FakeAccountRepository _withOthers({Account? account}) => FakeAccountRepository(
  account: account,
  devices: [
    makeSession(id: 'current', deviceName: 'Pixel 8', isCurrent: true),
    makeSession(id: 's2', deviceName: 'Galaxy A54'),
  ],
);

/// An account whose only device is the current one.
FakeAccountRepository _alone({Account? account}) => FakeAccountRepository(
  account: account,
  devices: [makeSession(id: 'current', deviceName: 'Pixel 8', isCurrent: true)],
);

FakeAccountRepository _failing(ApiFailure failure) =>
    _alone()..changePasswordScript.always = failure;

Future<void> _open(
  WidgetTester tester,
  FakeAccountRepository repo, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) async {
  await pumpAccountApp(
    tester,
    repo,
    role: role,
    path: _pagePath(role),
    settle: settle,
    largeText: largeText,
  );
  expect(currentPath(tester), _pagePath(role));
}

Future<void> _fill(
  WidgetTester tester, {
  String current = _currentPassword,
  String next = _newPassword,
  String? confirm,
}) async {
  await type(tester, _current, current);
  await type(tester, _new, next);
  await type(tester, _confirm, confirm ?? next);
}

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled(_submitLabel));

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String current = _currentPassword,
  String next = _newPassword,
  String? confirm,
}) async {
  await _fill(tester, current: current, next: next, confirm: confirm);
  await _submit(tester);
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.tap(buttonLabelled(label));
  await tester.pumpAndSettle();
}

/// The calls of the repository other than the profile and device loads that
/// the account screens make by themselves.
List<String> _calls(FakeAccountRepository repo) =>
    repo.calls.where((c) => c != 'me' && c != 'sessions').toList();

Finder _snackBar() => find.byType(SnackBar);

/// A `Text` or `RichText` that shows [value], so that the typed text of an
/// editable field does not match.
Finder _textShowing(String value) => find.byWidgetPredicate(
  (widget) =>
      (widget is Text &&
          (widget.data ?? widget.textSpan?.toPlainText() ?? '').contains(
            value,
          )) ||
      (widget is RichText && widget.text.toPlainText().contains(value)),
  description: 'text showing "$value"',
);

void _expectNoFieldErrors(WidgetTester tester) {
  for (final label in [_current, _new, _confirm]) {
    expect(fieldError(tester, label), isNull, reason: label);
  }
}

String _typed(WidgetTester tester, String label) =>
    tester.widget<TextField>(fieldLabeled(label)).controller!.text;

void _expectTypedKept(
  WidgetTester tester, {
  String current = _currentPassword,
  String next = _newPassword,
  String? confirm,
}) {
  expect(_typed(tester, _current), current);
  expect(_typed(tester, _new), next);
  expect(_typed(tester, _confirm), confirm ?? next);
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
  group('the page', () {
    for (final role in _roles) {
      testWidgets('is titled Ubah kata sandi for a $role', (tester) async {
        await _open(tester, _alone(), role: role);

        expect(appBarTitle('Ubah kata sandi'), findsOneWidget);
        expect(currentPath(tester), _pagePath(role));
      });
    }

    testWidgets('uses the white detail app bar with a back button', (
      tester,
    ) async {
      await _open(tester, _alone());

      expect(find.byType(DetailAppBar), findsOneWidget);
      expectDetailAppBar(tester);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('announces the title as a header', (tester) async {
      await _open(tester, _alone());

      _expectHeader(tester, appBarTitle('Ubah kata sandi'));
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester, _alone());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('shows the three labelled fields, the helper and the button', (
      tester,
    ) async {
      await _open(tester, _alone());

      expect(field(_current), findsOneWidget);
      expect(field(_new), findsOneWidget);
      expect(field(_confirm), findsOneWidget);
      expect(find.text(_helper), findsOneWidget);
      expect(find.text(_toggleLabel), findsOneWidget);
      expect(buttonLabelled(_submitLabel), findsOneWidget);
    });

    testWidgets('places the fields in order: current, new, confirm', (
      tester,
    ) async {
      await _open(tester, _alone());

      final current = tester.getTopLeft(fieldLabeled(_current)).dy;
      final next = tester.getTopLeft(fieldLabeled(_new)).dy;
      final confirm = tester.getTopLeft(fieldLabeled(_confirm)).dy;
      expect(current, lessThan(next));
      expect(next, lessThan(confirm));
    });

    testWidgets('puts the helper with the new password field', (tester) async {
      await _open(tester, _alone());

      final helper = tester.getTopLeft(find.text(_helper)).dy;
      expect(helper, greaterThan(tester.getTopLeft(find.text(_new)).dy));
      expect(helper, lessThan(tester.getTopLeft(find.text(_confirm)).dy));
    });

    testWidgets('starts empty, without errors and without a request', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      _expectTypedKept(tester, current: '', next: '', confirm: '');
      _expectNoFieldErrors(tester);
      expect(_snackBar(), findsNothing);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('starts with the three passwords hidden', (tester) async {
      await _open(tester, _alone());

      for (final label in [_current, _new, _confirm]) {
        expect(labeledTextField(tester, label).obscureText, isTrue);
      }
    });

    testWidgets('Kembali returns to the account tab without a request', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('never prints null or an English term', (tester) async {
      await _open(tester, _alone());

      expect(find.textContaining('null'), findsNothing);
      for (final english in ['Password', 'Current', 'Confirm', 'Save']) {
        expect(find.textContaining(english), findsNothing);
      }
    });
  });

  group('the fields', () {
    testWidgets('keep paste on and offer password autofill for the current '
        'password', (tester) async {
      await _open(tester, _alone());

      expectCredentialField(tester, _current, AutofillHints.password);
    });

    testWidgets('keep paste on and offer new password autofill for the new '
        'password and its confirmation', (tester) async {
      await _open(tester, _alone());

      expectCredentialField(tester, _new, AutofillHints.newPassword);
      expectCredentialField(tester, _confirm, AutofillHints.newPassword);
    });

    testWidgets('draw no label inside the field', (tester) async {
      await _open(tester, _alone());

      expectNoDecorationLabels(tester);
    });

    testWidgets('put each label above its field and read it once', (
      tester,
    ) async {
      await _open(tester, _alone());

      for (final label in [_current, _new, _confirm]) {
        expect(
          tester.getRect(find.text(label)).bottom,
          lessThanOrEqualTo(tester.getRect(fieldLabeled(label)).top),
        );
        expectFieldNode(tester, label);
      }
    });

    testWidgets('keep each field error on its field node', (tester) async {
      await _open(tester, _alone());
      await _submit(tester);

      for (final label in [_current, _new, _confirm]) {
        final error = fieldError(tester, label);
        expect(error, isNotNull, reason: label);
        expectFieldNode(tester, label, error: error);
      }
    });
  });

  group('show password', () {
    testWidgets('one checkbox reveals and hides all three fields', (
      tester,
    ) async {
      await _open(tester, _alone());
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      for (final label in [_current, _new, _confirm]) {
        expect(labeledTextField(tester, label).obscureText, isFalse);
      }

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      for (final label in [_current, _new, _confirm]) {
        expect(labeledTextField(tester, label).obscureText, isTrue);
      }
    });

    testWidgets('is a labelled checkbox of at least 48 dp', (tester) async {
      await _open(tester, _alone());
      expectShowPasswordCheckbox(tester, checked: false);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      expectShowPasswordCheckbox(tester, checked: true);
    });

    testWidgets('keeps the typed text when toggled', (tester) async {
      await _open(tester, _alone());
      await _fill(tester);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();

      _expectTypedKept(tester);
    });

    testWidgets('stays revealed after a failed request', (tester) async {
      await _open(tester, _failing(const ApiFailure.network()));
      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();

      await _fillAndSubmit(tester);

      for (final label in [_current, _new, _confirm]) {
        expect(labeledTextField(tester, label).obscureText, isFalse);
      }
    });
  });

  group('strength hint', () {
    testWidgets('invites typing while the new password is empty', (
      tester,
    ) async {
      await _open(tester, _alone());

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('follows the new password while typing', (tester) async {
      await _open(tester, _alone());

      await type(tester, _new, 'abc');
      expect(find.text(_tooShort), findsOneWidget);

      await type(tester, _new, 'kopi tubruk');
      expect(find.text(_fair), findsOneWidget);

      await type(tester, _new, 'kopi tubruk pa');
      expect(find.text(_strong), findsOneWidget);

      await type(tester, _new, 'kopi tubruk pagi');
      expect(find.text(_veryStrong), findsOneWidget);
    });

    testWidgets('ignores the current password and the confirmation', (
      tester,
    ) async {
      await _open(tester, _alone());

      await type(tester, _current, 'kopi tubruk pagi');
      await type(tester, _confirm, 'kopi tubruk pagi');

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('shows a single strength line at a time', (tester) async {
      await _open(tester, _alone());

      await type(tester, _new, 'kopi tubruk pagi');

      expect(find.textContaining('Kekuatan'), findsOneWidget);
    });

    testWidgets('flags a common password as easy to guess', (tester) async {
      await _open(tester, _alone());

      await type(tester, _new, 'password123');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('goes back to the invitation when the password is cleared', (
      tester,
    ) async {
      await _open(tester, _alone());
      await type(tester, _new, 'kopi tubruk pagi');

      await type(tester, _new, '');

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('weakens a password that contains the name of the account', (
      tester,
    ) async {
      final repo = _alone(
        account: makeAccount(name: 'Budi Santoso', email: 'sarip@example.com'),
      );
      await _open(tester, repo);

      await type(tester, _new, 'kopi tubruk pagi');
      expect(find.text(_veryStrong), findsOneWidget);

      await type(tester, _new, 'budi-kopi-tubruk');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('weakens a password that contains the email of the account', (
      tester,
    ) async {
      final repo = _alone(
        account: makeAccount(name: 'Budi Santoso', email: 'sarip@example.com'),
      );
      await _open(tester, repo);

      await type(tester, _new, 'sarip-kopi-tubruk');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('announces the strength line as a live region', (tester) async {
      await _open(tester, _alone());
      await type(tester, _new, 'kopi tubruk pagi');

      expectLiveRegion(tester, _veryStrong);
    });

    testWidgets('exposes only the strength text, not the bars, to semantics', (
      tester,
    ) async {
      await _open(tester, _alone());
      await type(tester, _new, 'kopi tubruk pagi');
      final handle = tester.ensureSemantics();

      expect(find.bySemanticsLabel(RegExp('Kekuatan')), findsOneWidget);
      handle.dispose();
    });
  });

  group('validation', () {
    testWidgets('an empty form shows an error on every field and sends '
        'nothing', (tester) async {
      final repo = _withOthers();
      await _open(tester, repo);

      await _submit(tester);

      for (final label in [_current, _new, _confirm]) {
        final error = fieldError(tester, label);
        expect(error, isNotNull, reason: label);
        expect(error, isNotEmpty, reason: label);
        expect(find.text(error!), findsAtLeastNWidgets(1));
      }
      expect(repo.changePasswordCalls, 0);
      expect(find.text(_dialogTitle), findsNothing);
      expect(currentPath(tester), _pagePath(UserRole.owner));
    });

    testWidgets('an empty current password is the only error', (tester) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester, current: '');

      expect(fieldError(tester, _current), isNotNull);
      expect(fieldError(tester, _new), isNull);
      expect(fieldError(tester, _confirm), isNull);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('an empty new password shows an error and sends nothing', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester, next: '', confirm: '');

      expect(fieldError(tester, _current), isNull);
      expect(fieldError(tester, _new), isNotNull);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('an empty confirmation shows an error on the confirmation', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester, confirm: '');

      expect(fieldError(tester, _current), isNull);
      expect(fieldError(tester, _new), isNull);
      expect(fieldError(tester, _confirm), isNotNull);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('a confirmation that differs from the new password is an '
        'error next to the confirmation', (tester) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester, confirm: 'teh manis sore hari ini');

      expect(fieldError(tester, _confirm), _mismatch);
      expect(fieldError(tester, _current), isNull);
      expect(fieldError(tester, _new), isNull);
      expect(find.text(_mismatch), findsOneWidget);
      expect(repo.changePasswordCalls, 0);
      _expectTypedKept(tester, confirm: 'teh manis sore hari ini');
    });

    testWidgets('compares the confirmation without trimming', (tester) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester, confirm: '$_newPassword ');

      expect(fieldError(tester, _confirm), _mismatch);
      expect(repo.changePasswordCalls, 0);
    });

    testWidgets('a mismatch is a field error, not a message at the form', (
      tester,
    ) async {
      await _open(tester, _alone());

      await _fillAndSubmit(tester, confirm: 'teh manis sore hari ini');

      expect(_snackBar(), findsNothing);
      expect(find.text(_mismatch), findsOneWidget);
    });

    testWidgets('the mismatch error is exposed on the confirmation node', (
      tester,
    ) async {
      await _open(tester, _alone());

      await _fillAndSubmit(tester, confirm: 'teh manis sore hari ini');

      expectFieldNode(tester, _confirm, error: _mismatch);
    });

    testWidgets('errors disappear once the form is fixed and sent again', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);
      await _submit(tester);

      await _fillAndSubmit(tester);

      expect(repo.changePasswordCalls, 1);
      expect(find.text(_mismatch), findsNothing);
    });

    testWidgets('a corrected confirmation is sent after a mismatch', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);
      await _fillAndSubmit(tester, confirm: 'teh manis sore hari ini');

      await type(tester, _confirm, _newPassword);
      await _submit(tester);

      expect(repo.passwordChanges, [
        (currentPassword: _currentPassword, newPassword: _newPassword),
      ]);
      expect(find.text(_mismatch), findsNothing);
    });

    testWidgets('does not ask the API to compare the two new passwords', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester, confirm: 'lain sekali');

      expect(repo.calls.where((c) => c == 'changePassword'), isEmpty);
    });
  });

  group('submit', () {
    testWidgets('sends the current and the new password untrimmed, once', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(
        tester,
        current: ' kopi tubruk ',
        next: '  teh manis sore  ',
      );

      expect(repo.passwordChanges, [
        (currentPassword: ' kopi tubruk ', newPassword: '  teh manis sore  '),
      ]);
    });

    testWidgets('does not send the confirmation as a separate value', (
      tester,
    ) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester);

      expect(repo.passwordChanges.single.newPassword, _newPassword);
      expect(repo.passwordChanges.single.currentPassword, _currentPassword);
    });

    testWidgets('does not end any device by itself', (tester) async {
      final repo = _withOthers();
      await _open(tester, repo);

      await _fillAndSubmit(tester);

      expect(repo.endCalls, 0);
      expect(repo.endOthersCalls, 0);
    });
  });

  group('while a request is in flight', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      final repo = _alone()..changePasswordScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);

      await tapAndPump(tester, buttonLabelled(_submitLabel));

      expectBusy(tester);
      expect(find.text(_submitLabel), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      final repo = _alone()..changePasswordScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);
      final button = buttonLabelled(_submitLabel);

      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.changePasswordCalls, 1);
    });

    testWidgets('keeps the typed values while busy', (tester) async {
      final repo = _alone()..changePasswordScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);

      await tapAndPump(tester, buttonLabelled(_submitLabel));

      _expectTypedKept(tester);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      final repo = _failing(const ApiFailure.network())
        ..changePasswordScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);
      await tapAndPump(tester, buttonLabelled(_submitLabel));

      repo.changePasswordScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(buttonLabelled(_submitLabel))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('does not leave the page until the request answers', (
      tester,
    ) async {
      final repo = _alone()..changePasswordScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);

      await tapAndPump(tester, buttonLabelled(_submitLabel));
      await tester.pump(const Duration(seconds: 5));

      expect(currentPath(tester), _pagePath(UserRole.owner));
      expect(find.text(_plainConfirmation), findsNothing);
    });
  });

  group('failures on a field', () {
    final cases = <String, ({ApiFailure failure, String label, String other})>{
      'CURRENT_PASSWORD_INCORRECT': (
        failure: const ApiFailure(
          code: 'CURRENT_PASSWORD_INCORRECT',
          field: 'currentPassword',
          statusCode: 422,
        ),
        label: _current,
        other: _new,
      ),
      'PASSWORD_UNCHANGED': (
        failure: const ApiFailure(
          code: 'PASSWORD_UNCHANGED',
          field: 'newPassword',
          statusCode: 422,
        ),
        label: _new,
        other: _current,
      ),
      'PASSWORD_TOO_COMMON': (
        failure: const ApiFailure(
          code: 'PASSWORD_TOO_COMMON',
          field: 'newPassword',
          statusCode: 422,
        ),
        label: _new,
        other: _current,
      ),
    };

    for (final entry in cases.entries) {
      final message = messageOfCode(entry.key);

      testWidgets('${entry.key} is shown on its field only', (tester) async {
        await _open(tester, _failing(entry.value.failure));

        await _fillAndSubmit(tester);

        expect(fieldError(tester, entry.value.label), message);
        expect(fieldError(tester, entry.value.other), isNull);
        expect(fieldError(tester, _confirm), isNull);
        expect(find.text(message), findsOneWidget);
        expect(_snackBar(), findsNothing);
        expect(currentPath(tester), _pagePath(UserRole.owner));
      });

      testWidgets('${entry.key} is exposed on the field node', (tester) async {
        await _open(tester, _failing(entry.value.failure));

        await _fillAndSubmit(tester);

        expectFieldNode(tester, entry.value.label, error: message);
      });

      testWidgets('${entry.key} keeps what the user typed', (tester) async {
        await _open(tester, _failing(entry.value.failure));

        await _fillAndSubmit(tester);

        _expectTypedKept(tester);
      });

      testWidgets('${entry.key} leaves the button usable again', (
        tester,
      ) async {
        await _open(tester, _failing(entry.value.failure));

        await _fillAndSubmit(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester
              .widget<ButtonStyleButton>(buttonLabelled(_submitLabel))
              .onPressed,
          isNotNull,
        );
      });

      testWidgets('${entry.key} stays on screen without a prompt', (
        tester,
      ) async {
        await _open(tester, _failing(entry.value.failure));
        await _fillAndSubmit(tester);

        await tester.pump(const Duration(seconds: 10));

        expect(find.text(message), findsOneWidget);
        expect(find.text(_dialogTitle), findsNothing);
      });
    }

    testWidgets('a corrected current password is sent on the next try', (
      tester,
    ) async {
      final repo = _alone()
        ..changePasswordScript.queue.add(
          const ApiFailure(
            code: 'CURRENT_PASSWORD_INCORRECT',
            field: 'currentPassword',
            statusCode: 422,
          ),
        );
      await _open(tester, repo);
      await _fillAndSubmit(tester, current: 'salah sekali');

      await type(tester, _current, _currentPassword);
      await _submit(tester);

      expect(repo.passwordChanges, [
        (currentPassword: 'salah sekali', newPassword: _newPassword),
        (currentPassword: _currentPassword, newPassword: _newPassword),
      ]);
      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(
        find.text(messageOfCode('CURRENT_PASSWORD_INCORRECT')),
        findsNothing,
      );
    });

    testWidgets('a field error is replaced by the error of the next failure', (
      tester,
    ) async {
      final repo = _alone()
        ..changePasswordScript.queue.addAll(const [
          ApiFailure(
            code: 'CURRENT_PASSWORD_INCORRECT',
            field: 'currentPassword',
            statusCode: 422,
          ),
          ApiFailure(
            code: 'PASSWORD_UNCHANGED',
            field: 'newPassword',
            statusCode: 422,
          ),
        ]);
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await _submit(tester);

      expect(fieldError(tester, _current), isNull);
      expect(fieldError(tester, _new), messageOfCode('PASSWORD_UNCHANGED'));
    });

    testWidgets('a field error goes away when the request starts again', (
      tester,
    ) async {
      final repo = _alone()
        ..changePasswordScript.queue.add(
          const ApiFailure(
            code: 'PASSWORD_TOO_COMMON',
            field: 'newPassword',
            statusCode: 422,
          ),
        );
      await _open(tester, repo);
      await _fillAndSubmit(tester);
      repo.changePasswordScript.gate = Completer<void>();

      await tapAndPump(tester, buttonLabelled(_submitLabel));

      expect(find.text(messageOfCode('PASSWORD_TOO_COMMON')), findsNothing);
      expect(repo.changePasswordCalls, 2);
    });
  });

  group('failures at the form', () {
    final cases = <String, ApiFailure>{
      'TOO_MANY_ATTEMPTS': const ApiFailure(
        code: 'TOO_MANY_ATTEMPTS',
        statusCode: 429,
      ),
      'PASSWORD_NOT_SET': const ApiFailure(
        code: 'PASSWORD_NOT_SET',
        statusCode: 409,
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
        await _open(tester, _failing(entry.value));

        await _fillAndSubmit(tester);

        expect(find.text(message), findsOneWidget);
        expect(_snackBar(), findsNothing);
        _expectNoFieldErrors(tester);
        expect(currentPath(tester), _pagePath(UserRole.owner));
        expect(find.text(_dialogTitle), findsNothing);
      });

      testWidgets('${entry.key} stays on screen as a live region', (
        tester,
      ) async {
        await _open(tester, _failing(entry.value));
        await _fillAndSubmit(tester);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(message), findsOneWidget);
        expectLiveRegion(tester, message);
      });

      testWidgets('${entry.key} keeps what the user typed and allows a retry', (
        tester,
      ) async {
        final repo = _failing(entry.value);
        await _open(tester, repo);
        await _fillAndSubmit(tester);

        _expectTypedKept(tester);
        await _submit(tester);

        expect(repo.changePasswordCalls, 2);
        expect(repo.passwordChanges.last, (
          currentPassword: _currentPassword,
          newPassword: _newPassword,
        ));
      });
    }

    testWidgets('the message goes away when the next request starts', (
      tester,
    ) async {
      final repo = _failing(const ApiFailure.network());
      await _open(tester, repo);
      await _fillAndSubmit(tester);
      repo.changePasswordScript.gate = Completer<void>();

      await tapAndPump(tester, buttonLabelled(_submitLabel));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('a retry that succeeds leaves the page', (tester) async {
      final repo = _alone()
        ..changePasswordScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await _submit(tester);

      expect(repo.changePasswordCalls, 2);
      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.text(_plainConfirmation), findsOneWidget);
    });

    testWidgets('the message of a failure gives way to a field error on the '
        'retry', (tester) async {
      final repo = _alone()
        ..changePasswordScript.queue.addAll(const [
          ApiFailure(code: 'TOO_MANY_ATTEMPTS', statusCode: 429),
          ApiFailure(
            code: 'CURRENT_PASSWORD_INCORRECT',
            field: 'currentPassword',
            statusCode: 422,
          ),
        ]);
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await _submit(tester);

      expect(find.text(messageOfCode('TOO_MANY_ATTEMPTS')), findsNothing);
      expect(
        fieldError(tester, _current),
        messageOfCode('CURRENT_PASSWORD_INCORRECT'),
      );
    });

    testWidgets('the too many attempts message is Indonesian', (tester) async {
      await _open(
        tester,
        _failing(const ApiFailure(code: 'TOO_MANY_ATTEMPTS', statusCode: 429)),
      );

      await _fillAndSubmit(tester);

      expect(
        find.text('Terlalu banyak percobaan. Coba lagi beberapa menit lagi.'),
        findsOneWidget,
      );
    });
  });

  group('success without other devices', () {
    for (final role in _roles) {
      testWidgets('returns a $role to the account tab with the confirmation', (
        tester,
      ) async {
        final repo = _alone(account: makeAccount(role: role));
        await _open(tester, repo, role: role);

        await _fillAndSubmit(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.text(_plainConfirmation), findsOneWidget);
        expect(find.text(_dialogTitle), findsNothing);
        expect(_calls(repo), ['changePassword']);
      });
    }

    testWidgets('shows the bottom navigation again', (tester) async {
      await _open(tester, _alone());

      await _fillAndSubmit(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('does not offer to end other devices', (tester) async {
      final repo = _alone();
      await _open(tester, repo);

      await _fillAndSubmit(tester);

      expect(find.text(_endOthersLabel), findsNothing);
      expect(find.text(_stayLabel), findsNothing);
      expect(repo.endOthersCalls, 0);
    });

    testWidgets('does not offer to end other devices when the API says there '
        'are none', (tester) async {
      final repo = _withOthers()..hasOtherSessions = false;
      await _open(tester, repo);

      await _fillAndSubmit(tester);

      expect(find.text(_dialogTitle), findsNothing);
      expect(find.text(_plainConfirmation), findsOneWidget);
      expect(repo.endOthersCalls, 0);
    });

    testWidgets('shows the confirmation as a live region, not a snack bar', (
      tester,
    ) async {
      await _open(tester, _alone());

      await _fillAndSubmit(tester);

      expect(_snackBar(), findsNothing);
      expectLiveRegion(tester, _plainConfirmation);
    });

    testWidgets('keeps the confirmation on screen', (tester) async {
      await _open(tester, _alone());
      await _fillAndSubmit(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_plainConfirmation), findsOneWidget);
      expect(_snackBar(), findsNothing);
    });

    testWidgets('returns to the account tab after opening from its row', (
      tester,
    ) async {
      final repo = _alone();
      await pumpAccountApp(tester, repo);
      await tester.tap(find.text('Ubah kata sandi'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), _pagePath(UserRole.owner));

      await _fillAndSubmit(tester);

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.text(_plainConfirmation), findsOneWidget);
    });

    testWidgets('leaves the form behind', (tester) async {
      await _open(tester, _alone());

      await _fillAndSubmit(tester);

      expect(field(_current), findsNothing);
      expect(buttonLabelled(_submitLabel), findsNothing);
    });

    testWidgets('does not show the passwords on the account tab', (
      tester,
    ) async {
      await _open(tester, _alone());

      await _fillAndSubmit(tester);

      _expectNoPasswordShown(tester, [_currentPassword, _newPassword]);
    });
  });

  group('success with other devices', () {
    testWidgets('asks before leaving, without ending any device', (
      tester,
    ) async {
      final repo = _withOthers();
      await _open(tester, repo);

      await _fillAndSubmit(tester);

      expect(find.text(_dialogTitle), findsOneWidget);
      expect(buttonLabelled(_endOthersLabel), findsOneWidget);
      expect(buttonLabelled(_stayLabel), findsOneWidget);
      expect(currentPath(tester), _pagePath(UserRole.owner));
      expect(repo.endOthersCalls, 0);
      expect(repo.changePasswordCalls, 1);
    });

    testWidgets('the prompt is modal: a barrier blocks the form behind it', (
      tester,
    ) async {
      await _open(tester, _withOthers());

      await _fillAndSubmit(tester);

      expect(find.byType(ModalBarrier), findsWidgets);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, isNotNull);
    });

    testWidgets('the prompt offers both choices as buttons of at least 48 dp', (
      tester,
    ) async {
      await _open(tester, _withOthers());

      await _fillAndSubmit(tester);

      for (final label in [_endOthersLabel, _stayLabel]) {
        final rect = tester.getRect(buttonLabelled(label));
        expect(rect.height, greaterThanOrEqualTo(48), reason: label);
        expect(rect.width, greaterThanOrEqualTo(48), reason: label);
      }
    });

    for (final role in _roles) {
      testWidgets('Tetap masuk returns a $role to the account tab with the '
          'plain confirmation', (tester) async {
        final repo = _withOthers(account: makeAccount(role: role));
        await _open(tester, repo, role: role);
        await _fillAndSubmit(tester);

        await _tapButton(tester, _stayLabel);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.text(_dialogTitle), findsNothing);
        expect(find.text(_plainConfirmation), findsOneWidget);
        expect(find.text(_combinedConfirmation), findsNothing);
        expect(repo.endOthersCalls, 0);
        expect(repo.devices, hasLength(2));
      });

      testWidgets('Keluarkan perangkat lain ends the other devices and returns '
          'a $role to the account tab', (tester) async {
        final repo = _withOthers(account: makeAccount(role: role));
        await _open(tester, repo, role: role);
        await _fillAndSubmit(tester);

        await _tapButton(tester, _endOthersLabel);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.text(_dialogTitle), findsNothing);
        expect(find.text(_combinedConfirmation), findsOneWidget);
        expect(find.text(_plainConfirmation), findsNothing);
        expect(_calls(repo), ['changePassword', 'endOthers']);
        expect(repo.devices.map((s) => s.id), ['current']);
      });
    }

    testWidgets('the combined confirmation is a live region, not a snack '
        'bar, and stays', (tester) async {
      await _open(tester, _withOthers());
      await _fillAndSubmit(tester);

      await _tapButton(tester, _endOthersLabel);
      await tester.pump(const Duration(seconds: 30));

      expect(_snackBar(), findsNothing);
      expect(find.text(_combinedConfirmation), findsOneWidget);
      expectLiveRegion(tester, _combinedConfirmation);
    });

    testWidgets('the plain confirmation after Tetap masuk is a live region '
        'and stays', (tester) async {
      await _open(tester, _withOthers());
      await _fillAndSubmit(tester);

      await _tapButton(tester, _stayLabel);
      await tester.pump(const Duration(seconds: 30));

      expect(_snackBar(), findsNothing);
      expectLiveRegion(tester, _plainConfirmation);
    });

    testWidgets('a double tap on Keluarkan perangkat lain ends once', (
      tester,
    ) async {
      final repo = _withOthers()..endOthersScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await tester.tap(buttonLabelled(_endOthersLabel));
      await tester.pump();
      if (buttonLabelled(_endOthersLabel).evaluate().isNotEmpty) {
        await tester.tap(buttonLabelled(_endOthersLabel), warnIfMissed: false);
        await tester.pump();
      }

      expect(repo.endOthersCalls, 1);
      expect(repo.changePasswordCalls, 1);
    });

    testWidgets('waits for the end of the other devices before leaving', (
      tester,
    ) async {
      final repo = _withOthers()..endOthersScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await tester.tap(buttonLabelled(_endOthersLabel));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(currentPath(tester), _pagePath(UserRole.owner));
      expect(find.text(_combinedConfirmation), findsNothing);

      repo.endOthersScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.text(_combinedConfirmation), findsOneWidget);
    });

    testWidgets('does not send the password change again', (tester) async {
      final repo = _withOthers();
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await _tapButton(tester, _endOthersLabel);

      expect(repo.changePasswordCalls, 1);
    });

    testWidgets('does not show the passwords in the prompt', (tester) async {
      await _open(tester, _withOthers());

      await _fillAndSubmit(tester);

      _expectNoPasswordShown(tester, [_currentPassword, _newPassword]);
    });
  });

  group('when ending the other devices fails', () {
    final failures = <String, ApiFailure>{
      'NETWORK_ERROR': const ApiFailure.network(),
      'FORBIDDEN': const ApiFailure(code: 'FORBIDDEN', statusCode: 403),
      'INTERNAL_ERROR': const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      ),
    };

    for (final entry in failures.entries) {
      final message = messageOfCode(entry.key);

      testWidgets('${entry.key} shows its message and keeps both choices', (
        tester,
      ) async {
        final repo = _withOthers()..endOthersScript.always = entry.value;
        await _open(tester, repo);
        await _fillAndSubmit(tester);

        await _tapButton(tester, _endOthersLabel);

        expect(find.text(message), findsOneWidget);
        expect(buttonLabelled(_endOthersLabel), findsOneWidget);
        expect(buttonLabelled(_stayLabel), findsOneWidget);
        expect(currentPath(tester), _pagePath(UserRole.owner));
        expect(repo.devices, hasLength(2));
      });

      testWidgets('${entry.key} message stays on screen', (tester) async {
        final repo = _withOthers()..endOthersScript.always = entry.value;
        await _open(tester, repo);
        await _fillAndSubmit(tester);
        await _tapButton(tester, _endOthersLabel);

        await tester.pump(const Duration(seconds: 30));

        expect(find.text(message), findsOneWidget);
        expect(_snackBar(), findsNothing);
      });
    }

    testWidgets('a retry that succeeds returns with the combined '
        'confirmation and never repeats the change', (tester) async {
      final repo = _withOthers()
        ..endOthersScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fillAndSubmit(tester);
      await _tapButton(tester, _endOthersLabel);

      await _tapButton(tester, _endOthersLabel);

      expect(_calls(repo), ['changePassword', 'endOthers', 'endOthers']);
      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.text(_combinedConfirmation), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(repo.devices.map((s) => s.id), ['current']);
    });

    testWidgets('a second failure keeps the prompt and its message', (
      tester,
    ) async {
      final repo = _withOthers()
        ..endOthersScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _fillAndSubmit(tester);
      await _tapButton(tester, _endOthersLabel);

      await _tapButton(tester, _endOthersLabel);

      expect(repo.endOthersCalls, 2);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(buttonLabelled(_stayLabel), findsOneWidget);
    });

    testWidgets('Tetap masuk after a failure returns with the plain '
        'confirmation only', (tester) async {
      final repo = _withOthers()
        ..endOthersScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _fillAndSubmit(tester);
      await _tapButton(tester, _endOthersLabel);

      await _tapButton(tester, _stayLabel);

      expect(currentPath(tester), accountPath(UserRole.owner));
      expect(find.text(_plainConfirmation), findsOneWidget);
      expect(find.text(_combinedConfirmation), findsNothing);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(_calls(repo), ['changePassword', 'endOthers']);
      expect(repo.devices, hasLength(2));
    });

    testWidgets('does not show the passwords next to the message', (
      tester,
    ) async {
      final repo = _withOthers()
        ..endOthersScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _fillAndSubmit(tester);

      await _tapButton(tester, _endOthersLabel);

      _expectNoPasswordShown(tester, [_currentPassword, _newPassword]);
    });
  });

  group('the passwords', () {
    testWidgets('are not announced while hidden, in any state', (tester) async {
      const secrets = [_currentPassword, _newPassword];
      final repo = _alone()
        ..changePasswordScript.queue.addAll(const [
          ApiFailure(
            code: 'CURRENT_PASSWORD_INCORRECT',
            field: 'currentPassword',
            statusCode: 422,
          ),
          ApiFailure(code: 'TOO_MANY_ATTEMPTS', statusCode: 429),
        ]);
      await _open(tester, repo);
      _expectNoPasswordShown(tester, secrets);

      await _fill(tester);
      _expectNoPasswordShown(tester, secrets);

      await _submit(tester);
      _expectNoPasswordShown(tester, secrets);

      await _submit(tester);
      _expectNoPasswordShown(tester, secrets);
    });

    testWidgets('are not labels or hints, nor text, when revealed', (
      tester,
    ) async {
      await _open(tester, _alone());
      await _fill(tester);

      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();

      _expectNoPasswordShown(tester, [
        _currentPassword,
        _newPassword,
      ], valueExposed: true);
    });

    testWidgets('are not printed, whatever the outcome', (tester) async {
      final printed = <String>[];
      final previous = debugPrint;
      final repo = _withOthers()
        ..changePasswordScript.queue.add(
          const ApiFailure(
            code: 'CURRENT_PASSWORD_INCORRECT',
            field: 'currentPassword',
            statusCode: 422,
          ),
        )
        ..endOthersScript.queue.add(const ApiFailure.network());

      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      try {
        await runZoned(
          () async {
            await _open(tester, repo);
            await _fillAndSubmit(tester);
            await _submit(tester);
            await _tapButton(tester, _endOthersLabel);
            await _tapButton(tester, _endOthersLabel);
          },
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => printed.add(line),
          ),
        );
      } finally {
        debugPrint = previous;
      }

      expect(currentPath(tester), accountPath(UserRole.owner));
      for (final line in printed) {
        expect(line, isNot(contains(_currentPassword)));
        expect(line, isNot(contains(_newPassword)));
      }
    });
  });

  group('accessibility', () {
    final states =
        <String, Future<void> Function(WidgetTester tester, bool largeText)>{
          'the empty form': (tester, largeText) =>
              _open(tester, _alone(), largeText: largeText),
          'the form with a typed password': (tester, largeText) async {
            await _open(tester, _alone(), largeText: largeText);
            await _fill(tester, next: 'budi');
            expect(find.text(_tooShort), findsOneWidget);
          },
          'the form with revealed passwords': (tester, largeText) async {
            await _open(tester, _alone(), largeText: largeText);
            await _fill(tester);
            await tester.tap(find.text(_toggleLabel));
            await tester.pumpAndSettle();
            expect(labeledTextField(tester, _new).obscureText, isFalse);
          },
          'the form with empty fields flagged': (tester, largeText) async {
            await _open(tester, _alone(), largeText: largeText);
            await _submit(tester);
            expect(fieldError(tester, _current), isNotNull);
            expect(fieldError(tester, _new), isNotNull);
            expect(fieldError(tester, _confirm), isNotNull);
          },
          'the form with a mismatch': (tester, largeText) async {
            await _open(tester, _alone(), largeText: largeText);
            await _fillAndSubmit(tester, confirm: 'lain sekali');
            expect(fieldError(tester, _confirm), _mismatch);
          },
          'the form with a wrong current password': (tester, largeText) async {
            await _open(
              tester,
              _failing(
                const ApiFailure(
                  code: 'CURRENT_PASSWORD_INCORRECT',
                  field: 'currentPassword',
                  statusCode: 422,
                ),
              ),
              largeText: largeText,
            );
            await _fillAndSubmit(tester);
            expect(
              fieldError(tester, _current),
              messageOfCode('CURRENT_PASSWORD_INCORRECT'),
            );
          },
          'the form with an unchanged password': (tester, largeText) async {
            await _open(
              tester,
              _failing(
                const ApiFailure(
                  code: 'PASSWORD_UNCHANGED',
                  field: 'newPassword',
                  statusCode: 422,
                ),
              ),
              largeText: largeText,
            );
            await _fillAndSubmit(tester);
            expect(
              fieldError(tester, _new),
              messageOfCode('PASSWORD_UNCHANGED'),
            );
          },
          'the form with a message at the form': (tester, largeText) async {
            await _open(
              tester,
              _failing(
                const ApiFailure(code: 'TOO_MANY_ATTEMPTS', statusCode: 429),
              ),
              largeText: largeText,
            );
            await _fillAndSubmit(tester);
            expect(
              find.text(messageOfCode('TOO_MANY_ATTEMPTS')),
              findsOneWidget,
            );
          },
          'the form while busy': (tester, largeText) async {
            final repo = _alone()
              ..changePasswordScript.gate = Completer<void>();
            await _open(tester, repo, largeText: largeText);
            await _fill(tester);
            await tapAndPump(tester, buttonLabelled(_submitLabel));
            expectBusy(tester);
          },
          'the prompt about other devices': (tester, largeText) async {
            await _open(tester, _withOthers(), largeText: largeText);
            await _fillAndSubmit(tester);
            expect(find.text(_dialogTitle), findsOneWidget);
          },
          'the prompt after ending devices failed': (tester, largeText) async {
            final repo = _withOthers()
              ..endOthersScript.always = const ApiFailure.network();
            await _open(tester, repo, largeText: largeText);
            await _fillAndSubmit(tester);
            await _tapButton(tester, _endOthersLabel);
            expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
            expect(find.text(_dialogTitle), findsOneWidget);
          },
          'the account tab with the plain confirmation':
              (tester, largeText) async {
                await _open(tester, _alone(), largeText: largeText);
                await _fillAndSubmit(tester);
                expect(find.text(_plainConfirmation), findsOneWidget);
              },
          'the account tab with the combined confirmation':
              (tester, largeText) async {
                await _open(tester, _withOthers(), largeText: largeText);
                await _fillAndSubmit(tester);
                await _tapButton(tester, _endOthersLabel);
                expect(find.text(_combinedConfirmation), findsOneWidget);
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
      testWidgets('meets the guidelines on the empty form for a $role', (
        tester,
      ) async {
        await _open(tester, _alone(), role: role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size on the empty form for a $role', (
        tester,
      ) async {
        await _open(tester, _alone(), role: role, largeText: true);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
