import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'account_ui_helpers.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _title = 'Hapus Akun';
const _warning =
    'Penghapusan akun bersifat permanen dan tidak bisa dibatalkan.';
const _listHeading = 'Yang akan terjadi';
const _items = [
  'Profil, email, dan metode masuk dihapus.',
  'Semua perangkat dikeluarkan.',
  'Catatan transaksi dapat disimpan sesuai kewajiban hukum.',
];
const _ownerItem =
    'Data properti Anda dihapus permanen 90 hari setelah akun dihapus.';
const _fieldLabel = 'Ketik HAPUS untuk melanjutkan';
const _submitLabel = 'Hapus akun saya';
const _deletedNotice = 'Akun Anda sudah dihapus.';

const _ownerLease =
    'Akun belum bisa dihapus karena salah satu properti Anda masih punya sewa '
    'aktif. Akhiri atau hapus sewa itu lebih dulu.';
const _tenantLease =
    'Akun belum bisa dihapus karena Anda masih punya sewa aktif. Minta pemilik '
    'atau pengelola kost mengakhiri sewa Anda lebih dulu.';
const _subscription =
    'Akun belum bisa dihapus karena langganan Google Play Anda masih berjalan '
    'otomatis. Batalkan langganan di Google Play, lalu coba lagi.';

const _reauthRequired = ApiFailure(code: 'REAUTHENTICATION_REQUIRED');
const _password = 'Kata sandi (wajib)';
const _google = 'Lanjutkan dengan Google';

String _pagePath(UserRole role) => '${accountPath(role)}/hapus-akun';

late InMemorySessionStore _store;
late FakeAccountRepository _accounts;
late FakeGoogleIdentity _identity;
late int _logouts;

Account _accountFor(UserRole role, {bool hasPassword = true}) => makeAccount(
  role: role,
  hasPassword: hasPassword,
  googleEmail: hasPassword ? null : 'andi@gmail.com',
);

Future<void> _open(
  WidgetTester tester, {
  UserRole role = UserRole.owner,
  bool hasPassword = true,
  bool largeText = false,
}) async {
  final account = _accountFor(role, hasPassword: hasPassword);
  _accounts = FakeAccountRepository(account: account);
  _store = InMemorySessionStore(storedSession(role: role));
  _identity = FakeGoogleIdentity();
  _logouts = 0;
  final app = buildTestApp(
    store: _store,
    accounts: _accounts,
    auth: FakeAuthRepository()..accountResult = account,
    leases: FakeLeaseRepository(lease: makeCurrentLease()),
    google: _identity,
    logout: () async => _logouts++,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, _pagePath(role));
  await tester.pumpAndSettle();
  expect(currentPath(tester), _pagePath(role));
}

Finder _deleteButton() => find.byType(DangerButton);

Finder _confirmField() => find.byType(TextField);

bool _enabled(WidgetTester tester) =>
    tester.widget<DangerButton>(_deleteButton()).onPressed != null;

Finder _message(String text) => find.widgetWithText(FormMessage, text);

Future<void> _typeConfirmation(WidgetTester tester, String text) async {
  await tester.ensureVisible(_confirmField());
  await tester.enterText(_confirmField(), text);
  await tester.pump();
}

Future<void> _tapDelete(WidgetTester tester) async {
  await tester.ensureVisible(_deleteButton());
  await tester.pumpAndSettle();
  await tester.tap(_deleteButton());
  await tester.pumpAndSettle();
}

Future<void> _confirmAndSubmit(WidgetTester tester) async {
  await _typeConfirmation(tester, 'HAPUS');
  await _tapDelete(tester);
}

Finder _dialog() => find.byType(AlertDialog);

Finder _inDialog(Finder finder) =>
    find.descendant(of: _dialog(), matching: finder);

Future<void> _answerPassword(WidgetTester tester, String password) async {
  await typeInto(tester, _password, password);
  await tester.tap(_inDialog(find.text('Lanjutkan')));
  await tester.pumpAndSettle();
}

Future<void> _cancelDialog(WidgetTester tester) async {
  await tester.tap(_inDialog(find.text('Batal')));
  await tester.pumpAndSettle();
}

void _expectStillSignedIn() {
  expect(_store.stored, isNotNull);
  expect(_logouts, 0);
}

void _expectScreenKept(WidgetTester tester, UserRole role) {
  expect(currentPath(tester), _pagePath(role));
  expect(find.text(_title), findsOneWidget);
  expect(_deleteButton(), findsOneWidget);
}

