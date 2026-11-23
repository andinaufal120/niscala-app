import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala/core/widgets/loading_screen.dart';
import 'package:niscala/features/auth/ui/accept_invitation_screen.dart';
import 'package:niscala/features/auth/ui/activation_screen.dart';
import 'package:niscala/features/auth/ui/confirm_email_change_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/reset_password_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import '../features/auth/ui/auth_ui_helpers.dart';
import '../helpers/a11y.dart';
import '../helpers/fakes.dart';

const _invitationLink = '/invitations/tok-1';
const _resetLink = '/password-reset?token=tok-1';
const _emailLink = '/email-change?token=tok-1';

const _inviteLink = 'Tautan undangan (wajib)';
const _resetField = 'Tautan atur ulang (wajib)';
const _emailField = 'Tautan konfirmasi (wajib)';
const _name = 'Nama lengkap (wajib)';
const _newPassword = 'Kata sandi baru (wajib)';

/// A session store whose read completes only when the test resolves it, so a
/// link can arrive while the session is still loading.
class _GatedSessionStore implements SessionStore {
  final _read = Completer<StoredSession?>();

  void resolve(StoredSession? session) => _read.complete(session);

  @override
  Future<StoredSession?> read() => _read.future;

  @override
  Future<void> write(StoredSession session) async {}

  @override
  Future<void> clear() async {}
}

Uri _currentUri(WidgetTester tester) =>
    containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri;

/// Opens [link] while the session loads, then resolves the session to
/// [stored] (null is signed out).
Future<void> _openWhileLoading(
  WidgetTester tester,
  String link, {
  StoredSession? stored,
  FakeInvitationRepository? invitations,
  FakeAuthRepository? auth,
}) async {
  useTallScreen(tester);
  final store = _GatedSessionStore();
  await tester.pumpWidget(
    buildTestApp(
      store: store,
      invitations: invitations,
      auth: auth,
      leases: FakeLeaseRepository(lease: makeCurrentLease()),
    ),
  );
  await tester.pump();
  goTo(tester, link);
  await tester.pump();
  store.resolve(stored);
  await tester.pumpAndSettle();
}

/// Opens [link] when the session is already known.
Future<void> _openKnown(
  WidgetTester tester,
  String link, {
  StoredSession? stored,
  FakeInvitationRepository? invitations,
  FakeAuthRepository? auth,
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      store: InMemorySessionStore(stored),
      invitations: invitations,
      auth: auth,
      leases: FakeLeaseRepository(lease: makeCurrentLease()),
    ),
  );
  await tester.pumpAndSettle();
  goTo(tester, link);
  await tester.pumpAndSettle();
}

