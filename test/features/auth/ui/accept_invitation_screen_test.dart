import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../account/ui/account_ui_helpers.dart';

const _link = 'Tautan undangan (wajib)';
const _tokenLink = 'https://niscala.example/undangan/abc123';
const _path = '/akun/undangan';

const _title = 'Terima Undangan';
const _helper = 'Tempel tautan yang dibagikan pemilik kost.';
const _linkRequired = 'Tempel tautan undangan dari pemilik kost.';
const _next = 'Lanjut';
const _accept = 'Terima undangan';
const _change = 'Ganti tautan';
const _accountCard = 'Diterima dengan akun';
const _confirmation =
    'Undangan diterima. Properti baru sudah tersedia di menu Properti.';
const _expired =
    'Tautan undangan sudah kedaluwarsa. Minta pemilik kost membuat tautan baru.';
const _used = 'Tautan undangan ini sudah dipakai.';
const _generic = 'Terjadi kesalahan. Coba lagi.';

InvitationPreview _invitation({
  InvitationLinkStatus status = InvitationLinkStatus.valid,
  String inviterName = 'Siti Pemilik',
  List<InvitationProperty>? properties,
}) => makeInvitationPreview(
  status: status,
  role: InvitationRole.manager,
  roomNumber: null,
  inviterName: inviterName,
  properties: properties,
);

Future<void> _open(
  WidgetTester tester,
  FakeInvitationRepository invitations, {
  FakeAccountRepository? accounts,
  FakePropertyRepository? properties,
  bool largeText = false,
  String path = _path,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: UserRole.manager)),
    invitations: invitations,
    accounts:
        accounts ??
        FakeAccountRepository(account: makeAccount(role: UserRole.manager)),
    properties: properties,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, path);
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester, [String link = _tokenLink]) async {
  await type(tester, _link, link);
  await tapVisible(tester, buttonLabelled(_next));
}

/// Shows the second step for [invitations].
Future<void> _openStepTwo(
  WidgetTester tester,
  FakeInvitationRepository invitations, {
  FakeAccountRepository? accounts,
  FakePropertyRepository? properties,
  bool largeText = false,
}) async {
  await _open(
    tester,
    invitations,
    accounts: accounts,
    properties: properties,
    largeText: largeText,
  );
  await _continue(tester);
}

Future<void> _tapAccept(WidgetTester tester) =>
    tapVisible(tester, buttonLabelled(_accept));

FakeInvitationRepository _withPreview(InvitationAcceptancePreview preview) =>
    FakeInvitationRepository()..previewAcceptanceResult = preview;

FakeInvitationRepository _failingPreview(ApiFailure failure) =>
    FakeInvitationRepository()..previewAcceptanceFailure = failure;

FakeInvitationRepository _failingAccept(ApiFailure failure) =>
    FakeInvitationRepository()..acceptFailure = failure;

FakeInvitationRepository _roleMismatch() => _withPreview(
  makeAcceptancePreview(
    accountRole: UserRole.owner,
    blocker: InvitationBlocker.roleMismatch,
  ),
);

FakeInvitationRepository _activeLease() => _withPreview(
  makeAcceptancePreview(
    accountRole: UserRole.tenant,
    blocker: InvitationBlocker.activeLease,
    activeLease: ActiveLeaseSummary(
      propertyName: 'Kos Mawar',
      roomNumber: '12',
      endDate: DateTime.utc(2026, 12, 31),
    ),
  ),
);

FakeInvitationRepository _twoProperties() => _withPreview(
  makeAcceptancePreview(
    invitation: _invitation(
      properties: [
        InvitationProperty(
          address: 'Jl. Melati 1, Bandung',
          name: 'Kos Melati',
        ),
        InvitationProperty(address: 'Jl. Mawar 2, Bandung', name: 'Kos Mawar'),
      ],
    ),
  ),
);

Finder _snackBar() => find.byType(SnackBar);

Finder _appBarTitle() => appBarTitle(_title);

void _expectNoAcceptButton() {
  expect(buttonLabelled(_accept), findsNothing);
}

