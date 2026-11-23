import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

const _homes = {
  UserRole.owner: '/beranda',
  UserRole.manager: '/beranda',
  UserRole.tenant: '/penyewa/beranda',
  UserRole.admin: '/admin',
};

const _invitationTargets = {
  UserRole.owner: '/beranda',
  UserRole.manager: '/akun/undangan?token=tok-1',
  UserRole.tenant: '/penyewa/akun/undangan?token=tok-1',
  UserRole.admin: '/admin',
};

SignedIn _verified(UserRole role) => SignedIn(role: role, emailVerified: true);

SignedIn _unverified(UserRole role) =>
    SignedIn(role: role, emailVerified: false);

/// The token that [location] carries in its query, decoded.
String? _tokenOf(String location) =>
    Uri.parse(location).queryParameters['token'];

void main() {
  group('isAppLink', () {
    const links = [
      '/invitations/abc',
      '/invitations/tok-1',
      '/invitations/a%20b',
      '/invitations/abc?utm=x',
      '/password-reset',
      '/password-reset?token=abc',
      '/password-reset?token=',
      '/password-reset?other=1',
      '/email-change',
      '/email-change?token=abc',
      '/email-change?token=',
    ];
    for (final link in links) {
      test('is true for $link', () {
        expect(isAppLink(Uri.parse(link)), isTrue);
      });
    }

    const others = [
      '/',
      '/invitations',
      '/invitations/',
      '/invitations/a/b',
      '/invitations/a/',
      '/invitation/abc',
      '/aktivasi',
      '/aktivasi?token=abc',
      '/atur-ulang-kata-sandi',
      '/atur-ulang-kata-sandi?token=abc',
      '/konfirmasi-email-baru',
      '/masuk',
      '/beranda',
      '/memuat',
      '/password-resets',
      '/email-changes',
      '/x/password-reset',
      '/x/email-change',
      '/penyewa/akun/undangan',
    ];
    for (final link in others) {
      test('is false for $link', () {
        expect(isAppLink(Uri.parse(link)), isFalse);
      });
    }
  });

  group('redirectForLink while the session loads', () {
    for (final link in [
      '/invitations/tok-1',
      '/password-reset?token=tok-1',
      '/email-change?token=tok-1',
    ]) {
      test('stays on $link', () {
        expect(
          redirectForLink(const SessionLoading(), Uri.parse(link)),
          isNull,
        );
      });
    }
  });

  group('redirectForLink for an invitation link', () {
    final link = Uri.parse('/invitations/tok-1');

    test('sends a signed out user to the activation screen', () {
      expect(redirectForLink(const SignedOut(), link), '/aktivasi?token=tok-1');
    });

    for (final role in UserRole.values) {
      test('sends a verified $role to ${_invitationTargets[role]}', () {
        expect(
          redirectForLink(_verified(role), link),
          _invitationTargets[role],
        );
      });

      test('sends an unverified $role to the email verification', () {
        expect(redirectForLink(_unverified(role), link), '/verifikasi-email');
      });
    }

    test('ignores a query on the invitation link', () {
      expect(
        redirectForLink(const SignedOut(), Uri.parse('/invitations/tok-1?x=1')),
        '/aktivasi?token=tok-1',
      );
    });

    test('puts a token with reserved characters in the query intact', () {
      final tokens = ['a&b=c', 'a b', 'a?b#c', 'a+b', 'ünï', 'a%b'];
      for (final token in tokens) {
        final uri = Uri(pathSegments: ['', 'invitations', token]);
        for (final session in [
          const SignedOut(),
          _verified(UserRole.tenant),
          _verified(UserRole.manager),
        ]) {
          final target = redirectForLink(session, uri)!;
          expect(
            _tokenOf(target),
            token,
            reason: '$token for $session gave $target',
          );
          expect(Uri.parse(target).queryParameters.keys, ['token']);
        }
      }
    });

    test('reads an encoded path segment back to the token', () {
      final target = redirectForLink(
        const SignedOut(),
        Uri.parse('/invitations/a%26b%20c'),
      )!;

      expect(Uri.parse(target).path, '/aktivasi');
      expect(_tokenOf(target), 'a&b c');
    });
  });

  group('redirectForLink for a password reset link', () {
    test('sends a signed out user to the reset screen with the token', () {
      expect(
        redirectForLink(
          const SignedOut(),
          Uri.parse('/password-reset?token=tok-1'),
        ),
        '/atur-ulang-kata-sandi?token=tok-1',
      );
    });

    for (final query in ['', '?token=', '?other=1', '?other=1&token=']) {
      test('sends a signed out user without a token to the bare screen '
          '(query "$query")', () {
        expect(
          redirectForLink(
            const SignedOut(),
            Uri.parse('/password-reset$query'),
          ),
          '/atur-ulang-kata-sandi',
        );
      });
    }

    test('puts a token with reserved characters in the query intact', () {
      for (final token in ['a&b=c', 'a b', 'a?b#c', 'a+b', 'a%b']) {
        final uri = Uri(
          path: '/password-reset',
          queryParameters: {'token': token},
        );
        final target = redirectForLink(const SignedOut(), uri)!;
        expect(Uri.parse(target).path, '/atur-ulang-kata-sandi');
        expect(_tokenOf(target), token, reason: target);
      }
    });

    test('ignores other query parameters when a token is present', () {
      final target = redirectForLink(
        const SignedOut(),
        Uri.parse('/password-reset?x=1&token=tok-1'),
      )!;

      expect(Uri.parse(target).path, '/atur-ulang-kata-sandi');
      expect(_tokenOf(target), 'tok-1');
    });

    for (final role in UserRole.values) {
      test('keeps a verified $role on the home', () {
        expect(
          redirectForLink(
            _verified(role),
            Uri.parse('/password-reset?token=tok-1'),
          ),
          _homes[role],
        );
      });

      test('sends an unverified $role to the email verification', () {
        expect(
          redirectForLink(
            _unverified(role),
            Uri.parse('/password-reset?token=tok-1'),
          ),
          '/verifikasi-email',
        );
      });
    }
  });

  group('redirectForLink for an email change link', () {
    test('sends a signed out user to the confirmation with the token', () {
      expect(
        redirectForLink(
          const SignedOut(),
          Uri.parse('/email-change?token=tok-1'),
        ),
        '/konfirmasi-email-baru?token=tok-1',
      );
    });

    for (final query in ['', '?token=', '?other=1', '?other=1&token=']) {
      test('sends a signed out user without a token to the bare screen '
          '(query "$query")', () {
        expect(
          redirectForLink(const SignedOut(), Uri.parse('/email-change$query')),
          '/konfirmasi-email-baru',
        );
      });
    }

    test('puts a token with reserved characters in the query intact', () {
      for (final token in ['a&b=c', 'a b', 'a?b#c', 'a+b', 'a%b']) {
        final uri = Uri(
          path: '/email-change',
          queryParameters: {'token': token},
        );
        final target = redirectForLink(const SignedOut(), uri)!;
        expect(Uri.parse(target).path, '/konfirmasi-email-baru');
        expect(_tokenOf(target), token, reason: target);
      }
    });

    for (final role in UserRole.values) {
      test('keeps a verified $role on the home', () {
        expect(
          redirectForLink(
            _verified(role),
            Uri.parse('/email-change?token=tok-1'),
          ),
          _homes[role],
        );
      });

      test('sends an unverified $role to the email verification', () {
        expect(
          redirectForLink(
            _unverified(role),
            Uri.parse('/email-change?token=tok-1'),
          ),
          '/verifikasi-email',
        );
      });
    }
  });

  group('redirectFor is unchanged for the screens that the links lead to', () {
    test('keeps a signed out user on the activation screen', () {
      expect(redirectFor(const SignedOut(), '/aktivasi'), isNull);
    });

    test('keeps a signed out user on the reset and confirmation screens', () {
      expect(redirectFor(const SignedOut(), '/atur-ulang-kata-sandi'), isNull);
      expect(redirectFor(const SignedOut(), '/konfirmasi-email-baru'), isNull);
    });

    test('keeps a tenant and a manager on their invitation screens', () {
      expect(
        redirectFor(_verified(UserRole.tenant), '/penyewa/akun/undangan'),
        isNull,
      );
      expect(
        redirectFor(_verified(UserRole.manager), '/akun/undangan'),
        isNull,
      );
    });
  });
}
