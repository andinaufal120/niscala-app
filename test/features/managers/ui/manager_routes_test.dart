import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/managers/ui/manager_detail_screen.dart';
import 'package:niscala/features/managers/ui/manager_form_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_qr_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_share_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'manager_ui_helpers.dart';

FakeManagerRepository _repo() =>
    FakeManagerRepository(managers: sampleManagers());

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

const _paths = [
  '/properti/p1/pengelola',
  '/properti/p1/pengelola/tambah',
  '/properti/p1/pengelola/m1',
  '/properti/p1/pengelola/m1/ubah',
  '/properti/p1/pengelola/m1/undangan',
  '/properti/p1/pengelola/m1/undangan/qr',
];

void main() {
  group('manager routes', () {
    testWidgets('/properti/:id/pengelola shows the manager list', (
      tester,
    ) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo, path: '/properti/p1/pengelola');

      final list = tester.widget<ManagerListScreen>(
        find.byType(ManagerListScreen),
      );
      expect(list.propertyId, 'p1');
      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(repo.calls, contains('list:p1'));
    });

    testWidgets('/properti/:id/pengelola/tambah shows the add form', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/tambah',
      );

      final form = tester.widget<ManagerFormScreen>(
        find.byType(ManagerFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.managerId, isNull);
      expect(find.byType(ManagerDetailScreen), findsNothing);
    });

    testWidgets('/properti/:id/pengelola/:managerId shows the detail', (
      tester,
    ) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo, path: '/properti/p1/pengelola/m2');

      final detail = tester.widget<ManagerDetailScreen>(
        find.byType(ManagerDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.managerId, 'm2');
      expect(repo.calls, contains('get:m2'));
    });

    testWidgets('.../ubah shows the edit form of the manager', (tester) async {
      final repo = _repo();
      await pumpManagerApp(
        tester,
        repo,
        path: '/properti/p1/pengelola/m2/ubah',
      );

      final form = tester.widget<ManagerFormScreen>(
        find.byType(ManagerFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.managerId, 'm2');
      expect(repo.calls, contains('get:m2'));
    });

    testWidgets('.../undangan shows the share screen for an existing link', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/m1/undangan',
      );

      final share = tester.widget<ManagerInvitationShareScreen>(
        find.byType(ManagerInvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.managerId, 'm1');
      expect(share.isNew, isFalse);
    });

    testWidgets('baru=1 marks the share screen as new', (tester) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/m1/undangan?baru=1',
      );

      final share = tester.widget<ManagerInvitationShareScreen>(
        find.byType(ManagerInvitationShareScreen),
      );
      expect(share.managerId, 'm1');
      expect(share.isNew, isTrue);
    });

    testWidgets('.../undangan/qr shows the QR screen', (tester) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/m1/undangan/qr',
      );

      final qr = tester.widget<ManagerInvitationQrScreen>(
        find.byType(ManagerInvitationQrScreen),
      );
      expect(qr.propertyId, 'p1');
      expect(qr.managerId, 'm1');
    });

    for (final path in _paths) {
      testWidgets('$path hides the navigation bar', (tester) async {
        await pumpManagerApp(tester, _repo(), path: path);

        expect(find.byType(NavigationBar), findsNothing);
      });
    }

    testWidgets(
      'the Properti tab is selected again after leaving the managers',
      (tester) async {
        await pumpManagerApp(tester, _repo(), path: '/properti/p1/pengelola');

        await pressBack(tester);
        await pressBack(tester);

        expect(_selectedTab(tester), 3);
      },
    );

    testWidgets('Kembali from the manager list returns to the property', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    testWidgets('Kembali from the add form returns to the manager list', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/tambah',
      );

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the detail returns to the manager list', (
      tester,
    ) async {
      await pumpManagerApp(tester, _repo(), path: '/properti/p1/pengelola/m2');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the edit form returns to the detail', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/m2/ubah',
      );

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m2');
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
    });

    testWidgets('Kembali from the QR screen returns to the share screen', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/m1/undangan/qr',
      );

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });

    testWidgets('the tenant routes of the property still work', (tester) async {
      await pumpManagerApp(tester, _repo(), path: '/properti/p1/penyewa');

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(ManagerListScreen), findsNothing);
    });

    testWidgets('an owner may open the manager list', (tester) async {
      await pumpManagerApp(tester, _repo());

      expect(find.byType(ManagerListScreen), findsOneWidget);
    });

    for (final path in _paths) {
      testWidgets('a manager opening $path is sent to the management home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpManagerApp(tester, repo, role: UserRole.manager, path: path);

        expect(currentPath(tester), '/beranda');
        expect(find.byType(ManagerListScreen), findsNothing);
        expect(find.byType(ManagerFormScreen), findsNothing);
        expect(find.byType(ManagerDetailScreen), findsNothing);
        expect(find.byType(ManagerInvitationShareScreen), findsNothing);
        expect(find.byType(ManagerInvitationQrScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });

      testWidgets('a tenant opening $path is sent to the tenant home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpManagerApp(tester, repo, role: UserRole.tenant, path: path);

        expect(currentPath(tester), '/penyewa/beranda');
        expect(find.byType(ManagerListScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });

      testWidgets('an admin opening $path is sent to the admin home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpManagerApp(tester, repo, role: UserRole.admin, path: path);

        expect(currentPath(tester), '/admin');
        expect(find.byType(ManagerListScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }
  });
}
