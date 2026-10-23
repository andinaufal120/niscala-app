import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

const _paths = [
  '/penyewa/pembayaran',
  '/penyewa/pembayaran/unggah/b1',
  '/penyewa/pembayaran/bukti/b1',
];

SessionState _signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

void main() {
  group('a tenant', () {
    for (final path in _paths) {
      test('may stay on $path', () {
        expect(redirectFor(_signedIn(UserRole.tenant), path), isNull);
      });
    }

    test('is sent home from a look-alike path', () {
      expect(
        redirectFor(_signedIn(UserRole.tenant), '/penyewa/pembayaran-lain'),
        '/penyewa/beranda',
      );
    });
  });

  group('other sessions', () {
    for (final path in _paths.skip(1)) {
      for (final role in [UserRole.owner, UserRole.manager]) {
        test('sends a $role from $path to the management home', () {
          expect(redirectFor(_signedIn(role), path), '/beranda');
        });
      }

      test('sends an admin from $path to the admin home', () {
        expect(redirectFor(_signedIn(UserRole.admin), path), '/admin');
      });

      test('sends a signed out user from $path to sign in', () {
        expect(redirectFor(const SignedOut(), path), '/masuk');
      });

      test('sends an unverified tenant from $path to verification', () {
        expect(
          redirectFor(_signedIn(UserRole.tenant, verified: false), path),
          '/verifikasi-email',
        );
      });
    }
  });
}
