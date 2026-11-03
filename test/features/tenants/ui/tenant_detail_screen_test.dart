import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'tenant_ui_helpers.dart';

const _edit = 'Ubah Data Penyewa';
const _regenerate = 'Buat Ulang Tautan Undangan';

const _created =
    'Tautan undangan dibuat 18 Okt 2026 dan belum digunakan. '
    'Berlaku hingga 25 Okt 2026.';
const _expired =
    'Tautan undangan kedaluwarsa pada 25 Okt 2026 tanpa digunakan.';

final _contacts = [
  EmergencyContact(
    name: 'Siti Rahma',
    relationship: 'Ibu',
    phone: '081355512345',
  ),
  EmergencyContact(name: 'Joko', relationship: 'Kakak', phone: '081355512346'),
];

Tenant _notActivated({
  String? email,
  String? occupation = 'Karyawan swasta',
  BillingCycle billingCycle = BillingCycle.monthly,
  bool noEndDate = false,
  bool noNextBillDate = false,
  int gracePeriodDays = 3,
  List<EmergencyContact>? emergencyContacts,
  TenantInvitation? invitation,
}) => makeTenant(
  id: 't1',
  email: email,
  occupation: occupation,
  billingCycle: billingCycle,
  noEndDate: noEndDate,
  noNextBillDate: noNextBillDate,
  gracePeriodDays: gracePeriodDays,
  emergencyContacts: emergencyContacts ?? _contacts,
  invitation: invitation,
);

Tenant _active({
  String? email = 'budi@example.com',
  String? occupation = 'Karyawan swasta',
  bool noEndDate = false,
  bool noNextBillDate = false,
  List<EmergencyContact>? emergencyContacts,
}) => makeTenant(
  id: 't1',
  email: email,
  occupation: occupation,
  accountStatus: TenantAccountStatus.active,
  noEndDate: noEndDate,
  noNextBillDate: noNextBillDate,
  gracePeriodDays: 3,
  emergencyContacts: emergencyContacts ?? _contacts,
);

FakeTenantRepository _repo([Tenant? tenant]) =>
    FakeTenantRepository(tenants: [tenant ?? _notActivated()]);

Future<void> _open(
  WidgetTester tester,
  FakeTenantRepository repo, {
  UserRole role = UserRole.owner,
  FakePropertyRepository? properties,
  FakeRoomRepository? rooms,
  bool settle = true,
  bool largeText = false,
}) => pumpTenantApp(
  tester,
  repo,
  role: role,
  properties: properties,
  rooms: rooms,
  path: '/properti/p1/penyewa/t1',
  settle: settle,
  largeText: largeText,
);

