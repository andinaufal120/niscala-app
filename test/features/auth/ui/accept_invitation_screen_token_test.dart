import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/auth/ui/accept_invitation_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'auth_ui_helpers.dart';
import 'link_screen_helpers.dart';

const _link = 'Tautan undangan (wajib)';
const _expired =
    'Tautan undangan sudah kedaluwarsa. Minta pemilik kost membuat tautan baru.';
const _used = 'Tautan undangan ini sudah dipakai.';

InvitationAcceptancePreview _blocked(InvitationLinkStatus status) =>
    makeAcceptancePreview(
      invitation: makeInvitationPreview(
        status: status,
        role: InvitationRole.manager,
        roomNumber: null,
      ),
    );

void main() {
  late FakeInvitationRepository invitations;

  setUpAll(() => initializeDateFormatting('id'));

  setUp(() => invitations = FakeInvitationRepository());

  group('accept invitation screen with a token', () {
    testWidgets('loads the preview of the token at once, only once', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(invitations.acceptancePreviews, ['tok-1']);
    });

    testWidgets('shows a loading state while the preview loads', (
      tester,
    ) async {
      invitations.previewAcceptanceGate = Completer<void>();
      addTearDown(() {
        if (!invitations.previewAcceptanceGate!.isCompleted) {
          invitations.previewAcceptanceGate!.complete();
        }
      });

      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
        settle: false,
      );

      expect(invitations.acceptancePreviews, ['tok-1']);
      expectInFlight();
      expect(buttonLabelled('Terima undangan'), findsNothing);
    });

    testWidgets('shows the invitation and the accept button without a paste '
        'step', (tester) async {
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text('Dari Siti Pemilik'), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Diterima dengan akun'), findsOneWidget);
      expect(buttonLabelled('Terima undangan'), findsOneWidget);
      expect(field(_link), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
    });

    testWidgets('accepts the invitation with the token of the link', (
      tester,
    ) async {
      invitations.acceptGate = Completer<void>();
      addTearDown(() {
        if (!invitations.acceptGate!.isCompleted) {
          invitations.acceptGate!.complete();
        }
      });
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      await tester.tap(buttonLabelled('Terima undangan'));
      await tester.pump();

      expect(invitations.acceptances, ['tok-1']);
    });

    testWidgets('an expired invitation shows its message and the paste field', (
      tester,
    ) async {
      invitations.previewAcceptanceResult = _blocked(
        InvitationLinkStatus.expired,
      );

      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text(_expired), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(buttonLabelled('Terima undangan'), findsNothing);
    });

    testWidgets('a used invitation shows its message and the paste field', (
      tester,
    ) async {
      invitations.previewAcceptanceResult = _blocked(InvitationLinkStatus.used);

      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text(_used), findsOneWidget);
      expect(field(_link), findsOneWidget);
    });

    testWidgets('an invitation for another role shows its message', (
      tester,
    ) async {
      invitations.previewAcceptanceResult = makeAcceptancePreview(
        blocker: InvitationBlocker.roleMismatch,
      );

      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(
        find.text(messageOfCode('INVITATION_ROLE_MISMATCH')),
        findsOneWidget,
      );
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Terima undangan'), findsNothing);
    });

    testWidgets('an unknown invitation says it was not found', (tester) async {
      invitations.previewAcceptanceFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );

      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.textContaining('tidak ditemukan'), findsOneWidget);
      expect(field(_link), findsOneWidget);
    });

    testWidgets('a network failure shows its message and lets the user retry '
        'by pasting the link', (tester) async {
      invitations.previewAcceptanceFailure = const ApiFailure.network();
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(field(_link), findsOneWidget);

      invitations.previewAcceptanceFailure = null;
      await type(tester, _link, 'https://niscala.example/invitations/tok-1');
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(invitations.acceptancePreviews, ['tok-1', 'tok-1']);
      expect(buttonLabelled('Terima undangan'), findsOneWidget);
    });

    testWidgets('an empty token behaves like no token', (tester) async {
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: ''),
        invitations: invitations,
      );

      expect(field(_link), findsOneWidget);
      expect(invitations.acceptancePreviews, isEmpty);
    });
  });

  group('accept invitation screen without a token', () {
    testWidgets('shows the paste step and loads nothing', (tester) async {
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(),
        invitations: invitations,
      );

      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(invitations.acceptancePreviews, isEmpty);
    });
  });

  group('accessibility of the accept screen opened from a link', () {
    testWidgets('meets the guidelines while loading', (tester) async {
      invitations.previewAcceptanceGate = Completer<void>();
      addTearDown(() {
        if (!invitations.previewAcceptanceGate!.isCompleted) {
          invitations.previewAcceptanceGate!.complete();
        }
      });
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
        settle: false,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the preview', (tester) async {
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an error', (tester) async {
      invitations.previewAcceptanceFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('does not overflow at large text with the preview', (
      tester,
    ) async {
      await pumpLinkScreen(
        tester,
        const AcceptInvitationScreen(token: 'tok-1'),
        invitations: invitations,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