void _expectLoginAfterDeletion(WidgetTester tester) {
  expect(currentPath(tester), '/masuk');
  expect(find.text('Masuk ke Niscala'), findsOneWidget);
  expect(_message(_deletedNotice), findsOneWidget);
  expect(_store.stored, isNull);
  expect(_logouts, 0);
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
      testWidgets('is titled Hapus Akun as a heading for a $role', (
        tester,
      ) async {
        await _open(tester, role: role);

        expect(find.text(_title), findsOneWidget);
        _expectHeader(tester, find.text(_title));
      });
    }

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('warns that the deletion is permanent', (tester) async {
      await _open(tester);

      expect(find.text(_warning), findsOneWidget);
    });

    testWidgets('lists what will happen under a heading', (tester) async {
      await _open(tester, role: UserRole.manager);

      expect(find.text(_listHeading), findsOneWidget);
      _expectHeader(tester, find.text(_listHeading));
      var previous = tester.getTopLeft(find.text(_listHeading)).dy;
      for (final item in _items) {
        expect(find.text(item), findsOneWidget);
        final top = tester.getTopLeft(find.text(item)).dy;
        expect(top, greaterThan(previous));
        previous = top;
      }
    });

    testWidgets('puts the warning above the list', (tester) async {
      await _open(tester);

      expect(
        tester.getTopLeft(find.text(_warning)).dy,
        lessThan(tester.getTopLeft(find.text(_listHeading)).dy),
      );
    });

    testWidgets('shows the property item for an owner after the others', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text(_ownerItem), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(_ownerItem)).dy,
        greaterThan(tester.getTopLeft(find.text(_items.last)).dy),
      );
    });

    for (final role in [UserRole.manager, UserRole.tenant]) {
      testWidgets('does not show the property item for a $role', (
        tester,
      ) async {
        await _open(tester, role: role);

        expect(find.text(_ownerItem), findsNothing);
        expect(find.textContaining('90 hari'), findsNothing);
        for (final item in _items) {
          expect(find.text(item), findsOneWidget);
        }
      });
    }

    testWidgets('has a labelled confirmation field and the danger button', (
      tester,
    ) async {
      await _open(tester);

      expect(
        find.byWidgetPredicate(
          (widget) => widget is LabeledField && widget.label == _fieldLabel,
        ),
        findsOneWidget,
      );
      expect(_confirmField(), findsOneWidget);
      expect(
        find.descendant(of: _deleteButton(), matching: find.text(_submitLabel)),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets(
      'starts with an empty field, a disabled button and no message',
      (tester) async {
        await _open(tester);

        expect(tester.widget<TextField>(_confirmField()).controller!.text, '');
        expect(_enabled(tester), isFalse);
        expect(find.byType(FormMessage), findsNothing);
        expect(_accounts.deleteAccountCalls, 0);
      },
    );

    testWidgets('never prints null or an English term', (tester) async {
      await _open(tester);

      expect(find.textContaining('null'), findsNothing);
      for (final english in ['Delete', 'Account', 'Cancel', 'Type']) {
        expect(find.textContaining(english), findsNothing);
      }
    });
  });

  group('the button', () {
    for (final entry in {
      'HAPUS': true,
      ' HAPUS ': true,
      '   HAPUS': true,
      'HAPUS  ': true,
      'hapus': false,
      'Hapus': false,
      'HAPU': false,
      'HAPUSS': false,
      'HAPUS AKUN': false,
      'H APUS': false,
      '': false,
      '   ': false,
    }.entries) {
      testWidgets(
        'is ${entry.value ? 'enabled' : 'disabled'} for "${entry.key}"',
        (tester) async {
          await _open(tester);

          await _typeConfirmation(tester, entry.key);

          expect(_enabled(tester), entry.value);
        },
      );
    }

    testWidgets('is disabled again when the word is changed', (tester) async {
      await _open(tester);
      await _typeConfirmation(tester, 'HAPUS');
      expect(_enabled(tester), isTrue);

      await _typeConfirmation(tester, 'HAPU');

      expect(_enabled(tester), isFalse);
    });

    testWidgets('sends nothing while it is disabled', (tester) async {
      await _open(tester);
      await _typeConfirmation(tester, 'hapus');

      await tester.tap(_deleteButton(), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_accounts.deleteAccountCalls, 0);
      expect(find.byType(FormMessage), findsNothing);
      expect(currentPath(tester), _pagePath(UserRole.owner));
    });

    testWidgets('typing the word alone sends nothing', (tester) async {
      await _open(tester);

      await _typeConfirmation(tester, 'HAPUS');

      expect(_accounts.deleteAccountCalls, 0);
      expect(currentPath(tester), _pagePath(UserRole.owner));
    });
  });

  group('Batal', () {
    for (final role in _roles) {
      testWidgets('returns a $role to the Akun tab without a request', (
        tester,
      ) async {
        await _open(tester, role: role);
        await _typeConfirmation(tester, 'HAPUS');

        await tester.ensureVisible(find.text('Batal'));
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(_accounts.deleteAccountCalls, 0);
        _expectStillSignedIn();
      });
    }
  });

  group('a successful deletion', () {
    for (final role in _roles) {
      testWidgets('ends the session and shows the sign in screen for a $role', (
        tester,
      ) async {
        await _open(tester, role: role);

        await _confirmAndSubmit(tester);

        expect(_accounts.deleteAccountCalls, 1);
        _expectLoginAfterDeletion(tester);
      });
    }

    testWidgets('shows the notice as a message that is not an error', (
      tester,
    ) async {
      await _open(tester);

      await _confirmAndSubmit(tester);

      final message = tester.widget<FormMessage>(_message(_deletedNotice));
      expect(message.isError, isFalse);
      expectLiveRegion(tester, _deletedNotice);
    });

    testWidgets('does not call the logout endpoint', (tester) async {
      await _open(tester);

      await _confirmAndSubmit(tester);

      expect(_logouts, 0);
    });

    testWidgets('sends only the deletion request', (tester) async {
      await _open(tester);
      _accounts.calls.clear();

      await _confirmAndSubmit(tester);

      expect(_accounts.calls, ['deleteMyAccount']);
    });
  });

  group('a refused deletion', () {
    final cases = {
      'OWNER_HAS_ACTIVE_LEASE': _ownerLease,
      'TENANT_HAS_ACTIVE_LEASE': _tenantLease,
      'SUBSCRIPTION_AUTO_RENEWING': _subscription,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} shows its message and keeps the screen', (
        tester,
      ) async {
        await _open(tester);
        _accounts.deleteAccountScript.always = ApiFailure(code: entry.key);

        await _confirmAndSubmit(tester);

        expect(_message(entry.value), findsOneWidget);
        expect(tester.widget<FormMessage>(_message(entry.value)).isError, true);
        expect(_accounts.deleteAccountCalls, 1);
        _expectScreenKept(tester, UserRole.owner);
        _expectStillSignedIn();
        expect(find.text(_deletedNotice), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('${entry.key} message is announced as a live region', (
        tester,
      ) async {
        await _open(tester);
        _accounts.deleteAccountScript.always = ApiFailure(code: entry.key);

        await _confirmAndSubmit(tester);

        expectLiveRegion(tester, entry.value);
      });
    }

    testWidgets('OWNER_HAS_ACTIVE_LEASE does not show the admin wording', (
      tester,
    ) async {
      await _open(tester);
      _accounts.deleteAccountScript.always = const ApiFailure(
        code: 'OWNER_HAS_ACTIVE_LEASE',
      );

      await _confirmAndSubmit(tester);

      expect(find.text(messageOfCode('OWNER_HAS_ACTIVE_LEASE')), findsNothing);
    });

    for (final role in [UserRole.manager, UserRole.tenant]) {
      testWidgets('TENANT_HAS_ACTIVE_LEASE is explained to a $role', (
        tester,
      ) async {
        await _open(tester, role: role);
        _accounts.deleteAccountScript.always = const ApiFailure(
          code: 'TENANT_HAS_ACTIVE_LEASE',
        );

        await _confirmAndSubmit(tester);

        expect(_message(_tenantLease), findsOneWidget);
        _expectScreenKept(tester, role);
        _expectStillSignedIn();
      });
    }

    for (final code in [
      'FORBIDDEN',
      'NETWORK_ERROR',
      'INTERNAL_ERROR',
      'SOMETHING_NEW',
    ]) {
      testWidgets('$code shows its mapped message and keeps the screen', (
        tester,
      ) async {
        await _open(tester);
        _accounts.deleteAccountScript.always = ApiFailure(code: code);

        await _confirmAndSubmit(tester);

        expect(_message(messageOfCode(code)), findsOneWidget);
        expect(find.text(_ownerLease), findsNothing);
        expect(find.text(_tenantLease), findsNothing);
        expect(find.text(_subscription), findsNothing);
        _expectScreenKept(tester, UserRole.owner);
        _expectStillSignedIn();
      });
    }

    testWidgets('a retry after a refusal ends the session', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue.add(
        const ApiFailure(code: 'SUBSCRIPTION_AUTO_RENEWING'),
      );
      await _confirmAndSubmit(tester);
      expect(_message(_subscription), findsOneWidget);

      await _confirmAndSubmit(tester);

      expect(_accounts.deleteAccountCalls, 2);
      _expectLoginAfterDeletion(tester);
    });
  });

  group('while the deletion is in flight', () {
    testWidgets('the button shows progress and is disabled', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.gate = Completer<void>();
      await _typeConfirmation(tester, 'HAPUS');

      await tester.tap(_deleteButton());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_enabled(tester), isFalse);
      _accounts.deleteAccountScript.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a second tap sends nothing', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.gate = Completer<void>();
      await _typeConfirmation(tester, 'HAPUS');
      await tester.tap(_deleteButton());
      await tester.pump();

      await tester.tap(_deleteButton(), warnIfMissed: false);
      await tester.pump();

      expect(_accounts.deleteAccountCalls, 1);
      _accounts.deleteAccountScript.gate!.complete();
      await tester.pumpAndSettle();
      expect(_accounts.deleteAccountCalls, 1);
    });

    testWidgets('the screen is usable again after a failure', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.gate = Completer<void>();
      _accounts.deleteAccountScript.always = const ApiFailure.network();
      await _typeConfirmation(tester, 'HAPUS');
      await tester.tap(_deleteButton());
      await tester.pump();

      _accounts.deleteAccountScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester), isTrue);
    });

    testWidgets('the session stays until the deletion succeeds', (
      tester,
    ) async {
      await _open(tester);
      _accounts.deleteAccountScript.gate = Completer<void>();
      await _typeConfirmation(tester, 'HAPUS');
      await tester.tap(_deleteButton());
      await tester.pump();

      expect(_store.stored, isNotNull);
      expect(currentPath(tester), _pagePath(UserRole.owner));
      _accounts.deleteAccountScript.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('when the API asks for the password again', () {
    testWidgets('opens the password dialog', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);

      await _confirmAndSubmit(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text('Konfirmasi kata sandi')), findsOneWidget);
      expect(_accounts.deleteAccountCalls, 1);
    });

    testWidgets('retries the deletion once after the password is accepted', (
      tester,
    ) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      await _confirmAndSubmit(tester);

      await _answerPassword(tester, 'rahasia panjang');

      expect(_accounts.reauthentications, ['rahasia panjang']);
      expect(_accounts.deleteAccountCalls, 2);
      expect(_dialog(), findsNothing);
      _expectLoginAfterDeletion(tester);
    });

    testWidgets('does not retry while the password is wrong', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      _accounts.reauthScript.queue.add(
        const ApiFailure(code: 'PASSWORD_INCORRECT'),
      );
      await _confirmAndSubmit(tester);

      await _answerPassword(tester, 'salah');

      expect(_dialog(), findsOneWidget);
      expect(_accounts.deleteAccountCalls, 1);
      _expectStillSignedIn();

      await _answerPassword(tester, 'benar sekali');

      expect(_accounts.deleteAccountCalls, 2);
      _expectLoginAfterDeletion(tester);
    });

    testWidgets('cancelling the dialog keeps the screen without an error', (
      tester,
    ) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      await _confirmAndSubmit(tester);

      await _cancelDialog(tester);

      expect(_dialog(), findsNothing);
      expect(_accounts.deleteAccountCalls, 1);
      expect(_accounts.reauthentications, isEmpty);
      expect(find.byType(FormMessage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      _expectScreenKept(tester, UserRole.owner);
      _expectStillSignedIn();
    });

    testWidgets('the user can submit again after cancelling', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      await _confirmAndSubmit(tester);
      await _cancelDialog(tester);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);

      await _tapDelete(tester);

      expect(_dialog(), findsOneWidget);
      expect(_accounts.deleteAccountCalls, 2);
    });

    testWidgets('shows a failure of the retry on the screen', (tester) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue
        ..add(_reauthRequired)
        ..add(const ApiFailure(code: 'TENANT_HAS_ACTIVE_LEASE'));
      await _confirmAndSubmit(tester);

      await _answerPassword(tester, 'rahasia panjang');

      expect(_accounts.deleteAccountCalls, 2);
      expect(_dialog(), findsNothing);
      expect(_message(_tenantLease), findsOneWidget);
      _expectScreenKept(tester, UserRole.owner);
      _expectStillSignedIn();
    });

    testWidgets('shows a second request for the password as a message', (
      tester,
    ) async {
      await _open(tester);
      _accounts.deleteAccountScript.queue
        ..add(_reauthRequired)
        ..add(_reauthRequired);
      await _confirmAndSubmit(tester);

      await _answerPassword(tester, 'rahasia panjang');

      expect(_accounts.deleteAccountCalls, 2);
      expect(_dialog(), findsNothing);
      expect(
        _message(messageOfCode('REAUTHENTICATION_REQUIRED')),
        findsOneWidget,
      );
      _expectScreenKept(tester, UserRole.owner);
      _expectStillSignedIn();
    });

    testWidgets('works for a tenant', (tester) async {
      await _open(tester, role: UserRole.tenant);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      await _confirmAndSubmit(tester);

      await _answerPassword(tester, 'rahasia panjang');

      expect(_accounts.deleteAccountCalls, 2);
      _expectLoginAfterDeletion(tester);
    });
  });

  group('when the API asks for Google again', () {
    testWidgets('opens the Google dialog for an account without a password', (
      tester,
    ) async {
      await _open(tester, hasPassword: false);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);

      await _confirmAndSubmit(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text('Konfirmasi akun')), findsOneWidget);
      expect(_inDialog(buttonLabelled(_google)), findsOneWidget);
      expect(fieldLabeled(_password), findsNothing);
    });

    testWidgets('retries the deletion once after Google confirms', (
      tester,
    ) async {
      await _open(tester, hasPassword: false);
      _identity.token = 'token-abc';
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      await _confirmAndSubmit(tester);

      await tester.tap(_inDialog(buttonLabelled(_google)));
      await tester.pumpAndSettle();

      expect(_accounts.googleReauthentications, ['token-abc']);
      expect(_accounts.reauthentications, isEmpty);
      expect(_accounts.deleteAccountCalls, 2);
      _expectLoginAfterDeletion(tester);
    });

    testWidgets('cancelling the dialog keeps the screen without an error', (
      tester,
    ) async {
      await _open(tester, hasPassword: false);
      _accounts.deleteAccountScript.queue.add(_reauthRequired);
      await _confirmAndSubmit(tester);

      await _cancelDialog(tester);

      expect(_accounts.deleteAccountCalls, 1);
      expect(_accounts.googleReauthentications, isEmpty);
      expect(find.byType(FormMessage), findsNothing);
      _expectScreenKept(tester, UserRole.owner);
      _expectStillSignedIn();
    });

    testWidgets('shows a failure of the retry on the screen', (tester) async {
      await _open(tester, hasPassword: false);
      _accounts.deleteAccountScript.queue
        ..add(_reauthRequired)
        ..add(const ApiFailure(code: 'SUBSCRIPTION_AUTO_RENEWING'));
      await _confirmAndSubmit(tester);

      await tester.tap(_inDialog(buttonLabelled(_google)));
      await tester.pumpAndSettle();

      expect(_accounts.deleteAccountCalls, 2);
      expect(_message(_subscription), findsOneWidget);
      _expectStillSignedIn();
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the initial state': (tester, large) async {
        await _open(tester, largeText: large);
      },
      'the initial state of a manager': (tester, large) async {
        await _open(tester, role: UserRole.manager, largeText: large);
      },
      'the initial state of a tenant': (tester, large) async {
        await _open(tester, role: UserRole.tenant, largeText: large);
      },
      'the enabled state': (tester, large) async {
        await _open(tester, largeText: large);
        await _typeConfirmation(tester, 'HAPUS');
        await tester.pumpAndSettle();
      },
      'the error state': (tester, large) async {
        await _open(tester, largeText: large);
        _accounts.deleteAccountScript.always = const ApiFailure(
          code: 'OWNER_HAS_ACTIVE_LEASE',
        );
        await _confirmAndSubmit(tester);
      },
      'the busy state': (tester, large) async {
        await _open(tester, largeText: large);
        _accounts.deleteAccountScript.gate = Completer<void>();
        await _typeConfirmation(tester, 'HAPUS');
        await tester.ensureVisible(_deleteButton());
        await tester.pump();
        await tester.tap(_deleteButton());
        await tester.pump();
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
        expect(find.text(_title), findsOneWidget);
      });
    }

    testWidgets('the confirmation field is announced once with its label', (
      tester,
    ) async {
      await _open(tester);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(_confirmField());
        expect(node.label, contains(_fieldLabel));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the button and Batal are at least 48 dp', (tester) async {
      await _open(tester);

      final handle = tester.ensureSemantics();
      try {
        for (final label in [_submitLabel, 'Batal']) {
          final rect = tester.getSemantics(find.text(label)).rect;
          expect(rect.height, greaterThanOrEqualTo(48), reason: label);
          expect(rect.width, greaterThanOrEqualTo(48), reason: label);
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the button is reachable at large text size', (tester) async {
      await _open(tester, largeText: true);
      await _typeConfirmation(tester, 'HAPUS');

      await _tapDelete(tester);

      expect(tester.takeException(), isNull);
      expect(_accounts.deleteAccountCalls, 1);
    });
  });
}
