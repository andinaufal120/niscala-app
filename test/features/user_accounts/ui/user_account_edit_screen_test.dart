import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/user_accounts/ui/user_account_detail_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_edit_screen.dart';
import 'package:niscala/features/user_accounts/ui/user_account_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'user_account_ui_helpers.dart';

const _name = 'Nama lengkap (wajib)';
const _email = 'Email (wajib)';
const _note =
    'Email baru berlaku setelah tautan yang dikirim ke alamat itu '
    'dikonfirmasi.';

FakeUserAccountRepository _repo([List<UserAccount>? accounts]) =>
    FakeUserAccountRepository(accounts: accounts ?? sampleUserAccounts());

Future<void> _open(
  WidgetTester tester,
  FakeUserAccountRepository repo,
  String id, {
  bool settle = true,
  bool largeText = false,
  UserRole role = UserRole.admin,
}) => pumpUserAccountApp(
  tester,
  repo,
  role: role,
  path: '/admin/$id/ubah',
  settle: settle,
  largeText: largeText,
);

Future<void> _save(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled('Simpan'));

Future<void> _fillAndSave(
  WidgetTester tester, {
  String? name,
  String? email,
  String? status,
}) async {
  if (name != null) await type(tester, _name, name);
  if (email != null) await type(tester, _email, email);
  if (status != null) await tapVisible(tester, find.text(status));
  await _save(tester);
}

