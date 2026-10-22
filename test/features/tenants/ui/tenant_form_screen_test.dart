import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
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
const _save = 'Simpan Penyewa';

const _phoneHelper =
    'Nomor ponsel Indonesia, diawali 08 atau 628. Contoh: 0812-5520-4471.';
const _invalidPhone = 'Nomor telepon tidak valid. Contoh: 0812-5520-4471.';
const _contactsHelper =
    'Isi 2 sampai 4 kontak, atau kosongkan agar penyewa melengkapinya saat '
    'aktivasi.';
const _contactsCount = 'Isi minimal 2 kontak darurat, atau kosongkan semuanya.';
const _endBeforeStart = 'Tanggal berakhir tidak boleh sebelum tanggal mulai.';
const _noRooms = 'Tidak ada kamar kosong. Tambahkan kamar terlebih dahulu.';

FakeTenantRepository _repo() => FakeTenantRepository(tenants: sampleTenants());

Future<void> _open(
  WidgetTester tester,
  FakeTenantRepository repo, {
  FakeRoomRepository? rooms,
  UserRole role = UserRole.owner,
  String query = '',
  bool settle = true,
  bool largeText = false,
}) => pumpTenantApp(
  tester,
  repo,
  rooms: rooms,
  role: role,
  path: '/properti/p1/penyewa/tambah$query',
  settle: settle,
  largeText: largeText,
);

/// A room repository without any room that can take a tenant: one occupied
/// room and one vacant room that is view-only.
FakeRoomRepository _fullRooms() => FakeRoomRepository(
  rooms: [
    occupiedRoom(id: 'r1', number: '08'),
    vacantRoom(id: 'r4', number: '11', editable: false),
  ],
);

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text(_save));

/// Chooses [room] (when not null), types a name and a phone number.
Future<void> _fill(
  WidgetTester tester, {
  String? room = 'Kamar 09',
  String name = 'Rina Putri',
  String phone = '0812-5520-4471',
}) async {
  if (room != null) await choose(tester, _room, room);
  await typeInto(tester, _name, name);
  await typeInto(tester, _phone, phone);
}

Future<void> _addBlock(WidgetTester tester) =>
    tapVisible(tester, find.text(_addContact));

/// Types the three fields of the [index]th (0-based) contact block.
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

/// Adds [count] contact blocks and fills each with distinct valid values.
Future<void> _addFilledBlocks(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await _addBlock(tester);
    await _fillBlock(
      tester,
      i,
      name: 'Kontak ${i + 1}',
      relation: 'Saudara ${i + 1}',
      phone: '08135551234$i',
    );
  }
}

String _text(WidgetTester tester, String label) =>
    labeledTextField(tester, label).controller!.text;

/// The text drawn before the field: a prefix text, or a `Text` wrapped in the
/// prefix icon (which Flutter lets us keep out of the semantics tree).
String _prefix(WidgetTester tester, String label) {
  final decoration = labeledTextField(tester, label).decoration;
  final prefix = decoration?.prefix;
  if (decoration?.prefixText != null) return decoration!.prefixText!;
  if (prefix is Text) return prefix.data ?? '';
  var icon = decoration?.prefixIcon;
  while (icon != null && icon is! Text) {
    icon = switch (icon) {
      ExcludeSemantics(:final child) => child,
      Padding(:final child) => child,
      _ => null,
    };
  }
  return icon is Text ? icon.data ?? '' : '';
}

String? _roomValue(WidgetTester tester) => tester
    .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
    .value;

BillingCycle? _cycleValue(WidgetTester tester) => tester
    .widget<DropdownButton<BillingCycle>>(
      find.byType(DropdownButton<BillingCycle>),
    )
    .value;

/// A day of the current month, which is the month a date picker opens on.
DateTime _day(int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, day);
}

DateTime _utcDay(int day) {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, day);
}

Uri _currentUri(WidgetTester tester) =>
    containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri;

