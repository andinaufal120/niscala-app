import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/auth/link_token.dart';

void main() {
  group('tokenFromQueryLink', () {
    test('reads the token of a password reset link', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset?token=abc'),
        'abc',
      );
    });

    test('reads the token of an email change link', () {
      expect(
        tokenFromQueryLink('https://niscala.app/email-change?token=abc'),
        'abc',
      );
    });

    test('reads the token of a link without a scheme', () {
      expect(tokenFromQueryLink('niscala.app/password-reset?token=abc'), 'abc');
    });

    test('reads the token of a link with another scheme', () {
      expect(tokenFromQueryLink('niscala://password-reset?token=abc'), 'abc');
    });

    test('reads the token of a query without a path', () {
      expect(tokenFromQueryLink('?token=abc'), 'abc');
    });

    test('keeps the characters of a long token', () {
      expect(
        tokenFromQueryLink(
          'https://niscala.app/password-reset?token=Ab_9-Zz0123456789xyz',
        ),
        'Ab_9-Zz0123456789xyz',
      );
    });

    test('trims whitespace and line breaks around a link', () {
      expect(
        tokenFromQueryLink(
          '  \n https://niscala.app/password-reset?token=abc \t\n',
        ),
        'abc',
      );
    });

    test('ignores the fragment', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset?token=abc#top'),
        'abc',
      );
    });

    test('ignores query parameters before the token', () {
      expect(
        tokenFromQueryLink(
          'https://niscala.app/password-reset?utm_source=wa&token=abc',
        ),
        'abc',
      );
    });

    test('ignores query parameters after the token', () {
      expect(
        tokenFromQueryLink(
          'https://niscala.app/password-reset?token=abc&utm_source=wa&x=y',
        ),
        'abc',
      );
    });

    test('ignores a trailing slash before the query', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset/?token=abc'),
        'abc',
      );
    });

    test('decodes a percent-encoded token', () {
      expect(
        tokenFromQueryLink(
          'https://niscala.app/password-reset?token=a%2Bb%7Ec',
        ),
        'a+b~c',
      );
    });

    test('returns a bare token unchanged', () {
      expect(tokenFromQueryLink('abc'), 'abc');
    });

    test('keeps the characters of a bare token', () {
      expect(
        tokenFromQueryLink('Ab_9-Zz0123456789xyz'),
        'Ab_9-Zz0123456789xyz',
      );
    });

    test('trims a bare token', () {
      expect(tokenFromQueryLink('  abc\n'), 'abc');
    });

    test('returns null for an empty input', () {
      expect(tokenFromQueryLink(''), isNull);
    });

    test('returns null for whitespace only', () {
      expect(tokenFromQueryLink('   \n\t '), isNull);
    });

    test('returns null for a link without a query', () {
      expect(tokenFromQueryLink('https://niscala.app/password-reset'), isNull);
    });

    test('returns null for a link without a token parameter', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset?other=1'),
        isNull,
      );
    });

    test('returns null for a token parameter without a value', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset?token='),
        isNull,
      );
    });

    test('returns null for a token parameter without an equals sign', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset?token'),
        isNull,
      );
    });

    test('does not take the last path segment as the token', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset/abc'),
        isNull,
      );
    });

    test('does not take a token from the fragment', () {
      expect(
        tokenFromQueryLink('https://niscala.app/password-reset#token=abc'),
        isNull,
      );
    });

    test('returns null for a link of slashes only', () {
      expect(tokenFromQueryLink('///'), isNull);
    });

    test('does not throw on a malformed percent escape', () {
      expect(
        () =>
            tokenFromQueryLink('https://niscala.app/password-reset?token=%zz'),
        returnsNormally,
      );
    });
  });
}
