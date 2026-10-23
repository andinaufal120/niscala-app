import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'property_ui_helpers.dart';

const _readOnlyOwner =
    'Properti ini tidak termasuk paket Anda saat ini. Data tidak bisa diubah, '
    'tetapi tagihan, pembayaran, dan keluhan tetap diproses. Menghapus '
    'properti tetap bisa.';
const _readOnlyManager =
    'Paket pemilik kost tidak mencakup properti ini. Anda hanya bisa melihat '
    'data sampai pemilik meningkatkan paket.';
const _managerOnly =
    'Hanya Pemilik Kost yang dapat mengubah atau menghapus properti.';
const _noBank = 'Belum ada rekening. Penyewa hanya bisa membayar tunai.';
const _deleteMessage =
    'Semua kamar dan penugasan Pengelola Kost di properti ini ikut terhapus. '
    'Tindakan ini tidak dapat dibatalkan.';

Property _melati({
  bool editable = true,
  BankAccount? bank,
  List<ManagerRef>? managers,
}) => makeProperty(
  id: 'p1',
  name: 'Kos Melati',
  address: 'Jl. Melati 1, Bandung',
  roomCount: 12,
  occupiedRoomCount: 5,
  bankAccount: bank,
  managers: managers ?? [managerSari, managerDewi],
  editable: editable,
);

Property _mawar() =>
    makeProperty(id: 'p2', name: 'Kos Mawar', address: 'Jl. Mawar 2');

Future<void> _openDetail(
  WidgetTester tester,
  FakePropertyRepository repo, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) => pumpPropertyApp(
  tester,
  repo,
  role: role,
  path: '/properti/p1',
  settle: settle,
  largeText: largeText,
);

/// Opens the detail of the first property by tapping it in the list.
Future<void> _openFromList(
  WidgetTester tester,
  FakePropertyRepository repo,
) async {
  await pumpPropertyApp(tester, repo);
  await tester.tap(find.text('Kos Melati'));
  await tester.pumpAndSettle();
}

Future<void> _askToDelete(WidgetTester tester) async {
  await tapVisible(tester, find.text('Hapus Properti'));
}

