import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

SessionState signedIn(UserRole role, {bool verified = true}) =>
    SignedIn(role: role, emailVerified: verified);

void main() {
  group('redirectFor while loading', () {
    test('stays on the loading route', () {
      expect(redirectFor(const SessionLoading(), '/memuat'), isNull);
    });

    for (final location in ['/masuk', '/beranda', '/', '/daftar', '/admin']) {
      test('sends $location to the loading route', () {
        expect(redirectFor(const SessionLoading(), location), '/memuat');
      });
    }
  });

  group('redirectFor when signed out', () {
    for (final location in ['/masuk', '/daftar', '/aktivasi']) {
      test('keeps the user on $location', () {
        expect(redirectFor(const SignedOut(), location), isNull);
      });
    }

    for (final location in [
      '/',
      '/memuat',
      '/beranda',
      '/properti',
      '/akun',
      '/penyewa/beranda',
      '/admin',
      '/verifikasi-email',
    ]) {
      test('sends $location to sign in', () {
        expect(redirectFor(const SignedOut(), location), '/masuk');
      });
    }
  });

  group('redirectFor with an unverified email', () {
    for (final role in [
      UserRole.owner,
      UserRole.manager,
      UserRole.tenant,
      UserRole.admin,
    ]) {
      test('keeps a $role on the verification route', () {
        expect(
          redirectFor(signedIn(role, verified: false), '/verifikasi-email'),
          isNull,
        );
      });

      for (final location in ['/beranda', '/penyewa/beranda', '/masuk', '/']) {
        test('sends a $role from $location to verification', () {
          expect(
            redirectFor(signedIn(role, verified: false), location),
            '/verifikasi-email',
          );
        });
      }
    }
  });

  group('redirectFor sends a verified account home', () {
    const homes = {
      UserRole.owner: '/beranda',
      UserRole.manager: '/beranda',
      UserRole.tenant: '/penyewa/beranda',
      UserRole.admin: '/admin',
    };
    const entryRoutes = [
      '/memuat',
      '/masuk',
      '/daftar',
      '/aktivasi',
      '/verifikasi-email',
      '/',
    ];

    for (final entry in homes.entries) {
      for (final location in entryRoutes) {
        test('${entry.key} from $location goes to ${entry.value}', () {
          expect(redirectFor(signedIn(entry.key), location), entry.value);
        });
      }

      test('${entry.key} stays on ${entry.value}', () {
        expect(redirectFor(signedIn(entry.key), entry.value), isNull);
      });
    }
  });

  group('redirectFor keeps roles in their own area', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      for (final location in [
        '/penyewa/beranda',
        '/penyewa/keluhan',
        '/penyewa/pembayaran',
        '/penyewa/akun',
        '/admin',
      ]) {
        test('$role at $location goes to the management home', () {
          expect(redirectFor(signedIn(role), location), '/beranda');
        });
      }

      for (final location in [
        '/beranda',
        '/keluhan',
        '/pembayaran',
        '/properti',
        '/akun',
      ]) {
        test('$role may stay at $location', () {
          expect(redirectFor(signedIn(role), location), isNull);
        });
      }
    }

    for (final location in [
      '/beranda',
      '/keluhan',
      '/pembayaran',
      '/properti',
      '/akun',
    ]) {
      test('a tenant at $location goes to the tenant home', () {
        expect(
          redirectFor(signedIn(UserRole.tenant), location),
          '/penyewa/beranda',
        );
      });
    }

    const propertyRoutes = [
      '/properti/tambah',
      '/properti/p1',
      '/properti/p1/ubah',
      '/properti/p1/kamar',
      '/properti/p1/kamar/tambah',
      '/properti/p1/kamar/r1',
      '/properti/p1/kamar/r1/ubah',
    ];

    for (final role in [UserRole.owner, UserRole.manager]) {
      for (final location in propertyRoutes) {
        test('$role may stay at $location', () {
          expect(redirectFor(signedIn(role), location), isNull);
        });
      }
    }

    for (final location in propertyRoutes) {
      test('a tenant at $location goes to the tenant home', () {
        expect(
          redirectFor(signedIn(UserRole.tenant), location),
          '/penyewa/beranda',
        );
      });

      test('an admin at $location goes to the admin home', () {
        expect(redirectFor(signedIn(UserRole.admin), location), '/admin');
      });

      test('a signed out user at $location goes to sign in', () {
        expect(redirectFor(const SignedOut(), location), '/masuk');
      });
    }

    for (final location in [
      '/penyewa/beranda',
      '/penyewa/keluhan',
      '/penyewa/pembayaran',
      '/penyewa/akun',
    ]) {
      test('a tenant may stay at $location', () {
        expect(redirectFor(signedIn(UserRole.tenant), location), isNull);
      });
    }
  });
}
