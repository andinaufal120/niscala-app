import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'tenant_ui_helpers.dart';

const _room = 'Kamar (wajib)';
const _name = 'Nama lengkap (wajib)';
const _phone = 'Nomor telepon (wajib)';
const _occupation = 'Pekerjaan / instansi (opsional)';
const _start = 'Tanggal mulai (opsional)';
const _end = 'Tanggal berakhir (opsional)';
const _cycle = 'Siklus penagihan (wajib)';
const _grace = 'Masa tenggang dalam hari (opsional)';
const _rent = 'Tarif sewa per siklus (wajib)';
const _contactName = 'Nama kontak (wajib)';
const _contactRelation = 'Hubungan (wajib)';
const _contactPhone = 'Nomor telepon kontak (wajib)';
const _addContact = 'Tambah Kontak Darurat';

const _invalidPhone = 'Nomor telepon tidak valid. Contoh: 0812-5520-4471.';
const _contactsCount = 'Isi minimal 2 kontak darurat, atau kosongkan semuanya.';
const _endBeforeStart = 'Tanggal berakhir tidak boleh sebelum tanggal mulai.';

final _contacts = [
  EmergencyContact(
    name: 'Siti Rahma',
    relationship: 'Ibu',
    phone: '081355512345',
  ),
  EmergencyContact(name: 'Joko', relationship: 'Kakak', phone: '081355512346'),
];

/// Budi: not activated, room 08, quarterly lease 1 Jan to 31 Des 2026, rent
/// Rp2.100.000, grace 3 days, two emergency contacts and an occupation.
Tenant _full() => makeTenant(
  id: 't1',
  name: 'Budi Santoso',
  phone: '081255204471',
  occupation: 'Karyawan swasta',
  emergencyContacts: _contacts,
  billingCycle: BillingCycle.quarterly,
  gracePeriodDays: 3,
  rent: 2100000,
);

/// Dewi: active, room 13, weekly lease from 1 Jan 2026 without end date, rent
/// Rp100.000, no occupation and no emergency contacts.
Tenant _sparse() => makeTenant(
  id: 't2',
  name: 'Dewi Lestari',
  phone: '081388899900',
  occupation: null,
  accountStatus: TenantAccountStatus.active,
  roomId: 'r6',
  roomNumber: '13',
  billingCycle: BillingCycle.weekly,
  noEndDate: true,
  rent: 100000,
);

DateTime _utcDay(int day) {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, day);
}

/// Rina: a lease from the 20th to the 25th of the current month, the month a
/// date picker opens on.
Tenant _dated() => makeTenant(
  id: 't3',
  name: 'Rina Putri',
  roomId: 'r7',
  roomNumber: '14',
  emergencyContacts: _contacts,
  startDate: _utcDay(20),
  endDate: _utcDay(25),
);

FakeTenantRepository _repo() =>
    FakeTenantRepository(tenants: [_full(), _sparse(), _dated()]);

Future<void> _openEdit(
  WidgetTester tester,
  FakeTenantRepository repo, {
  String tenantId = 't1',
  FakeRoomRepository? rooms,
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) => pumpTenantApp(
  tester,
  repo,
  rooms: rooms,
  role: role,
  path: '/properti/p1/penyewa/$tenantId/ubah',
  settle: settle,
  largeText: largeText,
);

/// The save button: the one button of the pinned footer.
Finder _saveButton() => find.descendant(
  of: find.byType(ActionFooter),
  matching: find.byType(FilledButton),
);

Future<void> _submit(WidgetTester tester) => tapVisible(tester, _saveButton());

Future<void> _tapFirstSave(WidgetTester tester) async {
  await tester.ensureVisible(_saveButton());
  await tester.pump();
  await tapAndPump(tester, _saveButton());
}

Future<void> _addBlock(WidgetTester tester) =>
    tapVisible(tester, find.text(_addContact));

Future<void> _fillBlock(
  WidgetTester tester,
  int index, {
  String name = 'Siti Rahma',
  String relation = 'Ibu',
  String phone = '081355512345',
}) async {
  await typeLabeledAt(tester, _contactName, index, name);
  await typeLabeledAt(tester, _contactRelation, index, relation);
  await typeLabeledAt(tester, _contactPhone, index, phone);
}

String _text(WidgetTester tester, String label) =>
    labeledTextField(tester, label).controller!.text;

BillingCycle? _cycleValue(WidgetTester tester) => tester
    .widget<DropdownButton<BillingCycle>>(
      find.byType(DropdownButton<BillingCycle>),
    )
    .value;

void _expectErrors(WidgetTester tester, Map<String, String> errors) {
  for (final label in [_name, _phone, _end, _rent]) {
    expect(labeledFieldError(tester, label), errors[label], reason: label);
  }
}

/// The note that a change of rent or billing cycle counts from the next bill.
Finder _nextBillNote() => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? '').toLowerCase().contains('tagihan berikutnya'),
  description: 'note about the next bill',
);

