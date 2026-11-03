import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/date_picker_semantics.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
import 'tenant_ui_helpers.dart';

const _start = 'Tanggal mulai (opsional)';
const _end = 'Tanggal berakhir (opsional)';
const _name = 'Nama lengkap (wajib)';
const _phone = 'Nomor telepon (wajib)';
const _room = 'Kamar (wajib)';
const _endBeforeStart = 'Tanggal berakhir tidak boleh sebelum tanggal mulai.';

DateTime _day(int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, day);
}

DateTime _utcDay(int day) {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, day);
}

Tenant _dated() => makeTenant(
  id: 't3',
  name: 'Rina Putri',
  roomId: 'r7',
  roomNumber: '14',
  startDate: _utcDay(20),
  endDate: _utcDay(25),
);

/// A way to show the tenant form, and to fill it so it can be saved.
class _Form {
  const _Form({
    required this.name,
    required this.open,
    required this.save,
    required this.fill,
  });

  final String name;
  final Future<void> Function(WidgetTester) open;
  final Future<void> Function(WidgetTester) save;

  /// Brings the form to a state where only the dates can make it invalid.
  final Future<void> Function(WidgetTester) fill;
}

Future<void> _saveCreate(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Penyewa'));

Future<void> _saveEdit(WidgetTester tester) => tapVisible(
  tester,
  find.descendant(
    of: find.byType(ActionFooter),
    matching: find.byType(FilledButton),
  ),
);

final _forms = [
  _Form(
    name: 'the create form',
    open: (tester) => pumpTenantApp(
      tester,
      FakeTenantRepository(tenants: sampleTenants()),
      path: '/properti/p1/penyewa/tambah',
    ),
    save: _saveCreate,
    fill: (tester) async {
      await choose(tester, _room, 'Kamar 09');
      await typeInto(tester, _name, 'Rina Putri');
      await typeInto(tester, _phone, '0812-5520-4471');
    },
  ),
  _Form(
    name: 'the edit form',
    open: (tester) => pumpTenantApp(
      tester,
      FakeTenantRepository(tenants: [_dated()]),
      path: '/properti/p1/penyewa/t3/ubah',
    ),
    save: _saveEdit,
    fill: (tester) async {},
  ),
];

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

/// Taps [day] in the open date picker and confirms.
Future<void> _pickInOpenPicker(WidgetTester tester, int day) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('$day'),
    ),
  );
  await tester.pumpAndSettle();
  final ok = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  ).okButtonLabel;
  await tester.tap(find.text(ok));
  await tester.pumpAndSettle();
}

String _shown(WidgetTester tester, String label) =>
    labeledTextField(tester, label).controller!.text;

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  for (final form in _forms) {
    group('date field semantics of ${form.name}', () {
      for (final label in [_start, _end]) {
        testWidgets('$label offers the tap action on the node of the field', (
          tester,
        ) async {
          await form.open(tester);

          await _withSemantics(tester, () async {
            final data = tester
                .getSemantics(fieldLabeled(label))
                .getSemanticsData();
            expect(data.hasAction(SemanticsAction.tap), isTrue);
          });
        });

        testWidgets('$label has one node with the tap action for the label', (
          tester,
        ) async {
          await form.open(tester);

          await _withSemantics(tester, () async {
            expect(tappableNodesAnnouncing(tester, label), hasLength(1));
          });
        });

        testWidgets('$label announces its label once', (tester) async {
          await form.open(tester);

          await _withSemantics(tester, () async {
            expect(nodesAnnouncing(tester, label), hasLength(1));
          });
        });

        testWidgets('$label opens the date picker when the tap action is '
            'performed', (tester) async {
          await form.open(tester);

          await openDatePickerThroughSemantics(tester, label);

          expect(find.byType(DatePickerDialog), findsOneWidget);
        });

        testWidgets('$label shows the date picked after opening the picker '
            'through the tap action', (tester) async {
          await form.open(tester);
          await openDatePickerThroughSemantics(tester, label);

          await _pickInOpenPicker(tester, 22);

          expect(find.byType(DatePickerDialog), findsNothing);
          expect(_shown(tester, label), formatDate(_day(22)));
          await _withSemantics(tester, () async {
            final node = tappableNodesAnnouncing(tester, label).single;
            expect(announced(node), contains(formatDate(_day(22))));
          });
        });

        testWidgets('$label keeps its date when the picker opened through the '
            'tap action is cancelled', (tester) async {
          await form.open(tester);
          final before = _shown(tester, label);
          await openDatePickerThroughSemantics(tester, label);

          final cancel = MaterialLocalizations.of(
            tester.element(find.byType(DatePickerDialog)),
          ).cancelButtonLabel;
          await tester.tap(find.text(cancel));
          await tester.pumpAndSettle();

          expect(find.byType(DatePickerDialog), findsNothing);
          expect(_shown(tester, label), before);
        });

        testWidgets('$label keeps a semantics target of at least 48 dp', (
          tester,
        ) async {
          await form.open(tester);

          await _withSemantics(tester, () async {
            final rect = tappableNodesAnnouncing(tester, label).single.rect;
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.width, greaterThanOrEqualTo(48));
          });
        });
      }

      testWidgets('keeps the tap action and the end date error on the node of '
          'the field', (tester) async {
        await form.open(tester);
        await form.fill(tester);
        await pickDate(tester, _start, 20);
        await pickDate(tester, _end, 5);
        await form.save(tester);

        expect(labeledFieldError(tester, _end), _endBeforeStart);
        await _withSemantics(tester, () async {
          final nodes = tappableNodesAnnouncing(tester, _end);
          expect(nodes, hasLength(1));
          expect(announced(nodes.single), contains(_endBeforeStart));
          expect(nodesAnnouncing(tester, _end), hasLength(1));
        });
      });

      testWidgets('opens the end date picker through the tap action while the '
          'error shows', (tester) async {
        await form.open(tester);
        await form.fill(tester);
        await pickDate(tester, _start, 20);
        await pickDate(tester, _end, 5);
        await form.save(tester);

        await openDatePickerThroughSemantics(tester, _end);
        await _pickInOpenPicker(tester, 27);

        expect(_shown(tester, _end), formatDate(_day(27)));
      });
    });
  }
}
