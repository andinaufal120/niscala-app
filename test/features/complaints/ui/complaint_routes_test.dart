import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

SessionState _in(UserRole role) => SignedIn(role: role, emailVerified: true);

void main() {
  group('redirects', () {
    const tenantPaths = [
      '/penyewa/keluhan',
      '/penyewa/keluhan/baru',
      '/penyewa/keluhan/c1',
    ];
    for (final path in tenantPaths) {
      test('a tenant may stay on $path', () {
        expect(redirectFor(_in(UserRole.tenant), path), isNull);
      });

      test('a management user is sent home from $path', () {
        for (final role in [UserRole.owner, UserRole.manager]) {
          expect(redirectFor(_in(role), path), '/beranda');
        }
      });
    }

    const managementPaths = ['/keluhan', '/keluhan/c1'];
    for (final path in managementPaths) {
      test('an owner and a manager may stay on $path', () {
        for (final role in [UserRole.owner, UserRole.manager]) {
          expect(redirectFor(_in(role), path), isNull);
        }
      });

      test('a tenant is sent home from $path', () {
        expect(redirectFor(_in(UserRole.tenant), path), '/penyewa/beranda');
      });
    }

    test('a signed out user is sent to sign in from a complaint', () {
      expect(redirectFor(const SignedOut(), '/penyewa/keluhan/c1'), '/masuk');
      expect(redirectFor(const SignedOut(), '/keluhan/c1'), '/masuk');
    });
  });

  group('screens', () {
    testWidgets('the tenant Keluhan tab shows the tenant list', (tester) async {
      await pumpComplaintApp(tester, FakeComplaintRepository());

      expect(find.byType(TenantComplaintListScreen), findsOneWidget);
      expect(find.byType(ManagementComplaintListScreen), findsNothing);
    });

    testWidgets('the management Keluhan tab shows the management list', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        FakeComplaintRepository(),
        role: UserRole.owner,
      );

      expect(find.byType(ManagementComplaintListScreen), findsOneWidget);
      expect(find.byType(TenantComplaintListScreen), findsNothing);
    });

    testWidgets('baru opens the form and is not read as a complaint id', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await pumpComplaintApp(tester, repo, path: '/penyewa/keluhan/baru');

      expect(find.byType(ComplaintFormScreen), findsOneWidget);
      expect(find.byType(TenantComplaintDetailScreen), findsNothing);
      expect(repo.getCalls, 0);
    });

    testWidgets('a tenant complaint id opens the tenant detail', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        FakeComplaintRepository(complaints: [makeComplaint(id: 'c9')]),
        path: '/penyewa/keluhan/c9',
      );

      expect(find.byType(TenantComplaintDetailScreen), findsOneWidget);
    });

    testWidgets('a management complaint id opens the management detail', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        FakeComplaintRepository(complaints: [makeComplaint(id: 'c9')]),
        role: UserRole.manager,
        path: '/keluhan/c9',
      );

      expect(find.byType(ManagementComplaintDetailScreen), findsOneWidget);
    });

    testWidgets('the navigation bar is hidden on a complaint', (tester) async {
      await pumpComplaintApp(
        tester,
        FakeComplaintRepository(complaints: [makeComplaint(id: 'c9')]),
        path: '/penyewa/keluhan/c9',
      );

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the Keluhan tab is selected again after Kembali', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        FakeComplaintRepository(complaints: [makeComplaint(id: 'c9')]),
        path: '/penyewa/keluhan/c9',
      );

      await pressBack(tester);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 1);
    });
  });
}
