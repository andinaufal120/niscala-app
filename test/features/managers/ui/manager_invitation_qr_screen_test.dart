import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/managers/ui/manager_invitation_qr_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_share_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala_api/api.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'manager_ui_helpers.dart';

const _url = 'https://niscala.example/undangan/abc123';
const _unavailable = 'Tautan undangan belum tersedia.';
const _regenerate = 'Buat Ulang Tautan Undangan';

FakeManagerRepository _repo({
  String name = 'Rina Putri',
  ManagerInvitation? invitation,
  bool withoutInvitation = false,
}) => FakeManagerRepository(
  managers: [
    makeManager(
      id: 'm1',
      name: name,
      invitation: invitation,
      withoutInvitation: withoutInvitation,
    ),
  ],
);

Future<void> _open(
  WidgetTester tester,
  FakeManagerRepository repo, {
  ShareRecorder? sharer,
  bool settle = true,
  bool largeText = false,
}) => pumpManagerApp(
  tester,
  repo,
  sharer: sharer,
  path: '/properti/p1/pengelola/m1/undangan/qr',
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

      expect(find.byType(ManagerInvitationQrScreen), findsOneWidget);
      expect(appBarTitle('Kode QR undangan'), findsOneWidget);
      expect(repo.calls, contains('get:m1'));
    });

    testWidgets('asks to have the manager scan the code', (tester) async {
      await _open(tester, _repo());

      expect(
        find.textContaining('memindai kode ini dengan kamera ponselnya'),
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
      final invitation = makeManagerInvitation(url: url);
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
      final invitation = makeManagerInvitation(
        expiresAt: DateTime.utc(2026, 11, 3, 12),
      );
      await _open(tester, _repo(invitation: invitation));

      expect(
        find.text('Berlaku hingga 3 Nov 2026 · sekali pakai'),
        findsOneWidget,
      );
    });
  });

  group('sharing without the code', () {
    testWidgets('offers Bagikan via WhatsApp, at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Bagikan via WhatsApp'), findsOneWidget);
      expectTargetSize(tester, 'Bagikan via WhatsApp');
    });

    testWidgets('Bagikan via WhatsApp hands a greeting with the link over', (
      tester,
    ) async {
      final sharer = ShareRecorder();
      await _open(tester, _repo(), sharer: sharer);

      await tapVisible(tester, find.text('Bagikan via WhatsApp'));

      expect(sharer.texts, hasLength(1));
      expect(sharer.texts.single, startsWith('Halo Rina, '));
      expect(sharer.texts.single, endsWith(': $_url'));
    });

    testWidgets('sharing keeps the QR code on screen', (tester) async {
      await _open(tester, _repo(), sharer: ShareRecorder());

      await tapVisible(tester, find.text('Bagikan via WhatsApp'));

      expect(find.byType(ManagerInvitationQrScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan/qr');
    });
  });

  group('navigation', () {
    testWidgets('Tutup is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expectTargetSize(tester, 'Tutup');
    });

    testWidgets('Tutup goes to the manager list', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text('Tutup'));

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
      expect(find.byType(ManagerInvitationQrScreen), findsNothing);
      expect(find.byType(ManagerInvitationShareScreen), findsNothing);
    });

    testWidgets('Kembali returns to the share screen', (tester) async {
      await _open(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });
  });

  group('without a link', () {
    final cases = <String, FakeManagerRepository Function()>{
      'no invitation': () => _repo(withoutInvitation: true),
      'an expired invitation': () =>
          _repo(invitation: makeManagerInvitation(expired: true)),
      'an invitation without a url': () =>
          _repo(invitation: makeManagerInvitation(withoutUrl: true)),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} says the link is not available', (
        tester,
      ) async {
        await _open(tester, entry.value());

        expect(find.text(_unavailable), findsOneWidget);
        expect(find.byType(QrImageView), findsNothing);
        expect(find.text('Bagikan via WhatsApp'), findsNothing);
      });

      testWidgets('${entry.key} offers to regenerate the link', (tester) async {
        await _open(tester, entry.value());

        expect(find.text(_regenerate), findsOneWidget);
        expectTargetSize(tester, _regenerate);
      });
    }

    testWidgets('regenerating shows the code of the new link', (tester) async {
      final repo = _repo(invitation: makeManagerInvitation(expired: true));
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.calls, contains('regenerate:m1'));
      expect(find.byType(QrImageView), findsOneWidget);
      expect(
        await _drawsData(tester, 'https://niscala.example/undangan/m1-1'),
        isTrue,
      );
    });

    testWidgets('a failed regeneration shows its message and no code', (
      tester,
    ) async {
      final repo = _repo(invitation: makeManagerInvitation(expired: true))
        ..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
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
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('shows the message of a manager that does not exist', (
      tester,
    ) async {
      await _open(tester, FakeManagerRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Pengelola tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the manager again', (tester) async {
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
      'a long name': (tester, large) => _open(
        tester,
        _repo(name: 'Anak Agung Gede Ngurah Putra Wijaya Kusuma'),
        largeText: large,
      ),
      'no invitation': (tester, large) =>
          _open(tester, _repo(withoutInvitation: true), largeText: large),
      'an expired invitation': (tester, large) => _open(
        tester,
        _repo(invitation: makeManagerInvitation(expired: true)),
        largeText: large,
      ),
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