void main() {
  group('content', () {
    testWidgets('shows the title Rincian Properti and loads the property', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openDetail(tester, repo);

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(appBarTitle('Rincian Properti'), findsOneWidget);
      expect(repo.calls, contains('get:p1'));
    });

    testWidgets('shows the name as a header and the address', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Jl. Melati 1, Bandung'), findsOneWidget);
      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Kos Melati')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the room count with occupied and vacant rooms', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(find.text('Jumlah kamar'), findsOneWidget);
      expect(find.textContaining('12'), findsAtLeastNWidgets(1));
      expect(find.text('5 terisi · 7 kosong'), findsOneWidget);
    });

    testWidgets('shows the number of managers and their names', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(find.text('Pengelola Kost'), findsOneWidget);
      expect(find.text('2 pengelola'), findsOneWidget);
      expect(find.textContaining('Sari'), findsOneWidget);
      expect(find.textContaining('Dewi'), findsOneWidget);
    });

    testWidgets('says there is no manager when none is assigned', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati(managers: [])]),
      );

      expect(find.text('Pengelola Kost'), findsOneWidget);
      expect(find.text('Belum ada pengelola'), findsOneWidget);
      expect(find.text('0 pengelola'), findsNothing);
    });

    testWidgets('shows the bank account for rent transfers', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati(bank: bankAccount)]),
      );

      expect(find.text('Rekening transfer sewa'), findsOneWidget);
      expect(find.text('BCA · 1234567890'), findsOneWidget);
      expect(find.text('a.n. Budi Santoso'), findsOneWidget);
      expect(find.text(_noBank), findsNothing);
    });

    testWidgets('says tenants can only pay cash when there is no account', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(find.text('Rekening transfer sewa'), findsOneWidget);
      expect(find.text(_noBank), findsOneWidget);
      expect(find.textContaining('a.n.'), findsNothing);
    });

    testWidgets('an editable property shows no view-only note', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(find.text('Hanya bisa dilihat'), findsNothing);
      expect(find.text(_readOnlyOwner), findsNothing);
      expect(find.text(_readOnlyManager), findsNothing);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Kos Melati'), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.always = const ApiFailure(code: 'PROPERTY_NOT_FOUND');
      await _openDetail(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('PROPERTY_NOT_FOUND')), findsOneWidget);
      expect(find.text('Hapus Properti'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _openDetail(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the property again', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.queue.add(const ApiFailure.network());
      await _openDetail(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Kos Melati'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Kembali returns to the list', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()]);
      await _openFromList(tester, repo);
      expect(backButton(), findsOneWidget);

      await pressBack(tester);

      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(currentPath(tester), '/properti');
    });
  });

  group('owner actions', () {
    testWidgets('an owner sees Ubah and Hapus Properti', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(find.text('Ubah'), findsOneWidget);
      expect(find.text('Hapus Properti'), findsOneWidget);
      expect(find.text(_managerOnly), findsNothing);
    });

    testWidgets('Ubah and Hapus Properti are at least 48 dp', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expectTargetSize(tester, 'Ubah');
      expectTargetSize(tester, 'Hapus Properti');
    });

    testWidgets('Ubah opens the edit form of the property', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      await tapVisible(tester, find.text('Ubah'));

      expect(currentPath(tester), '/properti/p1/ubah');
      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(
        tester
            .widget<PropertyFormScreen>(find.byType(PropertyFormScreen))
            .propertyId,
        'p1',
      );
    });

    testWidgets('a view-only property shows no Ubah but keeps Hapus Properti', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati(editable: false)]),
      );

      expect(find.text('Ubah'), findsNothing);
      expect(find.text('Hapus Properti'), findsOneWidget);
    });

    testWidgets('a view-only property tells the owner why', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati(editable: false)]),
      );

      expect(find.text('Hanya bisa dilihat'), findsOneWidget);
      expect(find.text(_readOnlyOwner), findsOneWidget);
      expect(find.text(_readOnlyManager), findsNothing);
    });
  });

  group('manager view', () {
    testWidgets('a manager sees neither Ubah nor Hapus Properti', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
        role: UserRole.manager,
      );

      expect(find.text('Ubah'), findsNothing);
      expect(find.text('Hapus Properti'), findsNothing);
      expect(find.text(_managerOnly), findsOneWidget);
    });

    testWidgets('a manager still sees the property data', (tester) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati(bank: bankAccount)]),
        role: UserRole.manager,
      );

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('BCA · 1234567890'), findsOneWidget);
      expect(find.text('5 terisi · 7 kosong'), findsOneWidget);
    });

    testWidgets(
      'a view-only property tells the manager to wait for an upgrade',
      (tester) async {
        await _openDetail(
          tester,
          FakePropertyRepository(properties: [_melati(editable: false)]),
          role: UserRole.manager,
        );

        expect(find.text('Hanya bisa dilihat'), findsOneWidget);
        expect(find.text(_readOnlyManager), findsOneWidget);
        expect(find.text(_readOnlyOwner), findsNothing);
      },
    );
  });

  group('delete', () {
    testWidgets('asks for confirmation with the property name', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openDetail(tester, repo);

      await _askToDelete(tester);

      expect(find.text('Hapus Kos Melati?'), findsOneWidget);
      expect(find.text(_deleteMessage), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('Batal closes the dialog and changes nothing', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()]);
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Kos Melati?'), findsNothing);
      expect(repo.deleted, isEmpty);
      expect(repo.properties, hasLength(2));
      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(snackBar('Properti dihapus'), findsNothing);
    });

    testWidgets('Hapus deletes the property once and returns to the list', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()]);
      await _openFromList(tester, repo);
      final loadsBefore = repo.listCalls;
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(repo.deleted, ['p1']);
      expect(currentPath(tester), '/properti');
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(PropertyDetailScreen), findsNothing);
      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('confirms the deletion with a snack bar', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()]);
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(snackBar('Properti dihapus'), findsOneWidget);
    });

    testWidgets('reloads the list when the detail was opened directly', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()]);
      await _openDetail(tester, repo);
      final loadsBefore = repo.listCalls;
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('deleting the last property shows the empty list', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Properti Pertama'), findsOneWidget);
    });

    testWidgets('sends one request when Hapus Properti is tapped again', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()])
        ..deleteScript.gate = gate;
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pump();
      await tester.tap(find.text('Hapus Properti'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Hapus Kos Melati?'), findsNothing);
      expect(repo.deleted, ['p1']);

      gate.complete();
      await tester.pumpAndSettle();
      expect(repo.deleted, ['p1']);
    });

    testWidgets('a failure explains why in a dialog titled with the problem', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()])
        ..deleteScript.always = const ApiFailure.network();
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Properti belum bisa dihapus'), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);
      expect(snackBar('Properti dihapus'), findsNothing);
    });

    testWidgets('a failure with an unknown code shows the generic message', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..deleteScript.always = const ApiFailure(code: 'PROPERTY_HAS_LEASE');
      await _openDetail(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Properti belum bisa dihapus'), findsOneWidget);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Mengerti closes the dialog and keeps the detail', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()])
        ..deleteScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _openFromList(tester, repo);
      await _askToDelete(tester);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Properti belum bisa dihapus'), findsNothing);
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1');
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(repo.properties, hasLength(2));
    });

    testWidgets('the list still shows the property after a failed delete', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()])
        ..deleteScript.always = const ApiFailure.network();
      await _openFromList(tester, repo);
      await _askToDelete(tester);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('the owner can delete again after a failure', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati(), _mawar()])
        ..deleteScript.queue.add(const ApiFailure.network());
      await _openFromList(tester, repo);
      await _askToDelete(tester);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      await _askToDelete(tester);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(repo.deleted, ['p1', 'p1']);
      expect(find.text('Kos Melati'), findsNothing);
      expect(snackBar('Properti dihapus'), findsOneWidget);
    });

    testWidgets('a view-only property can be deleted', (tester) async {
      final repo = FakePropertyRepository(
        properties: [_melati(editable: false), _mawar()],
      );
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(repo.deleted, ['p1']);
    });
  });

  group('accessibility', () {
    final states =
        <String, ({FakePropertyRepository Function() repo, UserRole role})>{
          'an owner with a bank account': (
            repo: () => FakePropertyRepository(
              properties: [_melati(bank: bankAccount)],
            ),
            role: UserRole.owner,
          ),
          'an owner without a bank account': (
            repo: () => FakePropertyRepository(properties: [_melati()]),
            role: UserRole.owner,
          ),
          'an owner with no manager': (
            repo: () =>
                FakePropertyRepository(properties: [_melati(managers: [])]),
            role: UserRole.owner,
          ),
          'a view-only property for an owner': (
            repo: () =>
                FakePropertyRepository(properties: [_melati(editable: false)]),
            role: UserRole.owner,
          ),
          'a manager': (
            repo: () => FakePropertyRepository(properties: [_melati()]),
            role: UserRole.manager,
          ),
          'a view-only property for a manager': (
            repo: () =>
                FakePropertyRepository(properties: [_melati(editable: false)]),
            role: UserRole.manager,
          ),
          'a failure': (
            repo: () =>
                FakePropertyRepository(properties: [_melati()])
                  ..getScript.always = const ApiFailure.network(),
            role: UserRole.owner,
          ),
        };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await _openDetail(tester, entry.value.repo(), role: entry.value.role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for ${entry.key}', (tester) async {
        await _openDetail(
          tester,
          entry.value.repo(),
          role: entry.value.role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with the delete confirmation open', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );
      await _askToDelete(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the delete confirmation open', (
      tester,
    ) async {
      await _openDetail(
        tester,
        FakePropertyRepository(properties: [_melati()]),
        largeText: true,
      );
      await _askToDelete(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Hapus Kos Melati?'), findsOneWidget);
    });

    testWidgets('meets the guidelines with the delete failure open', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..deleteScript.always = const ApiFailure.network();
      await _openDetail(tester, repo);
      await _askToDelete(tester);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the delete failure open', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..deleteScript.always = const ApiFailure.network();
      await _openDetail(tester, repo, largeText: true);
      await _askToDelete(tester);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Properti belum bisa dihapus'), findsOneWidget);
    });
  });
}
