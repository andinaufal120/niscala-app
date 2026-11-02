import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/managers/ui/manager_detail_screen.dart';
import 'package:niscala/features/managers/ui/manager_form_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_share_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'manager_ui_helpers.dart';

const _share = 'Bagikan tautan';
const _regenerate = 'Buat Ulang Tautan Undangan';

/// Rina (not activated, valid invitation), Agus (active) and Dewi (expired).
FakeManagerRepository _repo([List<Manager>? managers]) =>
    FakeManagerRepository(managers: managers ?? sampleManagers());

Future<void> _open(
  WidgetTester tester,
  FakeManagerRepository repo, {
  String managerId = 'm1',
  FakePropertyRepository? properties,
  bool settle = true,
  bool largeText = false,
}) => pumpManagerApp(
  tester,
  repo,
  properties: properties,
  path: '/properti/p1/pengelola/$managerId',
  settle: settle,
  largeText: largeText,
);

/// The `AlertDialog` shown on screen.
Finder _dialog() => find.byType(AlertDialog);

Finder _inDialog(Finder finder) =>
    find.descendant(of: _dialog(), matching: finder);

Future<void> _askToDelete(WidgetTester tester) =>
    tapVisible(tester, find.text('Hapus'));

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(_inDialog(find.text('Hapus')));
  await tester.pumpAndSettle();
}

/// Closes a failure dialog with its last button, when the screen shows its
/// failures in one.
Future<void> _closeFailureDialog(WidgetTester tester) async {
  if (_dialog().evaluate().isEmpty) return;
  await tester.tap(find.descendant(of: _dialog(), matching: anyButton()).last);
  await tester.pumpAndSettle();
}

