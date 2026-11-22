import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/widgets/reauth_dialog.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/fields.dart';
import '../../features/auth/ui/auth_ui_helpers.dart' show buttonLabelled;

const _password = 'Kata sandi (wajib)';
const _passwordTitle = 'Konfirmasi kata sandi';
const _googleTitle = 'Konfirmasi akun';
const _google = 'Lanjutkan dengan Google';
const _open = 'Buka dialog';

/// Shows a button that opens the dialog and keeps the answer of
/// [showReauthDialog] through [onResult].
class _Host extends ConsumerWidget {
  const _Host(this.onResult);

  final void Function(bool value) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the account loaded, as the app does, so the dialog can read it.
    ref.watch(myAccountProvider);
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async => onResult(await showReauthDialog(context, ref)),
          child: const Text(_open),
        ),
      ),
    );
  }
}

late FakeAccountRepository _accounts;
late FakeAuthRepository _auth;
late FakeGoogleIdentity _identity;
bool? _result;

Future<void> _pumpHost(WidgetTester tester, {bool hasPassword = true}) async {
  final account = makeAccount(
    hasPassword: hasPassword,
    googleEmail: hasPassword ? null : 'andi@gmail.com',
  );
  _accounts = FakeAccountRepository(account: account);
  _auth = FakeAuthRepository()..accountResult = account;
  _identity = FakeGoogleIdentity();
  _result = null;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(_accounts),
        authRepositoryProvider.overrideWithValue(_auth),
        googleIdentityProvider.overrideWithValue(_identity),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: _Host((value) => _result = value),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text(_open));
  await tester.pumpAndSettle();
}

Finder _dialog() => find.byType(AlertDialog);

Finder _inDialog(Finder finder) =>
    find.descendant(of: _dialog(), matching: finder);

Finder _googleButton() => _inDialog(buttonLabelled(_google));

Future<void> _submitPassword(WidgetTester tester, String password) async {
  await typeInto(tester, _password, password);
  await tester.tap(find.text('Lanjutkan'));
  await tester.pumpAndSettle();
}

