import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'room_ui_helpers.dart';

FakeRoomRepository _repo() => FakeRoomRepository(
  rooms: [
    occupiedRoom(id: 'r1', number: '08'),
    vacantRoom(id: 'r2'),
  ],
);

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('room routes', () {
    testWidgets('/properti/:id/kamar shows the room list of that property', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar');

      final list = tester.widget<RoomListScreen>(find.byType(RoomListScreen));
      expect(list.propertyId, 'p1');
      expect(currentPath(tester), '/properti/p1/kamar');
    });

    testWidgets('the list loads the rooms of the property in the path', (
      tester,
    ) async {
      final repo = _repo();
      await pumpRoomApp(tester, repo, path: '/properti/p1/kamar');

      expect(repo.calls, contains('list:p1'));
    });

    testWidgets('/properti/:id/kamar/tambah shows the add form', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar/tambah');

      final form = tester.widget<RoomFormScreen>(find.byType(RoomFormScreen));
      expect(form.propertyId, 'p1');
      expect(form.roomId, isNull);
      expect(find.byType(RoomDetailScreen), findsNothing);
    });

    testWidgets('/properti/:id/kamar/:roomId shows the room detail', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar/r2');

      final detail = tester.widget<RoomDetailScreen>(
        find.byType(RoomDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.roomId, 'r2');
    });

    testWidgets('/properti/:id/kamar/:roomId/ubah shows the edit form', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar/r1/ubah');

      final form = tester.widget<RoomFormScreen>(find.byType(RoomFormScreen));
      expect(form.propertyId, 'p1');
      expect(form.roomId, 'r1');
    });

    for (final path in [
      '/properti/p1/kamar',
      '/properti/p1/kamar/tambah',
      '/properti/p1/kamar/r1',
      '/properti/p1/kamar/r1/ubah',
    ]) {
      testWidgets('$path keeps the Properti tab selected', (tester) async {
        await pumpRoomApp(tester, _repo(), path: path);

        expect(_selectedTab(tester), 3);
      });
    }

    testWidgets('Kembali from the room list returns to the property', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    testWidgets('Kembali from the add form returns to the room list', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar/tambah');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.byType(RoomListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the room detail returns to the room list', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar/r1');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.byType(RoomListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the edit form returns to the room detail', (
      tester,
    ) async {
      await pumpRoomApp(tester, _repo(), path: '/properti/p1/kamar/r1/ubah');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/kamar/r1');
      expect(find.byType(RoomDetailScreen), findsOneWidget);
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role may open the room list', (tester) async {
        await pumpRoomApp(tester, _repo(), role: role);

        expect(find.byType(RoomListScreen), findsOneWidget);
      });
    }

    for (final path in [
      '/properti/p1/kamar',
      '/properti/p1/kamar/tambah',
      '/properti/p1/kamar/r1',
      '/properti/p1/kamar/r1/ubah',
    ]) {
      testWidgets('a tenant opening $path is sent to the tenant home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpRoomApp(tester, repo, role: UserRole.tenant, path: path);

        expect(currentPath(tester), '/penyewa/beranda');
        expect(find.byType(RoomListScreen), findsNothing);
        expect(find.byType(RoomDetailScreen), findsNothing);
        expect(find.byType(RoomFormScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }
  });
}
