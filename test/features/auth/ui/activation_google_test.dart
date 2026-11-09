import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/features/auth/ui/activation_screen.dart';
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
const _google = 'Aktifkan dengan Google';
const _tokenLink = 'https://niscala.example/undangan/abc123';

Finder _googleButton() => buttonLabelled(_google);

/// The password activation button, whether it shows its label or the progress
/// indicator.
Finder _passwordButton() {
  final labelled = buttonLabelled('Aktifkan Akun');
  return labelled.evaluate().isNotEmpty ? labelled : busyButton();
}

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

Future<void> _tapGoogle(WidgetTester tester) =>
    tapVisible(tester, _googleButton());

Future<void> _continueWith(WidgetTester tester, String link) async {
  await type(tester, _link, link);
  await tapVisible(tester, buttonLabelled('Lanjut'));
}

/// Shows the activation form of a valid invitation.
Future<void> _pumpForm(
  WidgetTester tester,
  FakeInvitationRepository invitations,
  FakeGoogleIdentity google, {
  bool largeText = false,
}) async {
  final app = buildTestApp(invitations: invitations, google: google);
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, '/aktivasi');
  await tester.pumpAndSettle();
  await _continueWith(tester, _tokenLink);
}

FakeInvitationRepository _withContactsRequired() =>
    FakeInvitationRepository()
      ..previewResult = makeInvitationPreview(emergencyContactsRequired: true);

Finder _contactField(String label, int index) => fieldLabeled(label).at(index);

