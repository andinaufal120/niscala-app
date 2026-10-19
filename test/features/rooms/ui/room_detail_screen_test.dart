import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'room_ui_helpers.dart';

const _readOnly =
    'Kamar ini tidak termasuk paket pemilik kost saat ini. Data kamar, masa '
    'sewa, dan penyewanya tidak bisa diubah. Tagihan tetap terbit, dan '
    'pembayaran serta keluhan penyewa tetap bisa diproses. Menghapus kamar '
    'tetap bisa.';
const _deleteMessage =
    'Kamar akan dihapus. Tindakan ini tidak dapat dibatalkan.';
const _activeLease =
    'Kamar ini masih memiliki masa sewa aktif. Akhiri masa sewa terlebih '
    'dahulu.';

Room _occupied({bool editable = true}) => occupiedRoom(editable: editable);

Room _vacant({bool editable = true}) =>
    vacantRoom(id: 'r1', number: '08', baseRate: 650000, editable: editable);

FakeRoomRepository _repo([Room? room]) => FakeRoomRepository(
  rooms: [
    room ?? _occupied(),
    vacantRoom(id: 'r2'),
  ],
);

Future<void> _openDetail(
  WidgetTester tester,
  FakeRoomRepository repo, {
  UserRole role = UserRole.owner,
  FakePropertyRepository? properties,
  bool settle = true,
  bool largeText = false,
}) => pumpRoomApp(
  tester,
  repo,
  role: role,
  properties: properties,
  path: '/properti/p1/kamar/r1',
  settle: settle,
  largeText: largeText,
);

/// Opens the detail of room 08 by tapping it in the room list.
Future<void> _openFromList(WidgetTester tester, FakeRoomRepository repo) async {
  await pumpRoomApp(tester, repo);
  await tester.tap(find.text('08'));
  await tester.pumpAndSettle();
}

Future<void> _askToDelete(WidgetTester tester) =>
    tapVisible(tester, find.text('Hapus Kamar'));

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(find.text('Hapus'));
  await tester.pumpAndSettle();
}

