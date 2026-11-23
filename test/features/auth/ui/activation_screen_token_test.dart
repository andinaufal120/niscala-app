import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/ui/activation_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';
import 'link_screen_helpers.dart';

const _link = 'Tautan undangan (wajib)';
const _name = 'Nama lengkap (wajib)';
const _email = 'Email (wajib)';
const _password = 'Kata sandi (wajib)';
const _confirm = 'Konfirmasi kata sandi (wajib)';

void main() {
  late FakeInvitationRepository invitations;

  setUp(() => invitations = FakeInvitationRepository());

  group('activation screen with a token', () {
    testWidgets('loads the preview of the token at once, only once', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(invitations.previews, ['tok-1']);
    });

    testWidgets('shows a loading state while the preview loads', (
      tester,
    ) async {
      invitations.previewGate = Completer<void>();
      addTearDown(() {
        if (!invitations.previewGate!.isCompleted) {
          invitations.previewGate!.complete();
        }
      });

      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
        settle: false,
      );

      expect(invitations.previews, ['tok-1']);
      expectInFlight();
      expect(field(_name), findsNothing);
      expect(buttonLabelled('Aktifkan Akun'), findsNothing);
    });

    testWidgets('shows the activation form of a valid invitation', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text('Undangan dari Siti Pemilik'), findsOneWidget);
      expect(find.text('Kos Melati · Kamar 08'), findsOneWidget);
      expect(textField(tester, _name).controller!.text, 'Budi Santoso');
      expect(field(_email), findsOneWidget);
      expect(buttonLabelled('Aktifkan Akun'), findsOneWidget);
    });

    testWidgets('skips the paste step of a valid invitation', (tester) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(field(_link), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
    });

    testWidgets('activates the account with the token of the link', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      await type(tester, _email, 'budi@example.com');
      await type(tester, _password, 'kopi tubruk pagi');
      await type(tester, _confirm, 'kopi tubruk pagi');
      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(invitations.activations.map((a) => a.token), ['tok-1']);
    });

    testWidgets('asks for the emergency contacts when the invitation needs '
        'them', (tester) async {
      invitations.previewResult = makeInvitationPreview(
        emergencyContactsRequired: true,
      );

      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text('Kontak darurat (wajib)'), findsOneWidget);
    });

    testWidgets('an expired invitation shows its message and the paste field', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.expired,
      );

      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.textContaining('kedaluwarsa'), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(field(_name), findsNothing);
      expect(invitations.previews, ['tok-1']);
    });

    testWidgets('a used invitation shows its message and the paste field', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.used,
      );

      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.textContaining('sudah dipakai'), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(field(_name), findsNothing);
    });

    testWidgets('an unknown invitation says it was not found', (tester) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );

      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.textContaining('tidak ditemukan'), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(field(_name), findsNothing);
    });

    testWidgets('a network failure shows its message and lets the user retry '
        'by pasting the link', (tester) async {
      invitations.previewFailure = const ApiFailure.network();
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(field(_link), findsOneWidget);

      invitations.previewFailure = null;
      await type(tester, _link, 'https://niscala.example/invitations/tok-1');
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(invitations.previews, ['tok-1', 'tok-1']);
      expect(field(_name), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('never shows the API error text or code', (tester) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );

      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.textContaining('INVITATION_NOT_FOUND'), findsNothing);
      expect(find.textContaining('not found'), findsNothing);
    });

    testWidgets('an empty token behaves like no token', (tester) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: ''),
        invitations: invitations,
      );

      expect(field(_link), findsOneWidget);
      expect(invitations.previews, isEmpty);
    });
  });

  group('activation screen without a token', () {
    testWidgets('shows the paste step and loads nothing', (tester) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(),
        invitations: invitations,
      );

      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(invitations.previews, isEmpty);
    });
  });

  group('accessibility of the activation screen opened from a link', () {
    testWidgets('meets the guidelines while loading', (tester) async {
      invitations.previewGate = Completer<void>();
      addTearDown(() {
        if (!invitations.previewGate!.isCompleted) {
          invitations.previewGate!.complete();
        }
      });
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
        settle: false,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the preview', (tester) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error', (tester) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('does not overflow at large text with the preview', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at large text with an error', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );
      await pumpLinkScreen(
        tester,
        const ActivationScreen(token: 'tok-1'),
        invitations: invitations,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
