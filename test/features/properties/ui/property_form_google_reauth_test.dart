import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'property_ui_helpers.dart';

const _bankName = 'Nama bank';
const _accountNumber = 'Nomor rekening';
const _holder = 'Nama pemilik rekening';
const _password = 'Kata sandi (wajib)';
const _google = 'Lanjutkan dengan Google';
const _reauthRequired = ApiFailure(code: 'REAUTHENTICATION_REQUIRED');
const _mismatch = 'Akun Google yang dipilih berbeda dari akun yang terhubung.';

/// An account that signed up with Google and has no password.
Account _googleOnlyAccount() => Account(
  email: 'budi@example.com',
  emailVerified: true,
  googleEmail: 'budi@example.com',
  hasPassword: false,
  id: 'account-1',
  name: 'Budi',
  role: UserRole.owner,
);

/// An [AccountRepository] that answers with the given account.
class _Accounts implements AccountRepository {
  _Accounts(this.account);

  final Account account;

  @override
  Future<Account> me() async => account;

  @override
  Future<List<Session>> sessions() async => [];

  @override
  Future<void> endSession(String id) async {}

  @override
  Future<void> endOtherSessions() async {}

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => false;
}

Property _melati() => makeProperty(
  id: 'p1',
  name: 'Kos Melati',
  address: 'Jl. Melati 1, Bandung',
  managers: [managerSari],
);

Finder _dialog() => find.byType(AlertDialog);

Finder _inDialog(Finder finder) =>
    find.descendant(of: _dialog(), matching: finder);

Finder _googleButton() => _inDialog(buttonLabelled(_google));

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

/// Both the account provider of the account tab and the one of the
/// authentication repository answer with a Google-only account, so the dialog
/// can read either.
Future<void> _pumpAndOpenDialog(
  WidgetTester tester,
  FakePropertyRepository repo,
  FakeGoogleIdentity google, {
  bool largeText = false,
}) async {
  repo.updateScript.queue.add(_reauthRequired);
  final auth = FakeAuthRepository()..accountResult = _googleOnlyAccount();
  await pumpPropertyApp(
    tester,
    repo,
    path: '/properti/p1/ubah',
    largeText: largeText,
    auth: auth,
    accounts: _Accounts(_googleOnlyAccount()),
    google: google,
  );
  await typeInto(tester, _bankName, 'BCA');
  await typeInto(tester, _accountNumber, '1234567890');
  await typeInto(tester, _holder, 'Budi Santoso');
  await tapVisible(tester, find.text('Simpan Perubahan'));
}

Future<void> _tapGoogle(WidgetTester tester) async {
  await tester.tap(_googleButton());
  await tester.pumpAndSettle();
}