Future<void> _fillContact(
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

String? _contactError(WidgetTester tester, String label, int index) => tester
    .widget<InputDecorator>(
      find.descendant(
        of: labeledField(label).at(index),
        matching: find.byType(InputDecorator),
      ),
    )
    .decoration
    .errorText;

Future<void> _fillTwoContacts(WidgetTester tester) async {
  await _fillContact(tester, 0);
  await _fillContact(
    tester,
    1,
    name: 'Adi',
    relationship: 'Kakak',
    phone: '081311112222',
  );
}

void main() {
  late FakeInvitationRepository invitations;
  late FakeGoogleIdentity google;

  setUp(() {
    invitations = FakeInvitationRepository();
    google = FakeGoogleIdentity();
  });

  group('content', () {
    testWidgets('offers the Google action next to the password option', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google);

      expect(_googleButton(), findsOneWidget);
      expect(buttonLabelled('Aktifkan Akun'), findsOneWidget);
      expect(field(_password), findsOneWidget);
      expect(google.requests, 0);
      expect(invitations.googleActivations, isEmpty);
    });

    testWidgets('does not offer the Google action before the link is valid', (
      tester,
    ) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        buildTestApp(invitations: invitations, google: google),
      );
      await tester.pumpAndSettle();
      goTo(tester, '/aktivasi');
      await tester.pumpAndSettle();

      expect(field(_link), findsOneWidget);
      expect(_googleButton(), findsNothing);
    });

    testWidgets('offers the Google action with emergency contacts too', (
      tester,
    ) async {
      await _pumpForm(tester, _withContactsRequired(), google);

      expect(_googleButton(), findsOneWidget);
      expect(field(_contactName), findsNWidgets(2));
    });

    testWidgets('the Google action is a labelled button of at least 48 dp', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text(_google));
        expect(
          node,
          isSemantics(label: _google, isButton: true, hasTapAction: true),
        );
        expect(node.rect.height, greaterThanOrEqualTo(48));
        expect(node.rect.width, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });
  });

  group('activating with Google', () {
    testWidgets('sends the token, the pre-filled name and the ID token', (
      tester,
    ) async {
      google.token = 'token-abc';
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(invitations.googleActivations, hasLength(1));
      final sent = invitations.googleActivations.single;
      expect(sent.token, 'abc123');
      expect(sent.name, 'Budi Santoso');
      expect(sent.idToken, 'token-abc');
      expect(sent.emergencyContacts, isNull);
      expect(invitations.activations, isEmpty);
    });

    testWidgets('sends the typed name without surrounding spaces', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, '  Budi S. ');

      await _tapGoogle(tester);

      expect(invitations.googleActivations.single.name, 'Budi S.');
    });

    testWidgets('needs no email or password', (tester) async {
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(invitations.googleActivations, hasLength(1));
      for (final label in [_email, _password, _confirm]) {
        expect(fieldError(tester, label), isNull);
      }
    });

    testWidgets('ignores what is typed in the email and password fields', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google);
      await type(tester, _email, 'budi');
      await type(tester, _password, 'x');
      await type(tester, _confirm, 'y');

      await _tapGoogle(tester);

      expect(invitations.googleActivations, hasLength(1));
      expect(invitations.activations, isEmpty);
      expect(fieldError(tester, _email), isNull);
      expect(fieldError(tester, _password), isNull);
      expect(fieldError(tester, _confirm), isNull);
    });

    testWidgets('a verified tenant lands on the tenant home', (tester) async {
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(ActivationScreen), findsNothing);
      expect(find.byType(VerifyEmailScreen), findsNothing);
    });

    testWidgets('a manager invitation lands on the management home', (
      tester,
    ) async {
      invitations
        ..previewResult = makeInvitationPreview(
          role: InvitationRole.manager,
          roomNumber: null,
        )
        ..activateGoogleResult = authSessionFor(UserRole.manager);
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(currentPath(tester), '/beranda');
      expect(invitations.googleActivations.single.emergencyContacts, isNull);
    });

    testWidgets('stores the new session', (tester) async {
      useTallScreen(tester);
      final store = InMemorySessionStore();
      await tester.pumpWidget(
        buildTestApp(store: store, invitations: invitations, google: google),
      );
      await tester.pumpAndSettle();
      goTo(tester, '/aktivasi');
      await tester.pumpAndSettle();
      await _continueWith(tester, _tokenLink);

      await _tapGoogle(tester);

      expect(store.stored?.role, UserRole.tenant);
      expect(store.stored?.emailVerified, isTrue);
      expect(
        store.stored?.accessToken,
        invitations.activateGoogleResult.accessToken,
      );
      expect(
        store.stored?.refreshToken,
        invitations.activateGoogleResult.refreshToken,
      );
    });
  });

  group('validation before the Google chooser opens', () {
    testWidgets('an empty name asks for the name and opens nothing', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, '');

      await _tapGoogle(tester);

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(google.requests, 0);
      expect(invitations.googleActivations, isEmpty);
    });

    testWidgets('a blank name counts as empty', (tester) async {
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, '    ');

      await _tapGoogle(tester);

      expect(fieldError(tester, _name), 'Nama wajib diisi.');
      expect(google.requests, 0);
      expect(invitations.googleActivations, isEmpty);
    });

    testWidgets('fixing the name lets the next tap through', (tester) async {
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, '');
      await _tapGoogle(tester);

      await type(tester, _name, 'Budi Santoso');
      await _tapGoogle(tester);

      expect(invitations.googleActivations, hasLength(1));
      expect(find.text('Nama wajib diisi.'), findsNothing);
    });

    testWidgets('empty emergency contact blocks name the missing fields', (
      tester,
    ) async {
      final repository = _withContactsRequired();
      await _pumpForm(tester, repository, google);

      await _tapGoogle(tester);

      for (var i = 0; i < 2; i++) {
        expect(_contactError(tester, _contactName, i), isNotNull);
        expect(_contactError(tester, _contactRelationship, i), isNotNull);
        expect(_contactError(tester, _contactPhone, i), isNotNull);
      }
      expect(google.requests, 0);
      expect(repository.googleActivations, isEmpty);
    });

    testWidgets('rejects an invalid contact phone number', (tester) async {
      final repository = _withContactsRequired();
      await _pumpForm(tester, repository, google);
      await _fillContact(tester, 0);
      await _fillContact(tester, 1, phone: '12345');

      await _tapGoogle(tester);

      expect(_contactError(tester, _contactPhone, 0), isNull);
      expect(
        _contactError(tester, _contactPhone, 1),
        contains('Nomor telepon tidak valid'),
      );
      expect(google.requests, 0);
      expect(repository.googleActivations, isEmpty);
    });

    testWidgets('exactly one contact is an error and opens nothing', (
      tester,
    ) async {
      final repository = _withContactsRequired();
      await _pumpForm(tester, repository, google);
      await _fillContact(tester, 0);
      final handle = tester.ensureSemantics();
      await tester.tap(find.byTooltip('Hapus kontak darurat 2'));
      await tester.pumpAndSettle();
      handle.dispose();

      await _tapGoogle(tester);

      expect(find.textContaining('minimal 2'), findsOneWidget);
      expect(google.requests, 0);
      expect(repository.googleActivations, isEmpty);
    });

    testWidgets('contacts are not validated when the invitation needs none', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(find.textContaining('minimal 2'), findsNothing);
      expect(invitations.googleActivations, hasLength(1));
    });
  });

  group('emergency contacts', () {
    testWidgets('are sent trimmed with the activation', (tester) async {
      final repository = _withContactsRequired();
      await _pumpForm(tester, repository, google);
      await _fillContact(
        tester,
        0,
        name: '  Ibu Budi ',
        relationship: ' Ibu ',
        phone: ' 081255204471 ',
      );
      await _fillContact(
        tester,
        1,
        name: 'Adi',
        relationship: 'Kakak',
        phone: '081311112222',
      );

      await _tapGoogle(tester);

      expect(repository.googleActivations, hasLength(1));
      expect(repository.googleActivations.single.emergencyContacts, [
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

    testWidgets('four contacts are all sent', (tester) async {
      final repository = _withContactsRequired();
      await _pumpForm(tester, repository, google);
      await tapVisible(tester, find.text('Tambah Kontak Darurat'));
      await tapVisible(tester, find.text('Tambah Kontak Darurat'));
      for (var i = 0; i < 4; i++) {
        await _fillContact(tester, i, name: 'Kontak $i');
      }

      await _tapGoogle(tester);

      expect(
        repository.googleActivations.single.emergencyContacts,
        hasLength(4),
      );
    });

    testWidgets('are kept after a failure and sent again on retry', (
      tester,
    ) async {
      final repository = _withContactsRequired()
        ..activateGoogleFailure = const ApiFailure.network();
      await _pumpForm(tester, repository, google);
      await _fillTwoContacts(tester);
      await _tapGoogle(tester);
      expect(find.text('Ibu Budi'), findsOneWidget);
      expect(find.text('081311112222'), findsOneWidget);
      repository.activateGoogleFailure = null;

      await _tapGoogle(tester);

      expect(repository.googleActivations, hasLength(2));
      expect(
        repository.googleActivations.last.emergencyContacts,
        repository.googleActivations.first.emergencyContacts,
      );
    });
  });

  group('cancelling the Google chooser', () {
    testWidgets('does nothing and shows no error', (tester) async {
      google.token = null;
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(google.requests, 1);
      expect(invitations.googleActivations, isEmpty);
      expect(currentPath(tester), '/aktivasi');
      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text(genericErrorMessage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      for (final label in [_name, _email, _password, _confirm]) {
        expect(fieldError(tester, label), isNull);
      }
    });

    testWidgets('keeps both actions usable and the typed name', (tester) async {
      google.token = null;
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, 'Budi S.');

      await _tapGoogle(tester);

      expect(find.text('Budi S.'), findsOneWidget);
      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, _passwordButton()), isTrue);
    });

    testWidgets('lets the user try again', (tester) async {
      google.token = null;
      await _pumpForm(tester, invitations, google);
      await _tapGoogle(tester);
      google.token = 'token-2';

      await _tapGoogle(tester);

      expect(google.requests, 2);
      expect(invitations.googleActivations.single.idToken, 'token-2');
      expect(currentPath(tester), '/penyewa/beranda');
    });
  });

  group('when the Google ID token cannot be obtained', () {
    testWidgets('shows that Google sign-in is not available', (tester) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(find.text('Masuk dengan Google belum tersedia.'), findsOneWidget);
      expect(invitations.googleActivations, isEmpty);
      expect(currentPath(tester), '/aktivasi');
    });

    testWidgets('shows the generic message for any other error', (
      tester,
    ) async {
      google.failure = Exception('plugin broke');
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(find.text(genericErrorMessage), findsOneWidget);
      expect(find.textContaining('plugin broke'), findsNothing);
      expect(invitations.googleActivations, isEmpty);
    });
  });

  group('failures from the server', () {
    final cases = {
      'GOOGLE_TOKEN_INVALID': 'Masuk dengan Google gagal. Coba lagi.',
      'GOOGLE_EMAIL_UNVERIFIED': 'Email akun Google ini belum terverifikasi.',
      'GOOGLE_ACCOUNT_ALREADY_REGISTERED':
          'Akun Google ini sudah terdaftar. Masuk dengan Google.',
      'EMAIL_ALREADY_REGISTERED': messageOfCode('EMAIL_ALREADY_REGISTERED'),
      'NETWORK_ERROR': messageOfCode('NETWORK_ERROR'),
      'INTERNAL_ERROR': messageOfCode('INTERNAL_ERROR'),
      'SOMETHING_NEW': genericErrorMessage,
    };

    for (final entry in cases.entries) {
      testWidgets('shows the message for ${entry.key}', (tester) async {
        invitations.activateGoogleFailure = ApiFailure(code: entry.key);
        await _pumpForm(tester, invitations, google);

        await _tapGoogle(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(currentPath(tester), '/aktivasi');
        expect(find.byType(ActivationScreen), findsOneWidget);
        expect(find.textContaining(entry.key), findsNothing);
      });
    }

    testWidgets('a name validation failure is shown on the name field', (
      tester,
    ) async {
      invitations.activateGoogleFailure = const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'name',
        statusCode: 422,
      );
      await _pumpForm(tester, invitations, google);

      await _tapGoogle(tester);

      expect(fieldError(tester, _name), 'Nama lengkap tidak valid.');
    });

    testWidgets('keeps the typed name and lets the user try again', (
      tester,
    ) async {
      invitations.activateGoogleFailure = const ApiFailure.network();
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, 'Budi S.');
      await _tapGoogle(tester);
      expect(find.text('Budi S.'), findsOneWidget);
      invitations.activateGoogleFailure = null;

      await _tapGoogle(tester);

      expect(invitations.googleActivations, hasLength(2));
      expect(invitations.googleActivations.last.name, 'Budi S.');
      expect(currentPath(tester), '/penyewa/beranda');
    });

    testWidgets('keeps the message on screen and announces it', (tester) async {
      invitations.activateGoogleFailure = const ApiFailure(
        code: 'GOOGLE_TOKEN_INVALID',
      );
      await _pumpForm(tester, invitations, google);
      await _tapGoogle(tester);

      await tester.pump(const Duration(seconds: 30));

      const message = 'Masuk dengan Google gagal. Coba lagi.';
      expect(find.text(message), findsOneWidget);
      expectLiveRegion(tester, message);
    });

    testWidgets('removes the message while the next request is in flight', (
      tester,
    ) async {
      invitations.activateGoogleFailure = const ApiFailure(
        code: 'GOOGLE_TOKEN_INVALID',
      );
      await _pumpForm(tester, invitations, google);
      await _tapGoogle(tester);
      invitations.activateGoogleGate = Completer<void>();

      await tapAndPump(tester, _googleButton());

      expect(find.text(messageOfCode('GOOGLE_TOKEN_INVALID')), findsNothing);
      expect(invitations.googleActivations, hasLength(2));
    });
  });

  group('while a request is in flight', () {
    testWidgets('waiting for the Google chooser disables both actions', (
      tester,
    ) async {
      google.gate = Completer<void>();
      await _pumpForm(tester, invitations, google);

      await tapAndPump(tester, _googleButton());

      expect(google.requests, 1);
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _passwordButton()), isFalse);
      google.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('waiting for the server disables both actions', (tester) async {
      invitations.activateGoogleGate = Completer<void>();
      await _pumpForm(tester, invitations, google);

      await tapAndPump(tester, _googleButton());

      expect(invitations.googleActivations, hasLength(1));
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _passwordButton()), isFalse);
      invitations.activateGoogleGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a password activation in flight disables the Google action', (
      tester,
    ) async {
      invitations.activateGate = Completer<void>();
      await _pumpForm(tester, invitations, google);
      await type(tester, _email, 'budi@example.com');
      await type(tester, _password, 'kopi tubruk pagi');
      await type(tester, _confirm, 'kopi tubruk pagi');

      await tapAndPump(tester, buttonLabelled('Aktifkan Akun'));

      expect(invitations.activations, hasLength(1));
      expect(_enabled(tester, _googleButton()), isFalse);
      expect(_enabled(tester, _passwordButton()), isFalse);
      invitations.activateGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a second tap sends one request', (tester) async {
      invitations.activateGoogleGate = Completer<void>();
      await _pumpForm(tester, invitations, google);

      await tapAndPump(tester, _googleButton());
      if (_googleButton().evaluate().isNotEmpty) {
        await tester.tap(_googleButton(), warnIfMissed: false);
        await tester.pump();
      }

      expect(google.requests, 1);
      expect(invitations.googleActivations, hasLength(1));
      invitations.activateGoogleGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('restores both actions when the request fails', (tester) async {
      invitations.activateGoogleGate = Completer<void>();
      invitations.activateGoogleFailure = const ApiFailure.network();
      await _pumpForm(tester, invitations, google);
      await tapAndPump(tester, _googleButton());

      invitations.activateGoogleGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_enabled(tester, _googleButton()), isTrue);
      expect(_enabled(tester, _passwordButton()), isTrue);
    });
  });

  group('availability', () {
    testWidgets('is reachable at large text size', (tester) async {
      await _pumpForm(tester, invitations, google, largeText: true);

      await _tapGoogle(tester);

      expect(tester.takeException(), isNull);
      expect(invitations.googleActivations, hasLength(1));
    });

    testWidgets('is reachable at large text size with emergency contacts', (
      tester,
    ) async {
      final repository = _withContactsRequired();
      await _pumpForm(tester, repository, google, largeText: true);
      await _fillTwoContacts(tester);

      await _tapGoogle(tester);

      expect(tester.takeException(), isNull);
      expect(repository.googleActivations, hasLength(1));
    });

    testWidgets('is reachable with the keyboard open at large text size', (
      tester,
    ) async {
      await _pumpForm(tester, invitations, google, largeText: true);
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await _tapGoogle(tester);

      expect(tester.takeException(), isNull);
      expect(invitations.googleActivations, hasLength(1));
    });

    testWidgets('is still offered after a password activation failure', (
      tester,
    ) async {
      invitations.activateFailure = const ApiFailure.network();
      await _pumpForm(tester, invitations, google);
      await type(tester, _email, 'budi@example.com');
      await type(tester, _password, 'kopi tubruk pagi');
      await type(tester, _confirm, 'kopi tubruk pagi');
      await tapVisible(tester, buttonLabelled('Aktifkan Akun'));

      expect(_googleButton(), findsOneWidget);
      expect(_enabled(tester, _googleButton()), isTrue);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines on the form', (tester) async {
      await _pumpForm(tester, invitations, google);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with emergency contacts', (tester) async {
      await _pumpForm(tester, _withContactsRequired(), google);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a name error', (tester) async {
      await _pumpForm(tester, invitations, google);
      await type(tester, _name, '');
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with contact errors', (tester) async {
      await _pumpForm(tester, _withContactsRequired(), google);
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a Google failure banner', (
      tester,
    ) async {
      invitations.activateGoogleFailure = const ApiFailure(
        code: 'GOOGLE_ACCOUNT_ALREADY_REGISTERED',
      );
      await _pumpForm(tester, invitations, google);
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with an unavailable banner', (
      tester,
    ) async {
      google.failure = const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
      await _pumpForm(tester, invitations, google);
      await _tapGoogle(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while a Google request is in flight', (
      tester,
    ) async {
      invitations.activateGoogleGate = Completer<void>();
      await _pumpForm(tester, invitations, google);
      await tapAndPump(tester, _googleButton());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size on the form', (tester) async {
      await _pumpForm(tester, invitations, google, largeText: true);

      expect(find.byType(ActivationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with contacts and errors', (
      tester,
    ) async {
      await _pumpForm(tester, _withContactsRequired(), google, largeText: true);

      await _tapGoogle(tester);

      expect(_contactError(tester, _contactName, 0), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a Google failure banner', (
      tester,
    ) async {
      invitations.activateGoogleFailure = const ApiFailure(
        code: 'GOOGLE_TOKEN_INVALID',
      );
      await _pumpForm(tester, invitations, google, largeText: true);

      await _tapGoogle(tester);

      expect(
        find.text('Masuk dengan Google gagal. Coba lagi.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size while a request is in flight', (
      tester,
    ) async {
      invitations.activateGoogleGate = Completer<void>();
      await _pumpForm(tester, invitations, google, largeText: true);
      await tester.scrollUntilVisible(
        _googleButton(),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tapAndPump(tester, _googleButton());

      expect(tester.takeException(), isNull);
    });
  });
}
