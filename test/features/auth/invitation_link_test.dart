import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/auth/invitation_link.dart';

void main() {
  group('invitationTokenFromLink', () {
    test('takes the last path segment of a link', () {
      expect(
        invitationTokenFromLink('https://niscala.example/undangan/abc123'),
        'abc123',
      );
    });

    test('takes the last path segment of a link with a deeper path', () {
      expect(
        invitationTokenFromLink('https://niscala.example/a/b/c/tok-en_9'),
        'tok-en_9',
      );
    });

    test('ignores a trailing slash', () {
      expect(
        invitationTokenFromLink('https://niscala.example/undangan/abc123/'),
        'abc123',
      );
    });

    test('ignores several trailing slashes', () {
      expect(
        invitationTokenFromLink('https://niscala.example/undangan/abc123//'),
        'abc123',
      );
    });

    test('ignores the query', () {
      expect(
        invitationTokenFromLink(
          'https://niscala.example/undangan/abc123?utm_source=wa&x=y',
        ),
        'abc123',
      );
    });

    test('ignores the fragment', () {
      expect(
        invitationTokenFromLink('https://niscala.example/undangan/abc123#top'),
        'abc123',
      );
    });

    test('ignores a trailing slash followed by a query', () {
      expect(
        invitationTokenFromLink('https://niscala.example/undangan/abc123/?a=b'),
        'abc123',
      );
    });

    test('trims whitespace around a link', () {
      expect(
        invitationTokenFromLink(
          '  \n https://niscala.example/undangan/abc123 \t ',
        ),
        'abc123',
      );
    });

    test('reads a link with another scheme', () {
      expect(invitationTokenFromLink('niscala://undangan/abc123'), 'abc123');
    });

    test('reads a link without a scheme', () {
      expect(
        invitationTokenFromLink('niscala.example/undangan/abc123'),
        'abc123',
      );
    });

    test('keeps the characters of the token', () {
      expect(
        invitationTokenFromLink('https://niscala.example/undangan/Ab_9-Zz'),
        'Ab_9-Zz',
      );
    });

    test('returns a bare token unchanged', () {
      expect(invitationTokenFromLink('abc123'), 'abc123');
    });

    test('trims a bare token', () {
      expect(invitationTokenFromLink('  abc123\n'), 'abc123');
    });

    test('returns null for an empty input', () {
      expect(invitationTokenFromLink(''), isNull);
    });

    test('returns null for whitespace only', () {
      expect(invitationTokenFromLink('   \n\t '), isNull);
    });

    test('returns null when the input has no path segment', () {
      expect(invitationTokenFromLink('///'), isNull);
    });

    test('returns null for a query without a path', () {
      expect(invitationTokenFromLink('?token=abc123'), isNull);
    });
  });
}