void _expectHeader(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(find.text(text)), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

/// Expects the single-line fields to show exactly the given errors, and no
/// error on the others.
void _expectErrors(WidgetTester tester, Map<String, String> errors) {
  for (final label in [_room, _name, _phone, _end, _rent]) {
    expect(labeledFieldError(tester, label), errors[label], reason: label);
  }
}

Future<void> _tapFirstSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text(_save));
  await tester.pump();
  await tapAndPump(tester, find.text(_save));
}

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('layout', () {
    testWidgets('shows the title and the submit button', (tester) async {
      await _open(tester, _repo());

      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(appBarTitle('Tambah Penyewa'), findsOneWidget);
      expect(find.text(_save), findsOneWidget);
    });

    testWidgets('loads the rooms of the property', (tester) async {
      final rooms = FakeRoomRepository(rooms: tenantRooms());
      await _open(tester, _repo(), rooms: rooms);

      expect(rooms.calls, contains('list:p1'));
    });

    testWidgets('shows every field with its label, empty or defaulted', (
      tester,
    ) async {
      await _open(tester, _repo());

      for (final label in [_room, _cycle]) {
        expect(labeledField(label), findsOneWidget, reason: label);
        expect(fieldLabeled(label), findsOneWidget, reason: label);
      }
      for (final label in [_name, _phone, _occupation, _start, _end, _rent]) {
        expect(fieldLabeled(label), findsOneWidget, reason: label);
        expect(_text(tester, label), isEmpty, reason: label);
      }
      expect(fieldLabeled(_grace), findsOneWidget);
      expect(_text(tester, _grace), '0');
    });

    testWidgets('marks required and optional fields in text', (tester) async {
      await _open(tester, _repo());

      for (final label in [_room, _name, _phone, _cycle, _rent]) {
        expect(label, endsWith('(wajib)'));
      }
      for (final label in [_occupation, _start, _end, _grace]) {
        expect(label, endsWith('(opsional)'));
      }
      expect(find.text('Kontak darurat (opsional)'), findsOneWidget);
    });

    testWidgets('the phone field states the accepted format', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          announced(tester.getSemantics(fieldLabeled(_phone))),
          contains(_phoneHelper),
        );
      } finally {
        handle.dispose();
      }
      expect(
        find.descendant(
          of: labeledField(_phone),
          matching: find.text(_phoneHelper),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the contact group explains the 2 to 4 contacts', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_contactsHelper), findsOneWidget);
    });

    testWidgets('the contact and lease groups have header titles', (
      tester,
    ) async {
      await _open(tester, _repo());

      _expectHeader(tester, 'Kontak darurat (opsional)');
      _expectHeader(tester, 'Masa sewa');
    });

    testWidgets('starts without contact blocks', (tester) async {
      await _open(tester, _repo());

      expect(fieldLabeled(_contactName), findsNothing);
      expect(find.text(_addContact), findsOneWidget);
    });

    testWidgets('the billing cycle starts on Bulanan', (tester) async {
      await _open(tester, _repo());

      expect(_cycleValue(tester), BillingCycle.monthly);
    });

    testWidgets('the billing cycle offers the five cycles by name', (
      tester,
    ) async {
      await _open(tester, _repo());

      await openDropdown(tester, _cycle);

      for (final label in [
        'Mingguan',
        'Bulanan',
        '3 Bulan',
        '6 Bulan',
        '12 Bulan',
      ]) {
        expect(find.text(label), findsAtLeastNWidgets(1), reason: label);
      }
    });

    testWidgets('the rent field has a Rp prefix and accepts digits only', (
      tester,
    ) async {
      await _open(tester, _repo());

      await typeInto(tester, _rent, 'a1b2.c3,');

      expect(_prefix(tester, _rent), 'Rp');
      expect(_text(tester, _rent), '123');
      expect(
        labeledTextField(tester, _rent).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('the grace period accepts digits only', (tester) async {
      await _open(tester, _repo());

      await typeInto(tester, _grace, 'a1b2-');

      expect(_text(tester, _grace), '12');
      expect(
        labeledTextField(tester, _grace).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('a manager can use the form', (tester) async {
      final repo = _repo();
      await _open(tester, repo, role: UserRole.manager);
      await _fill(tester);

      await _submit(tester);

      expect(repo.created, hasLength(1));
    });
  });

  group('room choice', () {
    testWidgets('lists only vacant rooms that can be edited', (tester) async {
      await _open(tester, _repo());

      await openDropdown(tester, _room);

      expect(find.text('Kamar 09'), findsAtLeastNWidgets(1));
      expect(find.text('Kamar 10'), findsAtLeastNWidgets(1));
      expect(find.text('Kamar 08'), findsNothing);
      expect(find.text('Kamar 11'), findsNothing);
    });

    testWidgets('starts without a room', (tester) async {
      await _open(tester, _repo());

      expect(_roomValue(tester), isNull);
    });

    testWidgets('choosing a room selects it', (tester) async {
      await _open(tester, _repo());

      await choose(tester, _room, 'Kamar 10');

      expect(_roomValue(tester), 'r3');
    });

    testWidgets('the kamar query parameter preselects a listed room', (
      tester,
    ) async {
      await _open(tester, _repo(), query: '?kamar=r3');

      expect(_roomValue(tester), 'r3');
    });

    for (final entry in {
      'an occupied room': 'r1',
      'a view-only vacant room': 'r4',
      'an unknown room': 'r99',
    }.entries) {
      testWidgets('${entry.key} in the query is not preselected', (
        tester,
      ) async {
        await _open(tester, _repo(), query: '?kamar=${entry.value}');

        expect(_roomValue(tester), isNull);
        expect(_text(tester, _rent), isEmpty);
      });
    }

    testWidgets('a preselected room can be changed', (tester) async {
      await _open(tester, _repo(), query: '?kamar=r2');

      await choose(tester, _room, 'Kamar 10');

      expect(_roomValue(tester), 'r3');
    });

    testWidgets('only the rooms of this property are listed', (tester) async {
      final rooms = FakeRoomRepository(
        rooms: [
          ...tenantRooms(),
          makeRoom(id: 'x1', propertyId: 'p2', number: '77'),
        ],
      );
      await _open(tester, _repo(), rooms: rooms);

      await openDropdown(tester, _room);

      expect(find.text('Kamar 77'), findsNothing);
    });
  });

  group('without a vacant room', () {
    testWidgets('says to add a room first', (tester) async {
      await _open(tester, _repo(), rooms: _fullRooms());

      expect(find.text(_noRooms), findsOneWidget);
    });

    testWidgets('disables the save button', (tester) async {
      final repo = _repo();
      await _open(tester, repo, rooms: _fullRooms());

      expect(isDisabled(tester, _save), isTrue);
      await tester.tap(find.text(_save), warnIfMissed: false);
      await tester.pump();
      expect(repo.created, isEmpty);
    });

    testWidgets('a property without rooms says the same', (tester) async {
      final repo = _repo();
      await _open(tester, repo, rooms: FakeRoomRepository());

      expect(find.text(_noRooms), findsOneWidget);
      expect(isDisabled(tester, _save), isTrue);
    });

    testWidgets('shows no such note when a room is available', (tester) async {
      await _open(tester, _repo());

      expect(find.text(_noRooms), findsNothing);
      expect(isDisabled(tester, _save), isFalse);
    });
  });

  group('loading the rooms', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final rooms = FakeRoomRepository(rooms: tenantRooms())
        ..listScript.gate = Completer<void>();
      await _open(tester, _repo(), rooms: rooms, settle: false);

      expectLoading(tester);
      expect(appBarTitle('Tambah Penyewa'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('shows the Indonesian message of a failure and a retry', (
      tester,
    ) async {
      final rooms = FakeRoomRepository(rooms: tenantRooms())
        ..listScript.always = const ApiFailure.network();
      await _open(tester, _repo(), rooms: rooms);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('Coba lagi loads the rooms and shows the form', (tester) async {
      final rooms = FakeRoomRepository(rooms: tenantRooms())
        ..listScript.queue.add(const ApiFailure.network());
      await _open(tester, _repo(), rooms: rooms);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(rooms.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(fieldLabeled(_name), findsOneWidget);
    });
  });

  group('rent pre-fill', () {
    testWidgets('is empty while no room is chosen', (tester) async {
      await _open(tester, _repo());

      expect(_text(tester, _rent), isEmpty);
    });

    testWidgets('a monthly lease takes the base rate of the chosen room', (
      tester,
    ) async {
      await _open(tester, _repo());

      await choose(tester, _room, 'Kamar 09');

      expect(_text(tester, _rent), '650000');
    });

    testWidgets('a preselected room fills the rent at once', (tester) async {
      await _open(tester, _repo(), query: '?kamar=r3');

      expect(_text(tester, _rent), '900000');
    });

    testWidgets('changing the room updates an untouched rent', (tester) async {
      await _open(tester, _repo());
      await choose(tester, _room, 'Kamar 09');

      await choose(tester, _room, 'Kamar 10');

      expect(_text(tester, _rent), '900000');
    });

    for (final entry in {
      'Mingguan': BillingCycle.weekly,
      '3 Bulan': BillingCycle.quarterly,
      '6 Bulan': BillingCycle.semiannual,
      '12 Bulan': BillingCycle.annual,
    }.entries) {
      testWidgets('${entry.key} clears an untouched rent', (tester) async {
        await _open(tester, _repo(), query: '?kamar=r2');

        await choose(tester, _cycle, entry.key);

        expect(_cycleValue(tester), entry.value);
        expect(_text(tester, _rent), isEmpty);
      });
    }

    testWidgets('a room chosen under another cycle leaves the rent empty', (
      tester,
    ) async {
      await _open(tester, _repo());
      await choose(tester, _cycle, '3 Bulan');

      await choose(tester, _room, 'Kamar 09');

      expect(_text(tester, _rent), isEmpty);
    });

    testWidgets('going back to Bulanan fills an untouched rent again', (
      tester,
    ) async {
      await _open(tester, _repo(), query: '?kamar=r2');
      await choose(tester, _cycle, 'Mingguan');

      await choose(tester, _cycle, 'Bulanan');

      expect(_text(tester, _rent), '650000');
    });

    testWidgets('a typed rent is kept when the room changes', (tester) async {
      await _open(tester, _repo());
      await choose(tester, _room, 'Kamar 09');
      await typeInto(tester, _rent, '700000');

      await choose(tester, _room, 'Kamar 10');

      expect(_text(tester, _rent), '700000');
    });

    testWidgets('a typed rent is kept when the cycle changes', (tester) async {
      await _open(tester, _repo(), query: '?kamar=r2');
      await typeInto(tester, _rent, '700000');

      await choose(tester, _cycle, '3 Bulan');
      expect(_text(tester, _rent), '700000');

      await choose(tester, _cycle, 'Bulanan');
      expect(_text(tester, _rent), '700000');
    });

    testWidgets('a rent typed before choosing a room is kept', (tester) async {
      await _open(tester, _repo());
      await typeInto(tester, _rent, '500000');

      await choose(tester, _room, 'Kamar 09');

      expect(_text(tester, _rent), '500000');
    });

    testWidgets('a rent the user cleared is not filled in again', (
      tester,
    ) async {
      await _open(tester, _repo(), query: '?kamar=r2');
      await typeInto(tester, _rent, '');

      await choose(tester, _room, 'Kamar 10');

      expect(_text(tester, _rent), isEmpty);
    });

    testWidgets('the pre-filled rent is sent as it is', (tester) async {
      final repo = _repo();
      await _open(tester, repo, query: '?kamar=r3');
      await _fill(tester, room: null);

      await _submit(tester);

      expect(repo.created.single.input.lease!.rent, 900000);
    });
  });

  group('emergency contacts', () {
    testWidgets('Tambah Kontak Darurat adds a block with three fields', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _addBlock(tester);

      for (final label in [_contactName, _contactRelation, _contactPhone]) {
        expect(labeledFieldAt(label, 0), findsOneWidget, reason: label);
        expect(labeledTextAt(tester, label), isEmpty, reason: label);
      }
      expect(find.byTooltip('Hapus kontak darurat 1'), findsOneWidget);
    });

    testWidgets('each block has its own numbered remove button', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _addBlock(tester);
      await _addBlock(tester);
      await _addBlock(tester);

      for (final n in [1, 2, 3]) {
        expect(find.byTooltip('Hapus kontak darurat $n'), findsOneWidget);
      }
      expect(fieldLabeled(_contactName), findsNWidgets(3));
    });

    testWidgets('the add button disappears at four blocks', (tester) async {
      await _open(tester, _repo());

      await _addBlock(tester);
      await _addBlock(tester);
      await _addBlock(tester);
      expect(find.text(_addContact), findsOneWidget);
      await _addBlock(tester);

      expect(fieldLabeled(_contactName), findsNWidgets(4));
      expect(find.text(_addContact), findsNothing);
    });

    testWidgets('removing a block brings the add button back', (tester) async {
      await _open(tester, _repo());
      for (var i = 0; i < 4; i++) {
        await _addBlock(tester);
      }

      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 4'));

      expect(fieldLabeled(_contactName), findsNWidgets(3));
      expect(find.text(_addContact), findsOneWidget);
    });

    testWidgets('removing a block keeps the others and renumbers them', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _addFilledBlocks(tester, 3);

      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 1'));

      expect(fieldLabeled(_contactName), findsNWidgets(2));
      expect(labeledTextAt(tester, _contactName, 0), 'Kontak 2');
      expect(labeledTextAt(tester, _contactName, 1), 'Kontak 3');
      expect(find.byTooltip('Hapus kontak darurat 3'), findsNothing);
      expect(find.byTooltip('Hapus kontak darurat 2'), findsOneWidget);
    });

    testWidgets('a remove button is at least 48 dp', (tester) async {
      await _open(tester, _repo());
      await _addBlock(tester);

      expectFinderTargetSize(tester, find.byTooltip('Hapus kontak darurat 1'));
    });

    testWidgets('the add button is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expectTargetSize(tester, _addContact);
    });

    testWidgets('adding or removing a block sends nothing', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      await _addBlock(tester);
      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 1'));

      expect(repo.created, isEmpty);
      expect(find.byType(TenantFormScreen), findsOneWidget);
    });

    testWidgets('empty blocks are not sent as contacts when removed', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addBlock(tester);
      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 1'));

      await _submit(tester);

      expect(repo.created.single.input.emergencyContacts, isEmpty);
    });
  });

  group('contact fields', () {
    const contactLabels = [_contactName, _contactRelation, _contactPhone];

    testWidgets('each contact field is a LabeledField with its marker', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _addFilledBlocks(tester, 2);

      for (final label in contactLabels) {
        expect(labeledField(label), findsNWidgets(2), reason: label);
        expect(find.text(label), findsNWidgets(2), reason: label);
      }
    });

    testWidgets('no contact field draws its label inside the decoration', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _addBlock(tester);

      for (final label in contactLabels) {
        expect(labeledField(label), findsOneWidget, reason: label);
        expect(labeledTextField(tester, label).decoration?.labelText, isNull);
      }
    });

    testWidgets('each contact label sits above its field', (tester) async {
      await _open(tester, _repo());
      await _addBlock(tester);

      for (final label in contactLabels) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(labeledFieldAt(label, 0));
        expect(text.bottom, lessThanOrEqualTo(input.top), reason: label);
      }
    });

    testWidgets('each contact label is read once, on its field node', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _addBlock(tester);

      for (final label in contactLabels) {
        expectFieldNode(tester, label);
      }
    });

    testWidgets('a contact error stays on its field node', (tester) async {
      await _open(tester, _repo());
      await _fill(tester);
      await _addBlock(tester);

      await _submit(tester);

      expectFieldNode(tester, _contactName, error: 'Nama kontak wajib diisi.');
    });

    testWidgets('tapping a contact label focuses its field', (tester) async {
      await _open(tester, _repo());
      await _addBlock(tester);

      await tester.tap(find.text(_contactPhone));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: labeledFieldAt(_contactPhone, 0),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });
  });

  group('contact validation', () {
    testWidgets('exactly one block is refused with the count message', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addBlock(tester);
      await _fillBlock(tester, 0);

      await _submit(tester);

      expect(find.text(_contactsCount), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('two blocks are accepted', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 2);

      await _submit(tester);

      expect(find.text(_contactsCount), findsNothing);
      expect(repo.created, hasLength(1));
    });

    testWidgets('four blocks are accepted', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 4);

      await _submit(tester);

      expect(repo.created.single.input.emergencyContacts, hasLength(4));
    });

    testWidgets('no block at all is accepted', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(find.text(_contactsCount), findsNothing);
      expect(repo.created, hasLength(1));
    });

    testWidgets('going from two blocks to one brings the count message', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 2);
      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 2'));

      await _submit(tester);

      expect(find.text(_contactsCount), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('removing the only block lets the form through', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addBlock(tester);
      await _submit(tester);
      expect(find.text(_contactsCount), findsOneWidget);

      await tapVisible(tester, find.byTooltip('Hapus kontak darurat 1'));
      await _submit(tester);

      expect(repo.created, hasLength(1));
    });

    testWidgets('an empty block names each missing field', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addBlock(tester);
      await _addBlock(tester);

      await _submit(tester);

      expect(
        labeledInputError(tester, _contactName),
        'Nama kontak wajib diisi.',
      );
      expect(
        labeledInputError(tester, _contactRelation),
        'Hubungan wajib diisi.',
      );
      expect(
        labeledInputError(tester, _contactPhone),
        'Nomor telepon kontak wajib diisi.',
      );
      expect(
        labeledInputError(tester, _contactName, 1),
        'Nama kontak wajib diisi.',
      );
      expect(repo.created, isEmpty);
    });

    testWidgets('only the empty field of a block shows its error', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 2);
      await typeLabeledAt(tester, _contactRelation, 1, '');

      await _submit(tester);

      expect(
        labeledInputError(tester, _contactRelation, 1),
        'Hubungan wajib diisi.',
      );
      expect(labeledInputError(tester, _contactRelation, 0), isNull);
      expect(labeledInputError(tester, _contactName, 1), isNull);
      expect(labeledInputError(tester, _contactPhone, 1), isNull);
      expect(repo.created, isEmpty);
    });

    testWidgets('a name of only spaces counts as empty', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 2);
      await typeLabeledAt(tester, _contactName, 0, '   ');

      await _submit(tester);

      expect(
        labeledInputError(tester, _contactName, 0),
        'Nama kontak wajib diisi.',
      );
      expect(repo.created, isEmpty);
    });

    testWidgets('an invalid contact phone shows the phone message', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 2);
      await typeLabeledAt(tester, _contactPhone, 1, '12345');

      await _submit(tester);

      expect(labeledInputError(tester, _contactPhone, 1), _invalidPhone);
      expect(labeledInputError(tester, _contactPhone, 0), isNull);
      expect(repo.created, isEmpty);
    });

    testWidgets('a contact phone with spaces and dashes is accepted', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addFilledBlocks(tester, 2);
      await typeLabeledAt(tester, _contactPhone, 0, '0813-5551 2345');

      await _submit(tester);

      expect(repo.created, hasLength(1));
    });

    testWidgets('fixing the block lets the next submit through', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addBlock(tester);
      await _addBlock(tester);
      await _submit(tester);
      expect(repo.created, isEmpty);

      await _fillBlock(tester, 0);
      await _fillBlock(tester, 1, name: 'Joko', relation: 'Kakak');
      await _submit(tester);

      expect(repo.created, hasLength(1));
    });
  });

  group('validation', () {
    testWidgets('no room asks to choose one and sends nothing', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, room: null);
      await typeInto(tester, _rent, '650000');

      await _submit(tester);

      _expectErrors(tester, {_room: 'Pilih kamar.'});
      expect(repo.created, isEmpty);
    });

    testWidgets('an empty name shows its error', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, name: '');

      await _submit(tester);

      _expectErrors(tester, {_name: 'Nama wajib diisi.'});
      expect(repo.created, isEmpty);
    });

    testWidgets('a name of only spaces counts as empty', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, name: '    ');

      await _submit(tester);

      _expectErrors(tester, {_name: 'Nama wajib diisi.'});
      expect(repo.created, isEmpty);
    });

    testWidgets('an empty phone shows its error', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, phone: '');

      await _submit(tester);

      _expectErrors(tester, {_phone: 'Nomor telepon wajib diisi.'});
      expect(repo.created, isEmpty);
    });

    testWidgets('a phone of only spaces counts as empty', (tester) async {
      await _open(tester, _repo());
      await _fill(tester, phone: '   ');

      await _submit(tester);

      _expectErrors(tester, {_phone: 'Nomor telepon wajib diisi.'});
    });

    final invalidPhones = {
      'letters': 'abcdefghij',
      'too short with 08': '08${'1' * 7}',
      'too long with 08': '08${'1' * 12}',
      'too short with 628': '628${'1' * 7}',
      'too long with 628': '628${'1' * 12}',
      'a plus sign': '+6281255204471',
      'another prefix': '0712${'3' * 8}',
      'a landline prefix': '021${'3' * 8}',
      'a letter inside': '0812552044a1',
      'a dot': '0812.5520.4471',
      'a missing prefix': '81255204471',
    };
    for (final entry in invalidPhones.entries) {
      testWidgets('rejects a phone with ${entry.key}', (tester) async {
        final repo = _repo();
        await _open(tester, repo);
        await _fill(tester, phone: entry.value);

        await _submit(tester);

        _expectErrors(tester, {_phone: _invalidPhone});
        expect(repo.created, isEmpty);
      });
    }

    final validPhones = {
      '08 and 8 digits': '08${'1' * 8}',
      '08 and 11 digits': '08${'1' * 11}',
      '628 and 8 digits': '628${'1' * 8}',
      '628 and 11 digits': '628${'1' * 11}',
      'dashes': '0812-5520-4471',
      'spaces': '0812 5520 4471',
      'spaces and dashes': '0812 - 5520 4471',
      '628 and dashes': '62-812-5520-4471',
    };
    for (final entry in validPhones.entries) {
      testWidgets('accepts a phone with ${entry.key}', (tester) async {
        final repo = _repo();
        await _open(tester, repo);
        await _fill(tester, phone: entry.value);

        await _submit(tester);

        expect(repo.created, hasLength(1));
      });
    }

    testWidgets('an empty rent shows its error', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, room: null);

      await _submit(tester);

      _expectErrors(tester, {
        _room: 'Pilih kamar.',
        _rent: 'Tarif sewa wajib diisi.',
      });
      expect(repo.created, isEmpty);
    });

    testWidgets('a rent of 0 must be more than 0', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await typeInto(tester, _rent, '0');

      await _submit(tester);

      _expectErrors(tester, {_rent: 'Tarif sewa harus lebih dari 0.'});
      expect(repo.created, isEmpty);
    });

    testWidgets('a rent of only zeros must be more than 0', (tester) async {
      await _open(tester, _repo());
      await _fill(tester);
      await typeInto(tester, _rent, '000');

      await _submit(tester);

      _expectErrors(tester, {_rent: 'Tarif sewa harus lebih dari 0.'});
    });

    testWidgets('a rent is required for the other cycles', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await choose(tester, _cycle, 'Mingguan');

      await _submit(tester);

      _expectErrors(tester, {_rent: 'Tarif sewa wajib diisi.'});
      expect(repo.created, isEmpty);
    });

    testWidgets('an empty form shows every required error', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      await _submit(tester);

      _expectErrors(tester, {
        _room: 'Pilih kamar.',
        _name: 'Nama wajib diisi.',
        _phone: 'Nomor telepon wajib diisi.',
        _rent: 'Tarif sewa wajib diisi.',
      });
      expect(repo.created, isEmpty);
    });

    testWidgets('keeps everything typed after a validation error', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _fill(tester, name: '', phone: '0812-5520-4471');
      await typeInto(tester, _occupation, 'Mahasiswa');
      await typeInto(tester, _grace, '4');
      await _addFilledBlocks(tester, 2);

      await _submit(tester);

      expect(_roomValue(tester), 'r2');
      expect(_text(tester, _phone), '0812-5520-4471');
      expect(_text(tester, _occupation), 'Mahasiswa');
      expect(_text(tester, _grace), '4');
      expect(_text(tester, _rent), '650000');
      expect(labeledTextAt(tester, _contactName, 1), 'Kontak 2');
    });

    testWidgets('fixing the errors lets the next submit through', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _submit(tester);
      expect(repo.created, isEmpty);

      await _fill(tester);
      await _submit(tester);

      expect(repo.created, hasLength(1));
    });

    testWidgets('errors disappear once the next submit is valid', (
      tester,
    ) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _open(tester, repo);
      await _submit(tester);
      await _fill(tester);

      await _tapFirstSave(tester);

      _expectErrors(tester, {});
    });
  });

  group('lease dates', () {
    testWidgets('the date fields are read-only', (tester) async {
      await _open(tester, _repo());

      expect(labeledTextField(tester, _start).readOnly, isTrue);
      expect(labeledTextField(tester, _end).readOnly, isTrue);
    });

    testWidgets('the date fields are at least 48 dp', (tester) async {
      await _open(tester, _repo());

      expectFinderTargetSize(tester, fieldLabeled(_start));
      expectFinderTargetSize(tester, fieldLabeled(_end));
    });

    testWidgets('tapping the start date opens a date picker', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, fieldLabeled(_start));

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('tapping the end date opens a date picker', (tester) async {
      await _open(tester, _repo());

      await tapVisible(tester, fieldLabeled(_end));

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('opening a picker submits and validates nothing', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await tapVisible(tester, fieldLabeled(_start));

      expect(repo.created, isEmpty);
      _expectErrors(tester, {});
    });

    testWidgets('the chosen start date is shown as a formatted date', (
      tester,
    ) async {
      await _open(tester, _repo());

      await pickDate(tester, _start, 20);

      expect(_text(tester, _start), formatDate(_day(20)));
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('the chosen end date is shown as a formatted date', (
      tester,
    ) async {
      await _open(tester, _repo());

      await pickDate(tester, _end, 25);

      expect(_text(tester, _end), formatDate(_day(25)));
    });

    testWidgets('cancelling the picker leaves the field empty', (tester) async {
      await _open(tester, _repo());

      await openAndCancelDatePicker(tester, _start);

      expect(_text(tester, _start), isEmpty);
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('cancelling keeps a date chosen before', (tester) async {
      await _open(tester, _repo());
      await pickDate(tester, _start, 20);

      await openAndCancelDatePicker(tester, _start);

      expect(_text(tester, _start), formatDate(_day(20)));
    });

    testWidgets('an end date before the start date is refused', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await pickDate(tester, _start, 20);
      await pickDate(tester, _end, 5);

      await _submit(tester);

      _expectErrors(tester, {_end: _endBeforeStart});
      expect(repo.created, isEmpty);
    });

    testWidgets('an end date on the start date is accepted', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await pickDate(tester, _start, 20);
      await pickDate(tester, _end, 20);

      await _submit(tester);

      expect(repo.created, hasLength(1));
    });

    testWidgets('an end date after the start date is accepted', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await pickDate(tester, _start, 5);
      await pickDate(tester, _end, 20);

      await _submit(tester);

      expect(repo.created, hasLength(1));
    });

    testWidgets('an end date without a start date is accepted', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await pickDate(tester, _end, 5);

      await _submit(tester);

      expect(repo.created, hasLength(1));
    });

    testWidgets('moving the end date after the start fixes the error', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await pickDate(tester, _start, 20);
      await pickDate(tester, _end, 5);
      await _submit(tester);
      expect(repo.created, isEmpty);

      await pickDate(tester, _end, 25);
      await _submit(tester);

      expect(repo.created, hasLength(1));
      expect(repo.created.single.input.lease!.endDate, _utcDay(25));
    });
  });

  group('request', () {
    testWidgets('sends the required values and the defaults', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(repo.created.single.propertyId, 'p1');
      expect(
        repo.created.single.input,
        NewTenantInput(
          roomId: 'r2',
          name: 'Rina Putri',
          phone: '0812-5520-4471',
          lease: LeaseInput(
            billingCycle: BillingCycle.monthly,
            rent: 650000,
            gracePeriodDays: 0,
          ),
        ),
      );
      expect(repo.created.single.input.occupation, isNull);
      expect(repo.created.single.input.emergencyContacts, isEmpty);
      expect(repo.created.single.input.lease!.startDate, isNull);
      expect(repo.created.single.input.lease!.endDate, isNull);
    });

    testWidgets('trims the name, phone and occupation', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, name: '  Rina Putri  ', phone: '  081255204471  ');
      await typeInto(tester, _occupation, '  Mahasiswa  ');

      await _submit(tester);

      final input = repo.created.single.input;
      expect(input.name, 'Rina Putri');
      expect(input.phone, '081255204471');
      expect(input.occupation, 'Mahasiswa');
    });

    testWidgets('an occupation of only spaces is not sent', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await typeInto(tester, _occupation, '   ');

      await _submit(tester);

      expect(repo.created.single.input.occupation, isNull);
    });

    testWidgets('sends the emergency contacts trimmed and in order', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _addBlock(tester);
      await _addBlock(tester);
      await _fillBlock(
        tester,
        0,
        name: '  Siti Rahma ',
        relation: ' Ibu ',
        phone: ' 081355512345 ',
      );
      await _fillBlock(
        tester,
        1,
        name: 'Joko',
        relation: 'Kakak',
        phone: '081355512346',
      );

      await _submit(tester);

      expect(repo.created.single.input.emergencyContacts, [
        EmergencyContact(
          name: 'Siti Rahma',
          relationship: 'Ibu',
          phone: '081355512345',
        ),
        EmergencyContact(
          name: 'Joko',
          relationship: 'Kakak',
          phone: '081355512346',
        ),
      ]);
    });

    testWidgets('sends the dates, cycle, grace period and rent', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await pickDate(tester, _start, 5);
      await pickDate(tester, _end, 20);
      await choose(tester, _cycle, '3 Bulan');
      await typeInto(tester, _grace, '7');
      await typeInto(tester, _rent, '1900000');

      await _submit(tester);

      expect(
        repo.created.single.input.lease,
        LeaseInput(
          startDate: _utcDay(5),
          endDate: _utcDay(20),
          billingCycle: BillingCycle.quarterly,
          gracePeriodDays: 7,
          rent: 1900000,
        ),
      );
    });

    for (final entry in {
      'Mingguan': BillingCycle.weekly,
      'Bulanan': BillingCycle.monthly,
      '3 Bulan': BillingCycle.quarterly,
      '6 Bulan': BillingCycle.semiannual,
      '12 Bulan': BillingCycle.annual,
    }.entries) {
      testWidgets('sends the ${entry.key} cycle', (tester) async {
        final repo = _repo();
        await _open(tester, repo);
        await _fill(tester);
        await choose(tester, _cycle, entry.key);
        await typeInto(tester, _rent, '100000');

        await _submit(tester);

        expect(repo.created.single.input.lease!.billingCycle, entry.value);
      });
    }

    testWidgets('sends the rent as an integer of rupiah', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await typeInto(tester, _rent, '0750000');

      await _submit(tester);

      expect(repo.created.single.input.lease!.rent, isA<int>());
      expect(repo.created.single.input.lease!.rent, 750000);
    });

    testWidgets('an emptied grace period is sent as 0', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await typeInto(tester, _grace, '');

      await _submit(tester);

      expect(repo.created.single.input.lease!.gracePeriodDays, 0);
    });

    testWidgets('sends the room the user chose over the preselected one', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, query: '?kamar=r2');
      await _fill(tester, room: 'Kamar 10');

      await _submit(tester);

      expect(repo.created.single.input.roomId, 'r3');
      expect(repo.created.single.input.lease!.rent, 900000);
    });
  });

  group('in flight', () {
    testWidgets('shows a busy disabled button', (tester) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);

      await _tapFirstSave(tester);

      expectBusy(tester);
    });

    testWidgets('a second tap sends one request', (tester) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);

      await _tapFirstSave(tester);
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.created, hasLength(1));
    });

    testWidgets('stays on the form until the request finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..createScript.gate = gate;
      await _open(tester, repo);
      await _fill(tester);
      await _tapFirstSave(tester);

      expect(find.byType(TenantFormScreen), findsOneWidget);
      expect(find.byType(InvitationShareScreen), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });
  });

  group('success', () {
    testWidgets('opens the share screen of the new tenant as new', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(currentPath(tester), '/properti/p1/penyewa/new-1/undangan');
      expect(_currentUri(tester).queryParameters, {'baru': '1'});
      final share = tester.widget<InvitationShareScreen>(
        find.byType(InvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.tenantId, 'new-1');
      expect(share.isNew, isTrue);
      expect(find.byType(TenantFormScreen), findsNothing);
    });

    testWidgets('Back does not return to the form', (tester) async {
      await _open(tester, _repo());
      await _fill(tester);
      await _submit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TenantFormScreen), findsNothing);
    });

    testWidgets('the new tenant is in the list after Selesai', (tester) async {
      final repo = _repo();
      await pumpTenantApp(tester, repo);
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await _fill(tester, name: 'Rina Putri');
      await _submit(tester);

      await tapVisible(tester, find.text('Selesai'));

      expect(find.byType(TenantListScreen), findsOneWidget);
      expect(find.text('Rina Putri'), findsOneWidget);
    });
  });

  group('failures', () {
    final fieldCases = <String, ({ApiFailure failure, String label})>{
      'a room that is no longer vacant': (
        failure: const ApiFailure(code: 'ROOM_NOT_VACANT', field: 'roomId'),
        label: _room,
      ),
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
        final repo = _repo()..createScript.queue.add(entry.value.failure);
        await _open(tester, repo);
        await _fill(tester);

        await _submit(tester);

        final message = errorMessageFor(entry.value.failure);
        _expectErrors(tester, {entry.value.label: message});
        expect(find.byType(TenantFormScreen), findsOneWidget);
        expect(snackBar(message), findsNothing);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
      });
    }

    testWidgets('a phone validation error says the phone number is invalid', (
      tester,
    ) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(labeledFieldError(tester, _phone), 'Nomor telepon tidak valid.');
    });

    testWidgets('a taken room says it is occupied', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'ROOM_NOT_VACANT', field: 'roomId'),
        );
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(labeledFieldError(tester, _room), 'Kamar sudah terisi.');
    });

    for (final field in [
      'emergencyContacts',
      'emergencyContacts.0.phone',
      'emergencyContacts.1.name',
    ]) {
      testWidgets('a $field error shows in the contact group', (tester) async {
        final repo = _repo()
          ..createScript.queue.add(
            ApiFailure(code: 'VALIDATION_FAILED', field: field),
          );
        await _open(tester, repo);
        await _fill(tester);
        await _addFilledBlocks(tester, 2);

        await _submit(tester);

        expect(find.text(validationMessage(field)), findsOneWidget);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
        _expectErrors(tester, {});
        expect(labeledTextAt(tester, _contactName, 0), 'Kontak 1');
      });
    }

    testWidgets('a field error keeps every typed value', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _open(tester, repo);
      await _fill(tester);
      await typeInto(tester, _occupation, 'Mahasiswa');
      await typeInto(tester, _grace, '3');
      await _addFilledBlocks(tester, 2);
      await pickDate(tester, _start, 5);

      await _submit(tester);

      expect(_roomValue(tester), 'r2');
      expect(_text(tester, _name), 'Rina Putri');
      expect(_text(tester, _phone), '0812-5520-4471');
      expect(_text(tester, _occupation), 'Mahasiswa');
      expect(_text(tester, _grace), '3');
      expect(_text(tester, _rent), '650000');
      expect(_text(tester, _start), formatDate(_day(5)));
      expect(labeledTextAt(tester, _contactName, 1), 'Kontak 2');
    });

    testWidgets('the button works again after a field error', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);
      expect(busyButton(), findsNothing);
      expect(isDisabled(tester, _save), isFalse);

      await typeInto(tester, _phone, '081255204471');
      await _submit(tester);

      expect(repo.created, hasLength(2));
      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });

    testWidgets('a field error goes away when the next submit starts', (
      tester,
    ) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);
      repo.createScript.gate = Completer<void>();

      await _tapFirstSave(tester);

      expect(labeledFieldError(tester, _phone), isNull);
      expectBusy(tester);
    });

    final bannerCases = <String, ApiFailure>{
      'a read-only property': const ApiFailure(code: 'PROPERTY_READ_ONLY'),
      'a read-only room': const ApiFailure(code: 'ROOM_READ_ONLY'),
      'a network failure': const ApiFailure.network(),
      'a server failure': const ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
      'a field the form does not have': const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'lease.gracePeriodDays',
      ),
      'a validation error without a field': const ApiFailure(
        code: 'VALIDATION_FAILED',
      ),
    };
    for (final entry in bannerCases.entries) {
      testWidgets('shows ${entry.key} in a banner and keeps the values', (
        tester,
      ) async {
        final repo = _repo()..createScript.queue.add(entry.value);
        await _open(tester, repo);
        await _fill(tester);
        await typeInto(tester, _occupation, 'Mahasiswa');

        await _submit(tester);

        final message = errorMessageFor(entry.value);
        expect(find.text(message), findsOneWidget);
        expect(snackBar(message), findsNothing);
        _expectErrors(tester, {});
        expect(find.byType(TenantFormScreen), findsOneWidget);
        expect(_roomValue(tester), 'r2');
        expect(_text(tester, _name), 'Rina Putri');
        expect(_text(tester, _phone), '0812-5520-4471');
        expect(_text(tester, _occupation), 'Mahasiswa');
        expect(_text(tester, _rent), '650000');
      });
    }

    testWidgets('announces the banner as a live region', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(const ApiFailure(code: 'PROPERTY_READ_ONLY'));
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);

      expectLiveRegion(tester, errorMessage('PROPERTY_READ_ONLY'));
    });

    testWidgets('the banner stays on screen until the next submit', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('the banner goes away when the next submit starts', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);
      repo.createScript.gate = Completer<void>();

      await _tapFirstSave(tester);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expectBusy(tester);
    });

    testWidgets('a successful retry after a banner opens the share screen', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);

      await _submit(tester);

      expect(repo.created, hasLength(2));
      expect(repo.created.first.input, repo.created.last.input);
      expect(find.byType(InvitationShareScreen), findsOneWidget);
    });

    testWidgets('a failure adds no tenant', (tester) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(repo.tenants, hasLength(3));
    });
  });

  group('structure', () {
    const labels = [
      _room,
      _name,
      _phone,
      _occupation,
      _start,
      _end,
      _cycle,
      _grace,
      _rent,
    ];

    testWidgets('wraps every field in a LabeledField with its visible text', (
      tester,
    ) async {
      await _open(tester, _repo());

      for (final label in labels) {
        expect(labeledField(label), findsOneWidget, reason: label);
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(LabeledField), findsNWidgets(labels.length));
    });

    testWidgets('marks five required and five optional labels in text', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.textContaining('(wajib)'), findsNWidgets(5));
      expect(find.textContaining('(opsional)'), findsNWidgets(5));
    });

    testWidgets('draws no label inside any field of the form', (tester) async {
      await _open(tester, _repo());

      expectNoDecorationLabels(tester);
    });

    testWidgets(
      'draws no label inside any field once contacts and errors show',
      (tester) async {
        await _open(tester, _repo());
        await _addFilledBlocks(tester, 2);
        await _submit(tester);

        expectNoDecorationLabels(tester);
      },
    );

    testWidgets('puts each label above its field', (tester) async {
      await _open(tester, _repo());

      for (final label in labels) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top), reason: label);
      }
    });

    testWidgets('reads every label once, on its field node', (tester) async {
      await _open(tester, _repo());

      for (final label in labels) {
        expectFieldNode(tester, label);
      }
    });

    testWidgets('keeps the room and name errors on their field nodes', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _submit(tester);

      expectFieldNode(tester, _room, error: 'Pilih kamar.');
      expectFieldNode(tester, _name, error: 'Nama wajib diisi.');
    });

    testWidgets('keeps the phone format help on the phone field node', (
      tester,
    ) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          announced(tester.getSemantics(fieldLabeled(_phone))),
          contains(_phoneHelper),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('tapping a label focuses its field', (tester) async {
      await _open(tester, _repo());

      await tester.tap(find.text(_phone));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_phone),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('puts the save button in a pinned ActionFooter', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectPinnedFooter(tester, _save);
    });

    testWidgets('keeps the busy save button inside the ActionFooter', (
      tester,
    ) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester);

      await _tapFirstSave(tester);

      expect(
        find.descendant(
          of: find.byType(ActionFooter),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expectBusy(tester);
    });

    testWidgets('keeps the footer on screen after scrolling at large text', (
      tester,
    ) async {
      await _open(tester, _repo(), largeText: true);
      final before = tester.getRect(find.byType(ActionFooter));
      expectFooterAtBottom(tester);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(ActionFooter)), before);
      expect(find.text(_save), findsOneWidget);
    });

    testWidgets('keeps the footer at the bottom at large text with errors', (
      tester,
    ) async {
      await _open(tester, _repo(), largeText: true);

      await _submit(tester);

      expectFooterAtBottom(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    Future<void> submitInFlight(WidgetTester tester) async {
      await tester.ensureVisible(find.text(_save));
      await tester.pump();
      await tapAndPump(tester, find.text(_save));
    }

    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the empty form': (tester, large) =>
          _open(tester, _repo(), largeText: large),
      'the form for a manager': (tester, large) =>
          _open(tester, _repo(), role: UserRole.manager, largeText: large),
      'the form with a preselected room': (tester, large) =>
          _open(tester, _repo(), query: '?kamar=r3', largeText: large),
      'the form without a vacant room': (tester, large) =>
          _open(tester, _repo(), rooms: _fullRooms(), largeText: large),
      'the form while the rooms load': (tester, large) => _open(
        tester,
        _repo(),
        rooms: FakeRoomRepository(rooms: tenantRooms())
          ..listScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
      'the form after the rooms failed to load': (tester, large) => _open(
        tester,
        _repo(),
        rooms: FakeRoomRepository(rooms: tenantRooms())
          ..listScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'the form with one contact block': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _addBlock(tester);
      },
      'the form with four contact blocks': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _addFilledBlocks(tester, 4);
      },
      'the form with chosen dates': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await pickDate(tester, _start, 5);
        await pickDate(tester, _end, 20);
      },
      'the form with a weekly cycle': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await choose(tester, _cycle, 'Mingguan');
      },
      'the form with required field errors': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _submit(tester);
      },
      'the form with an invalid phone and rent': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _fill(tester, phone: '12345');
        await typeInto(tester, _rent, '0');
        await _submit(tester);
      },
      'the form with a contact count error': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _fill(tester);
        await _addBlock(tester);
        await _fillBlock(tester, 0);
        await _submit(tester);
      },
      'the form with contact block errors': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _fill(tester);
        await _addBlock(tester);
        await _addBlock(tester);
        await _submit(tester);
      },
      'the form with an end date error': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _fill(tester);
        await pickDate(tester, _start, 20);
        await pickDate(tester, _end, 5);
        await _submit(tester);
      },
      'the form with server field errors': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(code: 'ROOM_NOT_VACANT', field: 'roomId'),
          );
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await _submit(tester);
      },
      'the form with a server contact error': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(
              code: 'VALIDATION_FAILED',
              field: 'emergencyContacts',
            ),
          );
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await _addFilledBlocks(tester, 2);
        await _submit(tester);
      },
      'the form with a banner': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(code: 'PROPERTY_READ_ONLY'),
          );
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await _submit(tester);
      },
      'the form in flight': (tester, large) async {
        final repo = _repo()..createScript.gate = Completer<void>();
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await submitInFlight(tester);
      },
      'the start date picker': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await tapVisible(tester, fieldLabeled(_start));
      },
      'the end date picker': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await tapVisible(tester, fieldLabeled(_end));
      },
      'the room list open': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await openDropdown(tester, _room);
      },
      'the billing cycle list open': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await openDropdown(tester, _cycle);
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
  });
}
