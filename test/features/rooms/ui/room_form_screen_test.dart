import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'room_ui_helpers.dart';

/// Every test of this file reads semantics labels.
void testWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) => testWidgetsWithSemantics(description, body);

const _number = 'Nomor kamar (wajib)';
const _rate = 'Tarif dasar per bulan (wajib)';
const _length = 'Panjang (m)';
const _width = 'Lebar (m)';
const _facility = 'Tambah fasilitas';
const _sizeGroup = 'Ukuran kamar (opsional)';
const _facilityGroup = 'Fasilitas (opsional)';
const _rateHelper =
    'Dipakai sebagai nilai awal saat mendaftarkan penyewa. Tarif tiap masa '
    'sewa bisa disesuaikan.';
const _rateHelperEdit =
    'Mengubah tarif dasar tidak mengubah tarif sewa masa sewa yang sudah ada.';
const _facilityHelper =
    'Ketik lalu ketuk Tambah. Maks. 15 fasilitas, 30 karakter per fasilitas.';
const _dimensionError =
    'Gunakan angka lebih dari 0 hingga 20, maksimal 2 desimal (contoh: 3,5).';
const _pairError = 'Isi panjang dan lebar, atau kosongkan keduanya.';
const _tagTooLong = 'Fasilitas maksimal 30 karakter.';
const _tagLimit = 'Sudah mencapai 15 fasilitas.';

Room _room({num? lengthM = 3.5, num? widthM = 4}) => occupiedRoom(
  id: 'r1',
  number: '08',
  baseRate: 800000,
  lengthM: lengthM,
  widthM: widthM,
  facilities: ['ac', 'kasur'],
);

FakeRoomRepository _repo({
  List<Room>? rooms,
  List<String> suggestions = const ['ac', 'kasur', 'kamar mandi dalam', 'wifi'],
}) => FakeRoomRepository(rooms: rooms ?? [_room()], suggestions: suggestions);

Future<void> _pumpAdd(
  WidgetTester tester,
  FakeRoomRepository repo, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) async {
  await pumpRoomApp(
    tester,
    repo,
    role: role,
    path: '/properti/p1/kamar/tambah',
    settle: settle,
    largeText: largeText,
  );
}

Future<void> _pumpEdit(
  WidgetTester tester,
  FakeRoomRepository repo, {
  bool settle = true,
  bool largeText = false,
}) async {
  await pumpRoomApp(
    tester,
    repo,
    path: '/properti/p1/kamar/r1/ubah',
    settle: settle,
    largeText: largeText,
  );
}

String _text(WidgetTester tester, String label) =>
    labeledTextField(tester, label).controller!.text;

