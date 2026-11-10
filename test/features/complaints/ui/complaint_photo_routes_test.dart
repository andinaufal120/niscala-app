import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/complaint_photo_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'complaint_photo_helpers.dart';

SessionState _in(UserRole role) => SignedIn(role: role, emailVerified: true);

FakeComplaintRepository _repo({String id = 'c9'}) => FakeComplaintRepository(
  complaints: [makeComplaint(id: id, hasPhoto: true)],
  photos: {id: tinyPng},
);

void main() {
  group('redirects', () {
    test('a tenant may stay on the photo of a complaint', () {
      expect(
        redirectFor(_in(UserRole.tenant), '/penyewa/keluhan/c1/foto'),
        isNull,
      );
    });

    test('a management user is sent home from the photo of a tenant '
        'complaint', () {
      for (final role in [UserRole.owner, UserRole.manager]) {
        expect(redirectFor(_in(role), '/penyewa/keluhan/c1/foto'), '/beranda');
      }
    });

    test('an owner and a manager may stay on the photo of a complaint', () {
      for (final role in [UserRole.owner, UserRole.manager]) {
        expect(redirectFor(_in(role), '/keluhan/c1/foto'), isNull);
      }
    });

    test('a tenant is sent home from the management photo', () {
      expect(
        redirectFor(_in(UserRole.tenant), '/keluhan/c1/foto'),
        '/penyewa/beranda',
      );
    });

    test('an admin is sent to the user accounts from either photo', () {
      for (final path in ['/penyewa/keluhan/c1/foto', '/keluhan/c1/foto']) {
        expect(redirectFor(_in(UserRole.admin), path), '/admin');
      }
    });

    test('a signed out user is sent to sign in from either photo', () {
      for (final path in ['/penyewa/keluhan/c1/foto', '/keluhan/c1/foto']) {
        expect(redirectFor(const SignedOut(), path), '/masuk');
      }
    });

    test('a user with an unverified email is sent to verify it', () {
      final session = SignedIn(role: UserRole.tenant, emailVerified: false);
      expect(
        redirectFor(session, '/penyewa/keluhan/c1/foto'),
        '/verifikasi-email',
      );
    });

    test('a user still loading is sent to the loading screen', () {
      expect(
        redirectFor(const SessionLoading(), '/penyewa/keluhan/c1/foto'),
        '/memuat',
      );
    });
  });

  group('screens', () {
    testWidgets('a tenant complaint photo path opens the photo screen', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo(), path: '/penyewa/keluhan/c9/foto');

      final screen = tester.widget<ComplaintPhotoScreen>(
        find.byType(ComplaintPhotoScreen),
      );
      expect(screen.complaintId, 'c9');
      expect(find.byType(TenantComplaintDetailScreen), findsNothing);
      expect(find.byType(ComplaintFormScreen), findsNothing);
    });

    testWidgets('a management complaint photo path opens the photo screen', (
      tester,
    ) async {
      await pumpComplaintApp(
        tester,
        _repo(),
        role: UserRole.manager,
        path: '/keluhan/c9/foto',
      );

      final screen = tester.widget<ComplaintPhotoScreen>(
        find.byType(ComplaintPhotoScreen),
      );
      expect(screen.complaintId, 'c9');
      expect(find.byType(ManagementComplaintDetailScreen), findsNothing);
    });

    testWidgets('the owner opens the photo screen too', (tester) async {
      await pumpComplaintApp(
        tester,
        _repo(),
        role: UserRole.owner,
        path: '/keluhan/c9/foto',
      );

      expect(find.byType(ComplaintPhotoScreen), findsOneWidget);
    });

    testWidgets('the photo screen loads the photo of the id in the path', (
      tester,
    ) async {
      final repo = _repo(id: 'abc-123');
      await pumpComplaintApp(
        tester,
        repo,
        path: '/penyewa/keluhan/abc-123/foto',
      );

      expect(repo.calls, contains('photo:abc-123'));
    });

    testWidgets('the navigation bar is hidden on the photo', (tester) async {
      await pumpComplaintApp(tester, _repo(), path: '/penyewa/keluhan/c9/foto');

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the tenant photo sits under the complaint, so Kembali '
        'returns to it', (tester) async {
      await pumpComplaintApp(tester, _repo(), path: '/penyewa/keluhan/c9/foto');

      await pressBack(tester);

      expect(find.byType(TenantComplaintDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/penyewa/keluhan/c9');
    });

    testWidgets('the management photo sits under the complaint, so Kembali '
        'returns to it', (tester) async {
      await pumpComplaintApp(
        tester,
        _repo(),
        role: UserRole.owner,
        path: '/keluhan/c9/foto',
      );

      await pressBack(tester);

      expect(find.byType(ManagementComplaintDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/keluhan/c9');
    });

    testWidgets('the Keluhan tab is selected again after leaving both '
        'screens', (tester) async {
      await pumpComplaintApp(tester, _repo(), path: '/penyewa/keluhan/c9/foto');

      await pressBack(tester);
      await pressBack(tester);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 1);
    });

    testWidgets('a tenant sent to the management photo lands on the tenant '
        'home', (tester) async {
      await pumpComplaintApp(tester, _repo(), path: '/keluhan/c9/foto');

      expect(find.byType(ComplaintPhotoScreen), findsNothing);
      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('an owner sent to the tenant photo lands on the management '
        'home', (tester) async {
      await pumpComplaintApp(
        tester,
        _repo(),
        role: UserRole.owner,
        path: '/penyewa/keluhan/c9/foto',
      );

      expect(find.byType(ComplaintPhotoScreen), findsNothing);
      expect(currentPath(tester), '/beranda');
    });

    testWidgets('baru still opens the form and not a complaint', (
      tester,
    ) async {
      await pumpComplaintApp(tester, _repo(), path: '/penyewa/keluhan/baru');

      expect(find.byType(ComplaintFormScreen), findsOneWidget);
      expect(find.byType(ComplaintPhotoScreen), findsNothing);
    });
  });
}
