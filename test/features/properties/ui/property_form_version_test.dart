import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'property_ui_helpers.dart';

const _name = 'Nama properti (wajib)';
const _bankName = 'Nama bank';
const _accountNumber = 'Nomor rekening';
const _holder = 'Nama pemilik rekening';
const _password = 'Kata sandi (wajib)';
const _conflict = ApiFailure(code: 'RESOURCE_VERSION_CONFLICT');
const _reauthRequired = ApiFailure(code: 'REAUTHENTICATION_REQUIRED');
const _conflictMessage =
    'Data ini sudah diubah oleh pengguna lain. Data terbaru sudah dimuat ulang.';

Property _melati({int version = 3, String name = 'Kos Melati'}) =>
    makeProperty(id: 'p1', name: name, version: version);

Future<void> _pumpEdit(
  WidgetTester tester,
  FakePropertyRepository repo, {
  bool largeText = false,
}) => pumpPropertyApp(
  tester,
  repo,
  path: '/properti/p1/ubah',
  largeText: largeText,
  accounts: _accounts,
);

/// The account repository behind the screens of the current test.
late FakeAccountRepository _accounts;

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Perubahan'));

Future<void> _fillBank(WidgetTester tester) async {
  await typeInto(tester, _bankName, 'BCA');
  await typeInto(tester, _accountNumber, '1234567890');
  await typeInto(tester, _holder, 'Budi Santoso');
}

/// Edits the bank account, submits, and types the password into the dialog
/// that the first failure opened.
Future<void> _reauthenticate(WidgetTester tester) async {
  await _fillBank(tester);
  await _submit(tester);
  await typeInto(tester, _password, 'rahasia panjang');
  await tester.tap(find.text('Lanjutkan'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _accounts = FakeAccountRepository());

  group('the edit form sends the version it read', () {
    testWidgets('sends the version of the loaded property', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 3)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [3]);
    });

    testWidgets('sends version 1 for a property at its first version', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 1)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [1]);
    });

    testWidgets('sends a larger version unchanged', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 7)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [7]);
    });

    testWidgets('sends the version together with the edited values', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 4)]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Kos Baru');

      await _submit(tester);

      expect(repo.updated.single.id, 'p1');
      expect(repo.updated.single.input.name, 'Kos Baru');
      expect(repo.updatedVersions, [4]);
    });

    testWidgets('the add form sends no update', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await pumpPropertyApp(tester, repo, path: '/properti/tambah');
      await typeInto(tester, _name, 'Kos Baru');
      await typeInto(tester, 'Alamat (wajib)', 'Jl. Baru 5');

      await tapVisible(tester, find.text('Simpan Properti'));

      expect(repo.updatedVersions, isEmpty);
      expect(repo.created, hasLength(1));
    });
  });

  group('re-authentication keeps the version', () {
    testWidgets('the retry sends the same version as the first attempt', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 5)]);
      repo.updateScript.queue.add(_reauthRequired);
      await _pumpEdit(tester, repo);

      await _reauthenticate(tester);

      expect(_accounts.reauthentications, ['rahasia panjang']);
      expect(repo.updated, hasLength(2));
      expect(repo.updatedVersions, [5, 5]);
    });

    testWidgets('a version conflict after the retry closes the form', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 5)]);
      repo.updateScript.queue
        ..add(_reauthRequired)
        ..add(_conflict);
      await _pumpEdit(tester, repo);

      await _reauthenticate(tester);

      expect(repo.updatedVersions, [5, 5]);
      expect(find.byType(PropertyFormScreen), findsNothing);
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1');
      expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a version conflict after the retry reloads the property', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 5)]);
      repo.updateScript.queue
        ..add(_reauthRequired)
        ..add(_conflict);
      await _pumpEdit(tester, repo);
      final loadsBefore = repo.getCalls;
      repo.properties[0] = _melati(version: 9, name: 'Kos Terbaru');

      await _reauthenticate(tester);

      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(find.text('Kos Terbaru'), findsAtLeastNWidgets(1));
    });
  });

  group('a version conflict on edit', () {
    FakePropertyRepository conflictingRepo() {
      final repo = FakePropertyRepository(properties: [_melati(version: 3)]);
      repo.updateScript.queue.add(_conflict);
      return repo;
    }

    testWidgets('closes the form and returns to the property detail', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(find.byType(PropertyFormScreen), findsNothing);
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1');
    });

    testWidgets(
      'shows the message in a snack bar on the screen it returns to',
      (tester) async {
        await _pumpEdit(tester, conflictingRepo());

        await _submit(tester);

        expect(snackBar(_conflictMessage), findsOneWidget);
        expect(messageOfCode('RESOURCE_VERSION_CONFLICT'), _conflictMessage);
      },
    );

    testWidgets('shows the message once and shows no success snack bar', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(find.text(_conflictMessage), findsOneWidget);
      expect(snackBar('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('sends the update once and does not open the password dialog', (
      tester,
    ) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updatedVersions, [3]);
      expect(_accounts.reauthentications, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('reloads the property and shows the changed data', (
      tester,
    ) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      final loadsBefore = repo.getCalls;
      repo.properties[0] = _melati(version: 5, name: 'Kos Terbaru');

      await _submit(tester);

      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(find.text('Kos Terbaru'), findsAtLeastNWidgets(1));
      expect(find.text('Kos Melati'), findsNothing);
    });

    testWidgets('the next edit sends the newer version', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      repo.properties[0] = _melati(version: 5, name: 'Kos Terbaru');
      await _submit(tester);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      goTo(tester, '/properti/p1/ubah');
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _name).controller!.text, 'Kos Terbaru');
      await _submit(tester);

      expect(repo.updatedVersions, [3, 5]);
    });

    testWidgets('meets the accessibility guidelines with the snack bar', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(snackBar(_conflictMessage), findsOneWidget);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the snack bar', (tester) async {
      await _pumpEdit(tester, conflictingRepo(), largeText: true);

      await _submit(tester);

      expect(snackBar(_conflictMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('other failures on edit stay on the form', () {
    testWidgets('a field error shows inline and does not close the form', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..updateScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
        );
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(
        labeledFieldError(tester, _name),
        messageOfCode('PROPERTY_NAME_TAKEN'),
      );
      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(find.text(_conflictMessage), findsNothing);
    });

    testWidgets(
      'a network failure shows a banner and does not close the form',
      (tester) async {
        final repo = FakePropertyRepository(properties: [_melati()])
          ..updateScript.queue.add(const ApiFailure.network());
        await _pumpEdit(tester, repo);

        await _submit(tester);

        expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
        expect(find.byType(PropertyFormScreen), findsOneWidget);
        expect(find.text(_conflictMessage), findsNothing);
      },
    );

    testWidgets('a retry after a failure sends the same version', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(version: 6)])
        ..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await _submit(tester);

      await _submit(tester);

      expect(repo.updatedVersions, [6, 6]);
    });
  });
}
