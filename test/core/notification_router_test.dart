import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

SessionState _signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

void main() {
  const suffixes = ['/notifikasi', '/notifikasi/pengaturan', '/notifikasi/n1'];

  for (final suffix in suffixes) {
    final managementPath = '/akun$suffix';
    final tenantPath = '/penyewa/akun$suffix';

    group('the page $suffix', () {
      for (final role in [UserRole.owner, UserRole.manager]) {
        test('may be opened by a $role at its management path', () {
          expect(redirectFor(_signedIn(role), managementPath), isNull);
        });

        test('sends a $role from the tenant path to the management home', () {
          expect(redirectFor(_signedIn(role), tenantPath), '/beranda');
        });
      }

      test('may be opened by a tenant at its tenant path', () {
        expect(redirectFor(_signedIn(UserRole.tenant), tenantPath), isNull);
      });

      test('sends a tenant from the management path to the tenant home', () {
        expect(
          redirectFor(_signedIn(UserRole.tenant), managementPath),
          '/penyewa/beranda',
        );
      });

      for (final path in [managementPath, tenantPath]) {
        test('sends an admin from $path to the admin home', () {
          expect(redirectFor(_signedIn(UserRole.admin), path), '/admin');
        });

        test('sends a signed out user from $path to sign in', () {
          expect(redirectFor(const SignedOut(), path), '/masuk');
        });

        test('sends a user who is still loading from $path to loading', () {
          expect(redirectFor(const SessionLoading(), path), '/memuat');
        });
      }

      for (final role in [UserRole.owner, UserRole.manager, UserRole.tenant]) {
        test('sends an unverified $role to verification', () {
          final path = role == UserRole.tenant ? tenantPath : managementPath;

          expect(
            redirectFor(_signedIn(role, verified: false), path),
            '/verifikasi-email',
          );
        });
      }
    });
  }
}
