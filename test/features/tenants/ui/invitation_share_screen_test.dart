import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala/features/tenants/ui/invitation_qr_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'tenant_ui_helpers.dart';

const _url = 'https://niscala.example/undangan/abc123';
const _unavailable = 'Tautan undangan belum tersedia.';
const _intro =
    'Bagikan tautan ini kepada Budi Santoso (081255204471). Ia akan '
    'melengkapi email dan kata sandi, atau masuk dengan Google, saat membuka '
    'tautan.';

Tenant _tenant({
  TenantInvitation? invitation,
  bool withoutInvitation = false,
}) => makeTenant(
  id: 't1',
  name: 'Budi Santoso',
  phone: '081255204471',
  invitation: invitation,
  withoutInvitation: withoutInvitation,
);

FakeTenantRepository _repo([Tenant? tenant]) =>
    FakeTenantRepository(tenants: [tenant ?? _tenant()]);

Future<void> _open(
  WidgetTester tester,
  FakeTenantRepository repo, {
  bool isNew = false,
  UserRole role = UserRole.owner,
  ShareRecorder? sharer,
  bool settle = true,
  bool largeText = false,
}) => pumpTenantApp(
  tester,
  repo,
  role: role,
  sharer: sharer,
  path: '/properti/p1/penyewa/t1/undangan${isNew ? '?baru=1' : ''}',
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
    testWidgets('loads the tenant by its id', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(find.byType(InvitationShareScreen), findsOneWidget);
      expect(repo.calls, contains('get:t1'));
    });

    testWidgets('a new tenant gets the heading Penyewa ditambahkan', (
      tester,
    ) async {
      await _open(tester, _repo(), isNew: true);

      expect(find.text('Penyewa ditambahkan'), findsOneWidget);
    });

    testWidgets('an existing tenant gets the heading Tautan undangan', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Penyewa ditambahkan'), findsNothing);
      expect(find.text('Tautan undangan'), findsNWidgets(2));
    });

    testWidgets('the heading is a header', (tester) async {
      await _open(tester, _repo(), isNew: true);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Penyewa ditambahkan')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('says who to share the link with and what happens next', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_intro), findsOneWidget);
    });

    testWidgets('uses the name and phone of the loaded tenant', (tester) async {
      final tenant = makeTenant(
        id: 't1',
        name: 'Rina Putri',
        phone: '081300000001',
      );
      await _open(tester, _repo(tenant));

      expect(
        find.text(
          'Bagikan tautan ini kepada Rina Putri (081300000001). Ia akan '
          'melengkapi email dan kata sandi, atau masuk dengan Google, saat '
          'membuka tautan.',
        ),
        findsOneWidget,
      );
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
      final invitation = makeTenantInvitation(
        expiresAt: DateTime.utc(2026, 11, 3, 12),
      );
      await _open(tester, _repo(_tenant(invitation: invitation)));

      expect(
        find.text('Berlaku hingga 3 Nov 2026 · sekali pakai'),
        findsOneWidget,
      );
    });

    testWidgets('shows the link of the loaded invitation', (tester) async {
      final invitation = makeTenantInvitation(
        url: 'https://niscala.example/undangan/zzz999',
      );
      await _open(tester, _repo(_tenant(invitation: invitation)));

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

    testWidgets('a manager sees the same screen', (tester) async {
      await _open(tester, _repo(), role: UserRole.manager, isNew: true);

      expect(find.text('Penyewa ditambahkan'), findsOneWidget);
      expect(find.text('Salin'), findsOneWidget);
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
      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan');
    });
  });

  group('sharing', () {
    testWidgets(
      'Bagikan via WhatsApp hands the invitation text to the sharer',
      (tester) async {
        final sharer = ShareRecorder();
        await _open(tester, _repo(), sharer: sharer);

        await tester.tap(find.text('Bagikan via WhatsApp'));
        await tester.pumpAndSettle();

        expect(sharer.texts, [
          invitationShareText(tenantName: 'Budi Santoso', url: _url),
        ]);
        expect(sharer.texts.single, contains(_url));
      },
    );

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

      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan');
      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Tampilkan kode QR opens the QR screen', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text('Tampilkan kode QR'));

      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan/qr');
      final qr = tester.widget<InvitationQrScreen>(
        find.byType(InvitationQrScreen),
      );
      expect(qr.propertyId, 'p1');
      expect(qr.tenantId, 't1');
    });

    testWidgets('Selesai goes to the tenant list', (tester) async {
      await _open(tester, _repo(), isNew: true);

      await tapVisible(tester, find.text('Selesai'));

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(find.byType(InvitationShareScreen), findsNothing);
    });

    testWidgets('the close button goes to the tenant list', (tester) async {
      await _open(tester, _repo(), isNew: true);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
    });

    testWidgets('the list shows the tenant after Selesai', (tester) async {
      await _open(tester, _repo(), isNew: true);

      await tapVisible(tester, find.text('Selesai'));

      expect(find.text('Budi Santoso'), findsOneWidget);
    });
  });

  group('without a link', () {
    final cases = <String, Tenant>{
      'no invitation': _tenant(withoutInvitation: true),
      'an invitation without a url': _tenant(
        invitation: makeTenantInvitation(url: null),
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

      testWidgets('${entry.key} keeps Selesai working', (tester) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text('Selesai'), findsOneWidget);
        await tapVisible(tester, find.text('Selesai'));

        expect(currentPath(tester), '/properti/p1/penyewa');
      });

      testWidgets('${entry.key} still shows the heading', (tester) async {
        await _open(tester, _repo(entry.value), isNew: true);

        expect(find.text('Penyewa ditambahkan'), findsOneWidget);
      });
    }

    testWidgets('a tenant with a link does not say it is unavailable', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_unavailable), findsNothing);
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
      expect(find.text(_intro), findsNothing);
    });

    testWidgets('shows the content once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_intro), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of a network failure', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Salin'), findsNothing);
    });

    testWidgets('shows the message of a tenant that does not exist', (
      tester,
    ) async {
      await _open(tester, FakeTenantRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Penyewa tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the tenant again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_intro), findsOneWidget);
    });

    testWidgets('the close button still works after a failure', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/penyewa');
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'a new tenant': (tester, large) =>
          _open(tester, _repo(), isNew: true, largeText: large),
      'an existing invitation': (tester, large) =>
          _open(tester, _repo(), largeText: large),
      'a manager': (tester, large) => _open(
        tester,
        _repo(),
        isNew: true,
        role: UserRole.manager,
        largeText: large,
      ),
      'no invitation': (tester, large) => _open(
        tester,
        _repo(_tenant(withoutInvitation: true)),
        isNew: true,
        largeText: large,
      ),
      'an invitation without a url': (tester, large) => _open(
        tester,
        _repo(_tenant(invitation: makeTenantInvitation(url: null))),
        largeText: large,
      ),
      'the copied link': (tester, large) async {
        ClipboardRecorder(tester);
        await _open(tester, _repo(), isNew: true, largeText: large);
        await tapVisible(tester, find.text('Salin'));
      },
      'a failure': (tester, large) => _open(
        tester,
        _repo()..getScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'a missing tenant': (tester, large) =>
          _open(tester, FakeTenantRepository(), largeText: large),
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