void main() {
  group('header', () {
    testWidgets('shows the room number as title and the property name', (
      tester,
    ) async {
      final repo = _repo();
      await _openDetail(tester, repo);

      expect(find.byType(RoomDetailScreen), findsOneWidget);
      expect(appBarTitle('Kamar 08'), findsOneWidget);
      expect(inAppBar('Kos Melati'), findsOneWidget);
      expect(repo.calls, contains('get:r1'));
    });

    testWidgets('still shows the room when the property cannot be loaded', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await _openDetail(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsNothing);
      expect(appBarTitle('Kamar 08'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Hapus Kamar'), findsOneWidget);
    });
  });

  group('occupied room', () {
    testWidgets('shows the rent of the lease and the base rate as a note', (
      tester,
    ) async {
      await _openDetail(tester, _repo());

      expect(find.text('Tarif sewa · masa sewa ini'), findsOneWidget);
      expect(find.textContaining('Rp750.000'), findsOneWidget);
      expect(find.text('Tarif dasar kamar: Rp800.000 / bulan'), findsOneWidget);
      expect(find.textContaining('/ bulan'), findsNWidgets(2));
      expect(find.text('Tarif dasar kamar'), findsNothing);
      expect(find.text('Nilai awal saat mendaftarkan penyewa'), findsNothing);
    });

    testWidgets('shows the Terisi badge', (tester) async {
      await _openDetail(tester, _repo());

      expect(statusBadge('Terisi'), findsOneWidget);
      expect(statusBadge('Kosong'), findsNothing);
    });

    testWidgets('shows the tenant, phone and lease dates', (tester) async {
      await _openDetail(tester, _repo());

      expect(find.text('Penyewa & masa sewa'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('1 Jan 2026'), findsOneWidget);
      expect(find.text('Berakhir'), findsOneWidget);
      expect(find.text('31 Des 2026'), findsOneWidget);
      expect(find.text('Kamar kosong'), findsNothing);
      expect(find.text('Belum ada penyewa di kamar ini.'), findsNothing);
    });

    testWidgets('shows a dash for a lease without end date', (tester) async {
      final room = makeRoom(
        id: 'r1',
        number: '08',
        lease: makeRoomLease(startDate: DateTime.utc(2026, 1, 1)),
      );
      await _openDetail(tester, _repo(room));

      expect(find.text('1 Jan 2026'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('shows a dash for a lease without start date', (tester) async {
      final room = makeRoom(
        id: 'r1',
        number: '08',
        lease: makeRoomLease(endDate: DateTime.utc(2026, 12, 31)),
      );
      await _openDetail(tester, _repo(room));

      expect(find.text('31 Des 2026'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('shows two dashes for a lease without dates', (tester) async {
      final room = makeRoom(id: 'r1', number: '08', lease: makeRoomLease());
      await _openDetail(tester, _repo(room));

      expect(find.text('-'), findsNWidgets(2));
    });

    testWidgets('the section titles are headers', (tester) async {
      await _openDetail(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        for (final title in ['Ukuran', 'Fasilitas', 'Penyewa & masa sewa']) {
          expect(
            tester.getSemantics(find.text(title)),
            isSemantics(isHeader: true),
          );
        }
      } finally {
        handle.dispose();
      }
    });
  });

  group('vacant room', () {
    testWidgets('shows the base rate with its purpose', (tester) async {
      await _openDetail(tester, _repo(_vacant()));

      expect(find.text('Tarif dasar kamar'), findsOneWidget);
      expect(find.textContaining('Rp650.000'), findsOneWidget);
      expect(find.textContaining('/ bulan'), findsOneWidget);
      expect(find.text('Nilai awal saat mendaftarkan penyewa'), findsOneWidget);
      expect(find.text('Tarif sewa · masa sewa ini'), findsNothing);
    });

    testWidgets('shows the Kosong badge', (tester) async {
      await _openDetail(tester, _repo(_vacant()));

      expect(statusBadge('Kosong'), findsOneWidget);
      expect(statusBadge('Terisi'), findsNothing);
    });

    testWidgets('says there is no tenant', (tester) async {
      await _openDetail(tester, _repo(_vacant()));

      expect(find.text('Kamar kosong'), findsOneWidget);
      expect(find.text('Belum ada penyewa di kamar ini.'), findsOneWidget);
      expect(find.text('Penyewa & masa sewa'), findsNothing);
      expect(find.text('Mulai'), findsNothing);
      expect(find.text('Berakhir'), findsNothing);
    });
  });

  group('dimensions and facilities', () {
    testWidgets('shows the dimensions with the area', (tester) async {
      await _openDetail(tester, _repo());

      expect(find.text('Ukuran'), findsOneWidget);
      expect(find.text('3,5 × 4 m'), findsOneWidget);
      expect(find.text('14 m²'), findsOneWidget);
      expect(find.text('Belum diisi'), findsNothing);
    });

    testWidgets(
      'writes dimensions with a decimal comma and no trailing zeros',
      (tester) async {
        final room = _occupied().withSize(10.5, 2);
        await _openDetail(tester, _repo(room));

        expect(find.text('10,5 × 2 m'), findsOneWidget);
        expect(find.text('21 m²'), findsOneWidget);
      },
    );

    testWidgets('keeps one decimal of the area when it has one', (
      tester,
    ) async {
      final room = _occupied().withSize(3.5, 4.2);
      await _openDetail(tester, _repo(room));

      expect(find.text('3,5 × 4,2 m'), findsOneWidget);
      expect(find.text('14,7 m²'), findsOneWidget);
    });

    testWidgets('rounds the area to two decimals', (tester) async {
      final room = _occupied().withSize(2.55, 3.33);
      await _openDetail(tester, _repo(room));

      expect(find.text('2,55 × 3,33 m'), findsOneWidget);
      expect(find.text('8,49 m²'), findsOneWidget);
    });

    testWidgets('says the size is not filled in when there is none', (
      tester,
    ) async {
      await _openDetail(tester, _repo(_vacant()));

      expect(find.text('Ukuran'), findsOneWidget);
      expect(find.text('Belum diisi'), findsOneWidget);
      expect(find.textContaining('×'), findsNothing);
      expect(find.textContaining('m²'), findsNothing);
    });

    testWidgets('shows one chip per facility', (tester) async {
      await _openDetail(tester, _repo());

      expect(find.text('Fasilitas'), findsOneWidget);
      expect(find.text('ac'), findsOneWidget);
      expect(find.text('kasur'), findsOneWidget);
      expect(find.text('Belum ada fasilitas'), findsNothing);
    });

    testWidgets('says there are no facilities when there are none', (
      tester,
    ) async {
      await _openDetail(tester, _repo(_vacant()));

      expect(find.text('Fasilitas'), findsOneWidget);
      expect(find.text('Belum ada fasilitas'), findsOneWidget);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Hapus Kamar'), findsNothing);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure', (tester) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'ROOM_NOT_FOUND');
      await _openDetail(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('ROOM_NOT_FOUND')), findsOneWidget);
      expect(find.text('Hapus Kamar'), findsNothing);
      expect(inAppBar('Ubah'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _openDetail(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the room again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _openDetail(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(appBarTitle('Kamar 08'), findsOneWidget);
    });
  });

  group('edit action', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role sees Ubah in the app bar, at least 48 dp', (
        tester,
      ) async {
        await _openDetail(tester, _repo(), role: role);

        expect(inAppBar('Ubah'), findsOneWidget);
        expectTargetSize(tester, 'Ubah');
      });
    }

    testWidgets('Ubah opens the edit form of the room', (tester) async {
      await _openDetail(tester, _repo());

      await tester.tap(inAppBar('Ubah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/kamar/r1/ubah');
      final form = tester.widget<RoomFormScreen>(find.byType(RoomFormScreen));
      expect(form.propertyId, 'p1');
      expect(form.roomId, 'r1');
    });

    testWidgets('a view-only room shows no Ubah but keeps Hapus Kamar', (
      tester,
    ) async {
      await _openDetail(tester, _repo(_occupied(editable: false)));

      expect(find.text('Ubah'), findsNothing);
      expect(find.text('Hapus Kamar'), findsOneWidget);
    });

    testWidgets('an editable room shows no view-only note', (tester) async {
      await _openDetail(tester, _repo());

      expect(find.text('Hanya bisa dilihat'), findsNothing);
      expect(find.text(_readOnly), findsNothing);
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a view-only room explains why to a $role', (tester) async {
        await _openDetail(
          tester,
          _repo(_occupied(editable: false)),
          role: role,
        );

        expect(find.text('Hanya bisa dilihat'), findsOneWidget);
        expect(find.text(_readOnly), findsOneWidget);
      });
    }

    testWidgets('a view-only vacant room shows the note too', (tester) async {
      await _openDetail(tester, _repo(_vacant(editable: false)));

      expect(find.text('Hanya bisa dilihat'), findsOneWidget);
      expect(find.text('Ubah'), findsNothing);
    });
  });

  group('delete', () {
    testWidgets('asks for confirmation with the room number', (tester) async {
      final repo = _repo();
      await _openDetail(tester, repo);

      await _askToDelete(tester);

      expect(find.text('Hapus Kamar 08?'), findsOneWidget);
      expect(find.text(_deleteMessage), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('Hapus Kamar is at least 48 dp', (tester) async {
      await _openDetail(tester, _repo());

      expectTargetSize(tester, 'Hapus Kamar');
    });

    testWidgets('a manager can delete a room too', (tester) async {
      final repo = _repo();
      await _openDetail(tester, repo, role: UserRole.manager);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['r1']);
    });

    testWidgets('Batal closes the dialog and changes nothing', (tester) async {
      final repo = _repo();
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Kamar 08?'), findsNothing);
      expect(repo.deleted, isEmpty);
      expect(repo.rooms, hasLength(2));
      expect(currentPath(tester), '/properti/p1/kamar/r1');
      expect(find.byType(RoomDetailScreen), findsOneWidget);
      expect(snackBar('Kamar dihapus'), findsNothing);
    });

    testWidgets('Hapus deletes the room once and returns to the list', (
      tester,
    ) async {
      final repo = _repo();
      await _openFromList(tester, repo);
      final loadsBefore = repo.listCalls;
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['r1']);
      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.byType(RoomListScreen), findsOneWidget);
      expect(find.byType(RoomDetailScreen), findsNothing);
      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('08'), findsNothing);
      expect(find.text('09'), findsOneWidget);
    });

    testWidgets('confirms the deletion with a snack bar', (tester) async {
      await _openFromList(tester, _repo());
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(snackBar('Kamar dihapus'), findsOneWidget);
    });

    testWidgets('reloads the list when the detail was opened directly', (
      tester,
    ) async {
      final repo = _repo();
      await _openDetail(tester, repo);
      final loadsBefore = repo.listCalls;
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(currentPath(tester), '/properti/p1/kamar');
      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('08'), findsNothing);
      expect(find.text('09'), findsOneWidget);
    });

    testWidgets('deleting the last room shows the empty list', (tester) async {
      final repo = FakeRoomRepository(rooms: [_occupied()]);
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(find.text('Tambah Kamar'), findsOneWidget);
    });

    testWidgets('sends one request when Hapus Kamar is tapped again', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..deleteScript.gate = gate;
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await tester.tap(find.text('Hapus'));
      await tester.pump();
      await tester.tap(find.text('Hapus Kamar'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Hapus Kamar 08?'), findsNothing);
      expect(repo.deleted, ['r1']);

      gate.complete();
      await tester.pumpAndSettle();
      expect(repo.deleted, ['r1']);
    });

    testWidgets('a failure explains why in a dialog titled with the problem', (
      tester,
    ) async {
      final repo = _repo()
        ..deleteScript.always = const ApiFailure(code: 'ROOM_HAS_ACTIVE_LEASE');
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(find.text('Kamar belum bisa dihapus'), findsOneWidget);
      expect(find.text(_activeLease), findsOneWidget);
      expect(find.text(errorMessage('ROOM_HAS_ACTIVE_LEASE')), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);
      expect(snackBar('Kamar dihapus'), findsNothing);
      expect(repo.rooms, hasLength(2));
    });

    testWidgets('a network failure shows its own message', (tester) async {
      final repo = _repo()..deleteScript.always = const ApiFailure.network();
      await _openDetail(tester, repo);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(find.text('Kamar belum bisa dihapus'), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('a failure with an unknown code shows the generic message', (
      tester,
    ) async {
      final repo = _repo()
        ..deleteScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _openDetail(tester, repo);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(find.text('Kamar belum bisa dihapus'), findsOneWidget);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Mengerti closes the dialog and keeps the detail', (
      tester,
    ) async {
      final repo = _repo()
        ..deleteScript.always = const ApiFailure(code: 'ROOM_HAS_ACTIVE_LEASE');
      await _openFromList(tester, repo);
      await _askToDelete(tester);
      await _confirmDelete(tester);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Kamar belum bisa dihapus'), findsNothing);
      expect(find.byType(RoomDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/kamar/r1');
      expect(appBarTitle('Kamar 08'), findsOneWidget);
      expect(repo.rooms, hasLength(2));
    });

    testWidgets('the list still shows the room after a failed delete', (
      tester,
    ) async {
      final repo = _repo()..deleteScript.always = const ApiFailure.network();
      await _openFromList(tester, repo);
      await _askToDelete(tester);
      await _confirmDelete(tester);
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(find.text('08'), findsOneWidget);
      expect(find.text('09'), findsOneWidget);
    });

    testWidgets('the room can be deleted again after a failure', (
      tester,
    ) async {
      final repo = _repo()..deleteScript.queue.add(const ApiFailure.network());
      await _openFromList(tester, repo);
      await _askToDelete(tester);
      await _confirmDelete(tester);
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      await _askToDelete(tester);
      await _confirmDelete(tester);

      expect(repo.deleted, ['r1', 'r1']);
      expect(find.text('08'), findsNothing);
      expect(snackBar('Kamar dihapus'), findsOneWidget);
    });

    testWidgets('a view-only room can be deleted', (tester) async {
      final repo = _repo(_occupied(editable: false));
      await _openFromList(tester, repo);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['r1']);
    });
  });

  group('tenant links', () {
    Room occupiedBy(String tenantId, {bool editable = true}) => makeRoom(
      id: 'r1',
      number: '08',
      lease: makeRoomLease(tenantId: tenantId, tenantName: 'Rina Putri'),
      editable: editable,
    );

    FakeTenantRepository tenantsOf(String tenantId) => FakeTenantRepository(
      tenants: [makeTenant(id: tenantId, name: 'Rina Putri')],
    );

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('an occupied room links a $role to the tenant detail', (
        tester,
      ) async {
        await pumpRoomApp(
          tester,
          _repo(occupiedBy('t9')),
          tenants: tenantsOf('t9'),
          role: role,
          path: '/properti/p1/kamar/r1',
        );

        expect(find.text('Lihat rincian penyewa'), findsOneWidget);
        expectTargetSize(tester, 'Lihat rincian penyewa');

        await tapVisible(tester, find.text('Lihat rincian penyewa'));

        expect(currentPath(tester), '/properti/p1/penyewa/t9');
        final detail = tester.widget<TenantDetailScreen>(
          find.byType(TenantDetailScreen),
        );
        expect(detail.propertyId, 'p1');
        expect(detail.tenantId, 't9');
        expect(find.text('Rina Putri'), findsOneWidget);
      });

      testWidgets('a vacant room offers a $role to add a tenant', (
        tester,
      ) async {
        await pumpRoomApp(
          tester,
          _repo(_vacant()),
          role: role,
          path: '/properti/p1/kamar/r1',
        );

        expect(find.text('Tambah Penyewa'), findsOneWidget);
        expectTargetSize(tester, 'Tambah Penyewa');

        await tapVisible(tester, find.text('Tambah Penyewa'));

        expect(currentPath(tester), '/properti/p1/penyewa/tambah');
        final form = tester.widget<TenantFormScreen>(
          find.byType(TenantFormScreen),
        );
        expect(form.propertyId, 'p1');
        expect(form.preselectedRoomId, 'r1');
      });
    }

    testWidgets('the add form opened from a vacant room has it chosen', (
      tester,
    ) async {
      await pumpRoomApp(
        tester,
        _repo(_vacant()),
        path: '/properti/p1/kamar/r1',
      );

      await tapVisible(tester, find.text('Tambah Penyewa'));

      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.value, 'r1');
    });

    testWidgets('an occupied room offers no Tambah Penyewa', (tester) async {
      await _openDetail(tester, _repo());

      expect(find.text('Tambah Penyewa'), findsNothing);
    });

    testWidgets('a vacant room offers no tenant detail link', (tester) async {
      await _openDetail(tester, _repo(_vacant()));

      expect(find.text('Lihat rincian penyewa'), findsNothing);
    });

    testWidgets('a view-only vacant room offers no Tambah Penyewa', (
      tester,
    ) async {
      await _openDetail(tester, _repo(_vacant(editable: false)));

      expect(find.text('Tambah Penyewa'), findsNothing);
      expect(find.text('Lihat rincian penyewa'), findsNothing);
    });

    testWidgets('a view-only occupied room still links to its tenant', (
      tester,
    ) async {
      await _openDetail(tester, _repo(_occupied(editable: false)));

      expect(find.text('Lihat rincian penyewa'), findsOneWidget);
      expect(find.text('Tambah Penyewa'), findsNothing);
    });

    testWidgets('no link shows after the room failed to load', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _openDetail(tester, repo);

      expect(find.text('Lihat rincian penyewa'), findsNothing);
      expect(find.text('Tambah Penyewa'), findsNothing);
    });
  });

  group('structure', () {
    testWidgets('uses a white detail app bar titled with the room number', (
      tester,
    ) async {
      await _openDetail(tester, _repo());

      expectDetailAppBar(tester);
      expect(appBarTitle('Kamar 08'), findsOneWidget);
    });

    testWidgets('an occupied room puts its sections in section cards', (
      tester,
    ) async {
      await _openDetail(tester, _repo());

      for (final title in ['Ukuran', 'Fasilitas', 'Penyewa & masa sewa']) {
        expectSectionCard(tester, title);
      }
      expect(
        find.descendant(
          of: sectionCardOf('Ukuran'),
          matching: find.text('3,5 × 4 m'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sectionCardOf('Fasilitas'),
          matching: find.text('kasur'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sectionCardOf('Penyewa & masa sewa'),
          matching: find.text('Budi Santoso'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a vacant room puts its size and facilities in section cards', (
      tester,
    ) async {
      await _openDetail(tester, _repo(_vacant()));

      expectSectionCard(tester, 'Ukuran');
      expectSectionCard(tester, 'Fasilitas');
      expect(
        find.descendant(
          of: sectionCardOf('Ukuran'),
          matching: find.text('Belum diisi'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sectionCardOf('Fasilitas'),
          matching: find.text('Belum ada fasilitas'),
        ),
        findsOneWidget,
      );
      expect(sectionCardOf('Penyewa & masa sewa'), findsNothing);
    });

    testWidgets('every section card takes the card look from the theme', (
      tester,
    ) async {
      await _openDetail(tester, _repo());

      expectCardLook(
        tester,
        find.descendant(
          of: find.byType(SectionCard),
          matching: find.byType(Card),
        ),
      );
    });
  });

  group('accessibility', () {
    final states =
        <String, ({FakeRoomRepository Function() repo, UserRole role})>{
          'an occupied room for an owner': (repo: _repo, role: UserRole.owner),
          'an occupied room for a manager': (
            repo: _repo,
            role: UserRole.manager,
          ),
          'a vacant room': (repo: () => _repo(_vacant()), role: UserRole.owner),
          'a room without size and facilities': (
            repo: () => _repo(_vacant()),
            role: UserRole.manager,
          ),
          'a lease without dates': (
            repo: () =>
                _repo(makeRoom(id: 'r1', number: '08', lease: makeRoomLease())),
            role: UserRole.owner,
          ),
          'a view-only occupied room': (
            repo: () => _repo(_occupied(editable: false)),
            role: UserRole.owner,
          ),
          'a view-only vacant room for a manager': (
            repo: () => _repo(_vacant(editable: false)),
            role: UserRole.manager,
          ),
          'a failure': (
            repo: () => _repo()..getScript.always = const ApiFailure.network(),
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
      final repo = _repo()..getScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with the delete confirmation open', (
      tester,
    ) async {
      await _openDetail(tester, _repo());
      await _askToDelete(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the delete confirmation open', (
      tester,
    ) async {
      await _openDetail(tester, _repo(), largeText: true);
      await _askToDelete(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Hapus Kamar 08?'), findsOneWidget);
    });

    testWidgets('meets the guidelines with the delete failure open', (
      tester,
    ) async {
      final repo = _repo()
        ..deleteScript.always = const ApiFailure(code: 'ROOM_HAS_ACTIVE_LEASE');
      await _openDetail(tester, repo);
      await _askToDelete(tester);
      await _confirmDelete(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the delete failure open', (
      tester,
    ) async {
      final repo = _repo()
        ..deleteScript.always = const ApiFailure(code: 'ROOM_HAS_ACTIVE_LEASE');
      await _openDetail(tester, repo, largeText: true);
      await _askToDelete(tester);
      await _confirmDelete(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Kamar belum bisa dihapus'), findsOneWidget);
    });
  });
}

extension on Room {
  Room withSize(num length, num width) => Room(
    id: id,
    propertyId: propertyId,
    number: number,
    baseRate: baseRate,
    occupancy: occupancy,
    lease: lease,
    lengthM: length,
    widthM: width,
    facilities: facilities,
    editable: editable,
  );
}
