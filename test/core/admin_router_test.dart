import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

SessionState _signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

const _adminLocations = ['/admin', '/admin/u1', '/admin/u1/ubah'];

void main() {
  group('an admin', () {
    for (final location in _adminLocations) {
      test('may stay at $location', () {
        expect(redirectFor(_signedIn(UserRole.admin), location), isNull);
      });
    }

    for (final location in [
      '/beranda',
      '/keluhan',
      '/pembayaran',
      '/properti',
      '/properti/p1',
      '/akun',
      '/akun/perangkat',
      '/akun/kata-sandi',
      '/akun/notifikasi',
      '/penyewa/beranda',
      '/penyewa/akun',
      '/masuk',
      '/memuat',
      '/',
      '/administrator',
    ]) {
      test('is sent from $location to the user accounts', () {
        expect(redirectFor(_signedIn(UserRole.admin), location), '/admin');
      });
    }

    for (final location in _adminLocations) {
      test(
        'with an unverified email is sent from $location to verification',
        () {
          expect(
            redirectFor(_signedIn(UserRole.admin, verified: false), location),
            '/verifikasi-email',
          );
        },
      );
    }
  });

  group('the user accounts', () {
    for (final location in _adminLocations) {
      for (final role in [UserRole.owner, UserRole.manager]) {
        test('send a $role from $location to the management home', () {
          expect(redirectFor(_signedIn(role), location), '/beranda');
        });
      }

      test('send a tenant from $location to the tenant home', () {
        expect(
          redirectFor(_signedIn(UserRole.tenant), location),
          '/penyewa/beranda',
        );
      });

      test('send a signed out user from $location to sign in', () {
        expect(redirectFor(const SignedOut(), location), '/masuk');
      });

      test('send a user who is still loading from $location to loading', () {
        expect(redirectFor(const SessionLoading(), location), '/memuat');
      });

      for (final role in [UserRole.owner, UserRole.manager, UserRole.tenant]) {
        test('send an unverified $role from $location to verification', () {
          expect(
            redirectFor(_signedIn(role, verified: false), location),
            '/verifikasi-email',
          );
        });
      }
    }
  });
}
