import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'room_ui_helpers.dart';

const _emptyWithName =
    'Belum ada kamar. Tambahkan kamar agar bisa mendaftarkan penyewa di '
    'Kos Melati.';
const _emptyWithoutName =
    'Belum ada kamar. Tambahkan kamar agar bisa mendaftarkan penyewa di '
    'properti ini.';
const _emptyFilter = 'Tidak ada kamar dengan status ini.';

/// Room 01 and 03 are occupied, 02 and 04 are vacant.
List<Room> _rooms() => [
  occupiedRoom(id: 'r1', number: '01'),
  vacantRoom(
    id: 'r2',
    number: '02',
    baseRate: 650000,
    lengthM: 3.5,
    widthM: 4,
    facilities: ['ac', 'kasur'],
  ),
  makeRoom(
    id: 'r3',
    number: '03',
    baseRate: 900000,
    lease: makeRoomLease(tenantName: 'Sari', rent: 850000),
  ),
  vacantRoom(id: 'r4', number: '04', baseRate: 500000, editable: false),
];

FakeRoomRepository _repo([List<Room>? rooms]) =>
    FakeRoomRepository(rooms: rooms ?? _rooms());

void main() {
  group('header', () {
    testWidgets('shows the title Kamar and the property name', (tester) async {
      final properties = propertiesWithMelati();
      await pumpRoomApp(tester, _repo(), properties: properties);

      expect(find.byType(RoomListScreen), findsOneWidget);
      expect(appBarTitle('Kamar'), findsOneWidget);
      expect(inAppBar('Kos Melati'), findsOneWidget);
      expect(properties.calls, contains('get:p1'));
    });

    testWidgets('still lists the rooms when the property cannot be loaded', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await pumpRoomApp(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsNothing);
      expect(appBarTitle('Kamar'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Rp800.000 / bulan'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
    });

    testWidgets('lists only the rooms of the property in the path', (
      tester,
    ) async {
      final rooms = _rooms()
        ..add(vacantRoom(id: 'x1', number: '99').copyWithProperty('p2'));
      await pumpRoomApp(tester, _repo(rooms));

      expect(find.text('99'), findsNothing);
      expect(find.text('01'), findsOneWidget);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpRoomApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('01'), findsNothing);
      expect(find.text(_emptyWithName), findsNothing);
    });

    testWidgets('shows the rooms once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await pumpRoomApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('01'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpRoomApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('01'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpRoomApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the rooms again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await pumpRoomApp(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpRoomApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('empty', () {
    testWidgets('invites the user to add a room in the named property', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo([]));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_emptyWithName), findsOneWidget);
      expect(find.text('Tambah Kamar'), findsOneWidget);
    });

    testWidgets('Tambah Kamar opens the add form', (tester) async {
      await pumpRoomApp(tester, _repo([]));

      await tester.tap(find.text('Tambah Kamar'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/kamar/tambah');
      expect(find.byType(RoomFormScreen), findsOneWidget);
    });

    testWidgets('says this property when its name is unknown', (tester) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await pumpRoomApp(tester, _repo([]), properties: properties);

      expect(find.text(_emptyWithoutName), findsOneWidget);
      expect(find.text(_emptyWithName), findsNothing);
      expect(find.text('Tambah Kamar'), findsOneWidget);
    });

    testWidgets('offers no action for a view-only property', (tester) async {
      await pumpRoomApp(
        tester,
        _repo([]),
        properties: propertiesWithMelati(editable: false),
      );

      expect(find.text(_emptyWithName), findsOneWidget);
      expect(find.text('Tambah Kamar'), findsNothing);
      expect(find.text('Tambah'), findsNothing);
    });

    testWidgets('a manager is invited to add a room too', (tester) async {
      await pumpRoomApp(tester, _repo([]), role: UserRole.manager);

      expect(find.text(_emptyWithName), findsOneWidget);
      expect(find.text('Tambah Kamar'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('shows one row per room in the order returned', (tester) async {
      await pumpRoomApp(tester, _repo());

      for (final number in ['01', '02', '03', '04']) {
        expect(find.text(number), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('01')).dy,
        lessThan(tester.getTopLeft(find.text('02')).dy),
      );
      expect(
        tester.getTopLeft(find.text('03')).dy,
        lessThan(tester.getTopLeft(find.text('04')).dy),
      );
    });

    testWidgets('shows the base rate per month of each room', (tester) async {
      await pumpRoomApp(tester, _repo());

      expect(find.text('Rp800.000 / bulan'), findsOneWidget);
      expect(find.text('Rp650.000 / bulan'), findsOneWidget);
      expect(find.text('Rp900.000 / bulan'), findsOneWidget);
      expect(find.text('Rp500.000 / bulan'), findsOneWidget);
    });

    testWidgets('does not show the rent of the lease', (tester) async {
      await pumpRoomApp(tester, _repo());

      expect(find.textContaining('Rp750.000'), findsNothing);
      expect(find.textContaining('Rp850.000'), findsNothing);
    });

    testWidgets('shows a text badge for occupied and vacant rooms', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      expect(statusBadge('Terisi'), findsNWidgets(2));
      expect(statusBadge('Kosong'), findsNWidgets(2));
    });

    testWidgets('an occupied room shows the tenant and the end of the lease', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      expect(find.text('Budi Santoso · s.d. 31 Des 2026'), findsOneWidget);
    });

    testWidgets('an occupied room without end date shows only the tenant', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      expect(find.text('Sari'), findsOneWidget);
      expect(find.textContaining('s.d.'), findsOneWidget);
    });

    testWidgets('a vacant room shows its dimensions and facilities', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      expect(find.text('3,5 × 4 m · ac, kasur'), findsOneWidget);
    });

    testWidgets('a vacant room with only dimensions shows no separator', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo([vacantRoom(lengthM: 10.5, widthM: 4)]));

      expect(find.text('10,5 × 4 m'), findsOneWidget);
    });

    testWidgets('a vacant room with only facilities shows just the tags', (
      tester,
    ) async {
      await pumpRoomApp(
        tester,
        _repo([
          vacantRoom(facilities: ['wifi', 'lemari']),
        ]),
      );

      expect(find.text('wifi, lemari'), findsOneWidget);
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('a vacant room with nothing to show has no sub line', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo([vacantRoom()]));

      expect(find.textContaining('×'), findsNothing);
      expect(find.textContaining('·'), findsNothing);
      final label = semanticsLabelOf(tester, '09');
      expect(label, contains('Rp650.000 / bulan'));
      expect(label, contains('Kosong'));
    });

    testWidgets('an occupied room shows no dimensions or facilities', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      expect(find.textContaining('kasur'), findsOneWidget);
      expect(find.textContaining('×'), findsOneWidget);
    });

    testWidgets('marks a view-only room with Hanya lihat', (tester) async {
      await pumpRoomApp(tester, _repo());

      expect(find.text('Hanya lihat'), findsOneWidget);
      expect(statusBadge('Hanya lihat'), findsOneWidget);
    });

    testWidgets('shows no Hanya lihat badge when every room is editable', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo([occupiedRoom(), vacantRoom()]));

      expect(find.text('Hanya lihat'), findsNothing);
    });

    testWidgets('reads each room as a single merged item', (tester) async {
      await pumpRoomApp(tester, _repo());

      final label = semanticsLabelOf(tester, '01');
      expect(label, contains('01'));
      expect(label, contains('Rp800.000 / bulan'));
      expect(label, contains('Budi Santoso · s.d. 31 Des 2026'));
      expect(label, contains('Terisi'));
      expect(label, isNot(contains('Rp650.000')));
      expect(label, isNot(contains('Kosong')));
    });

    testWidgets('includes Hanya lihat in the merged reading', (tester) async {
      await pumpRoomApp(tester, _repo());

      final label = semanticsLabelOf(tester, '04');
      expect(label, contains('Hanya lihat'));
      expect(label, contains('Kosong'));
    });

    testWidgets('tapping a room opens its detail', (tester) async {
      await pumpRoomApp(tester, _repo());

      await tester.tap(find.text('02'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/kamar/r2');
      final detail = tester.widget<RoomDetailScreen>(
        find.byType(RoomDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.roomId, 'r2');
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await pumpRoomApp(tester, _repo());
      await tester.tap(find.text('02'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.byType(RoomListScreen), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });
  });

  group('filter', () {
    testWidgets('offers Semua, Terisi and Kosong in the page body', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      for (final label in ['Semua', 'Terisi', 'Kosong']) {
        expect(filterChip(label), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: filterChip(label)),
          findsNothing,
        );
      }
    });

    testWidgets('the chip labels carry no counts', (tester) async {
      await pumpRoomApp(tester, _repo());

      expect(find.textContaining('Semua ('), findsNothing);
      expect(find.textContaining('Terisi ('), findsNothing);
      expect(find.textContaining('Kosong ('), findsNothing);
    });

    testWidgets('Semua is selected by default and shows every room', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      expectChipSelected(tester, 'Semua', selected: true);
      expectChipSelected(tester, 'Terisi', selected: false);
      expectChipSelected(tester, 'Kosong', selected: false);
      for (final number in ['01', '02', '03', '04']) {
        expect(find.text(number), findsOneWidget);
      }
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await pumpRoomApp(tester, _repo());

      for (final label in ['Semua', 'Terisi', 'Kosong']) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('Terisi shows only the occupied rooms', (tester) async {
      await pumpRoomApp(tester, _repo());

      await tester.tap(filterChip('Terisi'));
      await tester.pumpAndSettle();

      expect(find.text('01'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('02'), findsNothing);
      expect(find.text('04'), findsNothing);
      expectChipSelected(tester, 'Terisi', selected: true);
      expectChipSelected(tester, 'Semua', selected: false);
    });

    testWidgets('Kosong shows only the vacant rooms', (tester) async {
      await pumpRoomApp(tester, _repo());

      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      expect(find.text('02'), findsOneWidget);
      expect(find.text('04'), findsOneWidget);
      expect(find.text('01'), findsNothing);
      expect(find.text('03'), findsNothing);
      expectChipSelected(tester, 'Kosong', selected: true);
    });

    testWidgets('Semua brings every room back', (tester) async {
      await pumpRoomApp(tester, _repo());
      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Semua'));
      await tester.pumpAndSettle();

      for (final number in ['01', '02', '03', '04']) {
        expect(find.text(number), findsOneWidget);
      }
      expectChipSelected(tester, 'Semua', selected: true);
    });

    testWidgets('filtering updates in place without loading again', (
      tester,
    ) async {
      final repo = _repo();
      await pumpRoomApp(tester, repo);

      await tester.tap(filterChip('Terisi'));
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
      expect(find.byType(RoomListScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/kamar');
    });

    testWidgets('explains an empty result and keeps the chips', (tester) async {
      await pumpRoomApp(tester, _repo([occupiedRoom(id: 'r1', number: '01')]));

      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      expect(find.text(_emptyFilter), findsOneWidget);
      expect(find.text(_emptyWithName), findsNothing);
      expect(find.text('Tambah Kamar'), findsNothing);
      expect(find.text('01'), findsNothing);
      expect(filterChip('Semua'), findsOneWidget);
    });

    testWidgets('the rows come back after an empty result', (tester) async {
      await pumpRoomApp(tester, _repo([occupiedRoom(id: 'r1', number: '01')]));
      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Terisi'));
      await tester.pumpAndSettle();

      expect(find.text(_emptyFilter), findsNothing);
      expect(find.text('01'), findsOneWidget);
    });
  });

  group('add button', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role sees Tambah, at least 48 dp, that opens the form', (
        tester,
      ) async {
        await pumpRoomApp(tester, _repo(), role: role);

        expect(find.text('Tambah'), findsOneWidget);
        expectTargetSize(tester, 'Tambah');

        await tester.tap(find.text('Tambah'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/properti/p1/kamar/tambah');
        final form = tester.widget<RoomFormScreen>(find.byType(RoomFormScreen));
        expect(form.propertyId, 'p1');
        expect(form.roomId, isNull);
      });
    }

    testWidgets('a view-only property hides Tambah', (tester) async {
      await pumpRoomApp(
        tester,
        _repo(),
        properties: propertiesWithMelati(editable: false),
      );

      expect(find.text('Tambah'), findsNothing);
      expect(find.text('01'), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('shows exactly the three filter chips', (tester) async {
      await pumpRoomApp(tester, _repo());

      expect(
        find.byWidgetPredicate(
          (widget) => widget is ChoiceChip || widget is FilterChip,
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('every filter chip takes its look from the chip theme', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo());

      for (final label in ['Semua', 'Terisi', 'Kosong']) {
        expectChipStyledByTheme(tester, label);
      }
    });

    testWidgets('the selected chip keeps the chip theme look', (tester) async {
      await pumpRoomApp(tester, _repo());

      await tester.tap(filterChip('Terisi'));
      await tester.pumpAndSettle();

      expectChipStyledByTheme(tester, 'Terisi');
      expectChipStyledByTheme(tester, 'Semua');
    });
  });

  group('accessibility', () {
    final states = <String, FakeRoomRepository Function()>{
      'loaded': _repo,
      'with a single room': () => _repo([vacantRoom()]),
      'empty': () => _repo([]),
      'failed': () => _repo()..listScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      for (final role in [UserRole.owner, UserRole.manager]) {
        testWidgets('meets the guidelines when ${entry.key} for a $role', (
          tester,
        ) async {
          await pumpRoomApp(tester, entry.value(), role: role);

          await expectMeetsA11yGuidelines(tester);
        });
      }

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpRoomApp(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines when empty for a view-only property', (
      tester,
    ) async {
      await pumpRoomApp(
        tester,
        _repo([]),
        properties: propertiesWithMelati(editable: false),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines for a view-only property', (
      tester,
    ) async {
      await pumpRoomApp(
        tester,
        _repo(),
        properties: propertiesWithMelati(editable: false),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when the property name is unknown', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await pumpRoomApp(tester, _repo([]), properties: properties);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the Terisi filter', (tester) async {
      await pumpRoomApp(tester, _repo());
      await tester.tap(filterChip('Terisi'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the Terisi filter', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), largeText: true);
      await tester.tap(filterChip('Terisi'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines when the filter matches nothing', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo([occupiedRoom()]));
      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size when the filter matches nothing', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo([occupiedRoom()]), largeText: true);
      await tester.ensureVisible(filterChip('Kosong'));
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Kosong'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_emptyFilter), findsOneWidget);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpRoomApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpRoomApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}

extension on Room {
  Room copyWithProperty(String propertyId) => Room(
    id: id,
    propertyId: propertyId,
    number: number,
    baseRate: baseRate,
    occupancy: occupancy,
    lease: lease,
    lengthM: lengthM,
    widthM: widthM,
    facilities: facilities,
    editable: editable,
  );
}