void main() {
  late FakeInvitationRepository invitations;

  setUp(() => invitations = FakeInvitationRepository());

  group('step one: the link', () {
    testWidgets('is titled Terima Undangan with a back button', (tester) async {
      await _open(tester, invitations);

      expect(_appBarTitle(), findsOneWidget);
      expect(backButton(), findsOneWidget);
      expect(currentPath(tester), _path);
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester, invitations);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('shows the labelled link field, its helper and the button', (
      tester,
    ) async {
      await _open(tester, invitations);

      expect(labeledField(_link), findsOneWidget);
      expect(field(_link), findsOneWidget);
      expect(find.text(_helper), findsOneWidget);
      expect(buttonLabelled(_next), findsOneWidget);
      expect(buttonLabelled(_accept), findsNothing);
    });

    testWidgets('draws no label inside the field and keeps paste enabled', (
      tester,
    ) async {
      await _open(tester, invitations);

      expectNoDecorationLabels(tester);
      expect(textField(tester, _link).enableInteractiveSelection, isNot(false));
    });

    testWidgets('starts empty, without an error and without a request', (
      tester,
    ) async {
      await _open(tester, invitations);

      expect(textField(tester, _link).controller?.text, isEmpty);
      expect(fieldError(tester, _link), isNull);
      expect(invitations.acceptancePreviews, isEmpty);
      expect(invitations.acceptances, isEmpty);
    });

    testWidgets('an empty link names the field and sends nothing', (
      tester,
    ) async {
      await _open(tester, invitations);

      await tapVisible(tester, buttonLabelled(_next));

      expect(fieldError(tester, _link), _linkRequired);
      expect(invitations.acceptancePreviews, isEmpty);
    });

    testWidgets('the field error is exposed on the field node', (tester) async {
      await _open(tester, invitations);

      await tapVisible(tester, buttonLabelled(_next));

      expectFieldNode(tester, _link, error: _linkRequired);
    });

    testWidgets('a blank link counts as empty', (tester) async {
      await _open(tester, invitations);

      await _continue(tester, '   \n ');

      expect(fieldError(tester, _link), _linkRequired);
      expect(invitations.acceptancePreviews, isEmpty);
    });

    testWidgets('a link with no path segment sends nothing', (tester) async {
      await _open(tester, invitations);

      await _continue(tester, '///');

      expect(fieldError(tester, _link), _linkRequired);
      expect(invitations.acceptancePreviews, isEmpty);
    });

    testWidgets('sends the last path segment of the link as the token', (
      tester,
    ) async {
      await _open(tester, invitations);

      await _continue(tester);

      expect(invitations.acceptancePreviews, ['abc123']);
    });

    testWidgets('trims the link and drops the slash and the query', (
      tester,
    ) async {
      await _open(tester, invitations);

      await _continue(
        tester,
        '  https://niscala.example/undangan/abc123/?utm=wa  ',
      );

      expect(invitations.acceptancePreviews, ['abc123']);
    });

    testWidgets('sends a pasted bare token as it is', (tester) async {
      await _open(tester, invitations);

      await _continue(tester, 'abc123');

      expect(invitations.acceptancePreviews, ['abc123']);
    });

    testWidgets('only checks the link, it does not accept', (tester) async {
      await _open(tester, invitations);

      await _continue(tester);

      expect(invitations.acceptances, isEmpty);
      expect(invitations.previews, isEmpty);
    });

    testWidgets('the field error goes away on the next valid attempt', (
      tester,
    ) async {
      await _open(tester, invitations);
      await tapVisible(tester, buttonLabelled(_next));

      await _continue(tester);

      expect(find.text(_linkRequired), findsNothing);
      expect(invitations.acceptancePreviews, ['abc123']);
    });
  });

  group('while the link is being checked', () {
    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      invitations.previewAcceptanceGate = Completer<void>();
      await _open(tester, invitations);
      await type(tester, _link, _tokenLink);

      await tapAndPump(tester, buttonLabelled(_next));

      expectBusy(tester);
      expect(find.text(_next), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      invitations.previewAcceptanceGate = Completer<void>();
      await _open(tester, invitations);
      await type(tester, _link, _tokenLink);
      final button = buttonLabelled(_next);

      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(invitations.acceptancePreviews, hasLength(1));
    });

    testWidgets('restores the button when the check fails', (tester) async {
      invitations.previewAcceptanceGate = Completer<void>();
      invitations.previewAcceptanceFailure = const ApiFailure.network();
      await _open(tester, invitations);
      await type(tester, _link, _tokenLink);
      await tapAndPump(tester, buttonLabelled(_next));

      invitations.previewAcceptanceGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_next)).onPressed,
        isNotNull,
      );
    });

    testWidgets('stays on step one until the check answers', (tester) async {
      invitations.previewAcceptanceGate = Completer<void>();
      await _open(tester, invitations);
      await type(tester, _link, _tokenLink);

      await tapAndPump(tester, buttonLabelled(_next));
      await tester.pump(const Duration(seconds: 5));

      expect(field(_link), findsOneWidget);
      expect(buttonLabelled(_accept), findsNothing);
    });
  });

  group('failures of the check', () {
    final cases = {
      'INVITATION_NOT_FOUND': const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      ),
      'NETWORK_ERROR': const ApiFailure.network(),
      'INTERNAL_ERROR': const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      ),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} shows its Indonesian message in a banner', (
        tester,
      ) async {
        await _open(tester, _failingPreview(entry.value));

        await _continue(tester);

        expect(find.text(messageOfCode(entry.key)), findsOneWidget);
        expect(_snackBar(), findsNothing);
        expect(buttonLabelled(_accept), findsNothing);
        expect(field(_link), findsOneWidget);
      });
    }

    testWidgets('an unknown error code shows the generic message', (
      tester,
    ) async {
      await _open(tester, _failingPreview(const ApiFailure(code: 'NEW_CODE')));

      await _continue(tester);

      expect(find.text(_generic), findsOneWidget);
    });

    testWidgets('never shows the English text or the code of the API', (
      tester,
    ) async {
      await _open(
        tester,
        _failingPreview(
          const ApiFailure(code: 'INVITATION_NOT_FOUND', statusCode: 404),
        ),
      );

      await _continue(tester);

      expect(find.textContaining('INVITATION'), findsNothing);
      expect(find.textContaining('not found'), findsNothing);
    });

    testWidgets('the banner stays and is a live region', (tester) async {
      await _open(tester, _failingPreview(const ApiFailure.network()));
      await _continue(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('keeps the pasted link after a failure', (tester) async {
      await _open(tester, _failingPreview(const ApiFailure.network()));

      await _continue(tester);

      expect(textField(tester, _link).controller?.text, _tokenLink);
    });

    testWidgets('the banner goes away when the next check starts', (
      tester,
    ) async {
      final repo = _failingPreview(const ApiFailure.network());
      await _open(tester, repo);
      await _continue(tester);
      repo.previewAcceptanceGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled(_next));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(repo.acceptancePreviews, hasLength(2));
    });

    testWidgets('trying again after a failure opens step two', (tester) async {
      final repo = _failingPreview(const ApiFailure.network());
      await _open(tester, repo);
      await _continue(tester);
      repo.previewAcceptanceFailure = null;

      await tapVisible(tester, buttonLabelled(_next));

      expect(repo.acceptancePreviews, ['abc123', 'abc123']);
      expect(buttonLabelled(_accept), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('a corrected link after a failure sends the new token', (
      tester,
    ) async {
      final repo = _failingPreview(
        const ApiFailure(code: 'INVITATION_NOT_FOUND', statusCode: 404),
      );
      await _open(tester, repo);
      await _continue(tester);
      repo.previewAcceptanceFailure = null;

      await _continue(tester, 'https://niscala.example/undangan/xyz789');

      expect(repo.acceptancePreviews, ['abc123', 'xyz789']);
      expect(buttonLabelled(_accept), findsOneWidget);
    });
  });

  group('a link that cannot be accepted', () {
    testWidgets('an expired invitation says so and offers no accept button', (
      tester,
    ) async {
      await _open(
        tester,
        _withPreview(
          makeAcceptancePreview(
            invitation: _invitation(status: InvitationLinkStatus.expired),
          ),
        ),
      );

      await _continue(tester);

      expect(find.text(_expired), findsOneWidget);
      expect(find.text(_used), findsNothing);
      _expectNoAcceptButton();
    });

    testWidgets('a used invitation says so and offers no accept button', (
      tester,
    ) async {
      await _open(
        tester,
        _withPreview(
          makeAcceptancePreview(
            invitation: _invitation(status: InvitationLinkStatus.used),
          ),
        ),
      );

      await _continue(tester);

      expect(find.text(_used), findsOneWidget);
      expect(find.text(_expired), findsNothing);
      _expectNoAcceptButton();
    });

    testWidgets('the expired message stays and is a live region', (
      tester,
    ) async {
      await _open(
        tester,
        _withPreview(
          makeAcceptancePreview(
            invitation: _invitation(status: InvitationLinkStatus.expired),
          ),
        ),
      );
      await _continue(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_expired), findsOneWidget);
      expectLiveRegion(tester, _expired);
      expect(_snackBar(), findsNothing);
    });

    testWidgets('a role mismatch shows its message and no accept button', (
      tester,
    ) async {
      await _open(tester, _roleMismatch());

      await _continue(tester);

      expect(
        find.text(messageOfCode('INVITATION_ROLE_MISMATCH')),
        findsOneWidget,
      );
      _expectNoAcceptButton();
    });

    testWidgets('an active lease shows its message and no accept button', (
      tester,
    ) async {
      await _open(tester, _activeLease());

      await _continue(tester);

      expect(
        find.text(messageOfCode('TENANT_HAS_ACTIVE_LEASE')),
        findsOneWidget,
      );
      _expectNoAcceptButton();
    });

    for (final entry in {
      'role mismatch': (
        make: _roleMismatch,
        message: 'INVITATION_ROLE_MISMATCH',
      ),
      'active lease': (make: _activeLease, message: 'TENANT_HAS_ACTIVE_LEASE'),
    }.entries) {
      testWidgets('the ${entry.key} message stays and is a live region', (
        tester,
      ) async {
        await _open(tester, entry.value.make());
        await _continue(tester);

        await tester.pump(const Duration(seconds: 30));

        final message = messageOfCode(entry.value.message);
        expect(find.text(message), findsOneWidget);
        expectLiveRegion(tester, message);
        expect(_snackBar(), findsNothing);
      });

      testWidgets('the ${entry.key} message is not a failed request', (
        tester,
      ) async {
        final repo = entry.value.make();
        await _open(tester, repo);

        await _continue(tester);

        expect(repo.acceptances, isEmpty);
        expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      });
    }

    testWidgets('a preview that cannot be accepted offers no accept button', (
      tester,
    ) async {
      await _open(
        tester,
        _withPreview(makeAcceptancePreview(canAccept: false)),
      );

      await _continue(tester);

      _expectNoAcceptButton();
    });
  });

  group('step two: the invitation', () {
    testWidgets('keeps the title and replaces the link field', (tester) async {
      await _openStepTwo(tester, invitations);

      expect(_appBarTitle(), findsOneWidget);
      expect(currentPath(tester), _path);
      expect(field(_link), findsNothing);
      expect(buttonLabelled(_next), findsNothing);
      expect(buttonLabelled(_accept), findsOneWidget);
    });

    testWidgets('names the inviter', (tester) async {
      await _openStepTwo(tester, invitations);

      expect(find.text('Dari Siti Pemilik'), findsOneWidget);
    });

    testWidgets('follows the inviter of the preview', (tester) async {
      await _openStepTwo(
        tester,
        _withPreview(
          makeAcceptancePreview(
            invitation: _invitation(inviterName: 'Hartono'),
          ),
        ),
      );

      expect(find.text('Dari Hartono'), findsOneWidget);
      expect(find.text('Dari Siti Pemilik'), findsNothing);
    });

    testWidgets('lists the property with its address', (tester) async {
      await _openStepTwo(tester, invitations);

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Jl. Melati 1, Bandung'), findsOneWidget);
    });

    testWidgets('lists every invited property with its address', (
      tester,
    ) async {
      await _openStepTwo(tester, _twoProperties());

      for (final text in [
        'Kos Melati',
        'Jl. Melati 1, Bandung',
        'Kos Mawar',
        'Jl. Mawar 2, Bandung',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('shows the account that will accept, name and email', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      expect(find.text(_accountCard), findsOneWidget);
      expect(find.text('Andi Pengguna'), findsOneWidget);
      expect(find.text('andi@example.com'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Andi Pengguna')).dy,
        greaterThan(tester.getTopLeft(find.text(_accountCard)).dy),
      );
    });

    testWidgets('shows the account of the preview', (tester) async {
      await _openStepTwo(
        tester,
        _withPreview(
          makeAcceptancePreview(
            accountName: 'Rina Kelola',
            accountEmail: 'rina@example.com',
          ),
        ),
      );

      expect(find.text('Rina Kelola'), findsOneWidget);
      expect(find.text('rina@example.com'), findsOneWidget);
    });

    testWidgets('shows the expiry date of the invitation', (tester) async {
      await _openStepTwo(tester, invitations);

      expect(find.textContaining('25 Okt 2026'), findsOneWidget);
    });

    testWidgets('shows the Terima undangan button and the Ganti tautan one', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      expect(buttonLabelled(_accept), findsOneWidget);
      expect(buttonLabelled(_change), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_accept)).onPressed,
        isNotNull,
      );
    });

    testWidgets('shows no room, as it is a manager invitation', (tester) async {
      await _openStepTwo(tester, invitations);

      expect(find.textContaining('Kamar'), findsNothing);
    });

    testWidgets('accepting is not requested before the button is tapped', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      expect(invitations.acceptances, isEmpty);
    });
  });

  group('Ganti tautan', () {
    testWidgets('returns to step one keeping the typed link', (tester) async {
      await _openStepTwo(tester, invitations);

      await tapVisible(tester, buttonLabelled(_change));

      expect(field(_link), findsOneWidget);
      expect(textField(tester, _link).controller?.text, _tokenLink);
      expect(buttonLabelled(_next), findsOneWidget);
      expect(buttonLabelled(_accept), findsNothing);
      expect(currentPath(tester), _path);
    });

    testWidgets('does not accept or leave the page', (tester) async {
      await _openStepTwo(tester, invitations);

      await tapVisible(tester, buttonLabelled(_change));

      expect(invitations.acceptances, isEmpty);
      expect(_appBarTitle(), findsOneWidget);
    });

    testWidgets('a new link is checked with its own token', (tester) async {
      await _openStepTwo(tester, invitations);
      await tapVisible(tester, buttonLabelled(_change));

      await _continue(tester, 'https://niscala.example/undangan/xyz789');

      expect(invitations.acceptancePreviews, ['abc123', 'xyz789']);
      expect(buttonLabelled(_accept), findsOneWidget);
    });

    testWidgets('the new token is the one that is accepted', (tester) async {
      await _openStepTwo(tester, invitations);
      await tapVisible(tester, buttonLabelled(_change));
      await _continue(tester, 'https://niscala.example/undangan/xyz789');

      await _tapAccept(tester);

      expect(invitations.acceptances, ['xyz789']);
    });

    testWidgets('the step one error is gone after coming back', (tester) async {
      await _openStepTwo(tester, invitations);

      await tapVisible(tester, buttonLabelled(_change));

      expect(fieldError(tester, _link), isNull);
    });
  });

  group('accepting', () {
    testWidgets('sends the token of the checked link once', (tester) async {
      await _openStepTwo(tester, invitations);

      await _tapAccept(tester);

      expect(invitations.acceptances, ['abc123']);
    });

    testWidgets('disables the button and shows a labelled progress indicator', (
      tester,
    ) async {
      invitations.acceptGate = Completer<void>();
      await _openStepTwo(tester, invitations);

      await tapAndPump(tester, buttonLabelled(_accept));

      expectBusy(tester);
      expect(find.text(_accept), findsNothing);
    });

    testWidgets('a double tap sends one request', (tester) async {
      invitations.acceptGate = Completer<void>();
      await _openStepTwo(tester, invitations);
      final button = buttonLabelled(_accept);

      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(invitations.acceptances, hasLength(1));
    });

    testWidgets('does not leave the page until the request answers', (
      tester,
    ) async {
      invitations.acceptGate = Completer<void>();
      await _openStepTwo(tester, invitations);

      await tapAndPump(tester, buttonLabelled(_accept));
      await tester.pump(const Duration(seconds: 5));

      expect(currentPath(tester), _path);
      expect(find.text(_confirmation), findsNothing);
    });

    testWidgets('keeps showing the invitation while busy', (tester) async {
      invitations.acceptGate = Completer<void>();
      await _openStepTwo(tester, invitations);

      await tapAndPump(tester, buttonLabelled(_accept));

      expect(find.text('Dari Siti Pemilik'), findsOneWidget);
      expect(find.text('andi@example.com'), findsOneWidget);
    });

    testWidgets('restores the button when the request fails', (tester) async {
      final repo = _failingAccept(const ApiFailure.network())
        ..acceptGate = Completer<void>();
      await _openStepTwo(tester, repo);
      await tapAndPump(tester, buttonLabelled(_accept));

      repo.acceptGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_accept)).onPressed,
        isNotNull,
      );
    });
  });

  group('after accepting', () {
    testWidgets('returns to the Akun tab with the confirmation', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      await _tapAccept(tester);

      expect(currentPath(tester), accountPath(UserRole.manager));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text(_confirmation), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('leaves the invitation page behind', (tester) async {
      await _openStepTwo(tester, invitations);

      await _tapAccept(tester);

      expect(_appBarTitle(), findsNothing);
      expect(buttonLabelled(_accept), findsNothing);
      expect(find.text(_confirmation), findsOneWidget);
    });

    testWidgets('shows the confirmation as a live region, not a snack bar', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      await _tapAccept(tester);

      expect(_snackBar(), findsNothing);
      expectLiveRegion(tester, _confirmation);
    });

    testWidgets('keeps the confirmation on screen', (tester) async {
      await _openStepTwo(tester, invitations);
      await _tapAccept(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_confirmation), findsOneWidget);
      expect(_snackBar(), findsNothing);
    });

    testWidgets('reloads the profile', (tester) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(role: UserRole.manager),
      );
      await _openStepTwo(tester, invitations, accounts: accounts);
      final before = accounts.meCalls;

      await _tapAccept(tester);

      expect(accounts.meCalls, greaterThan(before));
    });

    testWidgets('reloads the property list so the new properties show', (
      tester,
    ) async {
      final properties = FakePropertyRepository(properties: [makeProperty()]);
      await _openStepTwo(tester, invitations, properties: properties);
      final container = containerOf(tester);
      final subscription = container.listen(propertyListProvider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pumpAndSettle();
      expect(properties.listCalls, 1);
      properties.properties.add(makeProperty(id: 'p2', name: 'Kos Mawar'));

      await _tapAccept(tester);
      await tester.pumpAndSettle();

      expect(properties.listCalls, 2);
      expect(container.read(propertyListProvider).value?.map((p) => p.name), [
        'Kos Melati',
        'Kos Mawar',
      ]);
    });

    testWidgets('does not reload before the request succeeds', (tester) async {
      final properties = FakePropertyRepository(properties: [makeProperty()]);
      final repo = _failingAccept(const ApiFailure.network());
      await _openStepTwo(tester, repo, properties: properties);
      final container = containerOf(tester);
      final subscription = container.listen(propertyListProvider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pumpAndSettle();

      await _tapAccept(tester);
      await tester.pumpAndSettle();

      expect(properties.listCalls, 1);
    });
  });

  group('failures of accepting', () {
    final cases = {
      'MANAGER_ALREADY_ADDED': const ApiFailure(
        code: 'MANAGER_ALREADY_ADDED',
        statusCode: 409,
      ),
      'INVITATION_USED': const ApiFailure(
        code: 'INVITATION_USED',
        statusCode: 409,
      ),
      'INVITATION_EXPIRED': const ApiFailure(
        code: 'INVITATION_EXPIRED',
        statusCode: 409,
      ),
      'INVITATION_NOT_FOUND': const ApiFailure(
        code: 'INVITATION_NOT_FOUND',
        statusCode: 404,
      ),
      'INVITATION_ROLE_MISMATCH': const ApiFailure(
        code: 'INVITATION_ROLE_MISMATCH',
        statusCode: 409,
      ),
      'TENANT_HAS_ACTIVE_LEASE': const ApiFailure(
        code: 'TENANT_HAS_ACTIVE_LEASE',
        statusCode: 409,
      ),
      'NETWORK_ERROR': const ApiFailure.network(),
      'INTERNAL_ERROR': const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      ),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} shows its message on the page', (tester) async {
        await _openStepTwo(tester, _failingAccept(entry.value));

        await _tapAccept(tester);

        expect(find.text(messageOfCode(entry.key)), findsOneWidget);
        expect(currentPath(tester), _path);
        expect(find.text(_confirmation), findsNothing);
        expect(_snackBar(), findsNothing);
      });
    }

    testWidgets('an unknown error code shows the generic message', (
      tester,
    ) async {
      await _openStepTwo(
        tester,
        _failingAccept(const ApiFailure(code: 'NEW_CODE')),
      );

      await _tapAccept(tester);

      expect(find.text(_generic), findsOneWidget);
    });

    testWidgets('MANAGER_ALREADY_ADDED says the user is already a manager', (
      tester,
    ) async {
      await _openStepTwo(
        tester,
        _failingAccept(
          const ApiFailure(code: 'MANAGER_ALREADY_ADDED', statusCode: 409),
        ),
      );

      await _tapAccept(tester);

      expect(
        find.text('Anda sudah menjadi pengelola untuk pemilik ini.'),
        findsOneWidget,
      );
    });

    testWidgets('never shows the English text or the code of the API', (
      tester,
    ) async {
      await _openStepTwo(
        tester,
        _failingAccept(
          const ApiFailure(code: 'MANAGER_ALREADY_ADDED', statusCode: 409),
        ),
      );

      await _tapAccept(tester);

      expect(find.textContaining('MANAGER_ALREADY'), findsNothing);
      expect(find.textContaining('already'), findsNothing);
    });

    testWidgets('the message stays and is a live region', (tester) async {
      await _openStepTwo(tester, _failingAccept(const ApiFailure.network()));
      await _tapAccept(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('keeps the invitation and both buttons after a failure', (
      tester,
    ) async {
      await _openStepTwo(tester, _failingAccept(const ApiFailure.network()));

      await _tapAccept(tester);

      expect(find.text('Dari Siti Pemilik'), findsOneWidget);
      expect(find.text('andi@example.com'), findsOneWidget);
      expect(buttonLabelled(_accept), findsOneWidget);
      expect(buttonLabelled(_change), findsOneWidget);
    });

    testWidgets('the message goes away when the next request starts', (
      tester,
    ) async {
      final repo = _failingAccept(const ApiFailure.network());
      await _openStepTwo(tester, repo);
      await _tapAccept(tester);
      repo.acceptGate = Completer<void>();

      await tapAndPump(tester, buttonLabelled(_accept));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(repo.acceptances, hasLength(2));
    });

    testWidgets('trying again after a failure accepts and goes back', (
      tester,
    ) async {
      final repo = _failingAccept(const ApiFailure.network());
      await _openStepTwo(tester, repo);
      await _tapAccept(tester);
      repo.acceptFailure = null;

      await _tapAccept(tester);

      expect(repo.acceptances, ['abc123', 'abc123']);
      expect(currentPath(tester), accountPath(UserRole.manager));
      expect(find.text(_confirmation), findsOneWidget);
    });

    testWidgets('Ganti tautan still works after a failure', (tester) async {
      await _openStepTwo(tester, _failingAccept(const ApiFailure.network()));
      await _tapAccept(tester);

      await tapVisible(tester, buttonLabelled(_change));

      expect(field(_link), findsOneWidget);
      expect(textField(tester, _link).controller?.text, _tokenLink);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('Kembali leaves the page after a failure', (tester) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(role: UserRole.manager),
      );
      final repo = _failingAccept(const ApiFailure.network());
      await _open(
        tester,
        repo,
        accounts: accounts,
        path: accountPath(UserRole.manager),
      );
      await tester.tap(find.text('Terima undangan pengelola'));
      await tester.pumpAndSettle();
      await _continue(tester);
      await _tapAccept(tester);

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.manager));
      expect(find.text(_confirmation), findsNothing);
    });

    testWidgets('does not reload the profile after a failure', (tester) async {
      final accounts = FakeAccountRepository(
        account: makeAccount(role: UserRole.manager),
      );
      await _openStepTwo(
        tester,
        _failingAccept(const ApiFailure.network()),
        accounts: accounts,
      );
      final before = accounts.meCalls;

      await _tapAccept(tester);

      expect(accounts.meCalls, before);
    });
  });

  group('structure', () {
    testWidgets('announces the title as a header', (tester) async {
      await _open(tester, invitations);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(_appBarTitle()),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('step two buttons have a target of at least 48 dp', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      for (final label in [_accept, _change]) {
        final rect = tester.getRect(buttonLabelled(label));
        expect(rect.height, greaterThanOrEqualTo(48), reason: label);
        expect(rect.width, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('step one button has a target of at least 48 dp', (
      tester,
    ) async {
      await _open(tester, invitations);

      final rect = tester.getRect(buttonLabelled(_next));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
    });

    testWidgets('button labels are spoken as their visible text', (
      tester,
    ) async {
      await _openStepTwo(tester, invitations);

      for (final label in [_accept, _change]) {
        expect(semanticsLabelOf(tester, label), startsWith(label));
      }
    });
  });

  group('accessibility', () {
    final states =
        <String, Future<void> Function(WidgetTester, {bool largeText})>{
          'step one': (tester, {largeText = false}) =>
              _open(tester, FakeInvitationRepository(), largeText: largeText),
          'step one with a field error': (tester, {largeText = false}) async {
            await _open(
              tester,
              FakeInvitationRepository(),
              largeText: largeText,
            );
            await tapVisible(tester, buttonLabelled(_next));
          },
          'step one while checking': (tester, {largeText = false}) async {
            final repo = FakeInvitationRepository()
              ..previewAcceptanceGate = Completer<void>();
            await _open(tester, repo, largeText: largeText);
            await type(tester, _link, _tokenLink);
            await tapAndPump(tester, buttonLabelled(_next));
          },
          'a failed check': (tester, {largeText = false}) async {
            await _open(
              tester,
              _failingPreview(const ApiFailure.network()),
              largeText: largeText,
            );
            await _continue(tester);
          },
          'an expired invitation': (tester, {largeText = false}) async {
            await _open(
              tester,
              _withPreview(
                makeAcceptancePreview(
                  invitation: _invitation(status: InvitationLinkStatus.expired),
                ),
              ),
              largeText: largeText,
            );
            await _continue(tester);
          },
          'a used invitation': (tester, {largeText = false}) async {
            await _open(
              tester,
              _withPreview(
                makeAcceptancePreview(
                  invitation: _invitation(status: InvitationLinkStatus.used),
                ),
              ),
              largeText: largeText,
            );
            await _continue(tester);
          },
          'a role mismatch': (tester, {largeText = false}) async {
            await _open(tester, _roleMismatch(), largeText: largeText);
            await _continue(tester);
          },
          'an active lease': (tester, {largeText = false}) async {
            await _open(tester, _activeLease(), largeText: largeText);
            await _continue(tester);
          },
          'step two': (tester, {largeText = false}) => _openStepTwo(
            tester,
            FakeInvitationRepository(),
            largeText: largeText,
          ),
          'step two with two properties': (tester, {largeText = false}) =>
              _openStepTwo(tester, _twoProperties(), largeText: largeText),
          'step two while accepting': (tester, {largeText = false}) async {
            final repo = FakeInvitationRepository()
              ..acceptGate = Completer<void>();
            await _openStepTwo(tester, repo, largeText: largeText);
            await tapAndPump(tester, buttonLabelled(_accept));
          },
          'step two with a failure': (tester, {largeText = false}) async {
            await _openStepTwo(
              tester,
              _failingAccept(
                const ApiFailure(
                  code: 'MANAGER_ALREADY_ADDED',
                  statusCode: 409,
                ),
              ),
              largeText: largeText,
            );
            await _tapAccept(tester);
          },
          'the Akun tab with the confirmation':
              (tester, {largeText = false}) async {
                await _openStepTwo(
                  tester,
                  FakeInvitationRepository(),
                  largeText: largeText,
                );
                await _tapAccept(tester);
              },
        };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines: ${entry.key}', (tester) async {
        await entry.value(tester);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size: ${entry.key}', (tester) async {
        await entry.value(tester, largeText: true);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
