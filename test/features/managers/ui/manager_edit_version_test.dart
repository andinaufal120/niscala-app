import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/managers/ui/manager_detail_screen.dart';
import 'package:niscala/features/managers/ui/manager_form_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'manager_ui_helpers.dart';

const _name = 'Nama lengkap (wajib)';
const _phone = 'Nomor telepon (WhatsApp) (wajib)';
const _conflict = ApiFailure(code: 'RESOURCE_VERSION_CONFLICT');
const _conflictMessage =
    'Data ini sudah diubah oleh pengguna lain. Data terbaru sudah dimuat ulang.';

Manager _manager({int version = 3, String name = 'Rina Putri'}) =>
    makeManager(id: 'm1', name: name, nickname: 'Bu Rina', version: version);

Future<void> _pumpEdit(
  WidgetTester tester,
  FakeManagerRepository repo, {
  bool largeText = false,
}) => pumpManagerApp(
  tester,
  repo,
  path: '/properti/p1/pengelola/m1/ubah',
  largeText: largeText,
);

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan'));

void main() {
  group('the edit form sends the version it read', () {
    testWidgets('sends the version of the loaded manager', (tester) async {
      final repo = FakeManagerRepository(managers: [_manager(version: 3)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [3]);
    });

    testWidgets('sends version 1 for a manager at its first version', (
      tester,
    ) async {
      final repo = FakeManagerRepository(managers: [_manager(version: 1)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [1]);
    });

    testWidgets('sends a larger version unchanged', (tester) async {
      final repo = FakeManagerRepository(managers: [_manager(version: 7)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [7]);
    });

    testWidgets('sends the version together with the edited values', (
      tester,
    ) async {
      final repo = FakeManagerRepository(managers: [_manager(version: 4)]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Rina Baru');

      await _submit(tester);

      expect(repo.updated.single.id, 'm1');
      expect(repo.updated.single.input.name, 'Rina Baru');
      expect(repo.updatedVersions, [4]);
    });

    testWidgets('the add form sends no update', (tester) async {
      final repo = FakeManagerRepository(managers: [_manager()]);
      await pumpManagerApp(tester, repo, path: '/properti/p1/pengelola/tambah');
      await typeInto(tester, _name, 'Agus Baru');
      await typeInto(tester, _phone, '0812-5520-4471');
      await tapVisible(tester, propertyTile('Kos Melati'));

      await _submit(tester);

      expect(repo.updatedVersions, isEmpty);
    });
  });

  group('a version conflict on edit', () {
    FakeManagerRepository conflictingRepo() {
      final repo = FakeManagerRepository(managers: [_manager(version: 3)]);
      repo.updateScript.queue.add(_conflict);
      return repo;
    }

    testWidgets('closes the form and returns to the manager detail', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(find.byType(ManagerFormScreen), findsNothing);
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/pengelola/m1');
    });

    testWidgets(
      'shows the message in a snack bar on the screen it returns to',
      (tester) async {
        await _pumpEdit(tester, conflictingRepo());

        await _submit(tester);

        expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
        expect(messageOfCode('RESOURCE_VERSION_CONFLICT'), _conflictMessage);
      },
    );

    testWidgets('shows the message once and shows no success snack bar', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(find.text(_conflictMessage), findsOneWidget);
      expect(find.text('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('sends the update once and does not retry', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updatedVersions, [3]);
    });

    testWidgets('reloads the manager and shows the changed data', (
      tester,
    ) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      final loadsBefore = repo.getCalls;
      repo.managers[0] = _manager(version: 5, name: 'Rina Terbaru');

      await _submit(tester);

      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(find.text('Rina Terbaru'), findsAtLeastNWidgets(1));
      expect(find.text('Rina Putri'), findsNothing);
    });

    testWidgets('the next edit sends the newer version', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      repo.managers[0] = _manager(version: 5, name: 'Rina Terbaru');
      await _submit(tester);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      goTo(tester, '/properti/p1/pengelola/m1/ubah');
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _name).controller!.text, 'Rina Terbaru');
      await _submit(tester);

      expect(repo.updatedVersions, [3, 5]);
    });

    testWidgets('meets the accessibility guidelines with the snack bar', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the snack bar', (tester) async {
      await _pumpEdit(tester, conflictingRepo(), largeText: true);

      await _submit(tester);

      expect(find.widgetWithText(SnackBar, _conflictMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('other failures on edit stay on the form', () {
    testWidgets('a field error shows inline and does not close the form', (
      tester,
    ) async {
      final repo = FakeManagerRepository(managers: [_manager()])
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(labeledFieldError(tester, _phone), isNotNull);
      expect(find.byType(ManagerFormScreen), findsOneWidget);
      expect(find.text(_conflictMessage), findsNothing);
    });

    testWidgets(
      'a network failure shows a banner and does not close the form',
      (tester) async {
        final repo = FakeManagerRepository(managers: [_manager()])
          ..updateScript.queue.add(const ApiFailure.network());
        await _pumpEdit(tester, repo);

        await _submit(tester);

        expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
        expect(find.byType(ManagerFormScreen), findsOneWidget);
        expect(find.text(_conflictMessage), findsNothing);
      },
    );

    testWidgets('a retry after a failure sends the same version', (
      tester,
    ) async {
      final repo = FakeManagerRepository(managers: [_manager(version: 6)])
        ..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await _submit(tester);

      await _submit(tester);

      expect(repo.updatedVersions, [6, 6]);
    });
  });
}