Future<void> _submitAdd(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Kamar'));

Future<void> _submitEdit(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Perubahan'));

Future<void> _fill(
  WidgetTester tester, {
  String number = '10',
  String rate = '700000',
  String? length,
  String? width,
}) async {
  await typeInto(tester, _number, number);
  await typeInto(tester, _rate, rate);
  if (length != null) await typeInto(tester, _length, length);
  if (width != null) await typeInto(tester, _width, width);
}

Future<void> _addTag(WidgetTester tester, String tag) async {
  await typeInto(tester, _facility, tag);
  await _tapInView(tester, buttonLabelled('Tambah'));
}

/// Scrolls [finder] clear of the app bar, then taps it.
Future<void> _tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The remove button of the chosen tag, exactly one when it is chosen.
Finder _chosen(String tag) => find.bySemanticsLabel('Hapus fasilitas $tag');

Future<void> _removeTag(WidgetTester tester, String tag) async {
  await tester.tap(removeFacilityButton(tag));
  await tester.pumpAndSettle();
}

String _prefix(WidgetTester tester, String label) {
  final decoration = labeledTextField(tester, label).decoration;
  final prefix = decoration?.prefix;
  return decoration?.prefixText ?? (prefix is Text ? prefix.data ?? '' : '');
}

void main() {
  group('add form', () {
    testWidgets('shows the title and the submit button', (tester) async {
      await _pumpAdd(tester, _repo());

      expect(find.byType(RoomFormScreen), findsOneWidget);
      expect(appBarTitle('Tambah Kamar'), findsOneWidget);
      expect(find.text('Simpan Kamar'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsNothing);
    });

    testWidgets('shows every field empty with its label', (tester) async {
      await _pumpAdd(tester, _repo());

      for (final label in [_number, _rate, _length, _width, _facility]) {
        expect(fieldLabeled(label), findsOneWidget);
        expect(_text(tester, label), isEmpty);
      }
    });

    testWidgets('the number field shows an example', (tester) async {
      await _pumpAdd(tester, _repo());

      expect(
        labeledTextField(tester, _number).decoration?.hintText,
        'Contoh: 08',
      );
    });

    testWidgets('the rate field has a Rp prefix and the number keyboard', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      expect(_prefix(tester, _rate), 'Rp');
      expect(
        labeledTextField(tester, _rate).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('the rate field accepts digits only', (tester) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _rate, 'a1b2.c3,');

      expect(_text(tester, _rate), '123');
    });

    testWidgets('the rate helper says what the base rate is for', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      expect(find.textContaining(_rateHelper), findsOneWidget);
      expect(find.textContaining(_rateHelperEdit), findsNothing);
    });

    testWidgets('the dimension fields use the decimal keyboard', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      expect(labeledTextField(tester, _length).keyboardType.decimal, isTrue);
      expect(labeledTextField(tester, _width).keyboardType.decimal, isTrue);
    });

    testWidgets('groups the dimension and facility fields', (tester) async {
      await _pumpAdd(tester, _repo());

      expect(find.text(_sizeGroup), findsOneWidget);
      expect(find.text(_facilityGroup), findsOneWidget);
      expect(find.text(_facilityHelper), findsOneWidget);
      for (final title in [_sizeGroup, _facilityGroup]) {
        expect(
          tester.getSemantics(find.text(title)),
          isSemantics(isHeader: true),
        );
      }
    });

    testWidgets('Kembali leaves the form without saving', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await typeInto(tester, _number, '10');

      await pressBack(tester);

      expect(find.byType(RoomListScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/kamar');
      expect(repo.created, isEmpty);
    });

    testWidgets('a manager can use the add form', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo, role: UserRole.manager);
      await _fill(tester);

      await _submitAdd(tester);

      expect(repo.created, hasLength(1));
    });
  });

  group('add validation', () {
    testWidgets('an empty number shows its error and sends nothing', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await typeInto(tester, _rate, '700000');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _number), 'Nomor kamar wajib diisi.');
      expect(labeledFieldError(tester, _rate), isNull);
      expect(repo.created, isEmpty);
    });

    testWidgets('a number of only spaces counts as empty', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, number: '   ');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _number), 'Nomor kamar wajib diisi.');
      expect(repo.created, isEmpty);
    });

    testWidgets('an empty rate shows its error and sends nothing', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await typeInto(tester, _number, '10');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _rate), 'Tarif sewa wajib diisi.');
      expect(labeledFieldError(tester, _number), isNull);
      expect(repo.created, isEmpty);
    });

    testWidgets('a rate of 0 must be more than 0', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, rate: '0');

      await _submitAdd(tester);

      expect(
        labeledFieldError(tester, _rate),
        'Tarif sewa harus lebih dari 0.',
      );
      expect(repo.created, isEmpty);
    });

    testWidgets('a rate of only zeros must be more than 0', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, rate: '000');

      await _submitAdd(tester);

      expect(
        labeledFieldError(tester, _rate),
        'Tarif sewa harus lebih dari 0.',
      );
      expect(repo.created, isEmpty);
    });

    testWidgets('an empty form shows both errors', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _number), 'Nomor kamar wajib diisi.');
      expect(labeledFieldError(tester, _rate), 'Tarif sewa wajib diisi.');
      expect(repo.created, isEmpty);
    });

    testWidgets('fixing the errors lets the next submit through', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _submitAdd(tester);
      expect(repo.created, isEmpty);

      await _fill(tester);
      await _submitAdd(tester);

      expect(repo.created, hasLength(1));
      expect(find.byType(RoomFormScreen), findsNothing);
    });

    testWidgets('keeps the typed values after a validation error', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());
      await _fill(tester, number: '', length: '3,5', width: '4');

      await _submitAdd(tester);

      expect(_text(tester, _rate), '700000');
      expect(_text(tester, _length), '3,5');
      expect(_text(tester, _width), '4');
    });
  });

  group('dimension validation', () {
    final invalid = <String, ({String length, String width})>{
      'text': (length: 'abc', width: '4'),
      'zero': (length: '0', width: '4'),
      'zero in the width': (length: '3,5', width: '0'),
      'above the maximum': (length: '20,01', width: '4'),
      'a whole number above the maximum': (length: '21', width: '4'),
      'three decimals': (length: '3,555', width: '4'),
      'three decimals in the width': (length: '3,5', width: '1,001'),
      'two separators': (length: '3,5,2', width: '4'),
    };

    for (final entry in invalid.entries) {
      testWidgets('rejects ${entry.key} with one message and no request', (
        tester,
      ) async {
        final repo = _repo();
        await _pumpAdd(tester, repo);
        await _fill(
          tester,
          length: entry.value.length,
          width: entry.value.width,
        );

        await _submitAdd(tester);

        expect(find.text(_dimensionError), findsOneWidget);
        expect(find.text(_pairError), findsNothing);
        expect(repo.created, isEmpty);
      });
    }

    testWidgets('two invalid values still show the message only once', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, length: 'abc', width: '99');

      await _submitAdd(tester);

      expect(find.text(_dimensionError), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('a length without a width asks for both', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, length: '3,5');

      await _submitAdd(tester);

      expect(find.text(_pairError), findsOneWidget);
      expect(find.text(_dimensionError), findsNothing);
      expect(repo.created, isEmpty);
    });

    testWidgets('a width without a length asks for both', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, width: '4');

      await _submitAdd(tester);

      expect(find.text(_pairError), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('the dimension message goes away once the values are fixed', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, length: '21', width: '4');
      await _submitAdd(tester);

      await typeInto(tester, _length, '3,5');
      await _submitAdd(tester);

      expect(find.text(_dimensionError), findsNothing);
      expect(repo.created, hasLength(1));
    });

    testWidgets('accepts the smallest and the largest value', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, length: '20', width: '0,01');

      await _submitAdd(tester);

      expect(repo.created.single.input.lengthM, 20);
      expect(repo.created.single.input.widthM, 0.01);
    });

    testWidgets('dimension errors appear next to the other field errors', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());
      await _fill(tester, number: '', rate: '', length: '3,5');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _number), 'Nomor kamar wajib diisi.');
      expect(labeledFieldError(tester, _rate), 'Tarif sewa wajib diisi.');
      expect(find.text(_pairError), findsOneWidget);
    });
  });

  group('area', () {
    testWidgets('shows no area while a dimension is missing', (tester) async {
      await _pumpAdd(tester, _repo());

      expect(find.textContaining('Luas'), findsNothing);

      await typeInto(tester, _length, '3,5');

      expect(find.textContaining('Luas'), findsNothing);
    });

    testWidgets('shows the area once both dimensions are valid', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _length, '3,5');
      await typeInto(tester, _width, '4');

      expect(find.text('Luas: 14 m²'), findsOneWidget);
    });

    testWidgets('announces the area as a live region', (tester) async {
      await _pumpAdd(tester, _repo());
      await typeInto(tester, _length, '3,5');
      await typeInto(tester, _width, '4');

      expectLiveRegion(tester, 'Luas: 14 m²');
    });

    testWidgets('shows decimals with a comma', (tester) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _length, '3,5');
      await typeInto(tester, _width, '4,2');

      expect(find.text('Luas: 14,7 m²'), findsOneWidget);
    });

    testWidgets('rounds the area to two decimals', (tester) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _length, '2,55');
      await typeInto(tester, _width, '3,33');

      expect(find.text('Luas: 8,49 m²'), findsOneWidget);
    });

    testWidgets('updates the area when a value changes', (tester) async {
      await _pumpAdd(tester, _repo());
      await typeInto(tester, _length, '3,5');
      await typeInto(tester, _width, '4');

      await typeInto(tester, _width, '2');

      expect(find.text('Luas: 7 m²'), findsOneWidget);
      expect(find.text('Luas: 14 m²'), findsNothing);
    });

    testWidgets('hides the area when a value is not valid', (tester) async {
      await _pumpAdd(tester, _repo());
      await typeInto(tester, _length, '3,5');
      await typeInto(tester, _width, '4');

      await typeInto(tester, _width, '25');

      expect(find.textContaining('Luas'), findsNothing);
    });

    testWidgets('hides the area when a value is cleared', (tester) async {
      await _pumpAdd(tester, _repo());
      await typeInto(tester, _length, '3,5');
      await typeInto(tester, _width, '4');

      await typeInto(tester, _length, '');

      expect(find.textContaining('Luas'), findsNothing);
    });
  });

  group('facilities', () {
    testWidgets('Tambah is at least 48 dp', (tester) async {
      await _pumpAdd(tester, _repo());

      expectTargetSize(tester, 'Tambah');
    });

    testWidgets('Tambah adds the typed tag as a chip', (tester) async {
      await _pumpAdd(tester, _repo(suggestions: const []));

      await _addTag(tester, 'ac');

      expect(find.text('ac'), findsAtLeastNWidgets(1));
      expect(_chosen('ac'), findsOneWidget);
    });

    testWidgets('the remove button of a chip is at least 48 dp', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      await _addTag(tester, 'ac');

      expectRemoveTargetSize(tester, 'ac');
    });

    testWidgets('adding a tag sends no request and leaves the form', (
      tester,
    ) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);

      await _addTag(tester, 'ac');

      expect(repo.created, isEmpty);
      expect(find.byType(RoomFormScreen), findsOneWidget);
    });

    testWidgets('keeps the order in which the tags were added', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _addTag(tester, 'wifi');
      await _addTag(tester, 'ac');
      await _addTag(tester, 'kasur');

      await _submitAdd(tester);

      expect(repo.created.single.input.facilities, ['wifi', 'ac', 'kasur']);
    });

    testWidgets('normalises a tag like the API does', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await _addTag(tester, '  AC   Dingin ');

      expect(_chosen('ac dingin'), findsOneWidget);
      await _submitAdd(tester);
      expect(repo.created.single.input.facilities, ['ac dingin']);
    });

    testWidgets('drops a duplicate after normalising', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _addTag(tester, 'ac');

      await _addTag(tester, '  AC ');

      expect(_chosen('ac'), findsOneWidget);
      expect(find.text(_tagLimit), findsNothing);
      expect(find.text(_tagTooLong), findsNothing);
      await _submitAdd(tester);
      expect(repo.created.single.input.facilities, ['ac']);
    });

    testWidgets('an empty input adds nothing', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await tapVisible(tester, buttonLabelled('Tambah'));
      await _addTag(tester, '    ');

      expect(find.bySemanticsLabel(RegExp('^Hapus fasilitas')), findsNothing);
      expect(find.text(_tagLimit), findsNothing);
      expect(find.text(_tagTooLong), findsNothing);
      await _submitAdd(tester);
      expect(repo.created.single.input.facilities, isEmpty);
    });

    testWidgets('a tag of 30 characters is added', (tester) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      final tag = 'a' * 30;

      await _addTag(tester, tag);

      expect(_chosen(tag), findsOneWidget);
      expect(find.text(_tagTooLong), findsNothing);
    });

    testWidgets('a tag is measured after normalising', (tester) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      final tag = 'a' * 30;

      await _addTag(tester, '   ${tag.toUpperCase()}   ');

      expect(_chosen(tag), findsOneWidget);
      expect(find.text(_tagTooLong), findsNothing);
    });

    testWidgets('a tag of 31 characters is refused with a message', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      final tag = 'a' * 31;

      await _addTag(tester, tag);

      expect(find.text(_tagTooLong), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Hapus fasilitas')), findsNothing);
    });

    testWidgets('a 16th tag is refused with a message', (tester) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      for (var i = 1; i <= 15; i++) {
        await _addTag(tester, 'fasilitas ${i.toString().padLeft(2, '0')}');
      }
      expect(find.text(_tagLimit), findsNothing);
      expect(_chosen('fasilitas 15'), findsOneWidget);

      await _addTag(tester, 'tambahan');

      expect(find.text(_tagLimit), findsOneWidget);
      expect(_chosen('tambahan'), findsNothing);
      expect(_chosen('fasilitas 15'), findsOneWidget);
    });

    testWidgets('all 15 tags are sent', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester);
      for (var i = 1; i <= 15; i++) {
        await _addTag(tester, 'f${i.toString().padLeft(2, '0')}');
      }

      await _submitAdd(tester);

      expect(repo.created.single.input.facilities, hasLength(15));
    });

    testWidgets('removing a chip drops the tag', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _addTag(tester, 'ac');
      await _addTag(tester, 'kasur');

      await _removeTag(tester, 'ac');

      expect(_chosen('ac'), findsNothing);
      expect(_chosen('kasur'), findsOneWidget);
      await _submitAdd(tester);
      expect(repo.created.single.input.facilities, ['kasur']);
    });

    testWidgets('a removed tag can be added again', (tester) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      await _addTag(tester, 'ac');
      await _removeTag(tester, 'ac');

      await _addTag(tester, 'ac');

      expect(_chosen('ac'), findsOneWidget);
    });

    testWidgets('removing a tag makes room for another one at the limit', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      for (var i = 1; i <= 15; i++) {
        await _addTag(tester, 'f${i.toString().padLeft(2, '0')}');
      }
      await _removeTag(tester, 'f01');

      await _addTag(tester, 'baru');

      expect(_chosen('baru'), findsOneWidget);
    });

    testWidgets('keeps the chips after a validation error', (tester) async {
      await _pumpAdd(tester, _repo(suggestions: const []));
      await _addTag(tester, 'ac');

      await _submitAdd(tester);

      expect(_chosen('ac'), findsOneWidget);
    });
  });

  group('facility suggestions', () {
    testWidgets('loads the suggestions of the property', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);

      expect(repo.calls, contains('suggestions:p1'));
    });

    testWidgets('shows the suggestions in a labelled group', (tester) async {
      await _pumpAdd(tester, _repo());

      expect(find.bySemanticsLabel(RegExp('Saran fasilitas')), findsWidgets);
      for (final tag in ['ac', 'kasur', 'kamar mandi dalam', 'wifi']) {
        expect(find.text(tag), findsOneWidget);
      }
    });

    testWidgets('tapping a suggestion chooses it', (tester) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await tapVisible(tester, find.text('wifi'));

      expect(_chosen('wifi'), findsOneWidget);
      await _submitAdd(tester);
      expect(repo.created.single.input.facilities, ['wifi']);
    });

    testWidgets('a chosen tag is no longer suggested', (tester) async {
      await _pumpAdd(tester, _repo());

      await tapVisible(tester, find.text('wifi'));

      expect(find.text('wifi'), findsOneWidget);
      expect(_chosen('wifi'), findsOneWidget);
      expect(find.text('ac'), findsOneWidget);
    });

    testWidgets('a removed tag is suggested again', (tester) async {
      await _pumpAdd(tester, _repo());
      await tapVisible(tester, find.text('wifi'));
      expect(find.text('wifi'), findsOneWidget);

      await _removeTag(tester, 'wifi');

      expect(find.text('wifi'), findsOneWidget);
      expect(_chosen('wifi'), findsNothing);
    });

    testWidgets('typing narrows the suggestions to matching tags', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _facility, 'ka');

      expect(find.text('kasur'), findsOneWidget);
      expect(find.text('kamar mandi dalam'), findsOneWidget);
      expect(find.text('ac'), findsNothing);
      expect(find.text('wifi'), findsNothing);
    });

    testWidgets('matching ignores case', (tester) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _facility, 'KAS');

      expect(find.text('kasur'), findsOneWidget);
      expect(find.text('kamar mandi dalam'), findsNothing);
    });

    testWidgets('matches inside the tag, not only at its start', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      await typeInto(tester, _facility, 'mandi');

      expect(find.text('kamar mandi dalam'), findsOneWidget);
      expect(find.text('kasur'), findsNothing);
    });

    testWidgets('suggestions are tappable targets of at least 48 dp', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('a failure to load suggestions is ignored silently', (
      tester,
    ) async {
      final repo = _repo()
        ..suggestionsScript.always = const ApiFailure.network();
      await _pumpAdd(tester, repo);
      await _fill(tester);

      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      await _addTag(tester, 'ac');
      await _submitAdd(tester);
      expect(repo.created.single.input.facilities, ['ac']);
    });
  });

  group('add submit', () {
    testWidgets('sends the trimmed number, rate and no optional values', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, number: '  10A  ', rate: '700000');

      await _submitAdd(tester);

      expect(repo.created.single.propertyId, 'p1');
      expect(
        repo.created.single.input,
        RoomInput(number: '10A', baseRate: 700000),
      );
      expect(repo.created.single.input.lengthM, isNull);
      expect(repo.created.single.input.widthM, isNull);
      expect(repo.created.single.input.facilities, isEmpty);
    });

    testWidgets('sends the dimensions as numbers, accepting a comma', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      await _fill(tester, length: '3,5', width: '4');

      await _submitAdd(tester);

      expect(repo.created.single.input.lengthM, 3.5);
      expect(repo.created.single.input.widthM, 4.0);
      expect(repo.created.single.input.lengthM, isA<double>());
      expect(repo.created.single.input.widthM, isA<double>());
    });

    testWidgets('sends the chosen facilities', (tester) async {
      final repo = _repo(suggestions: const []);
      await _pumpAdd(tester, repo);
      await _fill(tester, length: '3,5', width: '4');
      await _addTag(tester, 'ac');
      await _addTag(tester, 'kasur');

      await _submitAdd(tester);

      expect(
        repo.created.single.input,
        RoomInput(
          number: '10',
          baseRate: 700000,
          lengthM: 3.5,
          widthM: 4,
          facilities: ['ac', 'kasur'],
        ),
      );
    });

    testWidgets('shows a busy disabled button while the request is in flight', (
      tester,
    ) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await tapAndPump(tester, find.text('Simpan Kamar'));

      expectBusy(tester);
    });

    testWidgets('a second tap while in flight sends one request', (
      tester,
    ) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await tapAndPump(tester, find.text('Simpan Kamar'));
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.created, hasLength(1));
    });

    testWidgets('returns to the room list showing the new room', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpAdd(tester, repo);
      final loadsBefore = repo.listCalls;
      await _fill(tester, number: '10', rate: '700000');

      await _submitAdd(tester);

      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.byType(RoomListScreen), findsOneWidget);
      expect(find.byType(RoomFormScreen), findsNothing);
      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Rp700.000 / bulan'), findsOneWidget);
      expect(find.text('08'), findsOneWidget);
    });

    testWidgets('confirms the new room with a snack bar', (tester) async {
      await _pumpAdd(tester, _repo());
      await _fill(tester);

      await _submitAdd(tester);

      expect(snackBar('Kamar ditambahkan'), findsOneWidget);
    });

    testWidgets('adds the first room from the empty list', (tester) async {
      final repo = _repo(rooms: []);
      await pumpRoomApp(tester, repo);
      await tester.tap(find.text('Tambah Kamar'));
      await tester.pumpAndSettle();
      await _fill(tester);

      await _submitAdd(tester);

      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Tambah Kamar'), findsNothing);
    });
  });

  group('add failures', () {
    testWidgets('a taken number shows next to the number field', (
      tester,
    ) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
        );
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await _submitAdd(tester);

      expect(
        labeledFieldError(tester, _number),
        errorMessage('ROOM_NUMBER_TAKEN'),
      );
      expect(labeledFieldError(tester, _number), 'Nomor kamar sudah dipakai.');
      expect(labeledFieldError(tester, _rate), isNull);
      expect(find.byType(RoomFormScreen), findsOneWidget);
      expect(snackBar(errorMessage('ROOM_NUMBER_TAKEN')), findsNothing);
    });

    testWidgets('a rate error shows next to the rate field', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'baseRate'),
        );
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await _submitAdd(tester);

      expect(
        labeledFieldError(tester, _rate),
        errorMessage('VALIDATION_FAILED'),
      );
      expect(labeledFieldError(tester, _number), isNull);
    });

    for (final field in ['lengthM', 'widthM']) {
      testWidgets('a $field error shows in the dimension message place', (
        tester,
      ) async {
        final repo = _repo()
          ..createScript.queue.add(
            ApiFailure(code: 'VALIDATION_FAILED', field: field),
          );
        await _pumpAdd(tester, repo);
        await _fill(tester, length: '3,5', width: '4');

        await _submitAdd(tester);

        expect(find.text(errorMessage('VALIDATION_FAILED')), findsOneWidget);
        expect(labeledFieldError(tester, _number), isNull);
        expect(find.byType(RoomFormScreen), findsOneWidget);
      });
    }

    for (final field in ['facilities', 'facilities.0']) {
      testWidgets('a $field error shows in the facilities place', (
        tester,
      ) async {
        final repo = _repo(suggestions: const [])
          ..createScript.queue.add(
            ApiFailure(code: 'VALIDATION_FAILED', field: field),
          );
        await _pumpAdd(tester, repo);
        await _fill(tester);
        await _addTag(tester, 'ac');

        await _submitAdd(tester);

        expect(find.text(errorMessage('VALIDATION_FAILED')), findsOneWidget);
        expect(labeledFieldError(tester, _number), isNull);
        expect(_chosen('ac'), findsOneWidget);
      });
    }

    testWidgets('keeps the typed values after a field error', (tester) async {
      final repo = _repo(suggestions: const [])
        ..createScript.queue.add(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
        );
      await _pumpAdd(tester, repo);
      await _fill(tester, length: '3,5', width: '4');
      await _addTag(tester, 'ac');

      await _submitAdd(tester);

      expect(_text(tester, _number), '10');
      expect(_text(tester, _rate), '700000');
      expect(_text(tester, _length), '3,5');
      expect(_text(tester, _width), '4');
      expect(_chosen('ac'), findsOneWidget);
    });

    testWidgets('the button works again after a field error', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
        );
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _submitAdd(tester);
      expect(busyButton(), findsNothing);

      await typeInto(tester, _number, '11');
      await _submitAdd(tester);

      expect(repo.created, hasLength(2));
      expect(repo.created.last.input.number, '11');
      expect(currentPath(tester), '/properti/p1/kamar');
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('a field error goes away when the next submit starts', (
      tester,
    ) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
        );
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _submitAdd(tester);
      repo.createScript.gate = Completer<void>();

      await tapAndPump(tester, find.text('Simpan Kamar'));

      expect(labeledFieldError(tester, _number), isNull);
      expectBusy(tester);
    });

    final bannerCases = <String, ApiFailure>{
      'the plan limit': const ApiFailure(code: 'ROOM_LIMIT_REACHED'),
      'a read-only property': const ApiFailure(code: 'PROPERTY_READ_ONLY'),
      'a read-only room': const ApiFailure(code: 'ROOM_READ_ONLY'),
      'a network failure': const ApiFailure.network(),
      'a server failure': const ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
      'a field the form does not have': const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'propertyId',
      ),
    };

    for (final entry in bannerCases.entries) {
      testWidgets('shows ${entry.key} in a banner', (tester) async {
        final repo = _repo()..createScript.queue.add(entry.value);
        await _pumpAdd(tester, repo);
        await _fill(tester, length: '3,5', width: '4');

        await _submitAdd(tester);

        final message = errorMessage(entry.value.code);
        expect(find.text(message), findsOneWidget);
        expect(snackBar(message), findsNothing);
        expect(labeledFieldError(tester, _number), isNull);
        expect(labeledFieldError(tester, _rate), isNull);
        expect(find.byType(RoomFormScreen), findsOneWidget);
        expect(_text(tester, _number), '10');
        expect(_text(tester, _rate), '700000');
        expect(_text(tester, _length), '3,5');
        expect(_text(tester, _width), '4');
      });
    }

    testWidgets('announces the banner as a live region', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(const ApiFailure(code: 'ROOM_LIMIT_REACHED'));
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _submitAdd(tester);

      expectLiveRegion(tester, errorMessage('ROOM_LIMIT_REACHED'));
    });

    testWidgets('the banner stays on screen until the next submit', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _submitAdd(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('the banner goes away when the next submit starts', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _submitAdd(tester);
      repo.createScript.gate = Completer<void>();

      await tapAndPump(tester, find.text('Simpan Kamar'));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expectBusy(tester);
    });

    testWidgets('a successful retry after a banner completes the add', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fill(tester);
      await _submitAdd(tester);

      await _submitAdd(tester);

      expect(repo.created, hasLength(2));
      expect(repo.created.first.input, repo.created.last.input);
      expect(currentPath(tester), '/properti/p1/kamar');
      expect(snackBar('Kamar ditambahkan'), findsOneWidget);
    });

    testWidgets('a failure shows no success snack bar and adds nothing', (
      tester,
    ) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await _submitAdd(tester);

      expect(snackBar('Kamar ditambahkan'), findsNothing);
      expect(repo.rooms, hasLength(1));
    });
  });

  group('edit form', () {
    testWidgets('shows the title with the room number', (tester) async {
      await _pumpEdit(tester, _repo());

      expect(find.byType(RoomFormScreen), findsOneWidget);
      expect(appBarTitle('Ubah Kamar 08'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Simpan Kamar'), findsNothing);
    });

    testWidgets('loads the room by its id', (tester) async {
      final repo = _repo();
      await _pumpEdit(tester, repo);

      expect(repo.calls, contains('get:r1'));
    });

    testWidgets('pre-fills the number and the rate', (tester) async {
      await _pumpEdit(tester, _repo());

      expect(_text(tester, _number), '08');
      expect(_text(tester, _rate), '800000');
    });

    testWidgets('pre-fills the dimensions with a decimal comma', (
      tester,
    ) async {
      await _pumpEdit(tester, _repo());

      expect(_text(tester, _length), '3,5');
      expect(_text(tester, _width), '4');
      expect(find.text('Luas: 14 m²'), findsOneWidget);
    });

    testWidgets('writes whole and fractional dimensions without zeros', (
      tester,
    ) async {
      final repo = _repo(rooms: [_room(lengthM: 10.5, widthM: 2.0)]);
      await _pumpEdit(tester, repo);

      expect(_text(tester, _length), '10,5');
      expect(_text(tester, _width), '2');
    });

    testWidgets('pre-fills the facilities as chips', (tester) async {
      await _pumpEdit(tester, _repo());

      expect(_chosen('ac'), findsOneWidget);
      expect(_chosen('kasur'), findsOneWidget);
    });

    testWidgets('leaves the dimensions empty when the room has none', (
      tester,
    ) async {
      final repo = _repo(rooms: [_room(lengthM: null, widthM: null)]);
      await _pumpEdit(tester, repo);

      expect(_text(tester, _length), isEmpty);
      expect(_text(tester, _width), isEmpty);
      expect(find.textContaining('Luas'), findsNothing);
    });

    testWidgets('the rate helper adds that existing leases keep their rent', (
      tester,
    ) async {
      await _pumpEdit(tester, _repo());

      expect(find.textContaining(_rateHelper), findsOneWidget);
      expect(find.textContaining(_rateHelperEdit), findsOneWidget);
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _pumpEdit(tester, repo, settle: false);

      expectLoading(tester);
      expect(appBarTitle('Ubah Kamar'), findsOneWidget);
      expect(fieldLabeled(_number), findsNothing);
    });

    testWidgets('shows the failure with a retry when loading fails', (
      tester,
    ) async {
      final repo = _repo()
        ..getScript.always = const ApiFailure(code: 'ROOM_NOT_FOUND');
      await _pumpEdit(tester, repo);

      expect(find.byType(ErrorView), findsAtLeastNWidgets(1));
      expect(find.text(errorMessage('ROOM_NOT_FOUND')), findsOneWidget);
      expect(appBarTitle('Ubah Kamar'), findsOneWidget);
      expect(fieldLabeled(_number), findsNothing);
    });

    testWidgets('Coba lagi loads the form again', (tester) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _pumpEdit(tester, repo);
      repo.getScript.always = null;

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(_text(tester, _number), '08');
      expect(appBarTitle('Ubah Kamar 08'), findsOneWidget);
    });

    testWidgets('Kembali returns to the room detail', (tester) async {
      await _pumpEdit(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/kamar/r1');
      expect(find.byType(RoomDetailScreen), findsOneWidget);
    });
  });

  group('edit submit', () {
    testWidgets('validates like the add form', (tester) async {
      final repo = _repo();
      await _pumpEdit(tester, repo);
      await typeInto(tester, _number, '');
      await typeInto(tester, _rate, '');
      await typeInto(tester, _width, '');

      await _submitEdit(tester);

      expect(labeledFieldError(tester, _number), 'Nomor kamar wajib diisi.');
      expect(labeledFieldError(tester, _rate), 'Tarif sewa wajib diisi.');
      expect(find.text(_pairError), findsOneWidget);
      expect(repo.updated, isEmpty);
    });

    testWidgets('sends the unchanged values for the room id', (tester) async {
      final repo = _repo();
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(repo.updated.single.id, 'r1');
      expect(
        repo.updated.single.input,
        RoomInput(
          number: '08',
          baseRate: 800000,
          lengthM: 3.5,
          widthM: 4,
          facilities: ['ac', 'kasur'],
        ),
      );
    });

    testWidgets('sends the changed values', (tester) async {
      final repo = _repo();
      await _pumpEdit(tester, repo);
      await typeInto(tester, _number, ' 12 ');
      await typeInto(tester, _rate, '900000');
      await typeInto(tester, _length, '5,25');
      await typeInto(tester, _width, '3');
      await _removeTag(tester, 'ac');
      await _addTag(tester, 'wifi');

      await _submitEdit(tester);

      expect(
        repo.updated.single.input,
        RoomInput(
          number: '12',
          baseRate: 900000,
          lengthM: 5.25,
          widthM: 3,
          facilities: ['kasur', 'wifi'],
        ),
      );
    });

    testWidgets('clearing both dimensions sends none', (tester) async {
      final repo = _repo();
      await _pumpEdit(tester, repo);
      await typeInto(tester, _length, '');
      await typeInto(tester, _width, '');

      await _submitEdit(tester);

      expect(repo.updated.single.input.lengthM, isNull);
      expect(repo.updated.single.input.widthM, isNull);
    });

    testWidgets('shows a busy disabled button while in flight', (tester) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _pumpEdit(tester, repo);

      await tapAndPump(tester, find.text('Simpan Perubahan'));

      expectBusy(tester);
    });

    testWidgets('a second tap while in flight sends one request', (
      tester,
    ) async {
      final repo = _repo()..updateScript.gate = Completer<void>();
      await _pumpEdit(tester, repo);

      await tapAndPump(tester, find.text('Simpan Perubahan'));
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.updated, hasLength(1));
    });

    testWidgets('pops back to the detail showing the new values', (
      tester,
    ) async {
      final repo = _repo();
      await _pumpEdit(tester, repo);
      final loadsBefore = repo.getCalls;
      await typeInto(tester, _number, '12');
      await typeInto(tester, _rate, '900000');

      await _submitEdit(tester);

      expect(currentPath(tester), '/properti/p1/kamar/r1');
      expect(find.byType(RoomFormScreen), findsNothing);
      expect(find.byType(RoomDetailScreen), findsOneWidget);
      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(appBarTitle('Kamar 12'), findsOneWidget);
      expect(find.textContaining('Rp900.000'), findsOneWidget);
    });

    testWidgets('confirms the change with a snack bar', (tester) async {
      await _pumpEdit(tester, _repo());

      await _submitEdit(tester);

      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
    });

    testWidgets('a number conflict shows next to the number', (tester) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
        );
      await _pumpEdit(tester, repo);
      await typeInto(tester, _number, '09');

      await _submitEdit(tester);

      expect(
        labeledFieldError(tester, _number),
        errorMessage('ROOM_NUMBER_TAKEN'),
      );
      expect(_text(tester, _number), '09');
      expect(find.byType(RoomFormScreen), findsOneWidget);
    });

    testWidgets('a dimension error shows in the dimension message place', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'widthM'),
        );
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(find.text(errorMessage('VALIDATION_FAILED')), findsOneWidget);
    });

    for (final code in ['ROOM_READ_ONLY', 'PROPERTY_READ_ONLY']) {
      testWidgets('$code shows a banner', (tester) async {
        final repo = _repo()..updateScript.queue.add(ApiFailure(code: code));
        await _pumpEdit(tester, repo);

        await _submitEdit(tester);

        expect(find.text(errorMessage(code)), findsOneWidget);
        expect(snackBar(errorMessage(code)), findsNothing);
        expectLiveRegion(tester, errorMessage(code));
        expect(snackBar('Perubahan tersimpan'), findsNothing);
      });
    }

    testWidgets('a network failure keeps the form and its values', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await typeInto(tester, _number, '12');

      await _submitEdit(tester);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(_text(tester, _number), '12');
      expect(_chosen('ac'), findsOneWidget);
      expect(repo.rooms.single.number, '08');
    });

    testWidgets('a successful retry after a banner saves the change', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await _submitEdit(tester);

      await _submitEdit(tester);

      expect(repo.updated, hasLength(2));
      expect(currentPath(tester), '/properti/p1/kamar/r1');
      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
    });
  });

  group('structure', () {
    const labels = [_number, _rate, _length, _width, _facility];

    testWidgets('wraps every field in a LabeledField with its visible text', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      for (final label in labels) {
        expect(labeledField(label), findsOneWidget);
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(LabeledField), findsNWidgets(labels.length));
    });

    testWidgets(
      'marks the required fields (wajib) and leaves the others bare',
      (tester) async {
        await _pumpAdd(tester, _repo());

        expect(find.text('Nomor kamar (wajib)'), findsOneWidget);
        expect(find.text('Tarif dasar per bulan (wajib)'), findsOneWidget);
        expect(find.text('Panjang (m)'), findsOneWidget);
        expect(find.text('Lebar (m)'), findsOneWidget);
        expect(find.text('Tambah fasilitas'), findsOneWidget);
        expect(find.textContaining('(wajib)'), findsNWidgets(2));
      },
    );

    testWidgets('draws no label inside any field of the add form', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo());

      expectNoDecorationLabels(tester);
    });

    testWidgets('draws no label inside any field of the edit form', (
      tester,
    ) async {
      await _pumpEdit(tester, _repo());

      expect(find.byType(LabeledField), findsNWidgets(labels.length));
      expectNoDecorationLabels(tester);
    });

    testWidgets('puts each label above its field', (tester) async {
      await _pumpAdd(tester, _repo());

      for (final label in labels) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top));
      }
    });

    testWidgets('reads every field label once, on the field', (tester) async {
      await _pumpAdd(tester, _repo());

      for (final label in labels) {
        expectFieldNode(tester, label);
      }
    });

    testWidgets('keeps the number error on its field node', (tester) async {
      await _pumpAdd(tester, _repo());

      await _submitAdd(tester);

      expectFieldNode(tester, _number, error: 'Nomor kamar wajib diisi.');
    });

    testWidgets('tapping a label focuses its field', (tester) async {
      await _pumpAdd(tester, _repo());

      await tester.tap(find.text(_width));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_width),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('puts the add button in a pinned ActionFooter', (tester) async {
      await _pumpAdd(tester, _repo());

      expectPinnedFooter(tester, 'Simpan Kamar');
    });

    testWidgets('puts the edit button in a pinned ActionFooter', (
      tester,
    ) async {
      await _pumpEdit(tester, _repo());

      expectPinnedFooter(tester, 'Simpan Perubahan');
    });

    testWidgets('keeps the busy button inside the ActionFooter', (
      tester,
    ) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _pumpAdd(tester, repo);
      await _fill(tester);

      await tapAndPump(tester, find.text('Simpan Kamar'));

      expect(
        find.descendant(
          of: find.byType(ActionFooter),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expectBusy(tester);
    });

    testWidgets('keeps the footer on screen before and after scrolling', (
      tester,
    ) async {
      await _pumpAdd(tester, _repo(), largeText: true);
      final before = tester.getRect(find.byType(ActionFooter));
      expectFooterAtBottom(tester);
      expect(before.top, greaterThanOrEqualTo(0));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(ActionFooter)), before);
      expect(find.text('Simpan Kamar'), findsOneWidget);
    });

    testWidgets(
      'keeps the footer at the bottom on the edit form at large text',
      (tester) async {
        await _pumpEdit(tester, _repo(), largeText: true);

        expectFooterAtBottom(tester);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the empty add form': (tester, large) =>
          _pumpAdd(tester, _repo(), largeText: large),
      'the add form for a manager': (tester, large) =>
          _pumpAdd(tester, _repo(), role: UserRole.manager, largeText: large),
      'the add form without suggestions': (tester, large) => _pumpAdd(
        tester,
        _repo(suggestions: const [])
          ..suggestionsScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'the add form with the area': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await typeInto(tester, _length, '3,5');
        await typeInto(tester, _width, '4');
      },
      'the add form with chosen facilities': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await _tapInView(tester, find.text('wifi'));
        await _addTag(tester, 'kamar mandi dalam');
      },
      'the add form with filtered suggestions': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await typeInto(tester, _facility, 'ka');
      },
      'the add form with field errors': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await _submitAdd(tester);
      },
      'the add form with a dimension error': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await _fill(tester, length: '21', width: '4');
        await _submitAdd(tester);
      },
      'the add form with a dimension pair error': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await _fill(tester, length: '3,5');
        await _submitAdd(tester);
      },
      'the add form with a facility error': (tester, large) async {
        await _pumpAdd(tester, _repo(), largeText: large);
        await _addTag(tester, 'a' * 31);
      },
      'the add form at the facility limit': (tester, large) async {
        await _pumpAdd(tester, _repo(suggestions: const []), largeText: large);
        for (var i = 1; i <= 15; i++) {
          await _addTag(tester, 'f${i.toString().padLeft(2, '0')}');
        }
        await _addTag(tester, 'lebih');
      },
      'the add form with a server field error': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(code: 'ROOM_NUMBER_TAKEN', field: 'number'),
          );
        await _pumpAdd(tester, repo, largeText: large);
        await _fill(tester);
        await _submitAdd(tester);
      },
      'the add form with a server dimension error': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(code: 'VALIDATION_FAILED', field: 'lengthM'),
          );
        await _pumpAdd(tester, repo, largeText: large);
        await _fill(tester, length: '3,5', width: '4');
        await _submitAdd(tester);
      },
      'the add form with a banner': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(code: 'ROOM_LIMIT_REACHED'),
          );
        await _pumpAdd(tester, repo, largeText: large);
        await _fill(tester);
        await _submitAdd(tester);
      },
      'the add form in flight': (tester, large) async {
        final repo = _repo()..createScript.gate = Completer<void>();
        await _pumpAdd(tester, repo, largeText: large);
        await _fill(tester);
        await tester.ensureVisible(find.text('Simpan Kamar'));
        await tester.pump();
        await tapAndPump(tester, find.text('Simpan Kamar'));
      },
      'the edit form': (tester, large) =>
          _pumpEdit(tester, _repo(), largeText: large),
      'the edit form without size': (tester, large) => _pumpEdit(
        tester,
        _repo(rooms: [_room(lengthM: null, widthM: null)]),
        largeText: large,
      ),
      'the edit form in flight': (tester, large) async {
        final repo = _repo()..updateScript.gate = Completer<void>();
        await _pumpEdit(tester, repo, largeText: large);
        await tester.ensureVisible(find.text('Simpan Perubahan'));
        await tester.pump();
        await tapAndPump(tester, find.text('Simpan Perubahan'));
      },
      'the edit form with a banner': (tester, large) async {
        final repo = _repo()
          ..updateScript.queue.add(const ApiFailure(code: 'ROOM_READ_ONLY'));
        await _pumpEdit(tester, repo, largeText: large);
        await _submitEdit(tester);
      },
      'the edit form while loading': (tester, large) => _pumpEdit(
        tester,
        _repo()..getScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
      'the edit form after a loading failure': (tester, large) => _pumpEdit(
        tester,
        _repo()..getScript.always = const ApiFailure.network(),
        largeText: large,
      ),
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