/// The read-only room shown instead of a room picker.
Finder _roomShown(String number) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      RegExp('(Kamar\\s+$number\\b)|^$number\$').hasMatch(widget.data ?? ''),
  description: 'room $number',
);

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('layout', () {
    testWidgets('shows a titled screen with a save button', (tester) async {
      await _openEdit(tester, _repo());

      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(find.text('Tambah Penyewa'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.textContaining('Penyewa'),
        ),
        findsAtLeastNWidgets(1),
      );
      expect(_saveButton(), findsOneWidget);
    });

    testWidgets('is shown for the tenant and property of the path', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');

      final form = tester.widget<TenantFormScreen>(
        find.byType(TenantFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.tenantId, 't2');
      expect(repo.calls, contains('get:t2'));
    });

    testWidgets('pre-fills the personal data', (tester) async {
      await _openEdit(tester, _repo());

      expect(_text(tester, _name), 'Budi Santoso');
      expect(_text(tester, _phone), '081255204471');
      expect(_text(tester, _occupation), 'Karyawan swasta');
    });

    testWidgets('pre-fills the lease', (tester) async {
      await _openEdit(tester, _repo());

      expect(_text(tester, _start), '1 Jan 2026');
      expect(_text(tester, _end), '31 Des 2026');
      expect(_cycleValue(tester), BillingCycle.quarterly);
      expect(_text(tester, _grace), '3');
      expect(_text(tester, _rent), '2100000');
    });

    testWidgets('pre-fills the emergency contacts as blocks', (tester) async {
      await _openEdit(tester, _repo());

      expect(fieldLabeled(_contactName), findsNWidgets(2));
      expect(labeledTextAt(tester, _contactName, 0), 'Siti Rahma');
      expect(labeledTextAt(tester, _contactRelation, 0), 'Ibu');
      expect(labeledTextAt(tester, _contactPhone, 0), '081355512345');
      expect(labeledTextAt(tester, _contactName, 1), 'Joko');
      expect(labeledTextAt(tester, _contactRelation, 1), 'Kakak');
      expect(labeledTextAt(tester, _contactPhone, 1), '081355512346');
      expect(find.byTooltip('Hapus kontak darurat 2'), findsOneWidget);
    });

    testWidgets('leaves missing optional values empty', (tester) async {
      await _openEdit(tester, _repo(), tenantId: 't2');

      expect(_text(tester, _name), 'Dewi Lestari');
      expect(_text(tester, _phone), '081388899900');
      expect(_text(tester, _occupation), isEmpty);
      expect(_text(tester, _end), isEmpty);
      expect(_text(tester, _start), '1 Jan 2026');
      expect(_text(tester, _grace), '0');
      expect(_text(tester, _rent), '100000');
      expect(_cycleValue(tester), BillingCycle.weekly);
      expect(fieldLabeled(_contactName), findsNothing);
      expect(find.text(_addContact), findsOneWidget);
    });

    testWidgets('shows the room read-only and offers no room picker', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      expect(_roomShown('08'), findsAtLeastNWidgets(1));
      expect(labeledField(_room), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);
    });

    testWidgets('shows the room of the tenant it edits', (tester) async {
      await _openEdit(tester, _repo(), tenantId: 't2');

      expect(_roomShown('13'), findsAtLeastNWidgets(1));
      expect(_roomShown('08'), findsNothing);
    });

    testWidgets('does not need a vacant room', (tester) async {
      final rooms = FakeRoomRepository(
        rooms: [occupiedRoom(id: 'r1', number: '08')],
      );
      await _openEdit(tester, _repo(), rooms: rooms);

      expect(find.textContaining('Tidak ada kamar kosong'), findsNothing);
      expect(_text(tester, _name), 'Budi Santoso');
      expect(_saveButton(), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNotNull);
    });

    testWidgets('says a change of rent or billing cycle counts from the next '
        'bill', (tester) async {
      await _openEdit(tester, _repo());

      expect(_nextBillNote(), findsOneWidget);
    });

    testWidgets('the add form does not carry that note', (tester) async {
      await pumpTenantApp(tester, _repo(), path: '/properti/p1/penyewa/tambah');

      expect(_nextBillNote(), findsNothing);
    });

    testWidgets('marks required and optional fields in text', (tester) async {
      await _openEdit(tester, _repo());

      for (final label in [_name, _phone, _cycle, _rent]) {
        expect(fieldLabeled(label), findsOneWidget, reason: label);
      }
      for (final label in [_occupation, _start, _end, _grace]) {
        expect(fieldLabeled(label), findsOneWidget, reason: label);
      }
      expect(find.text('Kontak darurat (opsional)'), findsOneWidget);
    });

    testWidgets('draws no label inside any field of the form', (tester) async {
      await _openEdit(tester, _repo());

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts the save button in a pinned footer', (tester) async {
      await _openEdit(tester, _repo());

      expect(find.byType(ActionFooter), findsOneWidget);
      expectFooterAtBottom(tester);
    });

    testWidgets('a manager can use the form', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, role: UserRole.manager);

      await _submit(tester);

      expect(repo.updated, hasLength(1));
    });
  });

  group('loading', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _openEdit(tester, repo, settle: false);

      expectLoading(tester);
      expect(fieldLabeled(_name), findsNothing);
      expect(_saveButton(), findsNothing);
    });

    testWidgets('shows the form once the tenant is loaded', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _openEdit(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(_text(tester, _name), 'Budi Santoso');
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of a failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _openEdit(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
      expect(_saveButton(), findsNothing);
    });

    testWidgets('shows the message of a tenant that does not exist', (
      tester,
    ) async {
      await _openEdit(tester, FakeTenantRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Penyewa tidak ditemukan.'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('Coba lagi loads the tenant again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(_text(tester, _name), 'Budi Santoso');
    });

    testWidgets('sends nothing while loading', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _openEdit(tester, repo, settle: false);

      expect(repo.updated, isEmpty);
    });
  });

  group('emergency contacts', () {
    testWidgets('removing a prefilled block renumbers the others', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 1'));

      expect(fieldLabeled(_contactName), findsNWidgets(1));
      expect(labeledTextAt(tester, _contactName, 0), 'Joko');
      expect(find.byTooltip('Hapus kontak darurat 2'), findsNothing);
    });

    testWidgets('the add button disappears at four blocks', (tester) async {
      await _openEdit(tester, _repo());

      await _addBlock(tester);
      await _addBlock(tester);

      expect(fieldLabeled(_contactName), findsNWidgets(4));
      expect(find.text(_addContact), findsNothing);
    });

    testWidgets('the remove and add buttons are at least 48 dp', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      expectFinderTargetSize(tester, find.byTooltip('Hapus kontak darurat 1'));
      expectTargetSize(tester, _addContact);
    });

    testWidgets('exactly one contact is refused with the count message', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 2'));

      await _submit(tester);

      expect(find.text(_contactsCount), findsOneWidget);
      expect(repo.updated, isEmpty);
    });

    testWidgets('one contact added to none is refused too', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');
      await _addBlock(tester);
      await _fillBlock(tester, 0);

      await _submit(tester);

      expect(find.text(_contactsCount), findsOneWidget);
      expect(repo.updated, isEmpty);
    });

    testWidgets('removing every contact of a tenant lets the form through', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 2'));
      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 1'));

      await _submit(tester);

      expect(repo.updated.single.input.emergencyContacts, isEmpty);
    });

    testWidgets('two contacts are accepted', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');
      await _addBlock(tester);
      await _addBlock(tester);
      await _fillBlock(tester, 0);
      await _fillBlock(tester, 1, name: 'Joko', phone: '081355512346');

      await _submit(tester);

      expect(find.text(_contactsCount), findsNothing);
      expect(repo.updated.single.input.emergencyContacts, hasLength(2));
    });

    testWidgets('an emptied field of a prefilled block shows its error', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeLabeledAt(tester, _contactRelation, 1, '');

      await _submit(tester);

      expect(
        labeledInputError(tester, _contactRelation, 1),
        'Hubungan wajib diisi.',
      );
      expect(labeledInputError(tester, _contactName, 1), isNull);
      expect(labeledInputError(tester, _contactRelation, 0), isNull);
      expect(repo.updated, isEmpty);
    });

    testWidgets('an invalid contact phone shows the phone message', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeLabeledAt(tester, _contactPhone, 0, '12345');

      await _submit(tester);

      expect(labeledInputError(tester, _contactPhone, 0), _invalidPhone);
      expect(repo.updated, isEmpty);
    });
  });

  group('name of the tenant', () {
    const notEditableMessage =
        'Nama penyewa yang sudah aktif mengikuti akunnya dan tidak bisa '
        'diubah.';

    /// The hint that explains why the name cannot be changed.
    Finder hint() => find.textContaining('tidak bisa diubah');

    bool readOnly(WidgetTester tester) {
      final field = labeledTextField(tester, _name);
      return field.readOnly || field.enabled == false;
    }

    testWidgets('is read-only with a hint when the tenant is active', (
      tester,
    ) async {
      await _openEdit(tester, _repo(), tenantId: 't2');

      expect(labeledField(_name), findsOneWidget);
      expect(_text(tester, _name), 'Dewi Lestari');
      expect(readOnly(tester), isTrue);
      expect(hint(), findsOneWidget);
    });

    testWidgets('is editable without a hint when the tenant is not '
        'activated', (tester) async {
      await _openEdit(tester, _repo());

      expect(_text(tester, _name), 'Budi Santoso');
      expect(readOnly(tester), isFalse);
      expect(hint(), findsNothing);
    });

    testWidgets('keeps the other fields editable for an active tenant', (
      tester,
    ) async {
      await _openEdit(tester, _repo(), tenantId: 't2');

      for (final label in [_phone, _occupation, _grace, _rent]) {
        final field = labeledTextField(tester, label);
        expect(field.readOnly, isFalse, reason: label);
        expect(field.enabled, isNot(false), reason: label);
      }
    });

    testWidgets('an active tenant is saved with the name it has', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');
      await typeInto(tester, _occupation, 'Mahasiswa');

      await _submit(tester);

      expect(repo.updated.single.id, 't2');
      expect(repo.updated.single.input.name, 'Dewi Lestari');
      expect(repo.updated.single.input.occupation, 'Mahasiswa');
    });

    testWidgets('an active tenant needs no name to be filled in', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');

      await _submit(tester);

      expect(labeledFieldError(tester, _name), isNull);
      expect(repo.updated, hasLength(1));
    });

    testWidgets('the hint is shown with the form of an active tenant at large '
        'text', (tester) async {
      await _openEdit(tester, _repo(), tenantId: 't2', largeText: true);

      expect(tester.takeException(), isNull);
      expect(hint(), findsOneWidget);
    });

    testWidgets('the API refusing the name shows its message on the name '
        'field', (tester) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(
            code: 'TENANT_NAME_NOT_EDITABLE',
            field: 'name',
            statusCode: 422,
          ),
        );
      await _openEdit(tester, repo);
      await typeInto(tester, _name, 'Budi Hartono');

      await _submit(tester);

      expect(labeledFieldError(tester, _name), notEditableMessage);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(_text(tester, _name), 'Budi Hartono');
    });

    testWidgets('the API refusing the name of an active tenant shows its '
        'message', (tester) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(
            code: 'TENANT_NAME_NOT_EDITABLE',
            field: 'name',
            statusCode: 422,
          ),
        );
      await _openEdit(tester, repo, tenantId: 't2');

      await _submit(tester);

      expect(find.text(notEditableMessage), findsOneWidget);
      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(busyButton(), findsNothing);
    });

    testWidgets('meets the guidelines for an active tenant', (tester) async {
      await _openEdit(tester, _repo(), tenantId: 't2');

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('validation', () {
    testWidgets('an emptied name shows its error', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '');

      await _submit(tester);

      _expectErrors(tester, {_name: 'Nama wajib diisi.'});
      expect(repo.updated, isEmpty);
    });

    testWidgets('a name of only spaces counts as empty', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '    ');

      await _submit(tester);

      _expectErrors(tester, {_name: 'Nama wajib diisi.'});
      expect(repo.updated, isEmpty);
    });

    testWidgets('an emptied phone shows its error', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _phone, '');

      await _submit(tester);

      _expectErrors(tester, {_phone: 'Nomor telepon wajib diisi.'});
      expect(repo.updated, isEmpty);
    });

    final invalidPhones = {
      'letters': 'abcdefghij',
      'too short with 08': '08${'1' * 7}',
      'too long with 08': '08${'1' * 12}',
      'too short with 628': '628${'1' * 7}',
      'too long with 628': '628${'1' * 12}',
      'a plus sign': '+6281255204471',
      'another prefix': '0712${'3' * 8}',
    };
    for (final entry in invalidPhones.entries) {
      testWidgets('rejects a phone with ${entry.key}', (tester) async {
        final repo = _repo();
        await _openEdit(tester, repo);
        await typeInto(tester, _phone, entry.value);

        await _submit(tester);

        _expectErrors(tester, {_phone: _invalidPhone});
        expect(repo.updated, isEmpty);
      });
    }

    final validPhones = {
      '08 and 8 digits': '08${'1' * 8}',
      '628 and 11 digits': '628${'1' * 11}',
      'dashes': '0812-5520-4471',
      'spaces and dashes': '0812 - 5520 4471',
    };
    for (final entry in validPhones.entries) {
      testWidgets('accepts a phone with ${entry.key}', (tester) async {
        final repo = _repo();
        await _openEdit(tester, repo);
        await typeInto(tester, _phone, entry.value);

        await _submit(tester);

        expect(repo.updated, hasLength(1));
      });
    }

    testWidgets('an emptied rent shows its error', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _rent, '');

      await _submit(tester);

      _expectErrors(tester, {_rent: 'Tarif sewa wajib diisi.'});
      expect(repo.updated, isEmpty);
    });

    testWidgets('a rent of 0 must be more than 0', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _rent, '0');

      await _submit(tester);

      _expectErrors(tester, {_rent: 'Tarif sewa harus lebih dari 0.'});
      expect(repo.updated, isEmpty);
    });

    testWidgets('shows every error at once', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '');
      await typeInto(tester, _phone, '');
      await typeInto(tester, _rent, '');

      await _submit(tester);

      _expectErrors(tester, {
        _name: 'Nama wajib diisi.',
        _phone: 'Nomor telepon wajib diisi.',
        _rent: 'Tarif sewa wajib diisi.',
      });
      expect(repo.updated, isEmpty);
    });

    testWidgets('keeps everything typed after a validation error', (
      tester,
    ) async {
      await _openEdit(tester, _repo());
      await typeInto(tester, _name, '');
      await typeInto(tester, _occupation, 'Mahasiswa');
      await typeInto(tester, _grace, '5');

      await _submit(tester);

      expect(_text(tester, _phone), '081255204471');
      expect(_text(tester, _occupation), 'Mahasiswa');
      expect(_text(tester, _grace), '5');
      expect(_text(tester, _rent), '2100000');
      expect(labeledTextAt(tester, _contactName, 1), 'Joko');
    });

    testWidgets('fixing the errors lets the next submit through', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '');
      await _submit(tester);
      expect(repo.updated, isEmpty);

      await typeInto(tester, _name, 'Budi Hartono');
      await _submit(tester);

      expect(repo.updated, hasLength(1));
    });
  });

  group('lease dates', () {
    testWidgets('an end date before the start date is refused', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't3');

      await pickDate(tester, _end, 5);
      await _submit(tester);

      _expectErrors(tester, {_end: _endBeforeStart});
      expect(repo.updated, isEmpty);
    });

    testWidgets('a start date after the end date is refused', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't3');

      await pickDate(tester, _start, 28);
      await _submit(tester);

      _expectErrors(tester, {_end: _endBeforeStart});
      expect(repo.updated, isEmpty);
    });

    testWidgets('an end date on the start date is accepted', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't3');

      await pickDate(tester, _end, 20);
      await _submit(tester);

      expect(repo.updated, hasLength(1));
    });

    testWidgets('moving the end date after the start fixes the error', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't3');
      await pickDate(tester, _end, 5);
      await _submit(tester);
      expect(repo.updated, isEmpty);

      await pickDate(tester, _end, 27);
      await _submit(tester);

      expect(repo.updated.single.input.lease!.endDate, _utcDay(27));
    });

    testWidgets('the chosen dates are shown formatted', (tester) async {
      await _openEdit(tester, _repo(), tenantId: 't3');

      await pickDate(tester, _end, 27);

      expect(_text(tester, _end), formatDate(_utcDay(27)));
    });

    testWidgets('cancelling the picker keeps the date', (tester) async {
      await _openEdit(tester, _repo());

      await openAndCancelDatePicker(tester, _start);

      expect(_text(tester, _start), '1 Jan 2026');
    });

    testWidgets('the date fields are at least 48 dp', (tester) async {
      await _openEdit(tester, _repo());

      expectFinderTargetSize(tester, fieldLabeled(_start));
      expectFinderTargetSize(tester, fieldLabeled(_end));
    });
  });

  group('rent and billing cycle', () {
    testWidgets('changing the cycle keeps the rent of the lease', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      await choose(tester, _cycle, 'Mingguan');
      expect(_cycleValue(tester), BillingCycle.weekly);
      expect(_text(tester, _rent), '2100000');

      await choose(tester, _cycle, 'Bulanan');
      expect(_text(tester, _rent), '2100000');
    });

    testWidgets('the rent field has a Rp prefix and accepts digits only', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      await typeInto(tester, _rent, 'a1b2.c3,');

      expect(_text(tester, _rent), '123');
      expect(
        labeledTextField(tester, _rent).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('the grace period accepts digits only', (tester) async {
      await _openEdit(tester, _repo());

      await typeInto(tester, _grace, 'a1b2-');

      expect(_text(tester, _grace), '12');
    });
  });

  group('request', () {
    testWidgets('puts the current values when nothing is changed', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);

      await _submit(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.id, 't1');
      expect(
        repo.updated.single.input,
        TenantInput(
          name: 'Budi Santoso',
          phone: '081255204471',
          occupation: 'Karyawan swasta',
          emergencyContacts: _contacts,
          lease: LeaseInput(
            startDate: DateTime.utc(2026, 1, 1),
            endDate: DateTime.utc(2026, 12, 31),
            billingCycle: BillingCycle.quarterly,
            gracePeriodDays: 3,
            rent: 2100000,
          ),
        ),
      );
      expect(repo.created, isEmpty);
    });

    testWidgets('keeps missing values missing when nothing is changed', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');

      await _submit(tester);

      expect(repo.updated.single.id, 't2');
      expect(
        repo.updated.single.input,
        TenantInput(
          name: 'Dewi Lestari',
          phone: '081388899900',
          lease: LeaseInput(
            startDate: DateTime.utc(2026, 1, 1),
            billingCycle: BillingCycle.weekly,
            gracePeriodDays: 0,
            rent: 100000,
          ),
        ),
      );
    });

    testWidgets('keeps the lease dates when nothing is changed', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't3');

      await _submit(tester);

      final lease = repo.updated.single.input.lease!;
      expect(lease.startDate, _utcDay(20));
      expect(lease.endDate, _utcDay(25));
    });

    testWidgets('sends every changed value', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, 'Budi Hartono');
      await typeInto(tester, _phone, '0813 7778 8899');
      await typeInto(tester, _occupation, 'Mahasiswa');
      await typeLabeledAt(tester, _contactName, 1, 'Joko Susilo');
      await choose(tester, _cycle, '6 Bulan');
      await typeInto(tester, _grace, '7');
      await typeInto(tester, _rent, '4200000');

      await _submit(tester);

      final input = repo.updated.single.input;
      expect(input.name, 'Budi Hartono');
      expect(input.phone, '0813 7778 8899');
      expect(input.occupation, 'Mahasiswa');
      expect(input.emergencyContacts, [
        _contacts.first,
        EmergencyContact(
          name: 'Joko Susilo',
          relationship: 'Kakak',
          phone: '081355512346',
        ),
      ]);
      expect(input.lease!.billingCycle, BillingCycle.semiannual);
      expect(input.lease!.gracePeriodDays, 7);
      expect(input.lease!.rent, 4200000);
    });

    testWidgets('sends the picked dates as UTC days', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't3');
      await pickDate(tester, _start, 10);
      await pickDate(tester, _end, 27);

      await _submit(tester);

      final lease = repo.updated.single.input.lease!;
      expect(lease.startDate, _utcDay(10));
      expect(lease.endDate, _utcDay(27));
    });

    testWidgets('trims the name, phone and occupation', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '  Budi Hartono  ');
      await typeInto(tester, _phone, '  081255204471  ');
      await typeInto(tester, _occupation, '  Mahasiswa  ');

      await _submit(tester);

      final input = repo.updated.single.input;
      expect(input.name, 'Budi Hartono');
      expect(input.phone, '081255204471');
      expect(input.occupation, 'Mahasiswa');
    });

    testWidgets('a cleared occupation is sent as null', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _occupation, '   ');

      await _submit(tester);

      expect(repo.updated.single.input.occupation, isNull);
    });

    testWidgets('an emptied grace period is sent as 0', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _grace, '');

      await _submit(tester);

      expect(repo.updated.single.input.lease!.gracePeriodDays, 0);
    });

    testWidgets('sends the rent as an integer of rupiah', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _rent, '0750000');

      await _submit(tester);

      expect(repo.updated.single.input.lease!.rent, isA<int>());
      expect(repo.updated.single.input.lease!.rent, 750000);
    });
  });

  group('in flight', () {
    testWidgets('shows a busy disabled button', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _openEdit(tester, repo);

      await _tapFirstSave(tester);

      expectBusy(tester);
    });

    testWidgets('a second tap sends one request', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _openEdit(tester, repo);

      await _tapFirstSave(tester);
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.updated, hasLength(1));
    });

    testWidgets('stays on the form until the request finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..updateScript.gate = gate;
      await _openEdit(tester, repo);
      await _tapFirstSave(tester);

      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(find.byType(TenantDetailScreen), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(TenantDetailScreen), findsOneWidget);
    });
  });

  group('success', () {
    testWidgets('goes back to the detail of the tenant', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _occupation, 'Mahasiswa');

      await _submit(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      final detail = tester.widget<TenantDetailScreen>(
        find.byType(TenantDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.tenantId, 't1');
      expect(find.byType(TenantFormScreen), findsNothing);
    });

    testWidgets('the detail shows the fresh data', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, 'Budi Hartono');
      await typeInto(tester, _occupation, 'Mahasiswa');
      await typeInto(tester, _grace, '9');
      await choose(tester, _cycle, 'Mingguan');

      await _submit(tester);

      expect(find.text('Budi Hartono'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Mahasiswa'), findsOneWidget);
      expect(find.text('9 hari'), findsOneWidget);
      expect(find.text('Mingguan'), findsOneWidget);
      expect(find.text('Rp2.100.000 / minggu'), findsOneWidget);
    });

    testWidgets('the list shows the fresh data too', (tester) async {
      final repo = _repo();
      await pumpTenantApp(tester, repo);
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Ubah Data Penyewa'));
      await typeInto(tester, _name, 'Budi Hartono');
      await _submit(tester);

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/penyewa');
      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(find.text('Budi Hartono'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('keeps the room and the account status', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, tenantId: 't2');

      await _submit(tester);

      final saved = repo.tenants.firstWhere((t) => t.id == 't2');
      expect(saved.room.number, '13');
      expect(saved.accountStatus, TenantAccountStatus.active);
    });

    testWidgets('Back from the detail does not return to the form', (
      tester,
    ) async {
      await _openEdit(tester, _repo());
      await _submit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TenantFormScreen), findsNothing);
    });
  });

  group('failures', () {
    final fieldCases = <String, ({ApiFailure failure, String label})>{
      'a name error': (
        failure: const ApiFailure(code: 'VALIDATION_FAILED', field: 'name'),
        label: _name,
      ),
      'a phone error': (
        failure: const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        label: _phone,
      ),
      'a rent error': (
        failure: const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'lease.rent',
        ),
        label: _rent,
      ),
      'an end date error': (
        failure: const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'lease.endDate',
        ),
        label: _end,
      ),
    };
    for (final entry in fieldCases.entries) {
      testWidgets('${entry.key} shows next to its field', (tester) async {
        final repo = _repo()..updateScript.queue.add(entry.value.failure);
        await _openEdit(tester, repo);

        await _submit(tester);

        final message = entry.value.label == _name
            ? 'Nama lengkap tidak valid.'
            : errorMessageFor(entry.value.failure);
        _expectErrors(tester, {entry.value.label: message});
        expect(find.byType(TenantFormScreen), findsOneWidget);
        expect(snackBar(message), findsNothing);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
      });
    }

    testWidgets('a phone validation error says the number is invalid', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _openEdit(tester, repo);

      await _submit(tester);

      expect(labeledFieldError(tester, _phone), 'Nomor telepon tidak valid.');
    });

    for (final field in [
      'emergencyContacts',
      'emergencyContacts.0.phone',
      'emergencyContacts.1.name',
    ]) {
      testWidgets('a $field error shows in the contact group', (tester) async {
        final repo = _repo()
          ..updateScript.queue.add(
            ApiFailure(code: 'VALIDATION_FAILED', field: field),
          );
        await _openEdit(tester, repo);

        await _submit(tester);

        expect(find.text(validationMessage(field)), findsOneWidget);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
        _expectErrors(tester, {});
        expect(labeledTextAt(tester, _contactName, 0), 'Siti Rahma');
      });
    }

    testWidgets('a field error keeps every value and the form usable', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _openEdit(tester, repo);
      await typeInto(tester, _occupation, 'Mahasiswa');
      await typeInto(tester, _grace, '3');
      await _submit(tester);

      expect(_text(tester, _name), 'Budi Santoso');
      expect(_text(tester, _occupation), 'Mahasiswa');
      expect(_text(tester, _rent), '2100000');
      expect(busyButton(), findsNothing);

      await typeInto(tester, _phone, '081255204472');
      await _submit(tester);

      expect(repo.updated, hasLength(2));
      expect(currentPath(tester), '/properti/p1/penyewa/t1');
    });

    testWidgets('a field error goes away when the next submit starts', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _openEdit(tester, repo);
      await _submit(tester);
      repo.updateScript.gate = Completer<void>();

      await _tapFirstSave(tester);

      expect(labeledFieldError(tester, _phone), isNull);
      expectBusy(tester);
    });

    final bannerCases = <String, ApiFailure>{
      'a network failure': const ApiFailure.network(),
      'a server failure': const ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
      'a forbidden answer': const ApiFailure(code: 'FORBIDDEN'),
      'a read-only property': const ApiFailure(code: 'PROPERTY_READ_ONLY'),
      'a read-only room': const ApiFailure(code: 'ROOM_READ_ONLY'),
      'a validation error without a field': const ApiFailure(
        code: 'VALIDATION_FAILED',
      ),
    };
    for (final entry in bannerCases.entries) {
      testWidgets('shows ${entry.key} as a message and keeps the values', (
        tester,
      ) async {
        final repo = _repo()..updateScript.queue.add(entry.value);
        await _openEdit(tester, repo);
        await typeInto(tester, _occupation, 'Mahasiswa');

        await _submit(tester);

        final message = errorMessageFor(entry.value);
        expect(find.text(message), findsOneWidget);
        expect(snackBar(message), findsNothing);
        _expectErrors(tester, {});
        expect(find.byType(TenantFormScreen), findsOneWidget);
        expect(_text(tester, _occupation), 'Mahasiswa');
        expect(_text(tester, _name), 'Budi Santoso');
        expect(repo.tenants.first.occupation, 'Karyawan swasta');
      });
    }

    testWidgets('announces the message as a live region', (tester) async {
      final repo = _repo()
        ..updateScript.queue.add(const ApiFailure(code: 'FORBIDDEN'));
      await _openEdit(tester, repo);
      await _submit(tester);

      expectLiveRegion(tester, messageOfCode('FORBIDDEN'));
    });

    testWidgets('the message stays on screen until the next submit', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);
      await _submit(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('the message goes away when the next submit starts', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);
      await _submit(tester);
      repo.updateScript.gate = Completer<void>();

      await _tapFirstSave(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expectBusy(tester);
    });

    testWidgets('a successful retry after a network failure shows the detail', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);
      await typeInto(tester, _occupation, 'Mahasiswa');
      await _submit(tester);

      await _submit(tester);

      expect(repo.updated, hasLength(2));
      expect(repo.updated.first, repo.updated.last);
      expect(currentPath(tester), '/properti/p1/penyewa/t1');
    });

    testWidgets('a failure changes nothing on the tenant', (tester) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);
      await typeInto(tester, _name, 'Budi Hartono');

      await _submit(tester);

      expect(repo.tenants.first.name, 'Budi Santoso');
    });

    testWidgets('a tenant that is gone shows its message', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      repo.tenants.removeWhere((t) => t.id == 't1');

      await _submit(tester);

      expect(find.text('Penyewa tidak ditemukan.'), findsAtLeastNWidgets(1));
      expect(repo.updated, hasLength(1));
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the form of a not activated tenant': (tester, large) =>
          _openEdit(tester, _repo(), largeText: large),
      'the form of an active tenant without optional data': (tester, large) =>
          _openEdit(tester, _repo(), tenantId: 't2', largeText: large),
      'the form with four contacts': (tester, large) async {
        await _openEdit(tester, _repo(), largeText: large);
        await _addBlock(tester);
        await _addBlock(tester);
      },
      'the form while the tenant loads': (tester, large) => _openEdit(
        tester,
        _repo()..getScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
      'the form after the tenant failed to load': (tester, large) => _openEdit(
        tester,
        _repo()..getScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'the form of a tenant that does not exist': (tester, large) =>
          _openEdit(tester, FakeTenantRepository(), largeText: large),
      'the form with required field errors': (tester, large) async {
        await _openEdit(tester, _repo(), largeText: large);
        await typeInto(tester, _name, '');
        await typeInto(tester, _phone, '');
        await typeInto(tester, _rent, '');
        await _submit(tester);
      },
      'the form with a contact count error': (tester, large) async {
        await _openEdit(tester, _repo(), largeText: large);
        await tapVisible(tester, find.byTooltip('Hapus kontak darurat 2'));
        await _submit(tester);
      },
      'the form with an end date error': (tester, large) async {
        await _openEdit(tester, _repo(), tenantId: 't3', largeText: large);
        await pickDate(tester, _end, 5);
        await _submit(tester);
      },
      'the form with server field errors': (tester, large) async {
        final repo = _repo()
          ..updateScript.queue.add(
            const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
          );
        await _openEdit(tester, repo, largeText: large);
        await _submit(tester);
      },
      'the form with a failure message': (tester, large) async {
        final repo = _repo()
          ..updateScript.queue.add(const ApiFailure.network());
        await _openEdit(tester, repo, largeText: large);
        await _submit(tester);
      },
      'the form in flight': (tester, large) async {
        final repo = _repo()..updateScript.gate = Completer<void>();
        await _openEdit(tester, repo, largeText: large);
        await _tapFirstSave(tester);
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

    testWidgets('keeps the footer on screen after scrolling at large text', (
      tester,
    ) async {
      await _openEdit(tester, _repo(), largeText: true);
      final before = tester.getRect(find.byType(ActionFooter));
      expectFooterAtBottom(tester);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(ActionFooter)), before);
      expect(_saveButton(), findsOneWidget);
    });

    testWidgets('the note about the next bill is read by TalkBack', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(_nextBillNote()).label.toLowerCase(),
          contains('tagihan berikutnya'),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
