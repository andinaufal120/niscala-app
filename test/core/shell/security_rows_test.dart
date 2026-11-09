import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _googleEmail = 'andi.google@gmail.com';

/// The three sign-in states an account can be in.
enum _State {
  /// Signs in with a password only.
  passwordOnly,

  /// Signs in with a password and has Google linked.
  both,

  /// Signs in with Google only.
  googleOnly,
}

Account _accountOf(_State state, UserRole role) => makeAccount(
  role: role,
  hasPassword: state != _State.googleOnly,
  googleEmail: state == _State.passwordOnly ? null : _googleEmail,
);

FakeAccountRepository _repo(_State state, [UserRole role = UserRole.owner]) =>
    FakeAccountRepository(account: _accountOf(state, role));

/// A `Text` or `RichText` that shows [value] as all or part of its text, so
/// that the status and the Google email may share a line.
Finder _showing(String value) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(value),
  description: 'text showing "$value"',
);

Finder _security() => sectionCardOf('Keamanan');

Finder _inSecurity(Finder finder) =>
    find.descendant(of: _security(), matching: finder);

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

String _pagePath(UserRole role, String segment) =>
    '${accountPath(role)}/$segment';

void main() {
  for (final role in _roles) {
    group('the Keamanan section of a $role with a password only', () {
      testWidgets('shows the password as set with an Ubah action', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        expect(_inSecurity(find.text('Kata sandi')), findsOneWidget);
        expect(_inSecurity(find.text('Diatur')), findsOneWidget);
        expect(_inSecurity(find.text('Ubah')), findsOneWidget);
        expect(find.text('Belum diatur'), findsNothing);
        expect(find.text('Tambah'), findsNothing);
      });

      testWidgets('shows Google as not linked with a Hubungkan action', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        expect(_inSecurity(find.text('Google')), findsOneWidget);
        expect(_inSecurity(find.text('Belum terhubung')), findsOneWidget);
        expect(_inSecurity(find.text('Hubungkan')), findsOneWidget);
        expect(_showing('Terhubung'), findsNothing);
      });

      testWidgets('keeps Perangkat aktif and Keluar', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        expect(_inSecurity(find.text('Perangkat aktif')), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);
      });

      testWidgets('keeps the old single row name out of the screen', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        expect(find.text('Ubah kata sandi'), findsNothing);
      });

      testWidgets('sits below the heading and above Keluar', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        for (final text in ['Kata sandi', 'Google']) {
          expect(
            _top(tester, find.text(text)),
            greaterThan(_top(tester, find.text('Keamanan'))),
          );
          expect(
            _top(tester, find.text(text)),
            lessThan(_top(tester, find.text('Keluar'))),
          );
        }
      });

      testWidgets('Ubah opens the change password page', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        await tester.tap(find.text('Ubah'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), _pagePath(role, 'kata-sandi'));
        expect(appBarTitle('Ubah kata sandi'), findsOneWidget);
      });

      testWidgets('Hubungkan opens the link Google page', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        await tester.tap(find.text('Hubungkan'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), _pagePath(role, 'hubungkan-google'));
        expect(appBarTitle('Hubungkan Google'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('the actions are at least 48 dp and start their spoken '
          'label with the visible text', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        for (final action in ['Ubah', 'Hubungkan']) {
          expectTargetSize(tester, action);
          expect(semanticsLabelOf(tester, action), startsWith(action));
        }
      });

      testWidgets('the actions say what they act on when spoken', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );

        expect(
          semanticsLabelOf(tester, 'Ubah').toLowerCase(),
          contains('kata sandi'),
        );
        expect(
          semanticsLabelOf(tester, 'Hubungkan').toLowerCase(),
          contains('google'),
        );
      });
    });

    group('the Keamanan section of a $role with a password and Google', () {
      testWidgets('shows the password as set with an Ubah action', (
        tester,
      ) async {
        await pumpAccountApp(tester, _repo(_State.both, role), role: role);

        expect(_inSecurity(find.text('Diatur')), findsOneWidget);
        expect(_inSecurity(find.text('Ubah')), findsOneWidget);
      });

      testWidgets('shows Google as linked with its email and no action', (
        tester,
      ) async {
        await pumpAccountApp(tester, _repo(_State.both, role), role: role);

        expect(_inSecurity(find.text('Google')), findsOneWidget);
        expect(_inSecurity(_showing('Terhubung')), findsOneWidget);
        expect(_inSecurity(_showing(_googleEmail)), findsOneWidget);
        expect(find.text('Hubungkan'), findsNothing);
        expect(find.text('Belum terhubung'), findsNothing);
      });

      testWidgets('shows the Google email once, apart from the account email', (
        tester,
      ) async {
        await pumpAccountApp(tester, _repo(_State.both, role), role: role);

        expect(_showing(_googleEmail), findsOneWidget);
        expect(find.text('andi@example.com'), findsOneWidget);
      });

      testWidgets('tapping the linked Google row goes nowhere', (tester) async {
        await pumpAccountApp(tester, _repo(_State.both, role), role: role);

        await tester.tap(_showing('Terhubung'));
        await tester.pumpAndSettle();
        await tester.tap(_showing(_googleEmail));
        await tester.pumpAndSettle();

        expect(currentPath(tester), accountPath(role));
      });

      testWidgets('offers no way to unlink Google', (tester) async {
        await pumpAccountApp(tester, _repo(_State.both, role), role: role);

        for (final word in ['Putuskan', 'putus', 'Lepas', 'Hapus']) {
          expect(find.textContaining(word), findsNothing, reason: word);
        }
      });
    });

    group('the Keamanan section of a $role with Google only', () {
      testWidgets('shows the password as not set with a Tambah action', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
        );

        expect(_inSecurity(find.text('Kata sandi')), findsOneWidget);
        expect(_inSecurity(find.text('Belum diatur')), findsOneWidget);
        expect(_inSecurity(find.text('Tambah')), findsOneWidget);
        expect(find.text('Diatur'), findsNothing);
        expect(find.text('Ubah'), findsNothing);
      });

      testWidgets('shows Google as linked with its email and no action', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
        );

        expect(_inSecurity(_showing('Terhubung')), findsOneWidget);
        expect(_inSecurity(_showing(_googleEmail)), findsOneWidget);
        expect(find.text('Hubungkan'), findsNothing);
        expect(find.text('Belum terhubung'), findsNothing);
      });

      testWidgets('keeps Perangkat aktif and Keluar', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
        );

        expect(_inSecurity(find.text('Perangkat aktif')), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);
      });

      testWidgets('Tambah opens the add password page', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
        );

        await tester.tap(find.text('Tambah'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), _pagePath(role, 'tambah-kata-sandi'));
        expect(appBarTitle('Tambah kata sandi'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('Tambah is at least 48 dp and starts its spoken label with '
          'the visible text', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
        );

        expectTargetSize(tester, 'Tambah');
        expect(semanticsLabelOf(tester, 'Tambah'), startsWith('Tambah'));
        expect(
          semanticsLabelOf(tester, 'Tambah').toLowerCase(),
          contains('kata sandi'),
        );
      });
    });
  }

  group('an account with neither a password nor a linked Google', () {
    testWidgets('is not offered to link Google', (tester) async {
      final repo = FakeAccountRepository(
        account: makeAccount(hasPassword: false, googleEmail: null),
      );
      await pumpAccountApp(tester, repo);

      expect(find.text('Hubungkan'), findsNothing);
      expect(find.text('Perangkat aktif'), findsOneWidget);
    });
  });

  group('the rows while the account is not known', () {
    testWidgets('are not shown while the profile loads', (tester) async {
      final repo = FakeAccountRepository()..meScript.gate = Completer<void>();
      await pumpAccountApp(tester, repo, settle: false);

      for (final text in ['Kata sandi', 'Google', 'Ubah', 'Hubungkan']) {
        expect(find.text(text), findsNothing, reason: text);
      }
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
    });

    testWidgets('appear when the profile finishes loading', (tester) async {
      final repo = FakeAccountRepository()..meScript.gate = Completer<void>();
      await pumpAccountApp(tester, repo, settle: false);

      repo.meScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('are not shown when the profile fails to load', (tester) async {
      final repo = FakeAccountRepository()
        ..meScript.always = const ApiFailure.network();
      await pumpAccountApp(tester, repo);

      for (final text in ['Kata sandi', 'Google', 'Ubah', 'Hubungkan']) {
        expect(find.text(text), findsNothing, reason: text);
      }
      expect(find.text('Perangkat aktif'), findsOneWidget);
    });

    testWidgets('appear after Coba lagi loads the profile', (tester) async {
      final repo = FakeAccountRepository(
        account: _accountOf(_State.googleOnly, UserRole.owner),
      )..meScript.queue.add(const ApiFailure.network());
      await pumpAccountApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Belum diatur'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
    });
  });

  group('opening the pages', () {
    testWidgets('loads nothing from the link or add password APIs before a '
        'row is used', (tester) async {
      final repo = _repo(_State.googleOnly);
      await pumpAccountApp(tester, repo);

      expect(repo.addLocalPasswordCalls, 0);
      expect(repo.linkGoogleCalls, 0);
    });

    testWidgets('never asks Google for a token on the Akun tab', (
      tester,
    ) async {
      final google = FakeGoogleIdentity();
      await pumpAccountApp(tester, _repo(_State.passwordOnly), google: google);

      expect(google.requests, 0);
    });

    for (final role in _roles) {
      testWidgets('Kembali from the add password page returns a $role to '
          'Akun', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
        );
        await tester.tap(find.text('Tambah'));
        await tester.pumpAndSettle();

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Belum diatur'), findsOneWidget);
      });

      testWidgets('Kembali from the link Google page returns a $role to '
          'Akun', (tester) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
        );
        await tester.tap(find.text('Hubungkan'));
        await tester.pumpAndSettle();

        await pressBack(tester);

        expect(currentPath(tester), accountPath(role));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Belum terhubung'), findsOneWidget);
      });

      testWidgets('the add password page can be reached directly by a $role', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.googleOnly, role),
          role: role,
          path: _pagePath(role, 'tambah-kata-sandi'),
        );

        expect(currentPath(tester), _pagePath(role, 'tambah-kata-sandi'));
        expect(appBarTitle('Tambah kata sandi'), findsOneWidget);
      });

      testWidgets('the link Google page can be reached directly by a $role', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          _repo(_State.passwordOnly, role),
          role: role,
          path: _pagePath(role, 'hubungkan-google'),
        );

        expect(currentPath(tester), _pagePath(role, 'hubungkan-google'));
        expect(appBarTitle('Hubungkan Google'), findsOneWidget);
      });
    }
  });

  group('accessibility', () {
    for (final state in _State.values) {
      for (final role in _roles) {
        testWidgets('meets the guidelines for a $role that is ${state.name}', (
          tester,
        ) async {
          await pumpAccountApp(tester, _repo(state, role), role: role);

          await expectMeetsA11yGuidelines(tester);
        });

        testWidgets('fits at large text size for a $role that is '
            '${state.name}', (tester) async {
          await pumpAccountApp(
            tester,
            _repo(state, role),
            role: role,
            largeText: true,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('announces Keamanan as a header', (tester) async {
      await pumpAccountApp(tester, _repo(_State.googleOnly));

      expectSectionCard(tester, 'Keamanan');
    });
  });
}
