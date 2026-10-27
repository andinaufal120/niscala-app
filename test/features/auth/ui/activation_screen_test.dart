import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/features/auth/ui/activation_screen.dart';
import 'package:niscala/features/auth/ui/login_screen.dart';
import 'package:niscala/features/auth/ui/verify_email_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'auth_ui_helpers.dart';

const _link = 'Tautan undangan (wajib)';
const _name = 'Nama lengkap (wajib)';
const _email = 'Email (wajib)';
const _password = 'Kata sandi (wajib)';
const _confirm = 'Konfirmasi kata sandi (wajib)';
const _contactName = 'Nama kontak (wajib)';
const _contactRelationship = 'Hubungan (wajib)';
const _contactPhone = 'Nomor telepon kontak (wajib)';

const _tokenLink = 'https://niscala.example/undangan/abc123';

const _strengthHint = 'Kekuatan kata sandi akan muncul saat Anda mengetik.';
const _tooShort = 'Kekuatan: Lemah · terlalu pendek';
const _guessable = 'Kekuatan: Lemah · mudah ditebak';
const _veryStrong = 'Kekuatan: Sangat kuat · sangat sulit ditebak';

Future<void> pumpActivation(
  WidgetTester tester,
  FakeInvitationRepository invitations, {
  FakeAuthRepository? auth,
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(buildTestApp(invitations: invitations, auth: auth));
  await tester.pumpAndSettle();
  goTo(tester, '/aktivasi');
  await tester.pumpAndSettle();
}

Future<void> pumpActivationAtLargeText(
  WidgetTester tester,
  FakeInvitationRepository invitations,
) async {
  await pumpAtLargeText(tester, buildTestApp(invitations: invitations));
  await tester.pumpAndSettle();
  goTo(tester, '/aktivasi');
  await tester.pumpAndSettle();
}

Future<void> continueWith(WidgetTester tester, String link) async {
  await type(tester, _link, link);
  await tapVisible(tester, buttonLabelled('Lanjut'));
}

/// Shows the activation form of a valid invitation.
Future<void> pumpForm(
  WidgetTester tester,
  FakeInvitationRepository invitations, {
  FakeAuthRepository? auth,
}) async {
  await pumpActivation(tester, invitations, auth: auth);
  await continueWith(tester, _tokenLink);
}

Future<void> fill(
  WidgetTester tester, {
  String? name,
  String email = 'budi@example.com',
  String password = 'kopi tubruk pagi',
  String? confirm,
}) async {
  if (name != null) await type(tester, _name, name);
  await type(tester, _email, email);
  await type(tester, _password, password);
  await type(tester, _confirm, confirm ?? password);
}

Future<void> submit(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled('Aktifkan Akun'));

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String? name,
  String email = 'budi@example.com',
  String password = 'kopi tubruk pagi',
  String? confirm,
}) async {
  await fill(
    tester,
    name: name,
    email: email,
    password: password,
    confirm: confirm,
  );
  await submit(tester);
}

Finder _contactField(String label, int index) => fieldLabeled(label).at(index);

Future<void> fillContact(
  WidgetTester tester,
  int index, {
  String name = 'Ibu Budi',
  String relationship = 'Ibu',
  String phone = '081255204471',
}) async {
  await tester.enterText(_contactField(_contactName, index), name);
  await tester.enterText(
    _contactField(_contactRelationship, index),
    relationship,
  );
  await tester.enterText(_contactField(_contactPhone, index), phone);
  await tester.pump();
}

String? contactError(WidgetTester tester, String label, int index) => tester
    .widget<InputDecorator>(
      find.descendant(
        of: labeledField(label).at(index),
        matching: find.byType(InputDecorator),
      ),
    )
    .decoration
    .errorText;

Future<void> fillTwoContacts(WidgetTester tester) async {
  await fillContact(tester, 0);
  await fillContact(
    tester,
    1,
    name: 'Adi',
    relationship: 'Kakak',
    phone: '081311112222',
  );
}

FakeInvitationRepository withContactsRequired() =>
    FakeInvitationRepository()
      ..previewResult = makeInvitationPreview(emergencyContactsRequired: true);

