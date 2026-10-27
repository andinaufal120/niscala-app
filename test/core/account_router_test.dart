import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

const _managementPath = '/akun/perangkat';
const _tenantPath = '/penyewa/akun/perangkat';

SessionState _signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

void main() {
  group('the active devices page', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      test('may be opened by a $role at its management path', () {
        expect(redirectFor(_signedIn(role), _managementPath), isNull);
      });

      test('sends a $role from the tenant path to the management home', () {
        expect(redirectFor(_signedIn(role), _tenantPath), '/beranda');
      });
    }

    test('may be opened by a tenant at its tenant path', () {
      expect(redirectFor(_signedIn(UserRole.tenant), _tenantPath), isNull);
    });

    test('sends a tenant from the management path to the tenant home', () {
      expect(
        redirectFor(_signedIn(UserRole.tenant), _managementPath),
        '/penyewa/beranda',
      );
    });

    for (final path in [_managementPath, _tenantPath]) {
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
        final path = role == UserRole.tenant ? _tenantPath : _managementPath;

        expect(
          redirectFor(_signedIn(role, verified: false), path),
          '/verifikasi-email',
        );
      });
    }
  });
}
