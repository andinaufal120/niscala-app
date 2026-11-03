import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

const _root = '/pembayaran';
const _subPaths = ['/pembayaran/penyewa/t1', '/pembayaran/tagihan/b1'];
const _paths = [_root, ..._subPaths];

SessionState _signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

void main() {
  group('a management user', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      for (final path in _paths) {
        test('a $role may stay on $path', () {
          expect(redirectFor(_signedIn(role), path), isNull);
        });
      }

      test('a $role is sent home from a look-alike path', () {
        expect(redirectFor(_signedIn(role), '/pembayaran-lain'), '/beranda');
      });

      test('a $role is sent home from the tenant payments', () {
        expect(redirectFor(_signedIn(role), '/penyewa/pembayaran'), '/beranda');
      });
    }
  });

  group('a tenant', () {
    for (final path in _paths) {
      test('is sent home from $path', () {
        expect(
          redirectFor(_signedIn(UserRole.tenant), path),
          '/penyewa/beranda',
        );
      });
    }

    test('may still stay on the tenant payments', () {
      expect(
        redirectFor(_signedIn(UserRole.tenant), '/penyewa/pembayaran'),
        isNull,
      );
    });
  });

  group('other sessions', () {
    for (final path in _paths) {
      test('sends an admin from $path to the admin home', () {
        expect(redirectFor(_signedIn(UserRole.admin), path), '/admin');
      });

      test('sends a signed out user from $path to sign in', () {
        expect(redirectFor(const SignedOut(), path), '/masuk');
      });

      test('sends a loading session from $path to the loading screen', () {
        expect(redirectFor(SessionLoading(), path), '/memuat');
      });

      for (final role in UserRole.values) {
        test('sends an unverified $role from $path to verification', () {
          expect(
            redirectFor(_signedIn(role, verified: false), path),
            '/verifikasi-email',
          );
        });
      }
    }
  });
}
