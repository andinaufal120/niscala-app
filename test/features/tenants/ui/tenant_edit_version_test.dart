import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'tenant_ui_helpers.dart';

const _name = 'Nama lengkap (wajib)';
const _phone = 'Nomor telepon (wajib)';
const _conflict = ApiFailure(code: 'RESOURCE_VERSION_CONFLICT');
const _conflictMessage =
    'Data ini sudah diubah oleh pengguna lain. Data terbaru sudah dimuat ulang.';

Tenant _tenant({int version = 3, String name = 'Budi Santoso'}) => makeTenant(
  id: 't1',
  name: name,
  phone: '081255204471',
  version: version,
  emergencyContacts: [
    EmergencyContact(
      name: 'Siti Rahma',
      relationship: 'Ibu',
      phone: '081355512345',
    ),
    EmergencyContact(
      name: 'Joko',
      relationship: 'Kakak',
      phone: '081355512346',
    ),
  ],
);

Future<void> _pumpEdit(
  WidgetTester tester,
  FakeTenantRepository repo, {
  bool largeText = false,
}) => pumpTenantApp(
  tester,
  repo,
  path: '/properti/p1/penyewa/t1/ubah',
  largeText: largeText,
);

Finder _saveButton() => find.descendant(
  of: find.byType(ActionFooter),
  matching: find.byType(FilledButton),
);

Future<void> _submit(WidgetTester tester) => tapVisible(tester, _saveButton());

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('the edit form sends the version it read', () {
    testWidgets('sends the version of the loaded tenant', (tester) async {
      final repo = FakeTenantRepository(tenants: [_tenant(version: 3)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [3]);
    });

    testWidgets('sends version 1 for a tenant at its first version', (
      tester,
    ) async {
      final repo = FakeTenantRepository(tenants: [_tenant(version: 1)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [1]);
    });

    testWidgets('sends a larger version unchanged', (tester) async {
      final repo = FakeTenantRepository(tenants: [_tenant(version: 7)]);
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(repo.updatedVersions, [7]);
    });

    testWidgets('sends the version together with the edited values', (
      tester,
    ) async {
      final repo = FakeTenantRepository(tenants: [_tenant(version: 4)]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Budi Baru');

      await _submit(tester);

      expect(repo.updated.single.id, 't1');
      expect(repo.updated.single.input.name, 'Budi Baru');
      expect(repo.updatedVersions, [4]);
    });

    testWidgets('the add form sends no update', (tester) async {
      final repo = FakeTenantRepository(tenants: [_tenant()]);
      await pumpTenantApp(tester, repo, path: '/properti/p1/penyewa/tambah');

      expect(repo.updatedVersions, isEmpty);
      expect(find.byType(TenantFormScreen), findsOneWidget);
    });
  });

  group('a version conflict on edit', () {
    FakeTenantRepository conflictingRepo() {
      final repo = FakeTenantRepository(tenants: [_tenant(version: 3)]);
      repo.updateScript.queue.add(_conflict);
      return repo;
    }

    testWidgets('closes the form and returns to the tenant detail', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submit(tester);

      expect(find.byType(TenantFormScreen), findsNothing);
      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/penyewa/t1');
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

    testWidgets('reloads the tenant and shows the changed data', (
      tester,
    ) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      final loadsBefore = repo.getCalls;
      repo.tenants[0] = _tenant(version: 5, name: 'Budi Terbaru');

      await _submit(tester);

      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(find.text('Budi Terbaru'), findsAtLeastNWidgets(1));
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('the next edit sends the newer version', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      repo.tenants[0] = _tenant(version: 5, name: 'Budi Terbaru');
      await _submit(tester);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      goTo(tester, '/properti/p1/penyewa/t1/ubah');
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _name).controller!.text, 'Budi Terbaru');
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
      final repo = FakeTenantRepository(tenants: [_tenant()])
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _pumpEdit(tester, repo);

      await _submit(tester);

      expect(labeledFieldError(tester, _phone), isNotNull);
      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(find.text(_conflictMessage), findsNothing);
    });

    testWidgets(
      'a network failure shows a banner and does not close the form',
      (tester) async {
        final repo = FakeTenantRepository(tenants: [_tenant()])
          ..updateScript.queue.add(const ApiFailure.network());
        await _pumpEdit(tester, repo);

        await _submit(tester);

        expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
        expect(find.byType(TenantFormScreen), findsOneWidget);
        expect(find.text(_conflictMessage), findsNothing);
      },
    );

    testWidgets('a retry after a failure sends the same version', (
      tester,
    ) async {
      final repo = FakeTenantRepository(tenants: [_tenant(version: 6)])
        ..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await _submit(tester);

      await _submit(tester);

      expect(repo.updatedVersions, [6, 6]);
    });
  });
}