void main() {
  late FakeInvitationRepository invitations;
  late FakeAuthRepository auth;

  setUpAll(() => initializeDateFormatting('id'));

  setUp(() {
    invitations = FakeInvitationRepository();
    auth = FakeAuthRepository();
  });

  group('a link that arrives while the session loads', () {
    for (final link in [_invitationLink, _resetLink, _emailLink]) {
      testWidgets('$link shows the loading screen and checks nothing yet', (
        tester,
      ) async {
        useTallScreen(tester);
        final store = _GatedSessionStore();
        await tester.pumpWidget(
          buildTestApp(store: store, invitations: invitations, auth: auth),
        );
        await tester.pump();

        goTo(tester, link);
        await tester.pump();

        expect(find.byType(LoadingScreen), findsOneWidget);
        expect(currentPath(tester), Uri.parse(link).path);
        expect(invitations.previews, isEmpty);
        expect(invitations.acceptancePreviews, isEmpty);
        expect(auth.passwordResetPreviews, isEmpty);
        expect(auth.emailChangeConfirmations, isEmpty);
        await expectMeetsA11yGuidelines(tester);
        store.resolve(null);
        await tester.pumpAndSettle();
      });
    }
  });

  group('an invitation link', () {
    testWidgets('lands a signed out user on the activation form', (
      tester,
    ) async {
      await _openWhileLoading(
        tester,
        _invitationLink,
        invitations: invitations,
      );

      expect(currentPath(tester), '/aktivasi');
      expect(_currentUri(tester).queryParameters['token'], 'tok-1');
      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(invitations.previews, ['tok-1']);
      expect(find.text('Undangan dari Siti Pemilik'), findsOneWidget);
      expect(field(_name), findsOneWidget);
      expect(field(_inviteLink), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
    });

    testWidgets('lands a signed out user on the form when the session is '
        'already known', (tester) async {
      await _openKnown(tester, _invitationLink, invitations: invitations);

      expect(currentPath(tester), '/aktivasi');
      expect(invitations.previews, ['tok-1']);
      expect(field(_name), findsOneWidget);
      expect(field(_inviteLink), findsNothing);
    });

    testWidgets('shows the form of the preview, not the sign in screen', (
      tester,
    ) async {
      await _openWhileLoading(
        tester,
        _invitationLink,
        invitations: invitations,
      );

      expect(find.byType(LoginScreen), findsNothing);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('an unknown token shows the message and the paste field', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );

      await _openWhileLoading(
        tester,
        _invitationLink,
        invitations: invitations,
      );

      expect(currentPath(tester), '/aktivasi');
      expect(find.textContaining('tidak ditemukan'), findsOneWidget);
      expect(field(_inviteLink), findsOneWidget);
      expect(field(_name), findsNothing);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('an expired token shows the message and the paste field', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.expired,
      );

      await _openWhileLoading(
        tester,
        _invitationLink,
        invitations: invitations,
      );

      expect(find.textContaining('kedaluwarsa'), findsOneWidget);
      expect(field(_inviteLink), findsOneWidget);
    });

    testWidgets('a signed in tenant lands on Terima Undangan with the '
        'preview', (tester) async {
      invitations.previewAcceptanceResult = makeAcceptancePreview(
        invitation: makeInvitationPreview(),
        accountRole: UserRole.tenant,
      );

      await _openWhileLoading(
        tester,
        _invitationLink,
        stored: storedSession(role: UserRole.tenant),
        invitations: invitations,
      );

      expect(currentPath(tester), '/penyewa/akun/undangan');
      expect(_currentUri(tester).queryParameters['token'], 'tok-1');
      expect(find.byType(AcceptInvitationScreen), findsOneWidget);
      expect(invitations.acceptancePreviews, ['tok-1']);
      expect(invitations.previews, isEmpty);
      expect(find.text('Dari Siti Pemilik'), findsOneWidget);
      expect(buttonLabelled('Terima undangan'), findsOneWidget);
      expect(field(_inviteLink), findsNothing);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('a signed in manager lands on Terima Undangan with the '
        'preview', (tester) async {
      await _openWhileLoading(
        tester,
        _invitationLink,
        stored: storedSession(role: UserRole.manager),
        invitations: invitations,
      );

      expect(currentPath(tester), '/akun/undangan');
      expect(_currentUri(tester).queryParameters['token'], 'tok-1');
      expect(find.byType(AcceptInvitationScreen), findsOneWidget);
      expect(invitations.acceptancePreviews, ['tok-1']);
      expect(find.text('Dari Siti Pemilik'), findsOneWidget);
      expect(buttonLabelled('Terima undangan'), findsOneWidget);
      expect(field(_inviteLink), findsNothing);
    });

    testWidgets('a signed in manager with a dead token sees the message and '
        'the paste field', (tester) async {
      invitations.previewAcceptanceFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );

      await _openWhileLoading(
        tester,
        _invitationLink,
        stored: storedSession(role: UserRole.manager),
        invitations: invitations,
      );

      expect(currentPath(tester), '/akun/undangan');
      expect(find.textContaining('tidak ditemukan'), findsOneWidget);
      expect(field(_inviteLink), findsOneWidget);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('a signed in owner lands on the home and loads no preview', (
      tester,
    ) async {
      await _openWhileLoading(
        tester,
        _invitationLink,
        stored: storedSession(),
        invitations: invitations,
      );

      expect(currentPath(tester), '/beranda');
      expect(invitations.previews, isEmpty);
      expect(invitations.acceptancePreviews, isEmpty);
    });

    testWidgets('a signed in admin lands on the admin home', (tester) async {
      await _openWhileLoading(
        tester,
        _invitationLink,
        stored: storedSession(role: UserRole.admin),
        invitations: invitations,
      );

      expect(currentPath(tester), '/admin');
      expect(invitations.previews, isEmpty);
      expect(invitations.acceptancePreviews, isEmpty);
    });

    for (final role in UserRole.values) {
      testWidgets('an unverified $role lands on the email verification', (
        tester,
      ) async {
        await _openWhileLoading(
          tester,
          _invitationLink,
          stored: storedSession(role: role, emailVerified: false),
          invitations: invitations,
          auth: auth,
        );

        expect(currentPath(tester), '/verifikasi-email');
        expect(find.byType(VerifyEmailScreen), findsOneWidget);
        expect(invitations.previews, isEmpty);
        expect(invitations.acceptancePreviews, isEmpty);
      });
    }

    testWidgets('a link without a token segment stays out of the link routes', (
      tester,
    ) async {
      await _openKnown(tester, '/invitations', invitations: invitations);

      expect(currentPath(tester), '/masuk');
      expect(invitations.previews, isEmpty);
    });
  });

  group('a password reset link', () {
    testWidgets('lands a signed out user on the new password form', (
      tester,
    ) async {
      await _openWhileLoading(tester, _resetLink, auth: auth);

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(_currentUri(tester).queryParameters['token'], 'tok-1');
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(auth.passwordResetPreviews, ['tok-1']);
      expect(find.text('Untuk akun budi@example.com'), findsOneWidget);
      expect(field(_newPassword), findsOneWidget);
      expect(field(_resetField), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('lands a signed out user on the form when the session is '
        'already known', (tester) async {
      await _openKnown(tester, _resetLink, auth: auth);

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(auth.passwordResetPreviews, ['tok-1']);
      expect(field(_newPassword), findsOneWidget);
    });

    testWidgets('a dead token shows the message and the paste field', (
      tester,
    ) async {
      auth.previewPasswordResetFailure = const ApiFailure(
        code: 'PASSWORD_RESET_EXPIRED',
        statusCode: 409,
      );

      await _openWhileLoading(tester, _resetLink, auth: auth);

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(
        find.text(messageOfCode('PASSWORD_RESET_EXPIRED')),
        findsOneWidget,
      );
      expect(field(_resetField), findsOneWidget);
      expect(buttonLabelled('Minta Tautan Baru'), findsOneWidget);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('a link without a token shows the paste step', (tester) async {
      await _openWhileLoading(tester, '/password-reset', auth: auth);

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(field(_resetField), findsOneWidget);
      expect(auth.passwordResetPreviews, isEmpty);
    });

    testWidgets('a link with a blank token shows the paste step', (
      tester,
    ) async {
      await _openWhileLoading(tester, '/password-reset?token=', auth: auth);

      expect(currentPath(tester), '/atur-ulang-kata-sandi');
      expect(field(_resetField), findsOneWidget);
      expect(auth.passwordResetPreviews, isEmpty);
    });

    const homes = {
      UserRole.owner: '/beranda',
      UserRole.manager: '/beranda',
      UserRole.tenant: '/penyewa/beranda',
      UserRole.admin: '/admin',
    };
    for (final role in UserRole.values) {
      testWidgets('keeps a signed in $role on the home', (tester) async {
        await _openWhileLoading(
          tester,
          _resetLink,
          stored: storedSession(role: role),
          auth: auth,
        );

        expect(currentPath(tester), homes[role]);
        expect(find.byType(ResetPasswordScreen), findsNothing);
        expect(auth.passwordResetPreviews, isEmpty);
      });

      testWidgets('sends an unverified $role to the email verification', (
        tester,
      ) async {
        await _openWhileLoading(
          tester,
          _resetLink,
          stored: storedSession(role: role, emailVerified: false),
          auth: auth,
        );

        expect(currentPath(tester), '/verifikasi-email');
        expect(auth.passwordResetPreviews, isEmpty);
      });
    }
  });

  group('an email change link', () {
    testWidgets('confirms the new email of a signed out user at once', (
      tester,
    ) async {
      await _openWhileLoading(tester, _emailLink, auth: auth);

      expect(currentPath(tester), '/konfirmasi-email-baru');
      expect(_currentUri(tester).queryParameters['token'], 'tok-1');
      expect(find.byType(ConfirmEmailChangeScreen), findsOneWidget);
      expect(auth.emailChangeConfirmations, ['tok-1']);
      expect(find.text('Email diperbarui'), findsOneWidget);
      expect(field(_emailField), findsNothing);
      expect(buttonLabelled('Konfirmasi'), findsNothing);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('confirms when the session is already known', (tester) async {
      await _openKnown(tester, _emailLink, auth: auth);

      expect(currentPath(tester), '/konfirmasi-email-baru');
      expect(auth.emailChangeConfirmations, ['tok-1']);
      expect(find.text('Email diperbarui'), findsOneWidget);
    });

    testWidgets('a dead token shows the message and the paste field', (
      tester,
    ) async {
      auth.confirmEmailChangeFailure = const ApiFailure(
        code: 'EMAIL_CHANGE_NOT_FOUND',
        statusCode: 404,
      );

      await _openWhileLoading(tester, _emailLink, auth: auth);

      expect(currentPath(tester), '/konfirmasi-email-baru');
      expect(
        find.text(messageOfCode('EMAIL_CHANGE_NOT_FOUND')),
        findsOneWidget,
      );
      expect(field(_emailField), findsOneWidget);
      expect(find.text('Email diperbarui'), findsNothing);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('a link without a token shows the paste step', (tester) async {
      await _openWhileLoading(tester, '/email-change', auth: auth);

      expect(currentPath(tester), '/konfirmasi-email-baru');
      expect(field(_emailField), findsOneWidget);
      expect(auth.emailChangeConfirmations, isEmpty);
    });

    const homes = {
      UserRole.owner: '/beranda',
      UserRole.manager: '/beranda',
      UserRole.tenant: '/penyewa/beranda',
      UserRole.admin: '/admin',
    };
    for (final role in UserRole.values) {
      testWidgets('keeps a signed in $role on the home', (tester) async {
        await _openWhileLoading(
          tester,
          _emailLink,
          stored: storedSession(role: role),
          auth: auth,
        );

        expect(currentPath(tester), homes[role]);
        expect(find.byType(ConfirmEmailChangeScreen), findsNothing);
        expect(auth.emailChangeConfirmations, isEmpty);
      });

      testWidgets('sends an unverified $role to the email verification', (
        tester,
      ) async {
        await _openWhileLoading(
          tester,
          _emailLink,
          stored: storedSession(role: role, emailVerified: false),
          auth: auth,
        );

        expect(currentPath(tester), '/verifikasi-email');
        expect(auth.emailChangeConfirmations, isEmpty);
      });
    }
  });

  group('the paste flows', () {
    testWidgets('the activation screen without a token shows the paste step', (
      tester,
    ) async {
      await _openKnown(tester, '/aktivasi', invitations: invitations);

      expect(field(_inviteLink), findsOneWidget);
      expect(invitations.previews, isEmpty);
    });

    testWidgets('the reset screen without a token shows the paste step', (
      tester,
    ) async {
      await _openKnown(tester, '/atur-ulang-kata-sandi', auth: auth);

      expect(field(_resetField), findsOneWidget);
      expect(auth.passwordResetPreviews, isEmpty);
    });

    testWidgets('the confirmation screen without a token shows the paste '
        'step', (tester) async {
      await _openKnown(tester, '/konfirmasi-email-baru', auth: auth);

      expect(field(_emailField), findsOneWidget);
      expect(auth.emailChangeConfirmations, isEmpty);
    });

    testWidgets('the activation route reads the token of its query', (
      tester,
    ) async {
      await _openKnown(
        tester,
        '/aktivasi?token=tok-9',
        invitations: invitations,
      );

      expect(invitations.previews, ['tok-9']);
      expect(field(_inviteLink), findsNothing);
    });

    testWidgets('the Terima Undangan route reads the token of its query', (
      tester,
    ) async {
      await _openKnown(
        tester,
        '/akun/undangan?token=tok-9',
        stored: storedSession(role: UserRole.manager),
        invitations: invitations,
      );

      expect(invitations.acceptancePreviews, ['tok-9']);
      expect(field(_inviteLink), findsNothing);
      expect(buttonLabelled('Terima undangan'), findsOneWidget);
    });

    testWidgets('the Terima Undangan route without a token shows the paste '
        'step', (tester) async {
      await _openKnown(
        tester,
        '/penyewa/akun/undangan',
        stored: storedSession(role: UserRole.tenant),
        invitations: invitations,
      );

      expect(field(_inviteLink), findsOneWidget);
      expect(invitations.acceptancePreviews, isEmpty);
    });
  });
}
