import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'tenant_ui_helpers.dart';

const _url = 'https://niscala.example/undangan/abc123';

FakeTenantRepository _repo({
  String name = 'Budi Santoso',
  TenantInvitation? invitation,
}) => FakeTenantRepository(
  tenants: [makeTenant(id: 't1', name: name, invitation: invitation)],
);

Future<void> _open(
  WidgetTester tester,
  FakeTenantRepository repo, {
  UserRole role = UserRole.owner,
  ShareRecorder? sharer,
  bool settle = true,
  bool largeText = false,
}) => pumpTenantApp(
  tester,
  repo,
  role: role,
  sharer: sharer,
  path: '/properti/p1/penyewa/t1/undangan/qr',
  settle: settle,
  largeText: largeText,
);

/// Whether the QR code on screen draws exactly [data]. The widget does not
/// expose its data, so its painter is rendered next to a reference painter
/// with the same styling and the two images are compared.
Future<bool> _drawsData(WidgetTester tester, String data) async {
  final view = tester.widget<QrImageView>(find.byType(QrImageView));
  final shown =
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(QrImageView),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint && widget.painter is QrPainter,
                  ),
                ),
              )
              .painter!
          as QrPainter;
  final reference = QrPainter(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: view.errorCorrectionLevel,
    gapless: view.gapless,
    eyeStyle: view.eyeStyle,
    dataModuleStyle: view.dataModuleStyle,
  );
  final images = await tester.runAsync(
    () async => [
      await shown.toImageData(200),
      await reference.toImageData(200),
    ],
  );
  return listEquals(
    images![0]!.buffer.asUint8List(),
    images[1]!.buffer.asUint8List(),
  );
}

void main() {
  group('content', () {
    testWidgets('shows the title Kode QR undangan', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(find.byType(InvitationQrScreen), findsOneWidget);
      expect(appBarTitle('Kode QR undangan'), findsOneWidget);
      expect(repo.calls, contains('get:t1'));
    });

    testWidgets('shows the tenant name as a header', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Budi Santoso'), findsOneWidget);
      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Budi Santoso')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('asks to have the first name scan the code', (tester) async {
      await _open(tester, _repo());

      expect(
        find.text('Minta Budi memindai kode ini dengan kamera ponselnya.'),
        findsOneWidget,
      );
    });

    testWidgets('a single name is used as it is', (tester) async {
      await _open(tester, _repo(name: 'Dewi'));

      expect(
        find.text('Minta Dewi memindai kode ini dengan kamera ponselnya.'),
        findsOneWidget,
      );
    });

    testWidgets('draws one QR code holding the invitation url', (tester) async {
      await _open(tester, _repo());

      expect(find.byType(QrImageView), findsOneWidget);
      expect(await _drawsData(tester, _url), isTrue);
      expect(await _drawsData(tester, '$_url-other'), isFalse);
    });

    testWidgets('the QR code follows the loaded invitation', (tester) async {
      const url = 'https://niscala.example/undangan/zzz999';
      final invitation = makeTenantInvitation(url: url);
      await _open(tester, _repo(invitation: invitation));

      expect(await _drawsData(tester, url), isTrue);
      expect(await _drawsData(tester, _url), isFalse);
    });

    testWidgets('the QR code is announced as Kode QR tautan undangan', (
      tester,
    ) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          find.bySemanticsLabel('Kode QR tautan undangan'),
          findsOneWidget,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the url as text next to the code', (tester) async {
      await _open(tester, _repo());

      expect(find.text(_url), findsOneWidget);
    });

    testWidgets('says until when the link works and that it is single use', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(
        find.text('Berlaku hingga 25 Okt 2026 · sekali pakai'),
        findsOneWidget,
      );
    });

    testWidgets('the expiry follows the invitation', (tester) async {
      final invitation = makeTenantInvitation(
        expiresAt: DateTime.utc(2026, 11, 3, 12),
      );
      await _open(tester, _repo(invitation: invitation));

      expect(
        find.text('Berlaku hingga 3 Nov 2026 · sekali pakai'),
        findsOneWidget,
      );
    });

    testWidgets('a manager sees the same screen', (tester) async {
      await _open(tester, _repo(), role: UserRole.manager);

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Bagikan via WhatsApp'), findsOneWidget);
    });
  });

  group('sharing without the code', () {
    testWidgets('offers Bagikan via WhatsApp, at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Bagikan via WhatsApp'), findsOneWidget);
      expectTargetSize(tester, 'Bagikan via WhatsApp');
    });

    testWidgets('Bagikan via WhatsApp hands the invitation text over', (
      tester,
    ) async {
      final sharer = ShareRecorder();
      await _open(tester, _repo(), sharer: sharer);

      await tapVisible(tester, find.text('Bagikan via WhatsApp'));

      expect(sharer.texts, [
        invitationShareText(tenantName: 'Budi Santoso', url: _url),
      ]);
    });

    testWidgets('sharing keeps the QR code on screen', (tester) async {
      await _open(tester, _repo(), sharer: ShareRecorder());

      await tapVisible(tester, find.text('Bagikan via WhatsApp'));

      expect(find.byType(InvitationQrScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan/qr');
    });
  });

  group('navigation', () {
    testWidgets('Tutup is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expectTargetSize(tester, 'Tutup');
    });

    testWidgets('Tutup goes to the tenant list', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text('Tutup'));

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(find.byType(InvitationQrScreen), findsNothing);
      expect(find.byType(InvitationShareScreen), findsNothing);
    });

    testWidgets('Kembali returns to the share screen', (tester) async {
      await _open(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan');
      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(appBarTitle('Kode QR undangan'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('shows the code once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
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
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('shows the message of a tenant that does not exist', (
      tester,
    ) async {
      await _open(tester, FakeTenantRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Penyewa tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the tenant again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('uses the white detail app bar titled Kode QR undangan', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectDetailAppBar(tester);
      expect(appBarTitle('Kode QR undangan'), findsOneWidget);
    });

    testWidgets('the link and its expiry sit in one card', (tester) async {
      await _open(tester, _repo());

      final card = find.byType(Card);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(_url)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Berlaku hingga 25 Okt 2026 · sekali pakai'),
        ),
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
      'the loaded code': (tester, large) =>
          _open(tester, _repo(), largeText: large),
      'the loaded code for a manager': (tester, large) =>
          _open(tester, _repo(), role: UserRole.manager, largeText: large),
      'a long name': (tester, large) => _open(
        tester,
        _repo(name: 'Anak Agung Gede Ngurah Putra Wijaya Kusuma'),
        largeText: large,
      ),
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