void main() {
  group('for an account with a password', () {
    testWidgets('shows the password dialog', (tester) async {
      await _pumpHost(tester);

      await _openDialog(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text(_passwordTitle)), findsOneWidget);
      expect(
        _inDialog(find.text('Masukkan kata sandi Anda untuk melanjutkan.')),
        findsOneWidget,
      );
      expect(fieldLabeled(_password), findsOneWidget);
      expect(_inDialog(find.text('Tampilkan kata sandi')), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(_inDialog(find.text('Lanjutkan')), findsOneWidget);
      expect(find.text(_google), findsNothing);
      expect(_result, isNull);
    });

    testWidgets('shows the password dialog while the account is loading', (
      tester,
    ) async {
      final gate = Completer<void>();
      final account = makeAccount(hasPassword: false);
      _accounts = FakeAccountRepository(account: account);
      _auth = FakeAuthRepository()
        ..accountResult = account
        ..accountGate = gate;
      _identity = FakeGoogleIdentity();
      _result = null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(_accounts),
            authRepositoryProvider.overrideWithValue(_auth),
            googleIdentityProvider.overrideWithValue(_identity),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: _Host((value) => _result = value),
          ),
        ),
      );
      await tester.pump();

      await _openDialog(tester);

      expect(_inDialog(find.text(_passwordTitle)), findsOneWidget);
      expect(fieldLabeled(_password), findsOneWidget);
      gate.complete();
    });

    testWidgets('returns true after the password is accepted', (tester) async {
      await _pumpHost(tester);
      await _openDialog(tester);

      await _submitPassword(tester, 'rahasia panjang');

      expect(_accounts.reauthentications, ['rahasia panjang']);
      expect(_accounts.googleReauthentications, isEmpty);
      expect(_dialog(), findsNothing);
      expect(_result, isTrue);
    });

    testWidgets('a wrong password shows the message and keeps the dialog', (
      tester,
    ) async {
      await _pumpHost(tester);
      _accounts.reauthScript.always = const ApiFailure(
        code: 'PASSWORD_INCORRECT',
      );
      await _openDialog(tester);

      await _submitPassword(tester, 'salah');

      expect(_dialog(), findsOneWidget);
      expect(
        _inDialog(find.text(messageOfCode('PASSWORD_INCORRECT'))),
        findsOneWidget,
      );
      expect(_accounts.reauthentications, ['salah']);
      expect(_result, isNull);
    });

    testWidgets('the password can be corrected after a wrong one', (
      tester,
    ) async {
      await _pumpHost(tester);
      _accounts.reauthScript.queue.add(
        const ApiFailure(code: 'PASSWORD_INCORRECT'),
      );
      await _openDialog(tester);
      await _submitPassword(tester, 'salah');

      await _submitPassword(tester, 'benar sekali');

      expect(_accounts.reauthentications, ['salah', 'benar sekali']);
      expect(_dialog(), findsNothing);
      expect(_result, isTrue);
    });

    testWidgets('too many attempts shows the message and keeps the dialog', (
      tester,
    ) async {
      await _pumpHost(tester);
      _accounts.reauthScript.always = const ApiFailure(
        code: 'TOO_MANY_LOGIN_ATTEMPTS',
      );
      await _openDialog(tester);

      await _submitPassword(tester, 'salah');

      expect(_dialog(), findsOneWidget);
      expect(
        _inDialog(find.text(messageOfCode('TOO_MANY_LOGIN_ATTEMPTS'))),
        findsOneWidget,
      );
      expect(_result, isNull);
    });

    testWidgets('an empty password shows an error and sends nothing', (
      tester,
    ) async {
      await _pumpHost(tester);
      await _openDialog(tester);

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(labeledFieldError(tester, _password), 'Kata sandi wajib diisi.');
      expect(_dialog(), findsOneWidget);
      expect(_accounts.reauthentications, isEmpty);
      expect(_result, isNull);
    });

    testWidgets('Batal returns false without sending anything', (tester) async {
      await _pumpHost(tester);
      await _openDialog(tester);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(_result, isFalse);
      expect(_accounts.reauthentications, isEmpty);
      expect(_accounts.googleReauthentications, isEmpty);
    });

    testWidgets('the dialog can be opened again after Batal', (tester) async {
      await _pumpHost(tester);
      await _openDialog(tester);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      await _openDialog(tester);
      await _submitPassword(tester, 'rahasia panjang');

      expect(_result, isTrue);
      expect(_accounts.reauthentications, ['rahasia panjang']);
    });
  });

  group('for an account without a password', () {
    testWidgets('shows the Google dialog', (tester) async {
      await _pumpHost(tester, hasPassword: false);

      await _openDialog(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text(_googleTitle)), findsOneWidget);
      expect(_googleButton(), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(find.text(_passwordTitle), findsNothing);
      expect(fieldLabeled(_password), findsNothing);
      expect(_inDialog(find.text('Lanjutkan')), findsNothing);
      expect(_identity.requests, 0);
      expect(_result, isNull);
    });

    testWidgets('returns true after Google is accepted', (tester) async {
      await _pumpHost(tester, hasPassword: false);
      _identity.token = 'token-abc';
      await _openDialog(tester);

      await tester.tap(_googleButton());
      await tester.pumpAndSettle();

      expect(_identity.requests, 1);
      expect(_accounts.googleReauthentications, ['token-abc']);
      expect(_accounts.reauthentications, isEmpty);
      expect(_dialog(), findsNothing);
      expect(_result, isTrue);
    });

    testWidgets('a cancelled Google chooser keeps the dialog open', (
      tester,
    ) async {
      await _pumpHost(tester, hasPassword: false);
      _identity.token = null;
      await _openDialog(tester);

      await tester.tap(_googleButton());
      await tester.pumpAndSettle();

      expect(_dialog(), findsOneWidget);
      expect(_accounts.googleReauthentications, isEmpty);
      expect(_result, isNull);
    });

    testWidgets(
      'a mismatching account shows the message and keeps the dialog',
      (tester) async {
        await _pumpHost(tester, hasPassword: false);
        _accounts.reauthScript.always = const ApiFailure(
          code: 'GOOGLE_ACCOUNT_MISMATCH',
        );
        await _openDialog(tester);

        await tester.tap(_googleButton());
        await tester.pumpAndSettle();

        expect(_dialog(), findsOneWidget);
        expect(
          _inDialog(
            find.text(
              'Akun Google yang dipilih berbeda dari akun yang terhubung.',
            ),
          ),
          findsOneWidget,
        );
        expect(_result, isNull);
      },
    );

    testWidgets('Batal returns false without sending anything', (tester) async {
      await _pumpHost(tester, hasPassword: false);
      await _openDialog(tester);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(_result, isFalse);
      expect(_identity.requests, 0);
      expect(_accounts.googleReauthentications, isEmpty);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester)>{
      'the password dialog': (tester) async {
        await _pumpHost(tester);
        await _openDialog(tester);
      },
      'the password dialog with an empty password': (tester) async {
        await _pumpHost(tester);
        await _openDialog(tester);
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
      },
      'the password dialog with a wrong password': (tester) async {
        await _pumpHost(tester);
        _accounts.reauthScript.always = const ApiFailure(
          code: 'PASSWORD_INCORRECT',
        );
        await _openDialog(tester);
        await _submitPassword(tester, 'salah');
      },
      'the Google dialog': (tester) async {
        await _pumpHost(tester, hasPassword: false);
        await _openDialog(tester);
      },
      'the Google dialog with a mismatch': (tester) async {
        await _pumpHost(tester, hasPassword: false);
        _accounts.reauthScript.always = const ApiFailure(
          code: 'GOOGLE_ACCOUNT_MISMATCH',
        );
        await _openDialog(tester);
        await tester.tap(_googleButton());
        await tester.pumpAndSettle();
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await entry.value(tester);

        expect(_dialog(), findsOneWidget);
        await expectMeetsA11yGuidelines(tester);
      });
    }
  });
}