void main() {
  group('header', () {
    testWidgets('shows the title Rincian Penyewa and the property name', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(appBarTitle('Rincian Penyewa'), findsOneWidget);
      expect(inAppBar('Kos Melati'), findsOneWidget);
      expect(repo.calls, contains('get:t1'));
    });

    testWidgets('still shows the tenant when the property cannot be loaded', (
      tester,
    ) async {
      final properties = propertiesWithMelati()
        ..getScript.always = const ApiFailure.network();
      await _open(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsNothing);
      expect(appBarTitle('Rincian Penyewa'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('shows the name, phone and a missing email', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('081255204471 · email belum diisi'), findsOneWidget);
    });

    testWidgets('shows the phone and the email of an activated tenant', (
      tester,
    ) async {
      await _open(tester, _repo(_active()));

      expect(find.text('081255204471 · budi@example.com'), findsOneWidget);
      expect(find.textContaining('email belum diisi'), findsNothing);
    });

    testWidgets('a not activated tenant shows the Belum Diaktifkan badge', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(statusBadge('Belum Diaktifkan'), findsOneWidget);
      expect(statusBadge('Aktif'), findsNothing);
    });

    testWidgets('an active tenant shows the Aktif badge', (tester) async {
      await _open(tester, _repo(_active()));

      expect(statusBadge('Aktif'), findsOneWidget);
      expect(statusBadge('Belum Diaktifkan'), findsNothing);
    });
  });

  group('invitation', () {
    testWidgets('a valid invitation says when it was made and ends', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_created), findsOneWidget);
      expect(find.text(_expired), findsNothing);
    });

    testWidgets('a valid invitation offers to share the existing link', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Bagikan tautan yang ada'), findsOneWidget);
      expectTargetSize(tester, 'Bagikan tautan yang ada');
    });

    testWidgets('Bagikan tautan yang ada opens the share screen', (
      tester,
    ) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text('Bagikan tautan yang ada'));

      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan');
      final share = tester.widget<InvitationShareScreen>(
        find.byType(InvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.tenantId, 't1');
      expect(share.isNew, isFalse);
    });

    testWidgets('Kembali from the share screen reaches the tenant again', (
      tester,
    ) async {
      await _open(tester, _repo());
      await tapVisible(tester, find.text('Bagikan tautan yang ada'));

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      expect(find.byType(TenantDetailScreen), findsOneWidget);
    });

    testWidgets('an expired invitation says it ended unused', (tester) async {
      final tenant = _notActivated(
        invitation: makeTenantInvitation(expired: true),
      );
      await _open(tester, _repo(tenant));

      expect(find.text(_expired), findsOneWidget);
      expect(find.text(_created), findsNothing);
    });

    testWidgets('an expired invitation offers no share action', (tester) async {
      final tenant = _notActivated(
        invitation: makeTenantInvitation(expired: true),
      );
      await _open(tester, _repo(tenant));

      expect(find.text('Bagikan tautan yang ada'), findsNothing);
    });

    testWidgets('an active tenant shows no invitation box', (tester) async {
      await _open(tester, _repo(_active()));

      expect(find.textContaining('Tautan undangan'), findsNothing);
      expect(find.text('Bagikan tautan yang ada'), findsNothing);
    });

    testWidgets('an active tenant with a used invitation shows no box', (
      tester,
    ) async {
      final tenant = makeTenant(
        accountStatus: TenantAccountStatus.active,
        invitation: makeTenantInvitation(),
      );
      await _open(tester, _repo(tenant));

      expect(find.textContaining('Tautan undangan'), findsNothing);
      expect(find.text('Bagikan tautan yang ada'), findsNothing);
    });
  });

  group('lease', () {
    testWidgets('the section title is a header', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Masa sewa')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the dates, rent, cycle, grace and next bill', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Masa sewa'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('1 Jan 2026'), findsOneWidget);
      expect(find.text('Berakhir'), findsOneWidget);
      expect(find.text('31 Des 2026'), findsOneWidget);
      expect(find.text('Tarif sewa'), findsOneWidget);
      expect(find.text('Rp750.000 / bulan'), findsOneWidget);
      expect(find.text('Siklus penagihan'), findsOneWidget);
      expect(find.text('Bulanan'), findsOneWidget);
      expect(find.text('Masa tenggang'), findsOneWidget);
      expect(find.text('3 hari'), findsOneWidget);
      expect(find.text('Tagihan berikutnya'), findsOneWidget);
      expect(find.text('1 Nov 2026'), findsOneWidget);
    });

    testWidgets('shows a dash for a lease without end date', (tester) async {
      await _open(tester, _repo(_notActivated(noEndDate: true)));

      expect(find.text('Berakhir'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('31 Des 2026'), findsNothing);
    });

    testWidgets('shows a dash when there is no next bill', (tester) async {
      await _open(tester, _repo(_notActivated(noNextBillDate: true)));

      expect(find.text('Tagihan berikutnya'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('1 Nov 2026'), findsNothing);
    });

    testWidgets('shows two dashes without end date and next bill', (
      tester,
    ) async {
      final tenant = _notActivated(noEndDate: true, noNextBillDate: true);
      await _open(tester, _repo(tenant));

      expect(find.text('-'), findsNWidgets(2));
    });

    const cycles = {
      BillingCycle.weekly: ('Mingguan', 'minggu'),
      BillingCycle.monthly: ('Bulanan', 'bulan'),
      BillingCycle.quarterly: ('3 Bulan', '3 bulan'),
      BillingCycle.semiannual: ('6 Bulan', '6 bulan'),
      BillingCycle.annual: ('12 Bulan', '12 bulan'),
    };
    for (final entry in cycles.entries) {
      testWidgets('names the ${entry.key} cycle and its rent unit', (
        tester,
      ) async {
        await _open(tester, _repo(_notActivated(billingCycle: entry.key)));

        expect(find.text(entry.value.$1), findsOneWidget);
        expect(find.text('Rp750.000 / ${entry.value.$2}'), findsOneWidget);
      });
    }

    testWidgets('shows a grace period of zero days', (tester) async {
      await _open(tester, _repo(_notActivated(gracePeriodDays: 0)));

      expect(find.text('0 hari'), findsOneWidget);
    });

    testWidgets('links to the room by its number, at least 48 dp', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Kamar 08'), findsOneWidget);
      expectTargetSize(tester, 'Kamar 08');
    });

    testWidgets('the room link opens the room detail', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text('Kamar 08'));

      expect(currentPath(tester), '/properti/p1/kamar/r1');
      final detail = tester.widget<RoomDetailScreen>(
        find.byType(RoomDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.roomId, 'r1');
    });
  });

  group('other data', () {
    testWidgets('the section title is a header', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text('Data lainnya')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('lists each emergency contact with the relationship', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text('Data lainnya'), findsOneWidget);
      expect(find.text('Kontak darurat'), findsOneWidget);
      expect(find.text('Siti Rahma · Ibu'), findsOneWidget);
      expect(find.text('081355512345'), findsOneWidget);
      expect(find.text('Joko · Kakak'), findsOneWidget);
      expect(find.text('081355512346'), findsOneWidget);
      expect(find.text('Belum diisi'), findsNothing);
    });

    testWidgets('says the contacts are not filled in when there are none', (
      tester,
    ) async {
      await _open(tester, _repo(_notActivated(emergencyContacts: const [])));

      expect(find.text('Kontak darurat'), findsOneWidget);
      expect(find.text('Belum diisi'), findsOneWidget);
    });

    testWidgets('shows the occupation', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Pekerjaan / instansi'), findsOneWidget);
      expect(find.text('Karyawan swasta'), findsOneWidget);
    });

    testWidgets('shows a dash for a missing occupation', (tester) async {
      await _open(tester, _repo(_notActivated(occupation: null)));

      expect(find.text('Pekerjaan / instansi'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('offers no delete, payment pattern or AI section', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.textContaining('Hapus'), findsNothing);
      expect(find.textContaining('pola pembayaran'), findsNothing);
      expect(find.textContaining('AI'), findsNothing);
    });
  });

  group('edit', () {
    testWidgets('Ubah Data Penyewa is at least 48 dp and opens the form', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_edit), findsOneWidget);
      expectTargetSize(tester, _edit);

      await tapVisible(tester, find.text(_edit));

      expect(currentPath(tester), '/properti/p1/penyewa/t1/ubah');
      final form = tester.widget<TenantFormScreen>(
        find.byType(TenantFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.tenantId, 't1');
    });

    testWidgets('is offered for an active tenant too', (tester) async {
      await _open(tester, _repo(_active()));

      expect(find.text(_edit), findsOneWidget);

      await tapVisible(tester, find.text(_edit));

      expect(currentPath(tester), '/properti/p1/penyewa/t1/ubah');
    });

    testWidgets('is offered when the invitation has expired', (tester) async {
      final tenant = _notActivated(
        invitation: makeTenantInvitation(expired: true),
      );
      await _open(tester, _repo(tenant));

      expect(find.text(_edit), findsOneWidget);
    });

    testWidgets('a manager can edit the tenant', (tester) async {
      await _open(tester, _repo(), role: UserRole.manager);

      expect(find.text(_edit), findsOneWidget);

      await tapVisible(tester, find.text(_edit));

      expect(find.byType(TenantFormScreen), findsOneWidget);
    });

    testWidgets('Kembali from the edit form reaches the tenant again', (
      tester,
    ) async {
      await _open(tester, _repo());
      await tapVisible(tester, find.text(_edit));

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      expect(find.byType(TenantDetailScreen), findsOneWidget);
      expect(find.byType(TenantFormScreen), findsNothing);
    });

    testWidgets('the detail shows the saved data after an edit', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await tapVisible(tester, find.text(_edit));
      await typeInto(tester, 'Nama lengkap (wajib)', 'Budi Hartono');
      await typeInto(tester, 'Nomor telepon (wajib)', '081300000001');
      await typeInto(tester, 'Tarif sewa per siklus (wajib)', '900000');
      await tapVisible(
        tester,
        find.descendant(
          of: find.byType(ActionFooter),
          matching: find.byType(FilledButton),
        ),
      );

      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      expect(find.text('Budi Hartono'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.textContaining('081300000001'), findsOneWidget);
      expect(find.text('Rp900.000 / bulan'), findsOneWidget);
      expect(find.text('Rp750.000 / bulan'), findsNothing);
      expect(repo.getCalls, greaterThanOrEqualTo(2));
    });
  });

  group('regenerating the link', () {
    Finder dialog() => find.byType(AlertDialog);

    Future<void> closeFailureDialog(WidgetTester tester) async {
      if (dialog().evaluate().isEmpty) return;
      await tester.tap(
        find.descendant(of: dialog(), matching: anyButton()).last,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a valid invitation offers to regenerate the link', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_regenerate), findsOneWidget);
      expect(find.text('Bagikan tautan yang ada'), findsOneWidget);
      expectTargetSize(tester, _regenerate);
    });

    testWidgets('an expired invitation offers to regenerate the link', (
      tester,
    ) async {
      final tenant = _notActivated(
        invitation: makeTenantInvitation(expired: true),
      );
      await _open(tester, _repo(tenant));

      expect(find.text(_regenerate), findsOneWidget);
      expectTargetSize(tester, _regenerate);
    });

    testWidgets('a not activated tenant without invitation can regenerate', (
      tester,
    ) async {
      final tenant = makeTenant(withoutInvitation: true);
      await _open(tester, _repo(tenant));

      expect(find.text(_regenerate), findsOneWidget);
      expect(find.text('Bagikan tautan yang ada'), findsNothing);
    });

    testWidgets('an invitation without a link offers to regenerate', (
      tester,
    ) async {
      final tenant = makeTenant(invitation: makeTenantInvitation(url: null));
      await _open(tester, _repo(tenant));

      expect(find.text(_regenerate), findsOneWidget);
    });

    testWidgets('an active tenant cannot regenerate a link', (tester) async {
      await _open(tester, _repo(_active()));

      expect(find.text(_regenerate), findsNothing);
    });

    testWidgets('an active tenant with a used invitation cannot either', (
      tester,
    ) async {
      final tenant = makeTenant(
        accountStatus: TenantAccountStatus.active,
        invitation: makeTenantInvitation(),
      );
      await _open(tester, _repo(tenant));

      expect(find.text(_regenerate), findsNothing);
    });

    testWidgets('a manager can regenerate the link', (tester) async {
      final repo = _repo();
      await _open(tester, repo, role: UserRole.manager);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.regenerateCalls, 1);
    });

    testWidgets('asks the backend for a new link without asking anything', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.calls, contains('regenerate:t1'));
      expect(repo.regenerateCalls, 1);
      expect(dialog(), findsNothing);
    });

    testWidgets('then shows the new link on the share screen', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, find.text(_regenerate));

      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan');
      final share = tester.widget<InvitationShareScreen>(
        find.byType(InvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.tenantId, 't1');
      expect(share.isNew, isFalse);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/t1-1',
      );
    });

    testWidgets('an expired invitation gets a link to share', (tester) async {
      final tenant = _notActivated(
        invitation: makeTenantInvitation(expired: true),
      );
      await _open(tester, _repo(tenant));

      await tapVisible(tester, find.text(_regenerate));

      expect(currentPath(tester), '/properti/p1/penyewa/t1/undangan');
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/t1-1',
      );
    });

    testWidgets('Kembali shows the detail with the new invitation', (
      tester,
    ) async {
      final tenant = _notActivated(
        invitation: makeTenantInvitation(expired: true),
      );
      await _open(tester, _repo(tenant));
      await tapVisible(tester, find.text(_regenerate));

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      expect(find.text(_created), findsOneWidget);
      expect(find.text(_expired), findsNothing);
      expect(find.text('Bagikan tautan yang ada'), findsOneWidget);
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
      expect(find.byType(TenantDetailScreen), findsOneWidget);
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

      expect(find.byType(InvitationShareScreen), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });

    testWidgets('a failure shows its message and keeps the old link', (
      tester,
    ) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      expect(find.byType(InvitationShareScreen), findsNothing);
      expect(find.text('Bagikan tautan yang ada'), findsOneWidget);
      expect(find.text(_created), findsOneWidget);
      expect(repo.tenants.first.invitation!.url, contains('abc123'));
    });

    testWidgets('after a failure the old link is still the one shared', (
      tester,
    ) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await tapVisible(tester, find.text(_regenerate));
      await closeFailureDialog(tester);

      await tapVisible(tester, find.text('Bagikan tautan yang ada'));

      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        'https://niscala.example/undangan/abc123',
      );
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

    testWidgets('an unknown error code shows the generic message', (
      tester,
    ) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));
      await _open(tester, repo);

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('can be tried again after a failure', (tester) async {
      final repo = _repo()
        ..regenerateScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await tapVisible(tester, find.text(_regenerate));
      await closeFailureDialog(tester);

      await tapVisible(tester, find.text(_regenerate));

      expect(repo.regenerateCalls, 2);
      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });

    testWidgets('a tenant that is gone shows the message and reloads', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      repo.tenants.removeWhere((t) => t.id == 't1');

      await tapVisible(tester, find.text(_regenerate));

      expect(find.text('Penyewa tidak ditemukan.'), findsAtLeastNWidgets(1));
      expect(repo.getCalls, 2);
      expect(find.byType(InvitationShareScreen), findsNothing);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Masa sewa'), findsNothing);
      expect(find.text(_edit), findsNothing);
      expect(find.text(_regenerate), findsNothing);
    });

    testWidgets('shows the message of a tenant that does not exist', (
      tester,
    ) async {
      final repo = FakeTenantRepository(tenants: []);
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('TENANT_NOT_FOUND')), findsOneWidget);
      expect(find.text('Penyewa tidak ditemukan.'), findsOneWidget);
      expect(find.text('Masa sewa'), findsNothing);
      expect(find.text(_edit), findsNothing);
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
      expect(find.text('Budi Santoso'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Kembali returns to the tenant list', (tester) async {
      await _open(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
    });

    testWidgets('a manager sees the same detail', (tester) async {
      await _open(tester, _repo(), role: UserRole.manager);

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text(_created), findsOneWidget);
      expect(find.text('Bagikan tautan yang ada'), findsOneWidget);
    });
  });

  group('structure', () {
    testWidgets('uses the white detail app bar titled Rincian Penyewa', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectDetailAppBar(tester);
      expect(appBarTitle('Rincian Penyewa'), findsOneWidget);
    });

    testWidgets('the tenant name and contact sit in a section card', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(
        find.ancestor(
          of: find.text('Budi Santoso'),
          matching: find.byType(SectionCard),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('081255204471 · email belum diisi'),
          matching: find.byType(SectionCard),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the room, lease and other data sections are section cards', (
      tester,
    ) async {
      await _open(tester, _repo());

      for (final title in ['Kamar', 'Masa sewa', 'Data lainnya']) {
        expectSectionCard(tester, title);
      }
    });

    testWidgets('each section card holds its own content', (tester) async {
      await _open(tester, _repo());

      expect(
        find.descendant(
          of: sectionCardOf('Kamar'),
          matching: find.text('Kamar 08'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sectionCardOf('Masa sewa'),
          matching: find.text('Rp750.000 / bulan'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sectionCardOf('Data lainnya'),
          matching: find.text('Siti Rahma · Ibu'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sectionCardOf('Data lainnya'),
          matching: find.text('Karyawan swasta'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'the invitation box and its share action sit in a section card',
      (tester) async {
        await _open(tester, _repo());

        expect(
          find.ancestor(
            of: find.text(_created),
            matching: find.byType(SectionCard),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.text('Bagikan tautan yang ada'),
            matching: find.byType(SectionCard),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('every section card takes the card look from the theme', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectCardLook(
        tester,
        find.descendant(
          of: find.byType(SectionCard),
          matching: find.byType(Card),
        ),
      );
    });
  });

  group('accessibility', () {
    final states =
        <String, ({FakeTenantRepository Function() repo, UserRole role})>{
          'a not activated tenant for an owner': (
            repo: _repo,
            role: UserRole.owner,
          ),
          'a not activated tenant for a manager': (
            repo: _repo,
            role: UserRole.manager,
          ),
          'an expired invitation': (
            repo: () => _repo(
              _notActivated(invitation: makeTenantInvitation(expired: true)),
            ),
            role: UserRole.owner,
          ),
          'an active tenant': (
            repo: () => _repo(_active()),
            role: UserRole.owner,
          ),
          'a lease without dates': (
            repo: () =>
                _repo(_notActivated(noEndDate: true, noNextBillDate: true)),
            role: UserRole.owner,
          ),
          'a tenant without contacts and occupation': (
            repo: () =>
                _repo(_active(occupation: null, emergencyContacts: const [])),
            role: UserRole.manager,
          ),
          'a failure': (
            repo: () => _repo()..getScript.always = const ApiFailure.network(),
            role: UserRole.owner,
          ),
          'a missing tenant': (
            repo: () => FakeTenantRepository(),
            role: UserRole.owner,
          ),
          'a not activated tenant without invitation': (
            repo: () => _repo(makeTenant(withoutInvitation: true)),
            role: UserRole.owner,
          ),
        };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines for ${entry.key}', (tester) async {
        await _open(tester, entry.value.repo(), role: entry.value.role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for ${entry.key}', (tester) async {
        await _open(
          tester,
          entry.value.repo(),
          role: entry.value.role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }

    for (final large in [false, true]) {
      final suffix = large ? 'fits at large text size' : 'meets the guidelines';

      testWidgets('$suffix after a failed regeneration', (tester) async {
        final repo = _repo()
          ..regenerateScript.queue.add(const ApiFailure.network());
        await _open(tester, repo, largeText: large);
        await tapVisible(tester, find.text(_regenerate));

        if (large) {
          expect(tester.takeException(), isNull);
        } else {
          await expectMeetsA11yGuidelines(tester);
        }
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
