import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/auth/password_strength.dart';

/// A password of exactly [length] characters that matches no weak rule.
String strongOfLength(int length) => ('x7Kq' * 10).substring(0, length);

void main() {
  group('passwordStrength', () {
    test('is none for an empty password', () {
      expect(passwordStrength(''), PasswordStrength.none);
    });

    test(
      'is none for an empty password even when name and email are given',
      () {
        expect(
          passwordStrength('', name: 'Budi Santoso', email: 'budi@example.com'),
          PasswordStrength.none,
        );
      },
    );

    group('weak', () {
      test('when shorter than 8 characters', () {
        expect(passwordStrength('x7Kqx7K'), PasswordStrength.weak);
        expect(passwordStrength('a'), PasswordStrength.weak);
      });

      for (final common in [
        '12345678',
        'password',
        'password123',
        'qwerty123',
        'niscala123',
        'bismillah',
      ]) {
        test('for the common password $common', () {
          expect(passwordStrength(common), PasswordStrength.weak);
        });
      }

      test('for a common password in other letter case', () {
        expect(passwordStrength('PassWord123'), PasswordStrength.weak);
        expect(passwordStrength('BISMILLAH'), PasswordStrength.weak);
      });

      test('when it contains niscala in any letter case', () {
        expect(passwordStrength('my-niscala-secret-9'), PasswordStrength.weak);
        expect(passwordStrength('xx-NiScAlA-x7Kq-9'), PasswordStrength.weak);
      });

      test('when it contains the first word of the name', () {
        expect(
          passwordStrength('xx-budi-x7Kq-9', name: 'Budi Santoso'),
          PasswordStrength.weak,
        );
      });

      test('when it contains the first word of the name in other case', () {
        expect(
          passwordStrength('xx-BUDI-x7Kq-9', name: 'budi santoso'),
          PasswordStrength.weak,
        );
      });

      test('ignores a first word of the name shorter than 4 characters', () {
        expect(
          passwordStrength('xx-ani-x7Kq-9', name: 'Ani Putri'),
          PasswordStrength.strong,
        );
      });

      test('only looks at the first word of the name', () {
        expect(
          passwordStrength('xx-santoso-x7Kq', name: 'Budi Santoso'),
          isNot(PasswordStrength.weak),
        );
      });

      test('when it contains the email local part', () {
        expect(
          passwordStrength('xx-andi.naufal-9', email: 'andi.naufal@mail.com'),
          PasswordStrength.weak,
        );
      });

      test('when it contains the email local part in other case', () {
        expect(
          passwordStrength('xx-BUDI99-x7Kq', email: 'Budi99@mail.com'),
          PasswordStrength.weak,
        );
      });

      test('ignores an email local part shorter than 4 characters', () {
        expect(
          passwordStrength('xx-abc-x7Kq-9', email: 'abc@mail.com'),
          PasswordStrength.strong,
        );
      });

      test('does not match the email domain', () {
        expect(
          passwordStrength('xx-example-x7Kq', email: 'budi@example.com'),
          isNot(PasswordStrength.weak),
        );
      });

      test('when it is one repeated character', () {
        expect(passwordStrength('aaaaaaaa'), PasswordStrength.weak);
        expect(passwordStrength('zzzzzzzzzzzzzzzzzz'), PasswordStrength.weak);
        expect(passwordStrength('77777777777'), PasswordStrength.weak);
      });

      test('when it is an ascending run', () {
        expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
        expect(passwordStrength('23456789'), PasswordStrength.weak);
        expect(passwordStrength('0123456789'), PasswordStrength.weak);
        expect(
          passwordStrength('abcdefghijklmnopqrstuvwxyz'),
          PasswordStrength.weak,
        );
      });

      test('when it is a descending run', () {
        expect(passwordStrength('hgfedcba'), PasswordStrength.weak);
        expect(passwordStrength('87654321'), PasswordStrength.weak);
        expect(passwordStrength('9876543210'), PasswordStrength.weak);
        expect(
          passwordStrength('zyxwvutsrqponmlkjihgfedcba'),
          PasswordStrength.weak,
        );
      });

      test('when a run is typed in capital letters', () {
        expect(passwordStrength('ABCDEFGH'), PasswordStrength.weak);
        expect(passwordStrength('HGFEDCBA'), PasswordStrength.weak);
      });

      test('is not triggered by a run that wraps around the alphabet', () {
        expect(passwordStrength('xyzabcde'), PasswordStrength.fair);
      });

      test('is not triggered by a run with a gap', () {
        expect(passwordStrength('abcdefgz'), PasswordStrength.fair);
      });
    });

    group('length bands for a password with no weak pattern', () {
      test('is fair from 8 to 11 characters', () {
        expect(passwordStrength(strongOfLength(8)), PasswordStrength.fair);
        expect(passwordStrength(strongOfLength(11)), PasswordStrength.fair);
      });

      test('is strong from 12 to 15 characters', () {
        expect(passwordStrength(strongOfLength(12)), PasswordStrength.strong);
        expect(passwordStrength(strongOfLength(15)), PasswordStrength.strong);
      });

      test('is very strong from 16 characters', () {
        expect(
          passwordStrength(strongOfLength(16)),
          PasswordStrength.veryStrong,
        );
        expect(
          passwordStrength(strongOfLength(40)),
          PasswordStrength.veryStrong,
        );
      });

      test('accepts a long sentence with spaces', () {
        expect(
          passwordStrength('kopi tubruk di pagi hari'),
          PasswordStrength.veryStrong,
        );
      });
    });

    test('an empty name and email never make a password weak', () {
      expect(
        passwordStrength(strongOfLength(12), name: '', email: ''),
        PasswordStrength.strong,
      );
    });

    test('weak patterns win over length', () {
      expect(
        passwordStrength('niscala-niscala-niscala'),
        PasswordStrength.weak,
      );
      expect(passwordStrength('a' * 30), PasswordStrength.weak);
    });
  });

  group('passwordStrengthText', () {
    test('invites typing for an empty password', () {
      expect(
        passwordStrengthText(''),
        'Kekuatan kata sandi akan muncul saat Anda mengetik.',
      );
    });

    test('says too short for a weak password under 8 characters', () {
      expect(passwordStrengthText('abc'), 'Kekuatan: Lemah · terlalu pendek');
      expect(
        passwordStrengthText('x7Kqx7K'),
        'Kekuatan: Lemah · terlalu pendek',
      );
    });

    test('says easy to guess for a weak password of 8 or more characters', () {
      expect(
        passwordStrengthText('password123'),
        'Kekuatan: Lemah · mudah ditebak',
      );
      expect(
        passwordStrengthText('abcdefgh'),
        'Kekuatan: Lemah · mudah ditebak',
      );
    });

    test('says easy to guess when the password contains the name', () {
      expect(
        passwordStrengthText('xx-budi-x7Kq-9', name: 'Budi Santoso'),
        'Kekuatan: Lemah · mudah ditebak',
      );
    });

    test('describes a fair password', () {
      expect(
        passwordStrengthText(strongOfLength(9)),
        'Kekuatan: Cukup · tambah panjangnya agar lebih aman',
      );
    });

    test('describes a strong password', () {
      expect(
        passwordStrengthText(strongOfLength(13)),
        'Kekuatan: Kuat · sudah aman',
      );
    });

    test('describes a very strong password', () {
      expect(
        passwordStrengthText(strongOfLength(20)),
        'Kekuatan: Sangat kuat · sangat sulit ditebak',
      );
    });
  });
}
