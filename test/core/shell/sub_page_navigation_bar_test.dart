import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_qr_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../features/complaints/ui/complaint_ui_helpers.dart';
import '../../features/tenants/ui/tenant_ui_helpers.dart';
import '../../helpers/fakes.dart';

/// Every sub-page a management user can reach, with the screen it shows.
final _managementSubPages = <String, Finder>{
  '/properti/tambah': find.byType(PropertyFormScreen),
  '/properti/p1': find.byType(PropertyDetailScreen),
  '/properti/p1/ubah': find.byType(PropertyFormScreen),
  '/properti/p1/kamar': find.byType(RoomListScreen),
  '/properti/p1/kamar/tambah': find.byType(RoomFormScreen),
  '/properti/p1/kamar/r1': find.byType(RoomDetailScreen),
  '/properti/p1/kamar/r1/ubah': find.byType(RoomFormScreen),
  '/properti/p1/penyewa': find.byType(TenantListScreen),
  '/properti/p1/penyewa/tambah': find.byType(TenantFormScreen),
  '/properti/p1/penyewa/t2': find.byType(TenantDetailScreen),
  '/properti/p1/penyewa/t2/undangan': find.byType(InvitationShareScreen),
  '/properti/p1/penyewa/t2/undangan/qr': find.byType(InvitationQrScreen),
  '/keluhan/c1': find.byType(ManagementComplaintDetailScreen),
};

final _tenantSubPages = <String, Finder>{
  '/penyewa/keluhan/baru': find.byType(ComplaintFormScreen),
  '/penyewa/keluhan/c1': find.byType(TenantComplaintDetailScreen),
};

const _managementRoots = {
  '/beranda': 0,
  '/keluhan': 1,
  '/pembayaran': 2,
  '/properti': 3,
  '/akun': 4,
};

const _tenantRoots = {
  '/penyewa/beranda': 0,
  '/penyewa/keluhan': 1,
  '/penyewa/pembayaran': 2,
  '/penyewa/akun': 3,
};

/// Two complaints: c1 is new and c2 is done, so the filter chips matter.
FakeComplaintRepository _complaints() => FakeComplaintRepository(
  complaints: [
    makeComplaint(id: 'c1', description: 'Keran bocor.'),
    makeComplaint(
      id: 'c2',
      description: 'Lampu sudah diperbaiki.',
      status: ComplaintStatus.done,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  UserRole role = UserRole.owner,
  FakePropertyRepository? properties,
  FakeComplaintRepository? complaints,
  String? path,
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      store: InMemorySessionStore(storedSession(role: role)),
      properties:
          properties ??
          FakePropertyRepository(
            properties: [
              makeProperty(id: 'p1'),
              makeProperty(id: 'p2', name: 'Kos Mawar'),
            ],
          ),
      rooms: FakeRoomRepository(
        rooms: [
          occupiedRoom(id: 'r1', number: '08'),
          vacantRoom(id: 'r2'),
        ],
      ),
      tenants: FakeTenantRepository(tenants: sampleTenants()),
      complaints: complaints ?? _complaints(),
    ),
  );
  await tester.pumpAndSettle();
  if (path != null) {
    goTo(tester, path);
    await tester.pumpAndSettle();
  }
}

/// Expects the bottom navigation bar to be neither on show nor reachable,
/// whether it is removed or only covered.
void _expectNoBar(WidgetTester tester) {
  expect(find.byType(NavigationBar), findsNothing);
  expect(find.byType(NavigationDestination), findsNothing);
  expect(
    find.byType(NavigationBar, skipOffstage: false).hitTestable(),
    findsNothing,
  );
  expect(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Pembayaran'),
    ),
    findsNothing,
  );
}

/// Expects the bottom navigation bar on show at the bottom of the display and
/// reachable, with [selected] chosen.
void _expectBar(WidgetTester tester, int selected) {
  expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  expect(tester.getRect(find.byType(NavigationBar)).bottom, closeTo(height, 1));
  expect(selectedIndex(tester), selected);
}

int selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> _leave(WidgetTester tester, String mode) =>
    mode == 'Kembali' ? pressBack(tester) : _systemBack(tester);

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

bool _chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(filterChip(label)).selected;

void main() {
  group('tab roots keep the bar', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      for (final entry in _managementRoots.entries) {
        testWidgets('${entry.key} for a $role', (tester) async {
          await _pump(tester, role: role, path: entry.key);

          _expectBar(tester, entry.value);
        });
      }
    }

    for (final entry in _tenantRoots.entries) {
      testWidgets('${entry.key} for a tenant', (tester) async {
        await _pump(tester, role: UserRole.tenant, path: entry.key);

        _expectBar(tester, entry.value);
      });
    }

    testWidgets('the Properti tab root of a manager with one property', (
      tester,
    ) async {
      await _pump(
        tester,
        role: UserRole.manager,
        properties: FakePropertyRepository(properties: [makeProperty()]),
        path: '/properti',
      );

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(backButton(), findsNothing);
      _expectBar(tester, 3);
    });

    testWidgets(
      'a manager with one property loses the bar below its tab root',
      (tester) async {
        await _pump(
          tester,
          role: UserRole.manager,
          properties: FakePropertyRepository(properties: [makeProperty()]),
          path: '/properti',
        );

        goTo(tester, '/properti/p1/kamar');
        await tester.pumpAndSettle();

        expect(find.byType(RoomListScreen), findsOneWidget);
        _expectNoBar(tester);
      },
    );
  });

  group('sub-pages hide the bar', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      for (final entry in _managementSubPages.entries) {
        testWidgets('${entry.key} for a $role', (tester) async {
          await _pump(tester, role: role, path: entry.key);

          expect(entry.value, findsOneWidget);
          _expectNoBar(tester);
        });
      }
    }

    for (final entry in _tenantSubPages.entries) {
      testWidgets('${entry.key} for a tenant', (tester) async {
        await _pump(tester, role: UserRole.tenant, path: entry.key);

        expect(entry.value, findsOneWidget);
        _expectNoBar(tester);
      });
    }

    testWidgets('a sub-page opened by a tap hides the bar', (tester) async {
      await _pump(tester, role: UserRole.tenant, path: '/penyewa/keluhan');
      _expectBar(tester, 1);

      await tester.tap(find.text('Keran bocor.'));
      await tester.pumpAndSettle();

      expect(find.byType(TenantComplaintDetailScreen), findsOneWidget);
      _expectNoBar(tester);
    });
  });

  group('going back', () {
    testWidgets('Kembali from a complaint shows the bar on the same tab', (
      tester,
    ) async {
      await _pump(tester, role: UserRole.tenant, path: '/penyewa/keluhan');
      await tester.tap(find.text('Keran bocor.'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/penyewa/keluhan');
      _expectBar(tester, 1);
    });

    testWidgets('system back from a complaint shows the bar on the same tab', (
      tester,
    ) async {
      await _pump(tester, role: UserRole.tenant, path: '/penyewa/keluhan');
      await tester.tap(find.text('Keran bocor.'));
      await tester.pumpAndSettle();

      await _systemBack(tester);

      expect(currentPath(tester), '/penyewa/keluhan');
      _expectBar(tester, 1);
    });

    testWidgets('Kembali from the complaint form shows the bar again', (
      tester,
    ) async {
      await _pump(tester, role: UserRole.tenant, path: '/penyewa/keluhan');
      await tester.tap(find.text('Ajukan'));
      await tester.pumpAndSettle();
      _expectNoBar(tester);

      await pressBack(tester);

      _expectBar(tester, 1);
    });

    testWidgets('system back from the complaint form shows the bar again', (
      tester,
    ) async {
      await _pump(tester, role: UserRole.tenant, path: '/penyewa/keluhan');
      await tester.tap(find.text('Ajukan'));
      await tester.pumpAndSettle();

      await _systemBack(tester);

      _expectBar(tester, 1);
    });

    for (final mode in ['Kembali', 'system back']) {
      testWidgets('a tenant keeps the chosen filter chip after $mode', (
        tester,
      ) async {
        await _pump(tester, role: UserRole.tenant, path: '/penyewa/keluhan');
        await tester.tap(filterChip('Selesai'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lampu sudah diperbaiki.'));
        await tester.pumpAndSettle();
        _expectNoBar(tester);

        await _leave(tester, mode);

        _expectBar(tester, 1);
        expect(_chipSelected(tester, 'Selesai'), isTrue);
        expect(_chipSelected(tester, 'Aktif'), isFalse);
      });

      testWidgets('management keeps the chosen filter chip after $mode', (
        tester,
      ) async {
        await _pump(tester, path: '/keluhan');
        await tester.tap(filterChip('Selesai'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lampu sudah diperbaiki.'));
        await tester.pumpAndSettle();
        _expectNoBar(tester);

        await _leave(tester, mode);

        _expectBar(tester, 1);
        expect(_chipSelected(tester, 'Selesai'), isTrue);
        expect(_chipSelected(tester, 'Semua'), isFalse);
      });
    }

    testWidgets('property detail returns to the list with the bar', (
      tester,
    ) async {
      await _pump(tester, path: '/properti');
      await tester.tap(find.text('Kos Melati'));
      await tester.pumpAndSettle();
      _expectNoBar(tester);

      await pressBack(tester);

      expect(find.byType(PropertyListScreen), findsOneWidget);
      _expectBar(tester, 3);
    });

    testWidgets('room detail returns to the room list without the bar', (
      tester,
    ) async {
      await _pump(tester, path: '/properti/p1/kamar');
      await tester.tap(find.text('08'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(find.byType(RoomListScreen), findsOneWidget);
      _expectNoBar(tester);
    });

    testWidgets('a deep link to a room goes back, page by page, to the tab', (
      tester,
    ) async {
      await _pump(tester, path: '/properti/p1/kamar/r1');

      var pops = 0;
      while (find.byType(NavigationBar).evaluate().isEmpty && pops < 6) {
        await _systemBack(tester);
        pops++;
      }

      expect(currentPath(tester), '/properti');
      _expectBar(tester, 3);
    });

    testWidgets('a deep link to a complaint goes back to the Keluhan root', (
      tester,
    ) async {
      await _pump(tester, path: '/keluhan/c1');
      _expectNoBar(tester);

      await pressBack(tester);

      expect(currentPath(tester), '/keluhan');
      expect(find.byType(ManagementComplaintListScreen), findsOneWidget);
      _expectBar(tester, 1);
    });
  });

  group('deep link from another tab', () {
    testWidgets('lands on the sub-page and returns to its tab root', (
      tester,
    ) async {
      await _pump(tester);
      await _tapTab(tester, 'Akun');
      _expectBar(tester, 4);

      goTo(tester, '/keluhan/c1');
      await tester.pumpAndSettle();
      expect(find.byType(ManagementComplaintDetailScreen), findsOneWidget);
      _expectNoBar(tester);

      await _systemBack(tester);

      expect(currentPath(tester), '/keluhan');
      _expectBar(tester, 1);
    });

    testWidgets('keeps the state of the tab it lands on', (tester) async {
      await _pump(tester, path: '/keluhan');
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Akun');

      goTo(tester, '/keluhan/c1');
      await tester.pumpAndSettle();
      await pressBack(tester);

      _expectBar(tester, 1);
      expect(_chipSelected(tester, 'Selesai'), isTrue);
    });

    testWidgets('leaves the state of the other tabs alone', (tester) async {
      await _pump(tester, path: '/keluhan');
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      goTo(tester, '/properti/p1');
      await tester.pumpAndSettle();
      await pressBack(tester);
      await _tapTab(tester, 'Keluhan');

      expect(_chipSelected(tester, 'Selesai'), isTrue);
    });
  });

  group('with a large text size', () {
    testWidgets('a sub-page has no bar and does not overflow', (tester) async {
      await pumpComplaintApp(
        tester,
        _complaints(),
        path: '/penyewa/keluhan/c1',
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      _expectNoBar(tester);
    });
  });
}
