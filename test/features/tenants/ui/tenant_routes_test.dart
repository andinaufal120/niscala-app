import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_qr_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'tenant_ui_helpers.dart';

FakeTenantRepository _repo() => FakeTenantRepository(tenants: sampleTenants());

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('tenant routes', () {
    testWidgets('/properti/:id/penyewa shows the tenant list of the property', (
      tester,
    ) async {
      final repo = _repo();
      await pumpTenantApp(tester, repo, path: '/properti/p1/penyewa');

      final list = tester.widget<TenantListScreen>(
        find.byType(TenantListScreen),
      );
      expect(list.propertyId, 'p1');
      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(repo.calls, contains('list:p1'));
    });

    testWidgets('/properti/:id/penyewa/tambah shows the add form', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo(), path: '/properti/p1/penyewa/tambah');

      final form = tester.widget<TenantFormScreen>(
        find.byType(TenantFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.preselectedRoomId, isNull);
      expect(find.byType(TenantDetailScreen), findsNothing);
    });

    testWidgets('the kamar query parameter names the preselected room', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo(),
        path: '/properti/p1/penyewa/tambah?kamar=r3',
      );

      final form = tester.widget<TenantFormScreen>(
        find.byType(TenantFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.preselectedRoomId, 'r3');
    });

    testWidgets('/properti/:id/penyewa/:tenantId shows the tenant detail', (
      tester,
    ) async {
      final repo = _repo();
      await pumpTenantApp(tester, repo, path: '/properti/p1/penyewa/t2');

      final detail = tester.widget<TenantDetailScreen>(
        find.byType(TenantDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.tenantId, 't2');
      expect(repo.calls, contains('get:t2'));
    });

    testWidgets('.../undangan shows the share screen for an existing link', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo(),
        path: '/properti/p1/penyewa/t2/undangan',
      );

      final share = tester.widget<InvitationShareScreen>(
        find.byType(InvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.tenantId, 't2');
      expect(share.isNew, isFalse);
    });

    testWidgets('baru=1 marks the share screen as new', (tester) async {
      await pumpTenantApp(
        tester,
        _repo(),
        path: '/properti/p1/penyewa/t2/undangan?baru=1',
      );

      final share = tester.widget<InvitationShareScreen>(
        find.byType(InvitationShareScreen),
      );
      expect(share.tenantId, 't2');
      expect(share.isNew, isTrue);
    });

    testWidgets('.../undangan/qr shows the QR screen', (tester) async {
      await pumpTenantApp(
        tester,
        _repo(),
        path: '/properti/p1/penyewa/t2/undangan/qr',
      );

      final qr = tester.widget<InvitationQrScreen>(
        find.byType(InvitationQrScreen),
      );
      expect(qr.propertyId, 'p1');
      expect(qr.tenantId, 't2');
    });

    for (final path in [
      '/properti/p1/penyewa',
      '/properti/p1/penyewa/tambah',
      '/properti/p1/penyewa/t2',
      '/properti/p1/penyewa/t2/undangan',
      '/properti/p1/penyewa/t2/undangan/qr',
    ]) {
      testWidgets('$path hides the navigation bar', (tester) async {
        await pumpTenantApp(tester, _repo(), path: path);

        expect(find.byType(NavigationBar), findsNothing);
      });
    }

    testWidgets(
      'the Properti tab is selected again after leaving the tenants',
      (tester) async {
        await pumpTenantApp(tester, _repo(), path: '/properti/p1/penyewa');

        await pressBack(tester);
        await pressBack(tester);

        expect(_selectedTab(tester), 3);
      },
    );

    testWidgets('Kembali from the tenant list returns to the property', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    testWidgets('Kembali from the add form returns to the tenant list', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo(), path: '/properti/p1/penyewa/tambah');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the tenant detail returns to the tenant list', (
      tester,
    ) async {
      await pumpTenantApp(tester, _repo(), path: '/properti/p1/penyewa/t2');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the QR screen returns to the share screen', (
      tester,
    ) async {
      await pumpTenantApp(
        tester,
        _repo(),
        path: '/properti/p1/penyewa/t2/undangan/qr',
      );

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/t2/undangan');
      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('a $role may open the tenant list', (tester) async {
        await pumpTenantApp(tester, _repo(), role: role);

        expect(find.byType(TenantListScreen), findsOneWidget);
      });
    }

    for (final path in [
      '/properti/p1/penyewa',
      '/properti/p1/penyewa/tambah',
      '/properti/p1/penyewa/t2',
      '/properti/p1/penyewa/t2/undangan',
      '/properti/p1/penyewa/t2/undangan/qr',
    ]) {
      testWidgets('a tenant opening $path is sent to the tenant home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpTenantApp(tester, repo, role: UserRole.tenant, path: path);

        expect(currentPath(tester), '/penyewa/beranda');
        expect(find.byType(TenantListScreen), findsNothing);
        expect(find.byType(TenantFormScreen), findsNothing);
        expect(find.byType(TenantDetailScreen), findsNothing);
        expect(find.byType(InvitationShareScreen), findsNothing);
        expect(find.byType(InvitationQrScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });

      testWidgets('an admin opening $path is sent to the admin home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpTenantApp(tester, repo, role: UserRole.admin, path: path);

        expect(currentPath(tester), '/admin');
        expect(find.byType(TenantListScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }
  });
}