void main() {
  group('header', () {
    testWidgets('shows the title Rincian Pengelola', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(find.byType(ManagerDetailScreen), findsOneWidget);
      expect(appBarTitle('Rincian Pengelola'), findsOneWidget);
      expect(repo.calls, contains('get:m1'));
    });

    testWidgets('is shown for the manager and property of the path', (
      tester,
    ) async {
      await _open(tester, _repo(), managerId: 'm2');

      final detail = tester.widget<ManagerDetailScreen>(
        find.byType(ManagerDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.managerId, 'm2');
    });

    testWidgets('a nickname is the main text and the name is secondary', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Bu Rina'), findsOneWidget);
      expect(find.textContaining('Rina Putri'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Bu Rina')).dy,
        lessThan(tester.getTopLeft(find.textContaining('Rina Putri')).dy),
      );
    });

    testWidgets('a manager without a nickname shows the name once', (
      tester,
    ) async {
      await _open(tester, _repo(), managerId: 'm3');

      expect(find.textContaining('Dewi Lestari'), findsOneWidget);
    });

    testWidgets('shows the phone number', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('081255204471'), findsOneWidget);
    });

    testWidgets('says the email is not filled in while there is none', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Belum diisi'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('shows the email once the manager has set one', (tester) async {
      await _open(tester, _repo(), managerId: 'm2');

      expect(find.textContaining('agus@example.com'), findsOneWidget);
      expect(find.text('Belum diisi'), findsNothing);
    });

    testWidgets('a not activated manager shows the Belum Diaktifkan badge', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(statusBadge('Belum Diaktifkan'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNothing);
    });

    testWidgets('an active manager shows the Aktif badge', (tester) async {
      await _open(tester, _repo(), managerId: 'm2');

      expect(statusBadge('Aktif'), findsOneWidget);
      expect(statusBadge('Belum Diaktifkan'), findsNothing);
    });

    testWidgets('lists the assigned properties with their addresses', (
      tester,
    ) async {
      await _open(tester, _repo(), managerId: 'm2');

      expect(find.textContaining('Kos Melati'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Jl. Melati 1, Bandung'), findsOneWidget);
      expect(find.textContaining('Kos Mawar'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Jl. Mawar 2, Bandung'), findsOneWidget);
      expect(find.textContaining('Kos Anggrek'), findsNothing);
    });

    testWidgets('a single property shows only its own address', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('Jl. Melati 1, Bandung'), findsOneWidget);
      expect(find.textContaining('Jl. Mawar 2, Bandung'), findsNothing);
    });
  });

  group('invitation', () {
    testWidgets('a valid invitation says when it ends', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('25 Okt 2026'), findsOneWidget);
      expect(find.textContaining('Kedaluwarsa'), findsNothing);
    });

    testWidgets('the end of the invitation follows the manager', (
      tester,
    ) async {
      final manager = makeManager(
        invitation: makeManagerInvitation(
          expiresAt: DateTime.utc(2026, 11, 3, 12),
        ),
      );
      await _open(tester, _repo([manager]));

      expect(find.textContaining('3 Nov 2026'), findsOneWidget);
      expect(find.textContaining('25 Okt 2026'), findsNothing);
    });

    testWidgets(
      'a valid invitation offers to share and to regenerate the link',
      (tester) async {
        await _open(tester, _repo());

        expect(find.text(_share), findsOneWidget);
        expect(find.text(_regenerate), findsOneWidget);
        expectTargetSize(tester, _share);
        expectTargetSize(tester, _regenerate);
      },
    );

    testWidgets('Bagikan tautan opens the share screen', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text(_share));

      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
      final share = tester.widget<ManagerInvitationShareScreen>(
        find.byType(ManagerInvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.managerId, 'm1');
      expect(share.isNew, isFalse);
    });

    testWidgets('Kembali from the share screen reaches the manager again', (
      tester,
    ) async {
      await _open(tester, _repo());
      await tapVisible(tester, find.text(_share));

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m1');
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
    });

    testWidgets('an expired invitation says Kedaluwarsa', (tester) async {
      await _open(tester, _repo(), managerId: 'm3');

      expect(find.textContaining('Kedaluwarsa'), findsAtLeastNWidgets(1));
      expect(find.textContaining('25 Okt 2026'), findsAtLeastNWidgets(1));
    });

    testWidgets('an expired invitation offers no share action', (tester) async {
      await _open(tester, _repo(), managerId: 'm3');

      expect(find.text(_share), findsNothing);
    });

    testWidgets('an expired invitation can be regenerated', (tester) async {
      await _open(tester, _repo(), managerId: 'm3');

      expect(find.text(_regenerate), findsOneWidget);
      expectTargetSize(tester, _regenerate);
    });

    testWidgets('an invitation without a link offers only to regenerate', (
      tester,
    ) async {
      final manager = makeManager(
        invitation: makeManagerInvitation(withoutUrl: true),
      );
      await _open(tester, _repo([manager]));

      expect(find.text(_share), findsNothing);
      expect(find.text(_regenerate), findsOneWidget);
    });

    testWidgets('a not activated manager without invitation can regenerate', (
      tester,
    ) async {
      final manager = makeManager(withoutInvitation: true);
      await _open(tester, _repo([manager]));

      expect(find.text(_share), findsNothing);
      expect(find.text(_regenerate), findsOneWidget);
    });

    testWidgets('an active manager shows no invitation at all', (tester) async {
      await _open(tester, _repo(), managerId: 'm2');

      expect(find.text(_share), findsNothing);
      expect(find.text(_regenerate), findsNothing);
      expect(find.textContaining('Kedaluwarsa'), findsNothing);
      expect(find.textContaining('undangan'), findsNothing);
    });

    testWidgets('an active manager with a used invitation shows no box', (
      tester,
    ) async {
      final manager = makeManager(
        accountStatus: ManagerAccountStatus.active,
        invitation: makeManagerInvitation(),
      );
      await _open(tester, _repo([manager]));

      expect(find.text(_share), findsNothing);
      expect(find.text(_regenerate), findsNothing);
    });
  });

  group('regenerating the link', () {
    testWidgets('asks the backend for a new link of the manager', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.calls, contains('regenerate:m1'));
      expect(repo.regenerateCalls, 1);
    });

    testWidgets('then shows the new link on the share screen', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text(_regenerate));

      expect(currentPath(tester), '/properti/p1/pengelola/m1/undangan');
      final share = tester.widget<ManagerInvitationShareScreen>(
        find.byType(ManagerInvitationShareScreen),
      );
      expect(share.managerId, 'm1');
      expect(share.isNew, isFalse);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/m1-1',
      );
    });

    testWidgets('an expired manager gets a link to share', (tester) async {
      await _open(tester, _repo(), managerId: 'm3');

      await tapVisible(tester, find.text(_regenerate));

      expect(currentPath(tester), '/properti/p1/pengelola/m3/undangan');
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/m3-1',
      );
    });

    testWidgets('Kembali shows the detail with the new invitation', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, managerId: 'm3');
      await tapVisible(tester, find.text(_regenerate));

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m3');
      expect(find.text(_share), findsOneWidget);
      expect(find.textContaining('Kedaluwarsa'), findsNothing);
    });

    testWidgets('a second tap while it is in flight sends one request', (
      tester,
    ) async {
      final repo = _repo()..regenerateScript.gate = Completer<void>();
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
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
    });

    testWidgets('stays on the detail until the new link arrives', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..regenerateScript.gate = gate;
      await _open(tester, repo);
      await tester.ensureVisible(find.text(_regenerate));
      await tester.pump();
      await tester.tap(find.text(_regenerate));
      await tester.pump();

      expect(find.byType(ManagerInvitationShareScreen), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });

    testWidgets('a failure shows its message and keeps the old link', (
      tester,
    ) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/pengelola/m1');
      expect(find.byType(ManagerInvitationShareScreen), findsNothing);
      expect(find.text(_share), findsOneWidget);
      expect(repo.managers.first.invitation!.url, contains('abc123'));
    });

    testWidgets('a failure message stays on screen', (tester) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure(code: 'INTERNAL_ERROR'));
      await _open(tester, repo);
      await tapVisible(tester, find.text(_regenerate));

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('can be tried again after a failure', (tester) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await tapVisible(tester, find.text(_regenerate));
      await _closeFailureDialog(tester);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.regenerateCalls, 2);
      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });

    testWidgets('a manager who became active shows the message and reloads', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      repo.managers[0] = makeManager(
        id: 'm1',
        name: 'Rina Putri',
        nickname: 'Bu Rina',
        email: 'rina@example.com',
        accountStatus: ManagerAccountStatus.active,
      );

      await tapVisible(tester, find.text(_regenerate));

      expect(
        find.text(
          'Pengelola ini sudah aktif, tautan undangan tidak diperlukan.',
        ),
        findsOneWidget,
      );
      expect(repo.getCalls, 2);
      expect(statusBadge('Aktif'), findsOneWidget);
      expect(find.text(_regenerate), findsNothing);
      expect(find.text(_share), findsNothing);
      expect(find.byType(ManagerInvitationShareScreen), findsNothing);
    });

    testWidgets('a manager that is gone shows the message and reloads', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      repo.managers.removeWhere((m) => m.id == 'm1');

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text('Pengelola tidak ditemukan.'), findsAtLeastNWidgets(1));
      expect(repo.getCalls, 2);
      expect(find.byType(ManagerInvitationShareScreen), findsNothing);
    });
  });

  group('edit', () {
    testWidgets('Ubah is at least 48 dp and opens the edit form', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Ubah'), findsOneWidget);
      expectTargetSize(tester, 'Ubah');

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola/m1/ubah');
      final form = tester.widget<ManagerFormScreen>(
        find.byType(ManagerFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.managerId, 'm1');
    });

    testWidgets('an active manager can be edited too', (tester) async {
      await _open(tester, _repo(), managerId: 'm2');

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/pengelola/m2/ubah');
    });

    testWidgets('Kembali from the edit form returns to the detail', (
      tester,
    ) async {
      await _open(tester, _repo());
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m1');
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('Hapus is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Hapus'), findsOneWidget);
      expectTargetSize(tester, 'Hapus');
    });

    testWidgets('an active manager can be deleted too', (tester) async {
      await _open(tester, _repo(), managerId: 'm2');

      expect(find.text('Hapus'), findsOneWidget);
    });

    testWidgets('asks for confirmation naming the manager', (tester) async {
      final repo = _repo();
      await _open(tester, repo, managerId: 'm2');

      await _askToDelete(tester);

      expect(_dialog(), findsOneWidget);
      expect(_inDialog(find.text('Hapus Agus Santoso?')), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(_inDialog(find.text('Hapus')), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('says the access is revoked and the account stays', (
      tester,
    ) async {
      await _open(tester, _repo(), managerId: 'm2');

      await _askToDelete(tester);

      final message = tester
          .widgetList<Text>(_inDialog(find.byType(Text)))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(message, contains('akses'));
      expect(message, contains('akun'));
    });

    testWidgets('Batal makes no call and keeps the detail', (tester) async {
      final repo = _repo();
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);

      await tester.tap(_inDialog(find.text('Batal')));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(repo.deleted, isEmpty);
      expect(repo.calls, isNot(contains('delete:m2')));
      expect(currentPath(tester), '/properti/p1/pengelola/m2');
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
      expect(repo.managers, hasLength(4));
    });

    testWidgets('dismissing the dialog makes no call', (tester) async {
      final repo = _repo();
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('confirming deletes the manager and leaves to the list', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.deleted, ['m2']);
      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
      expect(find.byType(ManagerDetailScreen), findsNothing);
      expect(find.text('Agus Santoso'), findsNothing);
    });

    testWidgets('the list is refreshed after the delete', (tester) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo);
      await tester.tap(find.text('Agus Santoso'));
      await tester.pumpAndSettle();
      expect(repo.listCalls, 1);
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(repo.listCalls, 2);
      expect(find.text('Agus Santoso'), findsNothing);
      expect(find.text('Bu Rina'), findsOneWidget);
    });

    testWidgets('deleting the last manager shows the empty list', (
      tester,
    ) async {
      final repo = _repo([makeManager(nickname: 'Bu Rina')]);
      await pumpManagerApp(tester, repo);
      await tester.tap(find.text('Bu Rina'));
      await tester.pumpAndSettle();
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(find.text('Tambah Pengelola'), findsAtLeastNWidgets(1));
      expect(find.text('Bu Rina'), findsNothing);
    });

    testWidgets('a manager that is already gone shows the message', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);
      repo.managers.removeWhere((m) => m.id == 'm2');

      await _confirmDelete(tester);

      expect(find.text('Pengelola tidak ditemukan.'), findsAtLeastNWidgets(1));
      expect(repo.getCalls, 2);
    });

    testWidgets('another failure shows its message and changes nothing', (
      tester,
    ) async {
      final repo = _repo()..deleteScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);

      await _confirmDelete(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/pengelola/m2');
      expect(find.byType(ManagerDetailScreen), findsOneWidget);
      expect(repo.managers, hasLength(4));
    });

    testWidgets('a failure message stays on screen', (tester) async {
      final repo = _repo()
        ..deleteScript.queue.add(const ApiFailure(code: 'INTERNAL_ERROR'));
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);
      await _confirmDelete(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('can be tried again after a failure', (tester) async {
      final repo = _repo()..deleteScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, managerId: 'm2');
      await _askToDelete(tester);
      await _confirmDelete(tester);
      await _closeFailureDialog(tester);

      await _askToDelete(tester);
      await _confirmDelete(tester);

      expect(repo.deleted, ['m2', 'm2']);
      expect(currentPath(tester), '/properti/p1/pengelola');
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Bu Rina'), findsNothing);
      expect(find.text('Ubah'), findsNothing);
    });

    testWidgets('shows the message of a manager that does not exist', (
      tester,
    ) async {
      await _open(tester, FakeManagerRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('MANAGER_NOT_FOUND')), findsOneWidget);
      expect(find.text('Pengelola tidak ditemukan.'), findsOneWidget);
      expect(find.text(_regenerate), findsNothing);
    });

    testWidgets('shows the Indonesian message of a network failure', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 1);
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
      expect(find.text('Bu Rina'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Kembali returns to the manager list', (tester) async {
      await _open(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.byType(ManagerListScreen), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('uses the white detail app bar titled Rincian Pengelola', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectDetailAppBar(tester);
      expect(appBarTitle('Rincian Pengelola'), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'a not activated manager': (tester, large) =>
          _open(tester, _repo(), largeText: large),
      'an expired invitation': (tester, large) =>
          _open(tester, _repo(), managerId: 'm3', largeText: large),
      'an active manager': (tester, large) =>
          _open(tester, _repo(), managerId: 'm2', largeText: large),
      'a manager without invitation': (tester, large) => _open(
        tester,
        _repo([makeManager(withoutInvitation: true)]),
        largeText: large,
      ),
      'a manager with a long name and many properties': (tester, large) =>
          _open(
            tester,
            _repo([
              makeManager(
                name: 'Anak Agung Gede Ngurah Putra Wijaya Kusuma',
                nickname: 'Gung Aji',
                email: 'anak.agung.gede.ngurah.putra@example.com',
                accountStatus: ManagerAccountStatus.active,
                properties: makeManagerCatalog(),
              ),
            ]),
            largeText: large,
          ),
      'a failure': (tester, large) => _open(
        tester,
        _repo()..getScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'a missing manager': (tester, large) =>
          _open(tester, FakeManagerRepository(), largeText: large),
      'the delete confirmation': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _askToDelete(tester);
      },
      'a failed delete': (tester, large) async {
        final repo = _repo()
          ..deleteScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, largeText: large);
        await _askToDelete(tester);
        await _confirmDelete(tester);
      },
      'a failed regeneration': (tester, large) async {
        final repo = _repo()
          ..regenerateScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, largeText: large);
        await tapVisible(tester, find.text(_regenerate));
      },
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

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
