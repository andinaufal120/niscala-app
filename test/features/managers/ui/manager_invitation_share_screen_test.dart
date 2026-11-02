import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/managers/ui/manager_invitation_qr_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_share_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'manager_ui_helpers.dart';

const _url = 'https://niscala.example/undangan/abc123';
const _unavailable = 'Tautan undangan belum tersedia.';
const _regenerate = 'Buat Ulang Tautan Undangan';

Manager _manager({
  ManagerInvitation? invitation,
  bool withoutInvitation = false,
  String? nickname,
}) => makeManager(
  id: 'm1',
  name: 'Rina Putri',
  nickname: nickname,
  phone: '081255204471',
  invitation: invitation,
  withoutInvitation: withoutInvitation,
);

FakeManagerRepository _repo([Manager? manager]) =>
    FakeManagerRepository(managers: [manager ?? _manager()]);

Future<void> _open(
  WidgetTester tester,
  FakeManagerRepository repo, {
  bool isNew = false,
  UserRole role = UserRole.owner,
  ShareRecorder? sharer,
  bool settle = true,
  bool largeText = false,
}) => pumpManagerApp(
  tester,
  repo,
  role: role,
  sharer: sharer,
  path: '/properti/p1/pengelola/m1/undangan${isNew ? '?baru=1' : ''}',
  settle: settle,
  largeText: largeText,
);

/// Runs [body] with semantics on, so that finders by semantics label work.
void _withSemantics(WidgetTester tester, void Function() body) {
  final handle = tester.ensureSemantics();
  try {
    body();
  } finally {
    handle.dispose();
  }
}

