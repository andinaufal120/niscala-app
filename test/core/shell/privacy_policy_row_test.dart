import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/external_link.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_card_row.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _title = 'Kebijakan Privasi';
const _subtitle = 'Baca bagaimana Niscala memakai data Anda';
const _hint = 'Membuka di peramban';
const _failureTitle = 'Halaman tidak bisa dibuka';
const _failureMessage = 'Tidak dapat membuka halaman. Coba lagi.';

Finder _row() =>
    find.ancestor(of: find.text(_title), matching: find.byType(ActionCardRow));

Finder _dialog() => find.byType(AlertDialog);

void main() {
  group('the privacy policy address', () {
    test('is the published page over https', () {
      expect(privacyPolicyUri.scheme, 'https');
      expect(privacyPolicyUri.host, 'niscala.andinaufal.com');
      expect(privacyPolicyUri.path, '/privacy/');
      expect(
        privacyPolicyUri,
        Uri.parse('https://niscala.andinaufal.com/privacy/'),
      );
    });
  });

  group('the Kebijakan Privasi row', () {
    for (final role in _roles) {
      testWidgets('is shown to a $role with its subtitle and icons', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(find.text(_title), findsOneWidget);
        expect(find.text(_subtitle), findsOneWidget);
        expect(_row(), findsOneWidget);
        expect(
          find.descendant(
            of: _row(),
            matching: find.byIcon(Icons.privacy_tip_outlined),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _row(), matching: find.byIcon(Icons.open_in_new)),
          findsOneWidget,
        );
      });

      testWidgets('shows no chevron for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(
          find.descendant(
            of: _row(),
            matching: find.byIcon(Icons.chevron_right),
          ),
          findsNothing,
        );
      });

      testWidgets('sits between Keamanan and Hapus akun for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        final top = tester.getTopLeft(find.text(_title)).dy;
        expect(
          top,
          greaterThan(tester.getBottomLeft(find.text('Perangkat aktif')).dy),
        );
        expect(top, lessThan(tester.getTopLeft(find.text('Hapus akun')).dy));
      });

      testWidgets('scrolls with the content of the tab for a $role', (
        tester,
      ) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        expect(
          find.ancestor(
            of: find.text(_title),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );
      });

      testWidgets('is one button of at least 48 dp that opens in the browser '
          'for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        final handle = tester.ensureSemantics();
        try {
          final node = tester.getSemantics(find.text(_title));
          expect(node, isSemantics(isButton: true, hasTapAction: true));
          expect(node.label, contains(_title));
          expect('${node.label} ${node.hint}', contains(_hint));
          expect(node.rect.height, greaterThanOrEqualTo(48));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('opens the policy page once and stays in the app for a '
          '$role', (tester) async {
        final links = FakeExternalLinkOpener();
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          role: role,
          externalLinks: links,
        );

        await tapVisible(tester, find.text(_title));

        expect(links.opened, [privacyPolicyUri]);
        expect(currentPath(tester), accountPath(role));
        expect(find.text('Keluar'), findsOneWidget);
        expect(_dialog(), findsNothing);
      });
    }

    testWidgets('does not open anything while the tab is shown', (
      tester,
    ) async {
      final links = FakeExternalLinkOpener();
      await pumpAccountApp(
        tester,
        FakeAccountRepository(),
        externalLinks: links,
      );

      expect(links.opened, isEmpty);
    });

    testWidgets('opens the page once for each tap', (tester) async {
      final links = FakeExternalLinkOpener();
      await pumpAccountApp(
        tester,
        FakeAccountRepository(),
        externalLinks: links,
      );

      await tapVisible(tester, find.text(_title));
      await tapVisible(tester, find.text(_title));

      expect(links.opened, [privacyPolicyUri, privacyPolicyUri]);
      expect(_dialog(), findsNothing);
    });

    testWidgets('keeps the chevron on the other rows', (tester) async {
      await pumpAccountApp(tester, FakeAccountRepository());

      for (final title in ['Notifikasi', 'Perangkat aktif', 'Hapus akun']) {
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text(title),
              matching: find.byType(ActionCardRow),
            ),
            matching: find.byIcon(Icons.chevron_right),
          ),
          findsOneWidget,
          reason: title,
        );
      }
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('shows a plain action card row with a chevron by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        themedApp(
          Scaffold(
            body: ActionCardRow(
              icon: Icons.mail_outline,
              title: 'Judul',
              subtitle: 'Keterangan',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('is not shown to an admin', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRoleProvider.overrideWithValue(UserRole.admin),
            externalLinkOpenerProvider.overrideWithValue(
              FakeExternalLinkOpener(),
            ),
            accountRepositoryProvider.overrideWithValue(
              FakeAccountRepository(account: makeAccount(role: UserRole.admin)),
            ),
          ],
          child: themedApp(const AccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_title), findsNothing);
      expect(find.text(_subtitle), findsNothing);
    });
  });

  group('when the page cannot be opened', () {
    for (final scenario in <(String, void Function(FakeExternalLinkOpener))>[
      ('the opener answers false', (links) => links.result = false),
      ('the opener throws', (links) => links.failure = Exception('no browser')),
    ]) {
      testWidgets('shows the failure dialog when ${scenario.$1}', (
        tester,
      ) async {
        final links = FakeExternalLinkOpener();
        scenario.$2(links);
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          externalLinks: links,
        );

        await tapVisible(tester, find.text(_title));

        expect(links.opened, [privacyPolicyUri]);
        expect(_dialog(), findsOneWidget);
        expect(
          find.descendant(of: _dialog(), matching: find.text(_failureTitle)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _dialog(), matching: find.text(_failureMessage)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _dialog(), matching: find.text('Mengerti')),
          findsOneWidget,
        );
      });

      testWidgets('closes the dialog with Mengerti and changes nothing when '
          '${scenario.$1}', (tester) async {
        final links = FakeExternalLinkOpener();
        scenario.$2(links);
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          externalLinks: links,
        );
        await tapVisible(tester, find.text(_title));

        await tester.tap(find.text('Mengerti'));
        await tester.pumpAndSettle();

        expect(_dialog(), findsNothing);
        expect(links.opened, [privacyPolicyUri]);
        expect(currentPath(tester), accountPath(UserRole.owner));
        expect(find.text(_title), findsOneWidget);
        expect(find.text('Keluar'), findsOneWidget);
      });

      testWidgets('tries again on the next tap when ${scenario.$1}', (
        tester,
      ) async {
        final links = FakeExternalLinkOpener();
        scenario.$2(links);
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          externalLinks: links,
        );
        await tapVisible(tester, find.text(_title));
        await tester.tap(find.text('Mengerti'));
        await tester.pumpAndSettle();

        await tapVisible(tester, find.text(_title));

        expect(links.opened, [privacyPolicyUri, privacyPolicyUri]);
        expect(_dialog(), findsOneWidget);
      });

      testWidgets('keeps the failure dialog accessible when '
          '${scenario.$1}', (tester) async {
        final links = FakeExternalLinkOpener();
        scenario.$2(links);
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          externalLinks: links,
        );
        await tapVisible(tester, find.text(_title));

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('keeps the failure dialog free of overflow at large text '
          'when ${scenario.$1}', (tester) async {
        final links = FakeExternalLinkOpener();
        scenario.$2(links);
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          externalLinks: links,
          largeText: true,
        );
        await tapVisible(tester, find.text(_title));

        expect(_dialog(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows no dialog after a retry that succeeds', (tester) async {
      final links = FakeExternalLinkOpener()..result = false;
      await pumpAccountApp(
        tester,
        FakeAccountRepository(),
        externalLinks: links,
      );
      await tapVisible(tester, find.text(_title));
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      links.result = true;
      await tapVisible(tester, find.text(_title));

      expect(links.opened, [privacyPolicyUri, privacyPolicyUri]);
      expect(_dialog(), findsNothing);
    });
  });

  group('the tab with the Kebijakan Privasi row', () {
    for (final role in _roles) {
      testWidgets('is accessible for a $role', (tester) async {
        await pumpAccountApp(tester, FakeAccountRepository(), role: role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('is free of overflow for a $role at large text', (
        tester,
      ) async {
        await pumpAccountApp(
          tester,
          FakeAccountRepository(),
          role: role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_title), findsOneWidget);
      });
    }
  });
}