void main() {
  late FakeInvitationRepository invitations;

  setUp(() => invitations = FakeInvitationRepository());

  group('entry from the sign in screen', () {
    testWidgets('offers the link to activate with an invitation link', (
      tester,
    ) async {
      await pumpLogin(tester, FakeAuthRepository());

      expect(buttonLabelled('Aktifkan dengan tautan undangan'), findsOneWidget);
    });

    testWidgets('the link opens the activation screen', (tester) async {
      await pumpLogin(tester, FakeAuthRepository());

      await tapVisible(
        tester,
        buttonLabelled('Aktifkan dengan tautan undangan'),
      );

      expect(currentPath(tester), '/aktivasi');
      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('the entry link is a target of at least 48 dp', (tester) async {
      await pumpLogin(tester, FakeAuthRepository());
      final handle = tester.ensureSemantics();
      try {
        final rect = tester
            .getSemantics(find.text('Aktifkan dengan tautan undangan'))
            .rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });
  });

  group('pasting the link', () {
    testWidgets('shows the title, the labelled link field and the button', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);

      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Aktivasi Akun'),
        ),
        findsOneWidget,
      );
      expect(field(_link), findsOneWidget);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
      expect(field(_name), findsNothing);
      expect(fieldError(tester, _link), isNull);
      expect(invitations.previews, isEmpty);
    });

    testWidgets('keeps paste enabled on the link field', (tester) async {
      await pumpActivation(tester, invitations);

      expect(textField(tester, _link).enableInteractiveSelection, isNot(false));
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('an empty link asks for the link and sends nothing', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);

      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(fieldError(tester, _link), isNotNull);
      expect(fieldError(tester, _link), contains('tautan'));
      expect(invitations.previews, isEmpty);
    });

    testWidgets('a blank link counts as empty', (tester) async {
      await pumpActivation(tester, invitations);

      await continueWith(tester, '   \n ');

      expect(fieldError(tester, _link), contains('tautan'));
      expect(invitations.previews, isEmpty);
    });

    testWidgets('a link with no path segment sends nothing', (tester) async {
      await pumpActivation(tester, invitations);

      await continueWith(tester, '///');

      expect(fieldError(tester, _link), isNotNull);
      expect(invitations.previews, isEmpty);
    });

    testWidgets('sends the last path segment of the link as the token', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(invitations.previews, ['abc123']);
    });

    testWidgets('trims the link, drops the slash and the query', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);

      await continueWith(
        tester,
        '  https://niscala.example/undangan/abc123/?utm=wa  ',
      );

      expect(invitations.previews, ['abc123']);
    });

    testWidgets('sends a pasted bare token as it is', (tester) async {
      await pumpActivation(tester, invitations);

      await continueWith(tester, 'abc123');

      expect(invitations.previews, ['abc123']);
    });

    testWidgets('the field error goes away on the next valid attempt', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);
      await tapVisible(tester, buttonLabelled('Lanjut'));

      await continueWith(tester, _tokenLink);

      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(invitations.previews, ['abc123']);
      expect(find.text(_link), findsNothing);
    });
  });

  group('preview of an invitation that cannot be used', () {
    testWidgets('an expired invitation shows a message and no form', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.expired,
      );
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.textContaining('kedaluwarsa'), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(field(_name), findsNothing);
      expect(buttonLabelled('Aktifkan Akun'), findsNothing);
    });

    testWidgets('a used invitation shows a message and no form', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.used,
      );
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.textContaining('sudah dipakai'), findsOneWidget);
      expect(find.textContaining('kedaluwarsa'), findsNothing);
      expect(field(_name), findsNothing);
      expect(buttonLabelled('Aktifkan Akun'), findsNothing);
    });

    testWidgets(
      'an unknown invitation says it was not found, not a generic error',
      (tester) async {
        invitations.previewFailure = const ApiFailure(
          code: 'INVITATION_NOT_FOUND',
          statusCode: 404,
        );
        await pumpActivation(tester, invitations);

        await continueWith(tester, _tokenLink);

        expect(find.textContaining('tidak ditemukan'), findsOneWidget);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
        expect(field(_name), findsNothing);
      },
    );

    testWidgets('a network failure shows its Indonesian message', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure.network();
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(field(_name), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a server failure shows its Indonesian message', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('an unknown error code shows the generic message', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('never shows the English text or the code of the API', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.textContaining('INVITATION'), findsNothing);
      expect(find.textContaining('not found'), findsNothing);
      expect(find.textContaining('expired'), findsNothing);
    });

    testWidgets('the message stays and is a live region', (tester) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.expired,
      );
      await pumpActivation(tester, invitations);
      await continueWith(tester, _tokenLink);

      await tester.pump(const Duration(seconds: 30));

      final text = tester
          .widgetList<Text>(find.textContaining('kedaluwarsa'))
          .single
          .data!;
      expect(find.text(text), findsOneWidget);
      expectLiveRegion(tester, text);
    });

    testWidgets('keeps the pasted link after a failure', (tester) async {
      invitations.previewFailure = const ApiFailure.network();
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.text(_tokenLink), findsOneWidget);
    });

    testWidgets('the message goes away when the next check starts', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure.network();
      await pumpActivation(tester, invitations);
      await continueWith(tester, _tokenLink);
      invitations.previewGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Lanjut'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(invitations.previews, hasLength(2));
    });

    testWidgets('a corrected link after a failure opens the form', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.used,
      );
      await pumpActivation(tester, invitations);
      await continueWith(tester, _tokenLink);
      invitations.previewResult = makeInvitationPreview();

      await type(tester, _link, 'https://niscala.example/undangan/xyz789');
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(invitations.previews, ['abc123', 'xyz789']);
      expect(field(_name), findsOneWidget);
      expect(find.textContaining('sudah dipakai'), findsNothing);
    });
  });

  group('while the link is being checked', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      invitations.previewGate = Completer<void>();
      await pumpActivation(tester, invitations);
      await type(tester, _link, _tokenLink);

      await tapAndPump(tester, buttonLabelled('Lanjut'));

      expectBusy(tester);
      expect(find.text('Lanjut'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      invitations.previewGate = Completer<void>();
      await pumpActivation(tester, invitations);
      await type(tester, _link, _tokenLink);
      final button = buttonLabelled('Lanjut');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(invitations.previews, hasLength(1));
    });

    testWidgets('restores the button when the check fails', (tester) async {
      invitations.previewGate = Completer<void>();
      invitations.previewFailure = const ApiFailure.network();
      await pumpActivation(tester, invitations);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Lanjut'));

      invitations.previewGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled('Lanjut')).onPressed,
        isNotNull,
      );
    });
  });

  group('activation form of a valid invitation', () {
    testWidgets('replaces the link field and keeps the title', (tester) async {
      await pumpForm(tester, invitations);

      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(currentPath(tester), '/aktivasi');
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Aktivasi Akun'),
        ),
        findsOneWidget,
      );
      expect(field(_link), findsNothing);
      expect(buttonLabelled('Lanjut'), findsNothing);
      expect(field(_name), findsOneWidget);
      expect(field(_email), findsOneWidget);
      expect(field(_password), findsOneWidget);
      expect(field(_confirm), findsOneWidget);
      expect(find.text('Tampilkan kata sandi'), findsOneWidget);
      expect(buttonLabelled('Aktifkan Akun'), findsOneWidget);
    });

    testWidgets('names the inviter, the property and the room', (tester) async {
      await pumpForm(tester, invitations);

      expect(find.textContaining('Siti Pemilik'), findsOneWidget);
      expect(find.textContaining('Kos Melati'), findsOneWidget);
      expect(find.textContaining('08'), findsOneWidget);
    });

    testWidgets('a manager invitation names every property and no room', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        role: InvitationRole.manager,
        roomNumber: null,
        properties: [
          InvitationProperty(address: 'Jl. Melati 1', name: 'Kos Melati'),
          InvitationProperty(address: 'Jl. Mawar 2', name: 'Kos Mawar'),
        ],
      );
      await pumpForm(tester, invitations);

      expect(find.textContaining('Kos Melati'), findsOneWidget);
      expect(find.textContaining('Kos Mawar'), findsOneWidget);
      expect(find.textContaining('Kamar'), findsNothing);
    });

    testWidgets('pre-fills the name from the invitation and nothing else', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      expect(textField(tester, _name).controller?.text, 'Budi Santoso');
      expect(textField(tester, _email).controller?.text, isEmpty);
      expect(textField(tester, _password).controller?.text, isEmpty);
      expect(textField(tester, _confirm).controller?.text, isEmpty);
    });

    testWidgets('shows no error and sends nothing before the first submit', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      for (final label in [_name, _email, _password, _confirm]) {
        expect(fieldError(tester, label), isNull);
      }
      expect(invitations.activations, isEmpty);
    });

    testWidgets('starts with both passwords hidden', (tester) async {
      await pumpForm(tester, invitations);

      expect(textField(tester, _password).obscureText, isTrue);
      expect(textField(tester, _confirm).obscureText, isTrue);
      expect(textField(tester, _email).obscureText, isFalse);
    });

    testWidgets('one checkbox reveals and hides both password fields', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      expect(find.byType(Checkbox), findsOneWidget);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));
      expect(textField(tester, _password).obscureText, isFalse);
      expect(textField(tester, _confirm).obscureText, isFalse);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));
      expect(textField(tester, _password).obscureText, isTrue);
      expect(textField(tester, _confirm).obscureText, isTrue);
    });

    testWidgets('the show password checkbox is labelled and 48 dp', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      expectShowPasswordCheckbox(tester, checked: false);

      await tapVisible(tester, find.text('Tampilkan kata sandi'));
      expectShowPasswordCheckbox(tester, checked: true);
    });

    testWidgets('the back button returns to the sign in screen', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      final handle = tester.ensureSemantics();

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(currentPath(tester), '/masuk');
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('emergency contacts', () {
    testWidgets('are not shown when the invitation does not need them', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      expect(find.textContaining('Kontak darurat'), findsNothing);
      expect(field(_contactName), findsNothing);
      expect(find.text('Tambah Kontak Darurat'), findsNothing);
    });

    testWidgets('start as two empty blocks when the invitation needs them', (
      tester,
    ) async {
      await pumpForm(tester, withContactsRequired());

      expect(find.text('Kontak darurat (wajib)'), findsOneWidget);
      expect(find.text('Kontak darurat 1'), findsOneWidget);
      expect(find.text('Kontak darurat 2'), findsOneWidget);
      expect(find.text('Kontak darurat 3'), findsNothing);
      expect(field(_contactName), findsNWidgets(2));
      expect(field(_contactRelationship), findsNWidgets(2));
      expect(field(_contactPhone), findsNWidgets(2));
      expect(find.text('Tambah Kontak Darurat'), findsOneWidget);
    });

    testWidgets('can grow up to four and then hide the add button', (
      tester,
    ) async {
      await pumpForm(tester, withContactsRequired());

      await tapVisible(tester, find.text('Tambah Kontak Darurat'));
      expect(field(_contactName), findsNWidgets(3));
      await tapVisible(tester, find.text('Tambah Kontak Darurat'));

      expect(field(_contactName), findsNWidgets(4));
      expect(find.text('Kontak darurat 4'), findsOneWidget);
      expect(find.text('Tambah Kontak Darurat'), findsNothing);
    });

    testWidgets('a block can be removed and the rest are renumbered', (
      tester,
    ) async {
      await pumpForm(tester, withContactsRequired());
      await tapVisible(tester, find.text('Tambah Kontak Darurat'));
      await fillContact(tester, 1, name: 'Adi');

      final handle = tester.ensureSemantics();
      await tester.tap(find.byTooltip('Hapus kontak darurat 1'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(field(_contactName), findsNWidgets(2));
      expect(find.text('Kontak darurat 3'), findsNothing);
      expect(find.text('Adi'), findsOneWidget);
    });

    testWidgets('submitting empty blocks names the missing fields', (
      tester,
    ) async {
      final repository = withContactsRequired();
      await pumpForm(tester, repository);
      await fill(tester);

      await submit(tester);

      for (var i = 0; i < 2; i++) {
        expect(contactError(tester, _contactName, i), isNotNull);
        expect(contactError(tester, _contactRelationship, i), isNotNull);
        expect(contactError(tester, _contactPhone, i), isNotNull);
      }
      expect(repository.activations, isEmpty);
    });

    testWidgets('rejects an invalid contact phone number', (tester) async {
      final repository = withContactsRequired();
      await pumpForm(tester, repository);
      await fill(tester);
      await fillContact(tester, 0);
      await fillContact(tester, 1, phone: '12345');

      await submit(tester);

      expect(contactError(tester, _contactPhone, 0), isNull);
      expect(
        contactError(tester, _contactPhone, 1),
        contains('Nomor telepon tidak valid'),
      );
      expect(repository.activations, isEmpty);
    });

    testWidgets('exactly one contact is an error and sends nothing', (
      tester,
    ) async {
      final repository = withContactsRequired();
      await pumpForm(tester, repository);
      await fill(tester);
      await fillContact(tester, 0);
      final handle = tester.ensureSemantics();
      await tester.tap(find.byTooltip('Hapus kontak darurat 2'));
      await tester.pumpAndSettle();
      handle.dispose();

      await submit(tester);

      expect(find.textContaining('minimal 2'), findsOneWidget);
      expect(repository.activations, isEmpty);
    });

    testWidgets('sends the trimmed contacts with the activation', (
      tester,
    ) async {
      final repository = withContactsRequired();
      await pumpForm(tester, repository);
      await fill(tester);
      await fillContact(
        tester,
        0,
        name: '  Ibu Budi ',
        relationship: ' Ibu ',
        phone: ' 081255204471 ',
      );
      await fillContact(
        tester,
        1,
        name: 'Adi',
        relationship: 'Kakak',
        phone: '081311112222',
      );

      await submit(tester);

      expect(repository.activations, hasLength(1));
      expect(repository.activations.single.emergencyContacts, [
        EmergencyContact(
          name: 'Ibu Budi',
          relationship: 'Ibu',
          phone: '081255204471',
        ),
        EmergencyContact(
          name: 'Adi',
          relationship: 'Kakak',
          phone: '081311112222',
        ),
      ]);
    });

    testWidgets('sends four contacts when four are filled', (tester) async {
      final repository = withContactsRequired();
      await pumpForm(tester, repository);
      await fill(tester);
      await tapVisible(tester, find.text('Tambah Kontak Darurat'));
      await tapVisible(tester, find.text('Tambah Kontak Darurat'));
      for (var i = 0; i < 4; i++) {
        await fillContact(tester, i, name: 'Kontak $i');
      }

      await submit(tester);

      expect(repository.activations.single.emergencyContacts, hasLength(4));
    });

    testWidgets('sends no contacts when the invitation does not need them', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(invitations.activations.single.emergencyContacts, isNull);
    });
  });

  group('activating with a manager invitation', () {
    FakeInvitationRepository managerInvitation() => FakeInvitationRepository()
      ..previewResult = makeInvitationPreview(
        role: InvitationRole.manager,
        roomNumber: null,
        emergencyContactsRequired: false,
        properties: [
          InvitationProperty(address: 'Jl. Melati 1', name: 'Kos Melati'),
          InvitationProperty(address: 'Jl. Mawar 2', name: 'Kos Mawar'),
        ],
      )
      ..activateResult = authSessionFor(UserRole.manager);

    testWidgets('shows no emergency contact fields', (tester) async {
      await pumpForm(tester, managerInvitation());

      expect(find.textContaining('Kontak darurat'), findsNothing);
      expect(field(_contactName), findsNothing);
      expect(field(_contactRelationship), findsNothing);
      expect(field(_contactPhone), findsNothing);
      expect(find.text('Tambah Kontak Darurat'), findsNothing);
    });

    testWidgets('names the inviter and every property but no room', (
      tester,
    ) async {
      await pumpForm(tester, managerInvitation());

      expect(find.textContaining('Siti Pemilik'), findsOneWidget);
      expect(find.textContaining('Kos Melati'), findsOneWidget);
      expect(find.textContaining('Kos Mawar'), findsOneWidget);
      expect(find.textContaining('Kamar'), findsNothing);
    });

    testWidgets('activates without sending emergency contacts', (tester) async {
      final repository = managerInvitation();
      await pumpForm(tester, repository);

      await fillAndSubmit(tester);

      expect(repository.activations, hasLength(1));
      expect(repository.activations.single.token, 'abc123');
      expect(repository.activations.single.emergencyContacts, isNull);
    });

    testWidgets('the form is valid without any contact', (tester) async {
      await pumpForm(tester, managerInvitation());

      await fillAndSubmit(tester);

      expect(find.textContaining('minimal 2'), findsNothing);
      expect(currentPath(tester), '/beranda');
    });

    testWidgets('meets the guidelines on the form', (tester) async {
      await pumpForm(tester, managerInvitation());

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('validation', () {
    testWidgets('empty fields name every field and send nothing', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await type(tester, _name, '');

      await submit(tester);

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(fieldError(tester, _password), 'Kata sandi minimal 8 karakter.');
      expect(fieldError(tester, _confirm), 'Ketik ulang kata sandi.');
      expect(invitations.activations, isEmpty);
    });

    testWidgets('a blank name counts as empty', (tester) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, name: '   ');

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(invitations.activations, isEmpty);
    });

    for (final bad in [
      'budi',
      'budi@',
      'budi@example',
      '@example.com',
      'a b@c.d',
    ]) {
      testWidgets('rejects the email "$bad" without a request', (tester) async {
        await pumpForm(tester, invitations);

        await fillAndSubmit(tester, email: bad);

        expect(fieldError(tester, _email), 'Format email tidak valid.');
        expect(invitations.activations, isEmpty);
      });
    }

    testWidgets('rejects a password shorter than 8 characters', (tester) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, password: 'x7Kqx7K');

      expect(fieldError(tester, _password), 'Kata sandi minimal 8 karakter.');
      expect(invitations.activations, isEmpty);
    });

    testWidgets('accepts a password of exactly 8 characters', (tester) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, password: 'x7Kqx7Kq');

      expect(invitations.activations, hasLength(1));
      expect(invitations.activations.single.password, 'x7Kqx7Kq');
    });

    testWidgets('accepts a password of exactly 128 characters', (tester) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, password: 'x7Kq' * 32);

      expect(invitations.activations, hasLength(1));
    });

    testWidgets('rejects a password longer than 128 characters', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, password: '${'x7Kq' * 32}z');

      expect(
        fieldError(tester, _password),
        'Kata sandi maksimal 128 karakter.',
      );
      expect(invitations.activations, isEmpty);
    });

    testWidgets('asks to retype when the confirmation is empty', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await fill(tester);
      await type(tester, _confirm, '');

      await submit(tester);

      expect(fieldError(tester, _confirm), 'Ketik ulang kata sandi.');
      expect(fieldError(tester, _password), isNull);
      expect(invitations.activations, isEmpty);
    });

    testWidgets('rejects a confirmation that differs from the password', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, confirm: 'kopi tubruk sore');

      expect(
        fieldError(tester, _confirm),
        'Konfirmasi tidak sama dengan kata sandi.',
      );
      expect(invitations.activations, isEmpty);
    });

    testWidgets('compares the confirmation without trimming', (tester) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester, confirm: 'kopi tubruk pagi ');

      expect(
        fieldError(tester, _confirm),
        'Konfirmasi tidak sama dengan kata sandi.',
      );
      expect(invitations.activations, isEmpty);
    });

    testWidgets('errors disappear once the form is valid and resubmitted', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await submit(tester);

      await fillAndSubmit(tester);

      expect(invitations.activations, hasLength(1));
      expect(find.text('Email wajib diisi.'), findsNothing);
    });
  });

  group('submit', () {
    testWidgets(
      'sends the token, the trimmed name and email and the untouched password',
      (tester) async {
        await pumpForm(tester, invitations);

        await fillAndSubmit(
          tester,
          name: '  Budi S. ',
          email: ' budi@example.com  ',
          password: ' kopi tubruk pagi ',
        );

        expect(invitations.activations, hasLength(1));
        final sent = invitations.activations.single;
        expect(sent.token, 'abc123');
        expect(sent.name, 'Budi S.');
        expect(sent.email, 'budi@example.com');
        expect(sent.password, ' kopi tubruk pagi ');
      },
    );

    testWidgets('sends the pre-filled name when the user leaves it', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(invitations.activations.single.name, 'Budi Santoso');
    });

    testWidgets('an unverified account is taken to email verification', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(currentPath(tester), '/verifikasi-email');
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.byType(ActivationScreen), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('stores the new session for a tenant', (tester) async {
      useTallScreen(tester);
      final store = InMemorySessionStore();
      await tester.pumpWidget(
        buildTestApp(store: store, invitations: invitations),
      );
      await tester.pumpAndSettle();
      goTo(tester, '/aktivasi');
      await tester.pumpAndSettle();
      await continueWith(tester, _tokenLink);

      await fillAndSubmit(tester);

      expect(store.stored?.role, UserRole.tenant);
      expect(store.stored?.emailVerified, isFalse);
      expect(store.stored?.accessToken, invitations.activateResult.accessToken);
      expect(
        store.stored?.refreshToken,
        invitations.activateResult.refreshToken,
      );
    });

    testWidgets('a verified tenant lands on the tenant home', (tester) async {
      invitations.activateResult = authSessionFor(UserRole.tenant);
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('a verified manager lands on the management home', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        role: InvitationRole.manager,
        roomNumber: null,
      );
      invitations.activateResult = authSessionFor(UserRole.manager);
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(currentPath(tester), '/beranda');
    });
  });

  group('failures', () {
    testWidgets('EMAIL_ALREADY_REGISTERED is shown on the email field', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_REGISTERED',
        field: 'email',
        statusCode: 409,
      );
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(
        fieldError(tester, _email),
        messageOfCode('EMAIL_ALREADY_REGISTERED'),
      );
      expect(fieldError(tester, _password), isNull);
      expect(find.byType(ActivationScreen), findsOneWidget);
    });

    testWidgets(
      'EMAIL_ALREADY_REGISTERED without a field still marks the email',
      (tester) async {
        invitations.activateFailure = const ApiFailure(
          code: 'EMAIL_ALREADY_REGISTERED',
        );
        await pumpForm(tester, invitations);

        await fillAndSubmit(tester);

        expect(
          fieldError(tester, _email),
          messageOfCode('EMAIL_ALREADY_REGISTERED'),
        );
      },
    );

    testWidgets('PASSWORD_TOO_COMMON is shown on the password field', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure(
        code: 'PASSWORD_TOO_COMMON',
        field: 'password',
      );
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(
        fieldError(tester, _password),
        messageOfCode('PASSWORD_TOO_COMMON'),
      );
      expect(fieldError(tester, _email), isNull);
    });

    testWidgets(
      'PASSWORD_TOO_COMMON without a field still marks the password',
      (tester) async {
        invitations.activateFailure = const ApiFailure(
          code: 'PASSWORD_TOO_COMMON',
        );
        await pumpForm(tester, invitations);

        await fillAndSubmit(tester);

        expect(
          fieldError(tester, _password),
          messageOfCode('PASSWORD_TOO_COMMON'),
        );
      },
    );

    final fieldCases = {'name': _name, 'email': _email, 'password': _password};
    for (final entry in fieldCases.entries) {
      testWidgets(
        'a failure for the ${entry.key} field is shown on that field',
        (tester) async {
          invitations.activateFailure = ApiFailure(
            code: 'VALIDATION_FAILED',
            field: entry.key,
            statusCode: 422,
          );
          await pumpForm(tester, invitations);

          await fillAndSubmit(tester);

          final message = fieldError(tester, entry.value);
          expect(message, isNotNull);
          expect(message, isNot('Terjadi kesalahan. Coba lagi.'));
          expect(message, endsWith(' tidak valid.'));
          for (final other in fieldCases.entries.where(
            (e) => e.key != entry.key,
          )) {
            expect(fieldError(tester, other.value), isNull);
          }
        },
      );
    }

    testWidgets('a validation failure on name says the full name is invalid', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'name',
        statusCode: 422,
      );
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(fieldError(tester, _name), 'Nama lengkap tidak valid.');
      expect(find.text('Nama properti tidak valid.'), findsNothing);
    });

    testWidgets('a validation failure on email says the email is invalid', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'email',
        statusCode: 422,
      );
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(fieldError(tester, _email), 'Email tidak valid.');
    });

    final bannerCases = {
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': 'Terjadi kesalahan. Coba lagi.',
    };
    for (final entry in bannerCases.entries) {
      testWidgets('${entry.key} is shown in a banner, not on a field', (
        tester,
      ) async {
        invitations.activateFailure = ApiFailure(code: entry.key);
        await pumpForm(tester, invitations);

        await fillAndSubmit(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        for (final label in [_name, _email, _password, _confirm]) {
          expect(fieldError(tester, label), isNull);
        }
        expect(currentPath(tester), '/aktivasi');
      });
    }

    testWidgets('the banner stays and is a live region', (tester) async {
      invitations.activateFailure = const ApiFailure.network();
      await pumpForm(tester, invitations);
      await fillAndSubmit(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('the banner goes away when the next request starts', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure.network();
      await pumpForm(tester, invitations);
      await fillAndSubmit(tester);
      invitations.activateGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(invitations.activations, hasLength(2));
    });

    testWidgets('the user can fix the email and activate again', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_REGISTERED',
        field: 'email',
      );
      await pumpForm(tester, invitations);
      await fillAndSubmit(tester);
      invitations.activateFailure = null;

      await type(tester, _email, 'budi.baru@example.com');
      await submit(tester);

      expect(invitations.activations, hasLength(2));
      expect(invitations.activations.last.email, 'budi.baru@example.com');
      expect(invitations.activations.last.token, 'abc123');
      expect(currentPath(tester), '/verifikasi-email');
    });

    testWidgets('keeps what the user typed after a failure', (tester) async {
      invitations.activateFailure = const ApiFailure.network();
      await pumpForm(tester, invitations);

      await fillAndSubmit(tester);

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
    });

    testWidgets('keeps the contacts the user typed after a failure', (
      tester,
    ) async {
      final repository = withContactsRequired()
        ..activateFailure = const ApiFailure.network();
      await pumpForm(tester, repository);
      await fill(tester);
      await fillTwoContacts(tester);

      await submit(tester);

      expect(find.text('Ibu Budi'), findsOneWidget);
      expect(find.text('081311112222'), findsOneWidget);
      expect(repository.activations, hasLength(1));
    });
  });

  group('while the account is being created', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      invitations.activateGate = Completer<void>();
      await pumpForm(tester, invitations);
      await fill(tester);

      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      expectBusy(tester);
      expect(find.text('Aktifkan Akun'), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      invitations.activateGate = Completer<void>();
      await pumpForm(tester, invitations);
      await fill(tester);
      final button = buttonLabelled('Aktifkan Akun');

      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(invitations.activations, hasLength(1));
    });

    testWidgets('an invalid form does not start a request', (tester) async {
      invitations.activateGate = Completer<void>();
      await pumpForm(tester, invitations);

      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(invitations.activations, isEmpty);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      invitations.activateGate = Completer<void>();
      invitations.activateFailure = const ApiFailure.network();
      await pumpForm(tester, invitations);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      invitations.activateGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(buttonLabelled('Aktifkan Akun'))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('strength meter', () {
    testWidgets('invites typing while the password is empty', (tester) async {
      await pumpForm(tester, invitations);

      expect(find.text(_strengthHint), findsOneWidget);
    });

    testWidgets('follows the password while typing', (tester) async {
      await pumpForm(tester, invitations);

      await type(tester, _password, 'abc');
      expect(find.text(_tooShort), findsOneWidget);

      await type(tester, _password, 'kopi tubruk pagi');
      expect(find.text(_veryStrong), findsOneWidget);
      expect(find.textContaining('Kekuatan'), findsOneWidget);
    });

    testWidgets('flags a common password as easy to guess', (tester) async {
      await pumpForm(tester, invitations);

      await type(tester, _password, 'password123');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('weakens a password that contains the pre-filled name', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await type(tester, _password, 'budi-kopi-tubruk');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('recovers when the name is changed to something else', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await type(tester, _password, 'budi-kopi-tubruk');

      await type(tester, _name, 'Siti Aminah');

      expect(find.text(_veryStrong), findsOneWidget);
    });

    testWidgets('weakens when the password contains the email local part', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await type(tester, _password, 'xx-andi.naufal-9');
      expect(find.text(_veryStrong), findsOneWidget);

      await type(tester, _email, 'andi.naufal@example.com');

      expect(find.text(_guessable), findsOneWidget);
    });

    testWidgets('announces the strength line as a live region', (tester) async {
      await pumpForm(tester, invitations);
      await type(tester, _password, 'kopi tubruk pagi');

      expectLiveRegion(tester, _veryStrong);
    });
  });

  group('authentication rules', () {
    testWidgets('the name field offers the name autofill hint', (tester) async {
      await pumpForm(tester, invitations);

      expect(
        textField(tester, _name).autofillHints,
        contains(AutofillHints.name),
      );
    });

    testWidgets('the email field keeps paste on and offers email autofill', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      expectCredentialField(tester, _email, AutofillHints.email);
    });

    testWidgets('both password fields offer new password autofill', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      expectCredentialField(tester, _password, AutofillHints.newPassword);
      expectCredentialField(tester, _confirm, AutofillHints.newPassword);
    });

    testWidgets('the link field sits in an autofill group', (tester) async {
      await pumpActivation(tester, invitations);

      expect(
        find.ancestor(of: field(_link), matching: find.byType(AutofillGroup)),
        findsOneWidget,
      );
    });
  });

  group('structure', () {
    const formLabels = [_name, _email, _password, _confirm];

    testWidgets('wraps the link field in a LabeledField with its marker', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);

      expect(labeledField(_link), findsOneWidget);
      expect(find.text(_link), findsOneWidget);
    });

    testWidgets('draws no label inside the link field', (tester) async {
      await pumpActivation(tester, invitations);

      expectNoDecorationLabels(tester);
    });

    testWidgets('keeps the link step without a footer', (tester) async {
      await pumpActivation(tester, invitations);

      expect(find.byType(ActionFooter), findsNothing);
      expect(buttonLabelled('Lanjut'), findsOneWidget);
    });

    testWidgets('a link step with a field error still has no footer', (
      tester,
    ) async {
      await pumpActivation(tester, invitations);
      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(find.byType(ActionFooter), findsNothing);
      expect(fieldError(tester, _link), contains('tautan'));
    });

    for (final status in [
      InvitationLinkStatus.expired,
      InvitationLinkStatus.used,
    ]) {
      testWidgets('a $status invitation shows no footer and no form', (
        tester,
      ) async {
        invitations.previewResult = makeInvitationPreview(status: status);
        await pumpActivation(tester, invitations);

        await continueWith(tester, _tokenLink);

        expect(find.byType(ActionFooter), findsNothing);
        expect(field(_name), findsNothing);
      });
    }

    testWidgets('a failed check shows no footer', (tester) async {
      invitations.previewFailure = const ApiFailure.network();
      await pumpActivation(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.byType(ActionFooter), findsNothing);
    });

    testWidgets(
      'the form wraps every field in a LabeledField with its marker',
      (tester) async {
        await pumpForm(tester, invitations);

        for (final label in formLabels) {
          expect(labeledField(label), findsOneWidget);
          expect(find.text(label), findsOneWidget);
        }
      },
    );

    testWidgets('the form draws no label inside any field', (tester) async {
      await pumpForm(tester, invitations);

      expectNoDecorationLabels(tester);
    });

    testWidgets('the form puts each label above its field', (tester) async {
      await pumpForm(tester, invitations);

      for (final label in formLabels) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top));
      }
    });

    testWidgets('the form reads each field label once, on its field', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      for (final label in formLabels) {
        expectFieldNode(tester, label);
      }
    });

    testWidgets('the form keeps each field error on its field node', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await typeInto(tester, _name, '');
      await submit(tester);

      expectFieldNode(tester, _name, error: 'Nama wajib diisi.');
      expectFieldNode(tester, _email, error: 'Email wajib diisi.');
      expectFieldNode(
        tester,
        _password,
        error: 'Kata sandi minimal 8 karakter.',
      );
      expectFieldNode(tester, _confirm, error: 'Ketik ulang kata sandi.');
    });

    testWidgets('tapping a label focuses its field on the form', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      await tester.tap(find.text(_password));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_password),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('the emergency contact fields are labelled fields', (
      tester,
    ) async {
      await pumpForm(tester, withContactsRequired());

      for (final label in [_contactName, _contactRelationship, _contactPhone]) {
        expect(labeledField(label), findsNWidgets(2));
        expect(find.text(label), findsNWidgets(2));
      }
    });

    testWidgets('pins the Aktifkan Akun action in a footer on the form', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      expectPinnedFooter(tester, 'Aktifkan Akun');
    });

    testWidgets('keeps the footer action pinned with emergency contacts', (
      tester,
    ) async {
      await pumpForm(tester, withContactsRequired());

      expectPinnedFooter(tester, 'Aktifkan Akun');
    });

    testWidgets('keeps the footer action pinned with a banner', (tester) async {
      invitations.activateFailure = const ApiFailure.network();
      await pumpForm(tester, invitations);
      await fillAndSubmit(tester);

      expectPinnedFooter(tester, 'Aktifkan Akun');
    });

    testWidgets('shows the busy state inside the footer', (tester) async {
      invitations.activateGate = Completer<void>();
      await pumpForm(tester, invitations);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      expect(
        find.descendant(of: find.byType(ActionFooter), matching: busyButton()),
        findsOneWidget,
      );
    });

    testWidgets('keeps the footer button on screen at large text size', (
      tester,
    ) async {
      await pumpActivationAtLargeText(tester, invitations);
      await continueWith(tester, _tokenLink);

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
        tester.getRect(buttonLabelled('Aktifkan Akun')).bottom,
        lessThanOrEqualTo(screen.height),
      );
      expectFooterAtBottom(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses a white app bar with the title on the form', (
      tester,
    ) async {
      await pumpForm(tester, invitations);

      expectWhiteAppBar(tester);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Aktivasi Akun'),
        ),
        findsOneWidget,
      );
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines on the link step', (tester) async {
      await pumpActivation(tester, invitations);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a link field error', (tester) async {
      await pumpActivation(tester, invitations);
      await tapVisible(tester, buttonLabelled('Lanjut'));

      await expectMeetsA11yGuidelines(tester);
    });

    for (final status in [
      InvitationLinkStatus.expired,
      InvitationLinkStatus.used,
    ]) {
      testWidgets('meets the guidelines with a $status invitation', (
        tester,
      ) async {
        invitations.previewResult = makeInvitationPreview(status: status);
        await pumpActivation(tester, invitations);
        await continueWith(tester, _tokenLink);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines with a not found invitation', (
      tester,
    ) async {
      invitations.previewFailure = const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      );
      await pumpActivation(tester, invitations);
      await continueWith(tester, _tokenLink);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a failed check', (tester) async {
      invitations.previewFailure = const ApiFailure.network();
      await pumpActivation(tester, invitations);
      await continueWith(tester, _tokenLink);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the link is being checked', (
      tester,
    ) async {
      invitations.previewGate = Completer<void>();
      await pumpActivation(tester, invitations);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled('Lanjut'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on the form', (tester) async {
      await pumpForm(tester, invitations);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on the form with emergency contacts', (
      tester,
    ) async {
      await pumpForm(tester, withContactsRequired());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with field errors', (tester) async {
      await pumpForm(tester, invitations);
      await type(tester, _name, '');
      await submit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with contact errors', (tester) async {
      await pumpForm(tester, withContactsRequired());
      await submit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with errors from the server', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure(
        code: 'EMAIL_ALREADY_REGISTERED',
        field: 'email',
      );
      await pumpForm(tester, invitations);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a banner on the form', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure.network();
      await pumpForm(tester, invitations);
      await fillAndSubmit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the account is being created', (
      tester,
    ) async {
      invitations.activateGate = Completer<void>();
      await pumpForm(tester, invitations);
      await fill(tester);
      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the passwords shown', (
      tester,
    ) async {
      await pumpForm(tester, invitations);
      await tapVisible(tester, find.text('Tampilkan kata sandi'));

      await expectMeetsA11yGuidelines(tester);
    });

    for (final password in ['abc', 'kopi tubruk pagi']) {
      testWidgets('meets the guidelines with the strength of "$password"', (
        tester,
      ) async {
        await pumpForm(tester, invitations);
        await type(tester, _password, password);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('fits at large text size on the link step', (tester) async {
      await pumpActivationAtLargeText(tester, invitations);

      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a link error', (tester) async {
      await pumpActivationAtLargeText(tester, invitations);

      await tapVisible(tester, buttonLabelled('Lanjut'));

      expect(fieldError(tester, _link), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a message about the link', (
      tester,
    ) async {
      invitations.previewResult = makeInvitationPreview(
        status: InvitationLinkStatus.expired,
      );
      await pumpActivationAtLargeText(tester, invitations);

      await continueWith(tester, _tokenLink);

      expect(find.textContaining('kedaluwarsa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size on the form', (tester) async {
      await pumpActivationAtLargeText(tester, invitations);
      await continueWith(tester, _tokenLink);

      expect(field(_name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with contacts and errors', (
      tester,
    ) async {
      await pumpActivationAtLargeText(tester, withContactsRequired());
      await continueWith(tester, _tokenLink);
      await type(tester, _password, 'abc');

      await submit(tester);

      expect(fieldError(tester, _email), 'Email wajib diisi.');
      expect(contactError(tester, _contactName, 0), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a banner on the form', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure.network();
      await pumpActivationAtLargeText(tester, invitations);
      await continueWith(tester, _tokenLink);
      await fill(tester);

      await submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