void main() {
  group('content', () {
    testWidgets('loads the manager by its id', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
      expect(repo.calls, contains('get:m1'));
    });

    testWidgets('a new manager gets the heading Pengelola ditambahkan', (
      tester,
    ) async {
      await _open(tester, _repo(), isNew: true);

      expect(find.text('Pengelola ditambahkan'), findsOneWidget);
    });

    testWidgets('an existing manager gets the heading Tautan undangan', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Pengelola ditambahkan'), findsNothing);
      expect(find.text('Tautan undangan'), findsNWidgets(2));
    });

    testWidgets('the heading is a header', (tester) async {
      await _open(tester, _repo(), isNew: true);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Pengelola ditambahkan')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('says who to share the link with', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('Rina Putri'), findsAtLeastNWidgets(1));
      expect(find.textContaining('081255204471'), findsAtLeastNWidgets(1));
    });

    testWidgets('uses the name and phone of the loaded manager', (
      tester,
    ) async {
      final manager = makeManager(
        id: 'm1',
        name: 'Tono Wijaya',
        phone: '081300000001',
      );
      await _open(tester, _repo(manager));

      expect(find.textContaining('Tono Wijaya'), findsAtLeastNWidgets(1));
      expect(find.textContaining('081300000001'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Rina Putri'), findsNothing);
    });

    testWidgets('the link card shows the link as selectable text', (
      tester,
    ) async {
      await _open(tester, _repo(), isNew: true);

      expect(find.text('Tautan undangan'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        _url,
      );
    });

    testWidgets(
      'the card says until when the link works and that it is single use',
      (tester) async {
        await _open(tester, _repo());

        expect(
          find.text('Berlaku hingga 25 Okt 2026 · sekali pakai'),
          findsOneWidget,
        );
      },
    );

    testWidgets('the expiry follows the invitation', (tester) async {
      final invitation = makeManagerInvitation(
        expiresAt: DateTime.utc(2026, 11, 3, 12),
      );
      await _open(tester, _repo(_manager(invitation: invitation)));

      expect(
        find.text('Berlaku hingga 3 Nov 2026 · sekali pakai'),
        findsOneWidget,
      );
    });

    testWidgets('shows the link of the loaded invitation', (tester) async {
      final invitation = makeManagerInvitation(
        url: 'https://niscala.example/undangan/zzz999',
      );
      await _open(tester, _repo(_manager(invitation: invitation)));

      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/zzz999',
      );
    });

    testWidgets('offers copy, WhatsApp, QR code and finish', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Salin'), findsOneWidget);
      expect(find.text('Bagikan via WhatsApp'), findsOneWidget);
      expect(find.text('Tampilkan kode QR'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('the copy button is spoken as Salin tautan undangan', (
      tester,
    ) async {
      await _open(tester, _repo());

      _withSemantics(tester, () {
        expect(find.bySemanticsLabel('Salin tautan undangan'), findsOneWidget);
      });
    });
  });

  group('target sizes', () {
    testWidgets('the close button is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expectFinderTargetSize(tester, find.byTooltip('Tutup'));
    });

    testWidgets('the copy button is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      _withSemantics(tester, () {
        final rect = tester
            .getSemantics(find.bySemanticsLabel('Salin tautan undangan'))
            .rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      });
    });

    for (final label in [
      'Bagikan via WhatsApp',
      'Tampilkan kode QR',
      'Selesai',
    ]) {
      testWidgets('$label is at least 48 dp', (tester) async {
        await _open(tester, _repo());

        expectTargetSize(tester, label);
      });
    }
  });

  group('copy', () {
    testWidgets('Salin copies the link to the clipboard', (tester) async {
      final clipboard = ClipboardRecorder(tester);
      await _open(tester, _repo());

      await tester.tap(find.text('Salin'));
      await tester.pumpAndSettle();

      expect(clipboard.copied, [_url]);
    });

    testWidgets('confirms nothing before the link is copied', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Tautan disalin.'), findsNothing);
    });

    testWidgets('confirms the copy with a text', (tester) async {
      ClipboardRecorder(tester);
      await _open(tester, _repo());

      await tester.tap(find.text('Salin'));
      await tester.pumpAndSettle();

      expect(find.text('Tautan disalin.'), findsOneWidget);
    });

    testWidgets('announces the confirmation as a live region', (tester) async {
      ClipboardRecorder(tester);
      await _open(tester, _repo());
      await tester.tap(find.text('Salin'));
      await tester.pumpAndSettle();

      expectLiveRegion(tester, 'Tautan disalin.');
    });

    testWidgets('the confirmation stays on screen', (tester) async {
      ClipboardRecorder(tester);
      await _open(tester, _repo());
      await tester.tap(find.text('Salin'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text('Tautan disalin.'), findsOneWidget);
    });

    testWidgets('copying shares and navigates nowhere', (tester) async {
      ClipboardRecorder(tester);
      final sharer = ShareRecorder();
      await _open(tester, _repo(), sharer: sharer);

      await tester.tap(find.text('Salin'));
      await tester.pumpAndSettle();

      expect(sharer.texts, isEmpty);
      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
    });
  });

  group('sharing', () {
    testWidgets('Bagikan via WhatsApp hands a greeting with the link over', (
      tester,
    ) async {
      final sharer = ShareRecorder();
      await _open(tester, _repo(), sharer: sharer);

      await tester.tap(find.text('Bagikan via WhatsApp'));
      await tester.pumpAndSettle();

      expect(sharer.texts, hasLength(1));
      expect(sharer.texts.single, startsWith('Halo Rina, '));
      expect(sharer.texts.single, endsWith(': $_url'));
    });

    testWidgets('the text carries the link unchanged', (tester) async {
      const url = 'https://niscala.example/undangan/a-b_c~1?x=1&y=2';
      final sharer = ShareRecorder();
      await _open(
        tester,
        _repo(_manager(invitation: makeManagerInvitation(url: url))),
        sharer: sharer,
      );

      await tester.tap(find.text('Bagikan via WhatsApp'));
      await tester.pumpAndSettle();

      expect(sharer.texts.single, endsWith(url));
    });

    testWidgets('shares once per tap', (tester) async {
      final sharer = ShareRecorder();
      await _open(tester, _repo(), sharer: sharer);

      await tester.tap(find.text('Bagikan via WhatsApp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bagikan via WhatsApp'));
      await tester.pumpAndSettle();

      expect(sharer.texts, hasLength(2));
    });

    testWidgets('sharing does not leave the screen', (tester) async {
      await _open(tester, _repo(), sharer: ShareRecorder());

      await tester.tap(find.text('Bagikan via WhatsApp'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Tampilkan kode QR opens the QR screen', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text('Tampilkan kode QR'));

      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan/qr');
      final qr = tester.widget<ManagerInvitationQrScreen>(
        find.byType(ManagerInvitationQrScreen),
      );
      expect(qr.propertyId, 'p1');
      expect(qr.managerId, 'm1');
    });

    testWidgets('Selesai goes to the manager list', (tester) async {
      await _open(tester, _repo(), isNew: true);

      await tapVisible(tester, find.text('Selesai'));

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
      expect(find.byType(ManagerInvitationShareScreen), findsNothing);
    });

    testWidgets('the close button goes to the manager list', (tester) async {
      await _open(tester, _repo(), isNew: true);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
    });

    testWidgets('the list shows the manager after Selesai', (tester) async {
      await _open(tester, _repo(), isNew: true);

      await tapVisible(tester, find.text('Selesai'));

      expect(find.text('Rina Putri'), findsOneWidget);
    });
  });

  group('without a link', () {
    final cases = <String, Manager>{
      'no invitation': _manager(withoutInvitation: true),
      'an expired invitation': _manager(
        invitation: makeManagerInvitation(expired: true),
      ),
      'an invitation without a url': _manager(
        invitation: makeManagerInvitation(withoutUrl: true),
      ),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} says the link is not available', (
        tester,
      ) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text(_unavailable), findsOneWidget);
        expect(find.byType(SelectableText), findsNothing);
        expect(find.textContaining('Berlaku hingga'), findsNothing);
      });

      testWidgets('${entry.key} hides copy, WhatsApp and QR code', (
        tester,
      ) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text('Salin'), findsNothing);
        expect(find.text('Bagikan via WhatsApp'), findsNothing);
        expect(find.text('Tampilkan kode QR'), findsNothing);
        _withSemantics(tester, () {
          expect(find.bySemanticsLabel('Salin tautan undangan'), findsNothing);
        });
      });

      testWidgets('${entry.key} offers to regenerate the link', (tester) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text(_regenerate), findsOneWidget);
        expectTargetSize(tester, _regenerate);
      });

      testWidgets('${entry.key} keeps Selesai working', (tester) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text('Selesai'), findsOneWidget);
        await tapVisible(tester, find.text('Selesai'));

        expect(currentPath(tester), '/properti/p1/pengelola');
      });

      testWidgets('${entry.key} still shows the heading', (tester) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text('Pengelola ditambahkan'), findsOneWidget);
      });
    }

    testWidgets('a manager with a link does not say it is unavailable', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_unavailable), findsNothing);
    });

    testWidgets('regenerating shows the new link and its actions', (
      tester,
    ) async {
      final repo = _repo(
        _manager(invitation: makeManagerInvitation(expired: true)),
      );
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.calls, contains('regenerate:m1'));
      expect(find.text(_unavailable), findsNothing);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/m1-1',
      );
      expect(find.text('Salin'), findsOneWidget);
      expect(find.text('Bagikan via WhatsApp'), findsOneWidget);
      expect(find.text('Tampilkan kode QR'), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
    });

    testWidgets('the new link is the one shared', (tester) async {
      final sharer = ShareRecorder();
      final repo = _repo(
        _manager(invitation: makeManagerInvitation(expired: true)),
      );
      await _open(tester, repo, sharer: sharer);
      await tapVisible(tester, find.text(_regenerate));

      await tester.tap(find.text('Bagikan via WhatsApp'));
      await tester.pumpAndSettle();

      expect(
        sharer.texts.single,
        endsWith(': https://niscala.example/undangan/m1-1'),
      );
    });

    testWidgets('a second tap while regenerating sends one request', (
      tester,
    ) async {
      final repo = _repo(
        _manager(invitation: makeManagerInvitation(expired: true)),
      )..regenerateScript.gate = Completer<void>();
      await _open(tester, repo);

      await tester.ensureVisible(find.text(_regenerate));
      await tester.pump();
      await tester.tap(find.text(_regenerate));
      await tester.pump();
      if (find.text(_regenerate).evaluate().isNotEmpty) {
        await tester.tap(find.text(_regenerate), warnIfMissed: false);
        await tester.pump();
      }

      expect(repo.regenerateCalls, 1);
    });

    testWidgets('a failed regeneration shows its message and no link', (
      tester,
    ) async {
      final repo = _repo(
        _manager(invitation: makeManagerInvitation(expired: true)),
      )..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
      expect(find.text(_unavailable), findsOneWidget);
      expect(find.text(_regenerate), findsOneWidget);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Selesai'), findsNothing);
    });

    testWidgets('shows the content once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of a network failure', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Salin'), findsNothing);
    });

    testWidgets('shows the message of a manager that does not exist', (
      tester,
    ) async {
      await _open(tester, FakeManagerRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Pengelola tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the manager again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('the close button still works after a failure', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola');
    });
  });

  group('structure', () {
    testWidgets('uses the white detail app bar with the close action', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectDetailAppBar(tester);
      expect(appBarTitle('Undangan Pengelola'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byTooltip('Tutup'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the link, its expiry and the copy action sit in one card', (
      tester,
    ) async {
      await _open(tester, _repo());

      final card = find.byType(Card);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(SelectableText)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Berlaku hingga 25 Okt 2026 · sekali pakai'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Salin')),
        findsOneWidget,
      );
    });

    testWidgets('the link card takes the card look from the theme', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectCardLook(tester, find.byType(Card));
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'a new manager': (tester, large) =>
          _open(tester, _repo(), isNew: true, largeText: large),
      'an existing invitation': (tester, large) =>
          _open(tester, _repo(), largeText: large),
      'a manager with a nickname': (tester, large) => _open(
        tester,
        _repo(_manager(nickname: 'Bu Rina')),
        isNew: true,
        largeText: large,
      ),
      'no invitation': (tester, large) => _open(
        tester,
        _repo(_manager(withoutInvitation: true)),
        isNew: true,
        largeText: large,
      ),
      'an expired invitation': (tester, large) => _open(
        tester,
        _repo(_manager(invitation: makeManagerInvitation(expired: true))),
        largeText: large,
      ),
      'the copied link': (tester, large) async {
        ClipboardRecorder(tester);
        await _open(tester, _repo(), isNew: true, largeText: large);
        await tapVisible(tester, find.text('Salin'));
      },
      'a failed regeneration': (tester, large) async {
        final repo = _repo(
          _manager(invitation: makeManagerInvitation(expired: true)),
        )..regenerateScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, largeText: large);
        await tapVisible(tester, find.text(_regenerate));
      },
      'a failure': (tester, large) => _open(
        tester,
        _repo()..getScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'a missing manager': (tester, large) =>
          _open(tester, FakeManagerRepository(), largeText: large),
      'loading': (tester, large) => _open(
        tester,
        _repo()..getScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