void main() {
  late FakePropertyRepository repo;
  late FakeGoogleIdentity google;

  setUp(() {
    repo = FakePropertyRepository(properties: [_melati()]);
    google = FakeGoogleIdentity();
  });

  group('dialog for an account without a password', () {
    testWidgets('offers Google instead of the password field', (tester) async {
      await _pumpAndOpenDialog(tester, repo, google);

      expect(_dialog(), findsOneWidget);
      expect(_googleButton(), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(fieldLabeled(_password), findsNothing);
      expect(find.text('Tampilkan kata sandi'), findsNothing);
      expect(_inDialog(find.text('Lanjutkan')), findsNothing);
      expect(find.textContaining('Masukkan kata sandi'), findsNothing);
      expect(google.requests, 0);
      expect(repo.googleReauthentications, isEmpty);
    });

    testWidgets('the Google action is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester, repo, google);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(_inDialog(find.text(_google)));
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

    testWidgets('sends the ID token and retries the same update', (
      tester,
    ) async {
      google.token = 'token-abc';
      await _pumpAndOpenDialog(tester, repo, google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(repo.googleReauthentications, ['token-abc']);
      expect(repo.reauthentications, isEmpty);
      expect(repo.updated, hasLength(2));
      expect(repo.updated.last.id, repo.updated.first.id);
      expect(repo.updated.last.input, repo.updated.first.input);
      expect(repo.calls.where((c) => c != 'list' && !c.startsWith('get:')), [
        'update:p1',
        'reauthenticateGoogle',
        'update:p1',
      ]);
    });

    testWidgets('a successful retry completes like a normal edit', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester, repo, google);

      await _tapGoogle(tester);

      expect(_dialog(), findsNothing);
      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
      expect(find.text('BCA · 1234567890'), findsOneWidget);
    });

    testWidgets('cancelling the Google chooser keeps the dialog without an '
        'error', (tester) async {
      google.token = null;
      await _pumpAndOpenDialog(tester, repo, google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(_dialog(), findsOneWidget);
      expect(_googleButton(), findsOneWidget);
      expect(_enabled(tester, _googleButton()), isTrue);
      expect(repo.googleReauthentications, isEmpty);
      expect(repo.updated, hasLength(1));
      expect(_inDialog(find.byType(CircularProgressIndicator)), findsNothing);
      expect(find.text(genericErrorMessage), findsNothing);
      expect(snackBar('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('the user can choose an account after cancelling', (
      tester,
    ) async {
      google.token = null;
      await _pumpAndOpenDialog(tester, repo, google);
      await _tapGoogle(tester);
      google.token = 'token-2';

      await _tapGoogle(tester);

      expect(google.requests, 2);
      expect(repo.googleReauthentications, ['token-2']);
      expect(_dialog(), findsNothing);
      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
    });

    testWidgets('Batal closes the dialog and keeps the form and its values', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester, repo, google);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(
        labeledTextField(tester, _accountNumber).controller!.text,
        '1234567890',
      );
      expect(google.requests, 0);
      expect(repo.googleReauthentications, isEmpty);
      expect(repo.updated, hasLength(1));
      expect(snackBar('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('the form offers Google again when submitted after Batal', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester, repo, google);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      repo.updateScript.queue.add(_reauthRequired);

      await tapVisible(tester, find.text('Simpan Perubahan'));

      expect(_googleButton(), findsOneWidget);
      expect(repo.updated, hasLength(2));
    });
  });

  group('failures in the dialog', () {
    final cases = {
      'GOOGLE_ACCOUNT_MISMATCH': _mismatch,
      'GOOGLE_TOKEN_INVALID': 'Masuk dengan Google gagal. Coba lagi.',
      'TOO_MANY_LOGIN_ATTEMPTS': messageOfCode('TOO_MANY_LOGIN_ATTEMPTS'),
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} keeps the dialog open with the message', (
        tester,
      ) async {
        repo.reauthScript.always = ApiFailure(code: entry.key);
        await _pumpAndOpenDialog(tester, repo, google);

        await _tapGoogle(tester);

        expect(_dialog(), findsOneWidget);
        expect(_inDialog(find.text(entry.value)), findsOneWidget);
        expect(_enabled(tester, _googleButton()), isTrue);
        expect(repo.updated, hasLength(1));
        expect(snackBar('Perubahan tersimpan'), findsNothing);
        expect(find.textContaining(entry.key), findsNothing);
      });
    }

    testWidgets('the mismatch message is announced as a live region', (
      tester,
    ) async {
      repo.reauthScript.always = const ApiFailure(
        code: 'GOOGLE_ACCOUNT_MISMATCH',
      );
      await _pumpAndOpenDialog(tester, repo, google);

      await _tapGoogle(tester);

      expectLiveRegion(tester, _mismatch);
    });

    testWidgets('the user can choose another account after a mismatch', (
      tester,
    ) async {
      repo.reauthScript.queue.add(
        const ApiFailure(code: 'GOOGLE_ACCOUNT_MISMATCH'),
      );
      await _pumpAndOpenDialog(tester, repo, google);
      await _tapGoogle(tester);

      await _tapGoogle(tester);

      expect(repo.googleReauthentications, hasLength(2));
      expect(repo.updated, hasLength(2));
      expect(_dialog(), findsNothing);
      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
    });

    testWidgets('the message goes away when the next attempt starts', (
      tester,
    ) async {
      repo.reauthScript.queue.add(
        const ApiFailure(code: 'GOOGLE_ACCOUNT_MISMATCH'),
      );
      await _pumpAndOpenDialog(tester, repo, google);
      await _tapGoogle(tester);
      google.gate = Completer<void>();

      await tester.tap(_googleButton());
      await tester.pump();

      expect(find.text(_mismatch), findsNothing);
      google.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('an unavailable Google sign-in is explained in the dialog', (
      tester,
    ) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _pumpAndOpenDialog(tester, repo, google);

      await _tapGoogle(tester);

      expect(_dialog(), findsOneWidget);
      expect(
        _inDialog(find.text('Masuk dengan Google belum tersedia.')),
        findsOneWidget,
      );
      expect(repo.googleReauthentications, isEmpty);
    });

    testWidgets('any other error of the Google chooser shows the generic '
        'message', (tester) async {
      google.failure = Exception('plugin broke');
      await _pumpAndOpenDialog(tester, repo, google);

      await _tapGoogle(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text(genericErrorMessage)), findsOneWidget);
      expect(find.textContaining('plugin broke'), findsNothing);
      expect(repo.googleReauthentications, isEmpty);
    });

    testWidgets('a second failure with another code closes the dialog', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester, repo, google);
      repo.updateScript.queue.add(const ApiFailure(code: 'PROPERTY_READ_ONLY'));

      await _tapGoogle(tester);

      expect(_dialog(), findsNothing);
      expect(find.text(messageOfCode('PROPERTY_READ_ONLY')), findsOneWidget);
      expect(repo.updated, hasLength(2));
      expect(find.byType(PropertyFormScreen), findsOneWidget);
    });
  });

  group('while the Google sign-in is in flight', () {
    testWidgets('waiting for the chooser sends one request on a second tap', (
      tester,
    ) async {
      google.gate = Completer<void>();
      await _pumpAndOpenDialog(tester, repo, google);

      await tester.tap(_googleButton());
      await tester.pump();
      if (_googleButton().evaluate().isNotEmpty) {
        await tester.tap(_googleButton(), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      google.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.googleReauthentications, hasLength(1));
    });

    testWidgets('a second tap sends one request', (tester) async {
      repo.reauthScript.gate = Completer<void>();
      await _pumpAndOpenDialog(tester, repo, google);

      await tester.tap(_googleButton());
      await tester.pump();
      if (_googleButton().evaluate().isNotEmpty) {
        await tester.tap(_googleButton(), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      expect(repo.googleReauthentications, hasLength(1));
      repo.reauthScript.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('restores the Google action when the request fails', (
      tester,
    ) async {
      repo.reauthScript.gate = Completer<void>();
      repo.reauthScript.always = const ApiFailure.network();
      await _pumpAndOpenDialog(tester, repo, google);
      await tester.tap(_googleButton());
      await tester.pump();

      repo.reauthScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(_inDialog(find.byType(CircularProgressIndicator)), findsNothing);
      expect(_enabled(tester, _googleButton()), isTrue);
    });
  });

  group('dialog for an account with a password', () {
    testWidgets('keeps the password dialog and offers no Google', (
      tester,
    ) async {
      repo.updateScript.queue.add(_reauthRequired);
      await pumpPropertyApp(
        tester,
        repo,
        path: '/properti/p1/ubah',
        google: google,
      );
      await typeInto(tester, _bankName, 'BCA');
      await typeInto(tester, _accountNumber, '1234567890');
      await typeInto(tester, _holder, 'Budi Santoso');
      await tapVisible(tester, find.text('Simpan Perubahan'));

      expect(_dialog(), findsOneWidget);
      expect(fieldLabeled(_password), findsOneWidget);
      expect(_inDialog(find.text('Lanjutkan')), findsOneWidget);
      expect(find.textContaining('Google'), findsNothing);
      expect(google.requests, 0);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the Google dialog': (tester, large) async {
        await _pumpAndOpenDialog(tester, repo, google, largeText: large);
      },
      'the Google dialog with a mismatch': (tester, large) async {
        repo.reauthScript.always = const ApiFailure(
          code: 'GOOGLE_ACCOUNT_MISMATCH',
        );
        await _pumpAndOpenDialog(tester, repo, google, largeText: large);
        await _tapGoogle(tester);
      },
      'the Google dialog in flight': (tester, large) async {
        repo.reauthScript.gate = Completer<void>();
        await _pumpAndOpenDialog(tester, repo, google, largeText: large);
        await tester.tap(_googleButton());
        await tester.pump();
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
        expect(_dialog(), findsOneWidget);
      });
    }

    testWidgets('the Google action is reachable at large text size', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester, repo, google, largeText: true);

      await tester.ensureVisible(_googleButton());
      await tester.pumpAndSettle();
      await tester.tap(_googleButton());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repo.googleReauthentications, hasLength(1));
    });
  });
}