/// Expects the status choice [label] to expose whether it is chosen, as a
/// checked or a selected control, with a target of at least 48 dp.
void _expectChoice(WidgetTester tester, String label, {required bool chosen}) {
  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(find.text(label));
    expect(
      node,
      anyOf(
        isSemantics(hasCheckedState: true, isChecked: chosen),
        isSemantics(hasSelectedState: true, isSelected: chosen),
      ),
    );
    expect(node.rect.height, greaterThanOrEqualTo(48));
    expect(node.rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

void _expectBanner(WidgetTester tester, String message) {
  expect(find.text(message), findsOneWidget);
  expect(find.byType(SnackBar), findsNothing);
  expect(fieldError(tester, _name), isNull);
  expect(fieldError(tester, _email), isNull);
  expect(field(_name), findsOneWidget);
  expect(currentPath(tester), '/admin/u1/ubah');
}

UserAccountInput _sent(FakeUserAccountRepository repo) =>
    repo.updated.single.input;

void main() {
  group('header', () {
    testWidgets('shows the title Ubah Akun, a back button and a white bar', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(find.byType(UserAccountEditScreen), findsOneWidget);
      expect(appBarTitle('Ubah Akun'), findsOneWidget);
      expect(backButton(), findsOneWidget);
      expectDetailAppBar(tester);
    });

    testWidgets('asks for the account in the path', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u2');

      final screen = tester.widget<UserAccountEditScreen>(
        find.byType(UserAccountEditScreen),
      );
      expect(screen.accountId, 'u2');
      expect(repo.calls, contains('get:u2'));
      expect(repo.calls, isNot(contains('get:u1')));
    });

    testWidgets('Kembali returns to the detail with nothing saved', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await pressBack(tester);

      expect(currentPath(tester), '/admin/u1');
      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
      expect(repo.updateCalls, 0);
    });

    testWidgets('announces the title of the screen as a header', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle('Ubah Akun')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('access', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role cannot open the edit screen', (tester) async {
        final repo = _repo();
        await _open(tester, repo, 'u1', role: role);

        expect(currentPath(tester), '/beranda');
        expect(find.byType(UserAccountEditScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }

    testWidgets('a tenant cannot open the edit screen', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1', role: UserRole.tenant);

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(UserAccountEditScreen), findsNothing);
      expect(repo.calls, isEmpty);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false);

      expectLoading(tester);
      expect(field(_name), findsNothing);
      expect(buttonLabelled('Simpan'), findsNothing);
    });

    testWidgets('shows the form once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _open(tester, repo, 'u1', settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(field(_name), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(field(_name), findsNothing);
      expect(buttonLabelled('Simpan'), findsNothing);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo, 'u1');

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 1);
    });

    testWidgets('Coba lagi loads the account again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, 'u1');

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(field(_name), findsOneWidget);
    });

    testWidgets('shows that the account was not found', (tester) async {
      await _open(tester, _repo(), 'missing');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text(messageOfCode('USER_ACCOUNT_NOT_FOUND')),
        findsOneWidget,
      );
      expect(field(_name), findsNothing);
    });
  });

  group('form', () {
    testWidgets('is prefilled with the name and email of the account', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(textField(tester, _name).controller?.text, 'Budi Santoso');
      expect(textField(tester, _email).controller?.text, 'budi@example.com');
      expect(fieldError(tester, _name), isNull);
      expect(fieldError(tester, _email), isNull);
    });

    testWidgets('is prefilled with the data of the account in the path', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u2');

      expect(textField(tester, _name).controller?.text, 'Siti Pemilik');
      expect(textField(tester, _email).controller?.text, 'siti@example.com');
    });

    testWidgets('offers Aktif and Nonaktif and no Dihapus', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Nonaktif'), findsOneWidget);
      expect(find.text('Dihapus'), findsNothing);
    });

    testWidgets('chooses Aktif for an active account', (tester) async {
      await _open(tester, _repo(), 'u1');

      _expectChoice(tester, 'Aktif', chosen: true);
      _expectChoice(tester, 'Nonaktif', chosen: false);
    });

    testWidgets('chooses Nonaktif for an inactive account', (tester) async {
      await _open(tester, _repo(), 'u3');

      _expectChoice(tester, 'Aktif', chosen: false);
      _expectChoice(tester, 'Nonaktif', chosen: true);
    });

    testWidgets('choosing a status moves the choice', (tester) async {
      await _open(tester, _repo(), 'u1');

      await tapVisible(tester, find.text('Nonaktif'));
      _expectChoice(tester, 'Aktif', chosen: false);
      _expectChoice(tester, 'Nonaktif', chosen: true);

      await tapVisible(tester, find.text('Aktif'));
      _expectChoice(tester, 'Aktif', chosen: true);
      _expectChoice(tester, 'Nonaktif', chosen: false);
    });

    testWidgets('choosing a status does not save anything', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await tapVisible(tester, find.text('Nonaktif'));

      expect(repo.updateCalls, 0);
      expect(currentPath(tester), '/admin/u1/ubah');
    });

    testWidgets('says that a new email stays pending until it is confirmed', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(find.text(_note), findsOneWidget);
    });

    testWidgets('shows the same note for an inactive account', (tester) async {
      await _open(tester, _repo(), 'u3');

      expect(find.text(_note), findsOneWidget);
    });

    testWidgets('has a Simpan button and no other save action', (tester) async {
      await _open(tester, _repo(), 'u1');

      expect(buttonLabelled('Simpan'), findsOneWidget);
      expect(find.text('Hapus'), findsNothing);
    });

    testWidgets('uses the email keyboard and keeps paste enabled', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expect(
        textField(tester, _email).keyboardType,
        TextInputType.emailAddress,
      );
      expect(
        textField(tester, _email).enableInteractiveSelection,
        isNot(false),
      );
      expect(textField(tester, _name).enableInteractiveSelection, isNot(false));
    });

    testWidgets('sends nothing before Simpan is pressed', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await type(tester, _name, 'Budi Baru');

      expect(repo.updateCalls, 0);
    });
  });

  group('validation', () {
    testWidgets('an empty name is an error and sends nothing', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: '');

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(fieldError(tester, _email), isNull);
      expect(repo.updateCalls, 0);
    });

    testWidgets('a blank name counts as empty', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: '   ');

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(repo.updateCalls, 0);
    });

    testWidgets('an empty email is an error and sends nothing', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, email: '');

      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(fieldError(tester, _name), isNull);
      expect(repo.updateCalls, 0);
    });

    testWidgets('a blank email counts as empty', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, email: '   ');

      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(repo.updateCalls, 0);
    });

    testWidgets('both errors show together', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: '', email: '');

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(repo.updateCalls, 0);
    });

    for (final bad in [
      'budi',
      'budi@',
      'budi@example',
      '@example.com',
      'a b@c.d',
    ]) {
      testWidgets('rejects the email "$bad" without a request', (tester) async {
        final repo = _repo();
        await _open(tester, repo, 'u1');

        await _fillAndSave(tester, email: bad);

        expect(fieldError(tester, _email), 'Format email tidak valid.');
        expect(fieldError(tester, _name), isNull);
        expect(repo.updateCalls, 0);
      });
    }

    testWidgets('a client side error does not leave the form', (tester) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, name: '');

      expect(currentPath(tester), '/admin/u1/ubah');
      expect(field(_name), findsOneWidget);
    });

    testWidgets('errors disappear once the form is valid and resubmitted', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, name: '', email: 'x');

      await _fillAndSave(tester, name: 'Budi Baru', email: 'budi@example.com');

      expect(repo.updateCalls, 1);
      expect(find.text('Nama wajib diisi.'), findsNothing);
      expect(find.text('Format email tidak valid.'), findsNothing);
    });

    testWidgets('keeps each field error on its field node', (tester) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, name: '', email: '');

      expectFieldNode(tester, _name, error: 'Nama wajib diisi.');
      expectFieldNode(tester, _email, error: 'Email wajib diisi.');
    });
  });

  group('submit', () {
    testWidgets('sends the name, email and status of an unchanged form', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _save(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.id, 'u1');
      expect(_sent(repo).name, 'Budi Santoso');
      expect(_sent(repo).email, 'budi@example.com');
      expect(_sent(repo).status, EditableAccountStatus.active);
    });

    testWidgets('sends the id of the account in the path', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u2');

      await _save(tester);

      expect(repo.updated.single.id, 'u2');
      expect(_sent(repo).name, 'Siti Pemilik');
    });

    testWidgets('sends the new name', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(_sent(repo).name, 'Budi Baru');
      expect(_sent(repo).email, 'budi@example.com');
    });

    testWidgets('trims the name', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: '  Budi Baru  ');

      expect(_sent(repo).name, 'Budi Baru');
    });

    testWidgets('sends the new email trimmed', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, email: '  budi.baru@example.com \n');

      expect(_sent(repo).email, 'budi.baru@example.com');
    });

    testWidgets('sends an email that differs only in case as the same email', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, email: ' Budi.Baru@Example.com ');

      final sent = _sent(repo).email;
      expect(sent, sent.trim());
      expect(sent.toLowerCase(), 'budi.baru@example.com');
    });

    testWidgets('sends Nonaktif as inactive', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, status: 'Nonaktif');

      expect(_sent(repo).status, EditableAccountStatus.inactive);
      expect(_sent(repo).name, 'Budi Santoso');
      expect(_sent(repo).email, 'budi@example.com');
    });

    testWidgets('sends Aktif as active to reactivate an account', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u3');

      await _fillAndSave(tester, status: 'Aktif');

      expect(_sent(repo).status, EditableAccountStatus.active);
    });

    testWidgets('keeps an inactive account inactive when untouched', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u3');

      await _save(tester);

      expect(_sent(repo).status, EditableAccountStatus.inactive);
    });

    testWidgets('sends the last status chosen', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');
      await tapVisible(tester, find.text('Nonaktif'));
      await tapVisible(tester, find.text('Aktif'));

      await _save(tester);

      expect(_sent(repo).status, EditableAccountStatus.active);
    });

    testWidgets('changes name, email and status in one request', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(
        tester,
        name: 'Budi Baru',
        email: 'budi.baru@example.com',
        status: 'Nonaktif',
      );

      expect(repo.updated, hasLength(1));
      expect(_sent(repo).name, 'Budi Baru');
      expect(_sent(repo).email, 'budi.baru@example.com');
      expect(_sent(repo).status, EditableAccountStatus.inactive);
    });
  });

  group('success', () {
    testWidgets('goes back to the detail of the account', (tester) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(currentPath(tester), '/admin/u1');
      expect(find.byType(UserAccountDetailScreen), findsOneWidget);
      expect(find.byType(UserAccountEditScreen), findsNothing);
    });

    testWidgets('the detail shows the saved name', (tester) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(find.text('Budi Baru'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('the detail is loaded again after the save', (tester) async {
      final repo = _repo();
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(
        repo.calls.lastIndexOf('get:u1'),
        greaterThan(repo.calls.indexOf('update:u1')),
      );
    });

    testWidgets('the detail shows Nonaktif after deactivating', (tester) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, status: 'Nonaktif');

      expect(statusBadge('Nonaktif'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNothing);
    });

    testWidgets('the detail shows Aktif after reactivating', (tester) async {
      await _open(tester, _repo(), 'u3');

      await _fillAndSave(tester, status: 'Aktif');

      expect(statusBadge('Aktif'), findsOneWidget);
      expect(statusBadge('Nonaktif'), findsNothing);
    });

    testWidgets('a new email shows as pending next to the current one', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, email: 'Budi.Baru@example.com');

      expect(find.text('Email baru menunggu konfirmasi'), findsOneWidget);
      expect(find.text('budi.baru@example.com'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('Tautan berlaku sampai'), findsOneWidget);
      expect(find.textContaining('10 Nov 2026'), findsOneWidget);
    });

    testWidgets('an unchanged email starts no pending change', (tester) async {
      await _open(tester, _repo(), 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(find.text('Email baru menunggu konfirmasi'), findsNothing);
    });

    testWidgets('the current email cancels a pending change', (tester) async {
      final repo = _repo([
        makeUserAccount(
          pendingEmail: 'baru@example.com',
          pendingEmailExpiresAt: DateTime.utc(2026, 10, 25, 12),
        ),
      ]);
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, email: 'BUDI@example.com');

      expect(find.text('Email baru menunggu konfirmasi'), findsNothing);
      expect(find.text('baru@example.com'), findsNothing);
      expect(find.text('budi@example.com'), findsOneWidget);
    });

    testWidgets('the list shows the saved name after going back', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      final listCallsBefore = repo.listCalls;

      await _fillAndSave(tester, name: 'Budi Baru');
      await pressBack(tester);

      expect(currentPath(tester), '/admin');
      expect(find.byType(UserAccountListScreen), findsOneWidget);
      expect(find.text('Budi Baru'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(repo.listCalls, greaterThan(listCallsBefore));
    });

    testWidgets('the list shows the saved status after going back', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await _fillAndSave(tester, status: 'Nonaktif');
      await pressBack(tester);

      expect(
        find.descendant(
          of: accountRow('Budi Santoso'),
          matching: find.text('Nonaktif'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is reached from the Ubah action of the detail', (
      tester,
    ) async {
      final repo = _repo();
      await pumpUserAccountApp(tester, repo, path: '/admin/u2');

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/u2/ubah');
      expect(textField(tester, _name).controller?.text, 'Siti Pemilik');
    });
  });

  group('failures', () {
    testWidgets('EMAIL_ALREADY_REGISTERED is shown on the email field', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'EMAIL_ALREADY_REGISTERED',
          field: 'email',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, email: 'siti@example.com');

      expect(fieldError(tester, _email), 'Email sudah terdaftar.');
      expect(fieldError(tester, _name), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(currentPath(tester), '/admin/u1/ubah');
      expectFieldNode(tester, _email, error: 'Email sudah terdaftar.');
    });

    testWidgets('a taken email keeps what the user typed', (tester) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'EMAIL_ALREADY_REGISTERED',
          field: 'email',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1');

      await _fillAndSave(
        tester,
        name: 'Budi Baru',
        email: 'siti@example.com',
        status: 'Nonaktif',
      );

      expect(textField(tester, _name).controller?.text, 'Budi Baru');
      expect(textField(tester, _email).controller?.text, 'siti@example.com');
      _expectChoice(tester, 'Nonaktif', chosen: true);
    });

    testWidgets('the email error goes away on the next try', (tester) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(
            code: 'EMAIL_ALREADY_REGISTERED',
            field: 'email',
            statusCode: 409,
          ),
        );
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, email: 'siti@example.com');

      await _fillAndSave(tester, email: 'budi.baru@example.com');

      expect(repo.updateCalls, 2);
      expect(repo.updated.last.input.email, 'budi.baru@example.com');
      expect(currentPath(tester), '/admin/u1');
    });

    testWidgets('CANNOT_MODIFY_OWN_ACCOUNT is shown as a message', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'CANNOT_MODIFY_OWN_ACCOUNT',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, status: 'Nonaktif');

      _expectBanner(
        tester,
        'Anda tidak dapat menonaktifkan akun Anda sendiri.',
      );
    });

    testWidgets('USER_ACCOUNT_DELETED is shown as a message', (tester) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'USER_ACCOUNT_DELETED',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      _expectBanner(tester, 'Akun ini sudah dihapus.');
    });

    testWidgets('USER_ACCOUNT_NOT_FOUND is shown as a message', (tester) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'USER_ACCOUNT_NOT_FOUND',
          statusCode: 404,
        );
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      _expectBanner(tester, messageOfCode('USER_ACCOUNT_NOT_FOUND'));
    });

    final bannerCases = {
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };
    for (final entry in bannerCases.entries) {
      testWidgets('${entry.key} is shown in a banner, not on a field', (
        tester,
      ) async {
        final repo = _repo()..updateScript.always = ApiFailure(code: entry.key);
        await _open(tester, repo, 'u1');

        await _fillAndSave(tester, name: 'Budi Baru');

        _expectBanner(tester, entry.value);
      });
    }

    testWidgets('a validation failure on name is shown on the name field', (
      tester,
    ) async {
      const failure = ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'name',
        statusCode: 422,
      );
      final repo = _repo()..updateScript.always = failure;
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(fieldError(tester, _name), errorMessageFor(failure));
      expect(fieldError(tester, _email), isNull);
      expect(currentPath(tester), '/admin/u1/ubah');
    });

    testWidgets('a validation failure on email is shown on the email field', (
      tester,
    ) async {
      const failure = ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'email',
        statusCode: 422,
      );
      final repo = _repo()..updateScript.always = failure;
      await _open(tester, repo, 'u1');

      await _fillAndSave(tester, name: 'Budi Baru');

      expect(fieldError(tester, _email), errorMessageFor(failure));
      expect(fieldError(tester, _name), isNull);
    });

    testWidgets('a failure leaves the detail as it was', (tester) async {
      final repo = _repo()..updateScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, name: 'Budi Baru');

      await pressBack(tester);

      expect(currentPath(tester), '/admin/u1');
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Budi Baru'), findsNothing);
    });

    testWidgets('the banner stays and is a live region', (tester) async {
      final repo = _repo()..updateScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, name: 'Budi Baru');

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('keeps what the user typed after a failure', (tester) async {
      final repo = _repo()..updateScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');

      await _fillAndSave(
        tester,
        name: 'Budi Baru',
        email: 'budi.baru@example.com',
        status: 'Nonaktif',
      );

      expect(textField(tester, _name).controller?.text, 'Budi Baru');
      expect(
        textField(tester, _email).controller?.text,
        'budi.baru@example.com',
      );
      _expectChoice(tester, 'Nonaktif', chosen: true);
    });

    testWidgets('the banner goes away when the next request starts', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, name: 'Budi Baru');
      repo.updateScript.gate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Simpan'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(repo.updateCalls, 2);
    });

    testWidgets('the user can retry after a failure', (tester) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, name: 'Budi Baru');

      await _save(tester);

      expect(repo.updateCalls, 2);
      expect(currentPath(tester), '/admin/u1');
      expect(find.text('Budi Baru'), findsOneWidget);
    });
  });

  group('while the account is being saved', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _open(tester, repo, 'u1');

      await tapAndPump(tester, buttonLabelled('Simpan'));

      expectBusy(tester);
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _open(tester, repo, 'u1');
      final button = buttonLabelled('Simpan');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.updateCalls, 1);
    });

    testWidgets('an invalid form does not start a request', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _open(tester, repo, 'u1');
      await type(tester, _name, '');

      await tapAndPump(tester, buttonLabelled('Simpan'));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(repo.updateCalls, 0);
    });

    testWidgets('goes back once the request completes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..updateScript.gate = gate;
      await _open(tester, repo, 'u1');
      await tapAndPump(tester, buttonLabelled('Simpan'));

      gate.complete();
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/u1');
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('stays on the form until the request completes', (
      tester,
    ) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _open(tester, repo, 'u1');

      await tapAndPump(tester, buttonLabelled('Simpan'));
      await tester.pump(const Duration(seconds: 5));

      expect(currentPath(tester), '/admin/u1/ubah');
    });

    testWidgets('restores the button when the request fails', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()
        ..updateScript.gate = gate
        ..updateScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');
      await tapAndPump(tester, buttonLabelled('Simpan'));

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled('Simpan')).onPressed,
        isNotNull,
      );
    });
  });

  group('structure', () {
    testWidgets('wraps the name and email in a LabeledField with a marker', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      for (final label in [_name, _email]) {
        expect(labeledField(label), findsOneWidget);
        expect(find.text(label), findsOneWidget);
      }
      expectNoDecorationLabels(tester);
    });

    testWidgets('puts each label above its field', (tester) async {
      await _open(tester, _repo(), 'u1');

      for (final label in [_name, _email]) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top));
      }
    });

    testWidgets('reads each label once, on its field', (tester) async {
      await _open(tester, _repo(), 'u1');

      expectFieldNode(tester, _name);
      expectFieldNode(tester, _email);
    });

    testWidgets('tapping a label focuses its field', (tester) async {
      await _open(tester, _repo(), 'u1');

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

    testWidgets('pins Simpan in a footer outside the scrolling area', (
      tester,
    ) async {
      await _open(tester, _repo(), 'u1');

      expectPinnedFooter(tester, 'Simpan');
    });
  });

  group('accessibility', () {
    final states = <String, (FakeUserAccountRepository, String)>{
      'an active account': (_repo(), 'u1'),
      'an inactive account': (_repo(), 'u3'),
      'an account with a pending email': (
        _repo([
          makeUserAccount(
            pendingEmail: 'baru@example.com',
            pendingEmailExpiresAt: DateTime.utc(2026, 10, 25, 12),
          ),
        ]),
        'u1',
      ),
      'a failure': (
        _repo()..getScript.always = const ApiFailure.network(),
        'u1',
      ),
      'an account that is not found': (_repo(), 'missing'),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await _open(tester, entry.value.$1, entry.value.$2);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for ${entry.key}', (tester) async {
        await _open(tester, entry.value.$1, entry.value.$2, largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with field errors', (tester) async {
      await _open(tester, _repo(), 'u1');
      await _fillAndSave(tester, name: '', email: 'x');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with field errors', (tester) async {
      await _open(tester, _repo(), 'u1', largeText: true);
      await _fillAndSave(tester, name: '', email: 'x');

      expect(fieldError(tester, _name), isNotNull);
      expect(fieldError(tester, _email), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with an error from the server', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'EMAIL_ALREADY_REGISTERED',
          field: 'email',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, email: 'siti@example.com');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with an error from the server', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'EMAIL_ALREADY_REGISTERED',
          field: 'email',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1', largeText: true);
      await _fillAndSave(tester, email: 'siti@example.com');

      expect(fieldError(tester, _email), 'Email sudah terdaftar.');
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with a banner', (tester) async {
      final repo = _repo()..updateScript.always = const ApiFailure.network();
      await _open(tester, repo, 'u1');
      await _fillAndSave(tester, name: 'Budi Baru');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with a banner', (tester) async {
      final repo = _repo()
        ..updateScript.always = const ApiFailure(
          code: 'CANNOT_MODIFY_OWN_ACCOUNT',
          statusCode: 409,
        );
      await _open(tester, repo, 'u1', largeText: true);
      await _fillAndSave(tester, status: 'Nonaktif');

      expect(
        find.text('Anda tidak dapat menonaktifkan akun Anda sendiri.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines while saving', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _open(tester, repo, 'u1');
      await tapAndPump(tester, buttonLabelled('Simpan'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while saving', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _open(tester, repo, 'u1', largeText: true);
      await tapAndPump(tester, buttonLabelled('Simpan'));

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with Nonaktif chosen', (tester) async {
      await _open(tester, _repo(), 'u1');
      await tapVisible(tester, find.text('Nonaktif'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the status choices are at least 48 dp', (tester) async {
      await _open(tester, _repo(), 'u1');

      expectTargetSize(tester, 'Aktif');
      expectTargetSize(tester, 'Nonaktif');
    });

    testWidgets('the Simpan button is at least 48 dp', (tester) async {
      await _open(tester, _repo(), 'u1');

      final size = tester.getSize(buttonLabelled('Simpan'));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });
}
