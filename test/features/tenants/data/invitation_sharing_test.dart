import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';

void main() {
  group('invitationShareText', () {
    test('greets the first word of the name and carries the link', () {
      expect(
        invitationShareText(
          tenantName: 'Budi Santoso',
          url: 'https://niscala.example/undangan/abc123',
        ),
        'Halo Budi, ini tautan undangan untuk mengaktifkan akun Niscala Anda: '
        'https://niscala.example/undangan/abc123',
      );
    });

    test('greets a single name as it is', () {
      expect(
        invitationShareText(tenantName: 'Sari', url: 'https://x.test/u/1'),
        'Halo Sari, ini tautan undangan untuk mengaktifkan akun Niscala Anda: '
        'https://x.test/u/1',
      );
    });

    test('uses only the first word of a long name', () {
      expect(
        invitationShareText(
          tenantName: 'Putu Ayu Lestari Dewi',
          url: 'https://x.test/u/1',
        ),
        startsWith('Halo Putu, '),
      );
    });

    test('splits the name on any run of spaces', () {
      expect(
        invitationShareText(
          tenantName: 'Budi   Santoso',
          url: 'https://x.test/u/1',
        ),
        startsWith('Halo Budi, '),
      );
    });

    test('keeps the link unchanged at the end', () {
      const url = 'https://niscala.example/undangan/a-b_c~1?x=1&y=2';
      expect(
        invitationShareText(tenantName: 'Budi Santoso', url: url),
        endsWith(': $url'),
      );
    });
  });
}
