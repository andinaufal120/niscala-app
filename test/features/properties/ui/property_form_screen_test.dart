import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'property_ui_helpers.dart';

const _name = 'Nama properti (wajib)';
const _address = 'Alamat (wajib)';
const _bankName = 'Nama bank';
const _accountNumber = 'Nomor rekening';
const _holder = 'Nama pemilik rekening';
const _password = 'Kata sandi (wajib)';
const _bankGroup = 'Rekening untuk transfer sewa (opsional)';
const _bankHelper =
    'Ditampilkan kepada penyewa properti ini saat membayar dengan transfer. '
    'Tanpa rekening, penyewa hanya bisa membayar tunai. Isi ketiga kolom, atau '
    'kosongkan semuanya.';
const _bankRequired = 'Wajib diisi jika rekening diisi.';
const _reauthRequired = ApiFailure(code: 'REAUTHENTICATION_REQUIRED');

Property _melati({BankAccount? bank}) => makeProperty(
  id: 'p1',
  name: 'Kos Melati',
  address: 'Jl. Melati 1, Bandung',
  bankAccount: bank,
  managers: [managerSari],
);

Future<void> _pumpAdd(
  WidgetTester tester,
  FakePropertyRepository repo, {
  bool settle = true,
  bool largeText = false,
}) => pumpPropertyApp(
  tester,
  repo,
  path: '/properti/tambah',
  settle: settle,
  largeText: largeText,
);

Future<void> _pumpEdit(
  WidgetTester tester,
  FakePropertyRepository repo, {
  bool settle = true,
  bool largeText = false,
}) => pumpPropertyApp(
  tester,
  repo,
  path: '/properti/p1/ubah',
  settle: settle,
  largeText: largeText,
);

String _text(WidgetTester tester, String label) =>
    labeledTextField(tester, label).controller!.text;

Future<void> _submitAdd(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Properti'));

Future<void> _submitEdit(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Perubahan'));

Future<void> _fillRequired(
  WidgetTester tester, {
  String name = 'Kos Baru',
  String address = 'Jl. Baru 5',
}) async {
  await typeInto(tester, _name, name);
  await typeInto(tester, _address, address);
}

Future<void> _fillBank(WidgetTester tester) async {
  await typeInto(tester, _bankName, 'BCA');
  await typeInto(tester, _accountNumber, '1234567890');
  await typeInto(tester, _holder, 'Budi Santoso');
}

Finder _dialog() => find.byType(AlertDialog);

Finder _inDialog(Finder finder) =>
    find.descendant(of: _dialog(), matching: finder);

/// Edits the bank account of the property and submits until the dialog opens.
Future<void> _openReauthDialog(
  WidgetTester tester,
  FakePropertyRepository repo,
) async {
  repo.updateScript.queue.add(_reauthRequired);
  await _pumpEdit(tester, repo);
  await _fillBank(tester);
  await _submitEdit(tester);
}

void main() {
  group('add form', () {
    testWidgets('shows the title and the submit button', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(appBarTitle('Tambah Properti'), findsOneWidget);
      expect(find.text('Simpan Properti'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsNothing);
    });

    testWidgets('shows every field empty with its label', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      for (final label in [
        _name,
        _address,
        _bankName,
        _accountNumber,
        _holder,
      ]) {
        expect(fieldLabeled(label), findsOneWidget);
        expect(_text(tester, label), isEmpty);
      }
    });

    testWidgets('shows the example hints', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      expect(
        labeledTextField(tester, _name).decoration?.hintText,
        'Contoh: Kos Melati',
      );
      expect(
        labeledTextField(tester, _address).decoration?.hintText,
        'Jalan, nomor, kelurahan, kota',
      );
    });

    testWidgets('the address field has several lines', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      final lines = labeledTextField(tester, _address).maxLines;
      expect(lines == null || lines > 1, isTrue);
    });

    testWidgets('the account number field uses the number keyboard', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      expect(
        labeledTextField(tester, _accountNumber).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('groups the bank fields under an optional heading', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      expect(find.text(_bankGroup), findsOneWidget);
      expect(find.text(_bankHelper), findsOneWidget);
    });

    testWidgets('the screen title and group heading are headers', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.text(_bankGroup)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Kembali leaves the form without saving', (tester) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await typeInto(tester, _name, 'Kos Baru');

      await pressBack(tester);

      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(currentPath(tester), '/properti');
      expect(repo.created, isEmpty);
    });
  });

  group('add validation', () {
    testWidgets('an empty name shows its error and sends nothing', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await typeInto(tester, _address, 'Jl. Baru 5');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _name), 'Nama properti wajib diisi.');
      expect(labeledFieldError(tester, _address), isNull);
      expect(repo.calls, isNot(contains('create')));
    });

    testWidgets('an empty address shows its error and sends nothing', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await typeInto(tester, _name, 'Kos Baru');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _address), 'Alamat wajib diisi.');
      expect(labeledFieldError(tester, _name), isNull);
      expect(repo.calls, isNot(contains('create')));
    });

    testWidgets('an empty form shows both errors', (tester) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _name), 'Nama properti wajib diisi.');
      expect(labeledFieldError(tester, _address), 'Alamat wajib diisi.');
      expect(repo.created, isEmpty);
    });

    testWidgets('a name of only spaces counts as empty', (tester) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester, name: '   ');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _name), 'Nama properti wajib diisi.');
      expect(repo.created, isEmpty);
    });

    testWidgets('an address of only spaces counts as empty', (tester) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester, address: '  ');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _address), 'Alamat wajib diisi.');
      expect(repo.created, isEmpty);
    });

    testWidgets('a bank name alone asks for the other two fields', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await typeInto(tester, _bankName, 'BCA');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _bankName), isNull);
      expect(labeledFieldError(tester, _accountNumber), _bankRequired);
      expect(labeledFieldError(tester, _holder), _bankRequired);
      expect(repo.created, isEmpty);
    });

    testWidgets('an account number alone asks for the other two fields', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await typeInto(tester, _accountNumber, '1234567890');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _bankName), _bankRequired);
      expect(labeledFieldError(tester, _accountNumber), isNull);
      expect(labeledFieldError(tester, _holder), _bankRequired);
      expect(repo.created, isEmpty);
    });

    testWidgets('a holder name alone asks for the other two fields', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await typeInto(tester, _holder, 'Budi Santoso');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _bankName), _bankRequired);
      expect(labeledFieldError(tester, _accountNumber), _bankRequired);
      expect(labeledFieldError(tester, _holder), isNull);
      expect(repo.created, isEmpty);
    });

    testWidgets('two bank fields ask only for the missing one', (tester) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await typeInto(tester, _bankName, 'BCA');
      await typeInto(tester, _holder, 'Budi Santoso');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _bankName), isNull);
      expect(labeledFieldError(tester, _accountNumber), _bankRequired);
      expect(labeledFieldError(tester, _holder), isNull);
    });

    testWidgets('bank errors appear together with required field errors', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());
      await typeInto(tester, _bankName, 'BCA');

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _name), 'Nama properti wajib diisi.');
      expect(labeledFieldError(tester, _address), 'Alamat wajib diisi.');
      expect(labeledFieldError(tester, _accountNumber), _bankRequired);
    });

    testWidgets('fixing the errors lets the next submit through', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _submitAdd(tester);
      expect(repo.created, isEmpty);

      await _fillRequired(tester);
      await _submitAdd(tester);

      expect(repo.created, hasLength(1));
      expect(find.byType(PropertyFormScreen), findsNothing);
    });
  });

  group('add submit', () {
    testWidgets('sends the trimmed name and address without a bank account', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(
        tester,
        name: '  Kos Baru  ',
        address: ' Jl. Baru 5, Bandung ',
      );

      await _submitAdd(tester);

      expect(repo.created, [
        PropertyInput(name: 'Kos Baru', address: 'Jl. Baru 5, Bandung'),
      ]);
      expect(repo.created.single.bankAccount, isNull);
    });

    testWidgets('sends the trimmed bank account when all three are filled', (
      tester,
    ) async {
      final repo = FakePropertyRepository();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await typeInto(tester, _bankName, ' BCA ');
      await typeInto(tester, _accountNumber, ' 1234567890 ');
      await typeInto(tester, _holder, ' Budi Santoso ');

      await _submitAdd(tester);

      expect(repo.created.single.bankAccount, bankAccount);
    });

    testWidgets('shows a busy disabled button while the request is in flight', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..createScript.gate = Completer<void>();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);

      await tapAndPump(tester, find.text('Simpan Properti'));

      expectBusy(tester);
    });

    testWidgets('a second tap while in flight sends one request', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..createScript.gate = Completer<void>();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);

      await tapAndPump(tester, find.text('Simpan Properti'));
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.created, hasLength(1));
    });

    testWidgets('returns to the list showing the new property', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpAdd(tester, repo);
      final loadsBefore = repo.listCalls;
      await _fillRequired(tester);

      await _submitAdd(tester);

      expect(currentPath(tester), '/properti');
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.byType(PropertyFormScreen), findsNothing);
      expect(repo.listCalls, greaterThan(loadsBefore));
      expect(find.text('Kos Baru'), findsOneWidget);
      expect(find.text('Jl. Baru 5'), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
    });

    testWidgets('confirms the new property with a snack bar', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());
      await _fillRequired(tester);

      await _submitAdd(tester);

      expect(snackBar('Properti ditambahkan'), findsOneWidget);
    });

    testWidgets('adds the first property from the empty list', (tester) async {
      final repo = FakePropertyRepository();
      await pumpPropertyApp(tester, repo);
      await tester.tap(find.text('Tambah Properti Pertama'));
      await tester.pumpAndSettle();
      await _fillRequired(tester);

      await _submitAdd(tester);

      expect(currentPath(tester), '/properti');
      expect(find.text('Kos Baru'), findsOneWidget);
      expect(find.text('Tambah Properti Pertama'), findsNothing);
    });
  });

  group('add failures', () {
    final fieldCases = <({String field, String code, String label})>[
      (field: 'name', code: 'PROPERTY_NAME_TAKEN', label: _name),
      (field: 'address', code: 'VALIDATION_FAILED', label: _address),
      (
        field: 'bankAccount.bankName',
        code: 'VALIDATION_FAILED',
        label: _bankName,
      ),
      (
        field: 'bankAccount.accountNumber',
        code: 'VALIDATION_FAILED',
        label: _accountNumber,
      ),
      (
        field: 'bankAccount.accountHolderName',
        code: 'VALIDATION_FAILED',
        label: _holder,
      ),
    ];

    for (final c in fieldCases) {
      testWidgets('shows a ${c.field} error next to its field', (tester) async {
        final repo = FakePropertyRepository()
          ..createScript.queue.add(ApiFailure(code: c.code, field: c.field));
        await _pumpAdd(tester, repo);
        await _fillRequired(tester);
        await _fillBank(tester);

        await _submitAdd(tester);

        expect(labeledFieldError(tester, c.label), errorMessage(c.code));
        expect(find.byType(PropertyFormScreen), findsOneWidget);
        expect(snackBar(errorMessage(c.code)), findsNothing);
      });
    }

    testWidgets('keeps the typed values after a field error', (tester) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
        );
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await _fillBank(tester);

      await _submitAdd(tester);

      expect(_text(tester, _name), 'Kos Baru');
      expect(_text(tester, _address), 'Jl. Baru 5');
      expect(_text(tester, _bankName), 'BCA');
      expect(_text(tester, _accountNumber), '1234567890');
      expect(_text(tester, _holder), 'Budi Santoso');
    });

    testWidgets('leaves the other fields without an error', (tester) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
        );
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);

      await _submitAdd(tester);

      expect(labeledFieldError(tester, _address), isNull);
      expect(labeledFieldError(tester, _bankName), isNull);
    });

    testWidgets('the button works again after a field error', (tester) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
        );
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await _submitAdd(tester);
      expect(busyButton(), findsNothing);

      await typeInto(tester, _name, 'Kos Lain');
      await _submitAdd(tester);

      expect(repo.created, hasLength(2));
      expect(repo.created.last.name, 'Kos Lain');
      expect(currentPath(tester), '/properti');
      expect(find.text('Kos Lain'), findsOneWidget);
    });

    final bannerCases = <String, ApiFailure>{
      'the plan limit': const ApiFailure(code: 'PROPERTY_LIMIT_REACHED'),
      'a read-only property': const ApiFailure(code: 'PROPERTY_READ_ONLY'),
      'a network failure': const ApiFailure.network(),
      'a server failure': const ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
      'a field the form does not have': const ApiFailure(
        code: 'VALIDATION_FAILED',
        field: 'managers',
      ),
    };

    for (final entry in bannerCases.entries) {
      testWidgets('shows ${entry.key} in a banner', (tester) async {
        final repo = FakePropertyRepository()
          ..createScript.queue.add(entry.value);
        await _pumpAdd(tester, repo);
        await _fillRequired(tester);

        await _submitAdd(tester);

        final message = errorMessage(entry.value.code);
        expect(find.text(message), findsOneWidget);
        expect(snackBar(message), findsNothing);
        expect(labeledFieldError(tester, _name), isNull);
        expect(labeledFieldError(tester, _address), isNull);
        expect(find.byType(PropertyFormScreen), findsOneWidget);
        expect(_text(tester, _name), 'Kos Baru');
        expect(_text(tester, _address), 'Jl. Baru 5');
      });
    }

    testWidgets('announces the banner as a live region', (tester) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(
          const ApiFailure(code: 'PROPERTY_LIMIT_REACHED'),
        );
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await _submitAdd(tester);

      expectLiveRegion(tester, errorMessage('PROPERTY_LIMIT_REACHED'));
    });

    testWidgets('the banner stays on screen until the next submit', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await _submitAdd(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('the banner goes away when the next submit starts', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await _submitAdd(tester);
      repo.createScript.gate = Completer<void>();

      await tapAndPump(tester, find.text('Simpan Properti'));

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expectBusy(tester);
    });

    testWidgets('a successful retry after a banner completes the add', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);
      await _submitAdd(tester);

      await _submitAdd(tester);

      expect(repo.created, hasLength(2));
      expect(repo.created.first, repo.created.last);
      expect(currentPath(tester), '/properti');
      expect(snackBar('Properti ditambahkan'), findsOneWidget);
    });

    testWidgets('a failure shows no success snack bar', (tester) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(const ApiFailure.network());
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);

      await _submitAdd(tester);

      expect(snackBar('Properti ditambahkan'), findsNothing);
      expect(repo.properties, isEmpty);
    });
  });

  group('edit form', () {
    testWidgets('shows the title and the submit button', (tester) async {
      await _pumpEdit(tester, FakePropertyRepository(properties: [_melati()]));

      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(appBarTitle('Ubah Properti'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Simpan Properti'), findsNothing);
    });

    testWidgets('loads the property by its id', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpEdit(tester, repo);

      expect(repo.calls, contains('get:p1'));
    });

    testWidgets('pre-fills the name and address', (tester) async {
      await _pumpEdit(tester, FakePropertyRepository(properties: [_melati()]));

      expect(_text(tester, _name), 'Kos Melati');
      expect(_text(tester, _address), 'Jl. Melati 1, Bandung');
    });

    testWidgets('pre-fills the bank account', (tester) async {
      await _pumpEdit(
        tester,
        FakePropertyRepository(properties: [_melati(bank: bankAccount)]),
      );

      expect(_text(tester, _bankName), 'BCA');
      expect(_text(tester, _accountNumber), '1234567890');
      expect(_text(tester, _holder), 'Budi Santoso');
    });

    testWidgets('leaves the bank fields empty when there is no account', (
      tester,
    ) async {
      await _pumpEdit(tester, FakePropertyRepository(properties: [_melati()]));

      expect(_text(tester, _bankName), isEmpty);
      expect(_text(tester, _accountNumber), isEmpty);
      expect(_text(tester, _holder), isEmpty);
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.gate = Completer<void>();
      await _pumpEdit(tester, repo, settle: false);

      expectLoading(tester);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('shows the failure with a retry when loading fails', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.always = const ApiFailure(code: 'PROPERTY_NOT_FOUND');
      await _pumpEdit(tester, repo);

      expect(find.byType(ErrorView), findsAtLeastNWidgets(1));
      expect(find.text(errorMessage('PROPERTY_NOT_FOUND')), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('Coba lagi loads the form again', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.always = const ApiFailure.network();
      await _pumpEdit(tester, repo);
      repo.getScript.always = null;

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(_text(tester, _name), 'Kos Melati');
    });
  });

  group('edit submit', () {
    testWidgets('validates like the add form', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, '');
      await typeInto(tester, _address, '');
      await typeInto(tester, _bankName, 'BCA');

      await _submitEdit(tester);

      expect(labeledFieldError(tester, _name), 'Nama properti wajib diisi.');
      expect(labeledFieldError(tester, _address), 'Alamat wajib diisi.');
      expect(labeledFieldError(tester, _accountNumber), _bankRequired);
      expect(labeledFieldError(tester, _holder), _bankRequired);
      expect(repo.updated, isEmpty);
    });

    testWidgets('sends the changed values for the property id', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, ' Kos Melati Baru ');

      await _submitEdit(tester);

      expect(repo.updated.single.id, 'p1');
      expect(
        repo.updated.single.input,
        PropertyInput(
          name: 'Kos Melati Baru',
          address: 'Jl. Melati 1, Bandung',
        ),
      );
    });

    testWidgets('sends the existing bank account unchanged', (tester) async {
      final repo = FakePropertyRepository(
        properties: [_melati(bank: bankAccount)],
      );
      await _pumpEdit(tester, repo);
      await typeInto(tester, _address, 'Jl. Baru 9');

      await _submitEdit(tester);

      expect(repo.updated.single.input.bankAccount, bankAccount);
      expect(repo.updated.single.input.address, 'Jl. Baru 9');
    });

    testWidgets('clearing all bank fields sends no bank account', (
      tester,
    ) async {
      final repo = FakePropertyRepository(
        properties: [_melati(bank: bankAccount)],
      );
      await _pumpEdit(tester, repo);
      await typeInto(tester, _bankName, '');
      await typeInto(tester, _accountNumber, '');
      await typeInto(tester, _holder, '');

      await _submitEdit(tester);

      expect(repo.updated.single.input.bankAccount, isNull);
    });

    testWidgets('shows a busy disabled button while in flight', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..updateScript.gate = Completer<void>();
      await _pumpEdit(tester, repo);

      await tapAndPump(tester, find.text('Simpan Perubahan'));

      expectBusy(tester);
    });

    testWidgets('a second tap while in flight sends one request', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..updateScript.gate = Completer<void>();
      await _pumpEdit(tester, repo);

      await tapAndPump(tester, find.text('Simpan Perubahan'));
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(repo.updated, hasLength(1));
    });

    testWidgets('pops back to the detail showing the new values', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Kos Melati Baru');
      await typeInto(tester, _address, 'Jl. Baru 9');

      await _submitEdit(tester);

      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyFormScreen), findsNothing);
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(find.text('Kos Melati Baru'), findsOneWidget);
      expect(find.text('Jl. Baru 9'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
    });

    testWidgets('confirms the change with a snack bar', (tester) async {
      await _pumpEdit(tester, FakePropertyRepository(properties: [_melati()]));

      await _submitEdit(tester);

      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
    });

    testWidgets('the detail shows a newly added bank account', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpEdit(tester, repo);
      await _fillBank(tester);

      await _submitEdit(tester);

      expect(find.text('BCA · 1234567890'), findsOneWidget);
      expect(find.text('a.n. Budi Santoso'), findsOneWidget);
    });

    testWidgets('editing only the name never opens the password dialog', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Kos Melati Baru');

      await _submitEdit(tester);

      expect(_dialog(), findsNothing);
      expect(repo.reauthentications, isEmpty);
      expect(repo.updated, hasLength(1));
    });

    testWidgets('a name conflict shows next to the name', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..updateScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
        );
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Kos Mawar');

      await _submitEdit(tester);

      expect(
        labeledFieldError(tester, _name),
        errorMessage('PROPERTY_NAME_TAKEN'),
      );
      expect(_text(tester, _name), 'Kos Mawar');
      expect(find.byType(PropertyFormScreen), findsOneWidget);
    });

    testWidgets('a read-only property shows a banner', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..updateScript.queue.add(const ApiFailure(code: 'PROPERTY_READ_ONLY'));
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(find.text(errorMessage('PROPERTY_READ_ONLY')), findsOneWidget);
      expect(snackBar(errorMessage('PROPERTY_READ_ONLY')), findsNothing);
      expectLiveRegion(tester, errorMessage('PROPERTY_READ_ONLY'));
      expect(snackBar('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('a network failure keeps the form and its values', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await typeInto(tester, _name, 'Kos Melati Baru');

      await _submitEdit(tester);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(_text(tester, _name), 'Kos Melati Baru');
      expect(repo.properties.single.name, 'Kos Melati');
    });
  });

  group('re-authentication', () {
    testWidgets('opens the password dialog when the API asks for it', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);

      expect(_dialog(), findsOneWidget);
      expect(find.text('Konfirmasi kata sandi'), findsOneWidget);
      expect(
        find.text('Masukkan kata sandi Anda untuk melanjutkan.'),
        findsOneWidget,
      );
      expect(fieldLabeled(_password), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(_inDialog(find.text('Lanjutkan')), findsOneWidget);
      expect(repo.reauthentications, isEmpty);
    });

    testWidgets('does not show the required code as a form banner', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);

      expect(
        find.text(errorMessage('REAUTHENTICATION_REQUIRED')),
        findsOneWidget,
      );
    });

    testWidgets('the password field supports paste and autofill', (
      tester,
    ) async {
      await _openReauthDialog(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      final input = labeledTextField(tester, _password);
      expect(input.obscureText, isTrue);
      expect(input.enableInteractiveSelection, isNot(false));
      expect(input.autofillHints, contains(AutofillHints.password));
      expect(
        find.ancestor(
          of: fieldLabeled(_password),
          matching: find.byType(AutofillGroup),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the checkbox shows and hides the password', (tester) async {
      await _openReauthDialog(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );
      expectShowPasswordCheckbox(tester, checked: false);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pump();

      expect(labeledTextField(tester, _password).obscureText, isFalse);
      expectShowPasswordCheckbox(tester, checked: true);

      await tester.tap(find.text('Tampilkan kata sandi'));
      await tester.pump();

      expect(labeledTextField(tester, _password).obscureText, isTrue);
    });

    testWidgets('Lanjutkan re-authenticates and retries the same update', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);
      await typeInto(tester, _password, 'rahasia panjang');

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(repo.reauthentications, ['rahasia panjang']);
      expect(repo.updated, hasLength(2));
      expect(repo.updated.last.id, repo.updated.first.id);
      expect(repo.updated.last.input, repo.updated.first.input);
      expect(repo.updated.last.input.bankAccount, bankAccount);
      expect(repo.calls.where((c) => c != 'list' && !c.startsWith('get:')), [
        'update:p1',
        'reauthenticate',
        'update:p1',
      ]);
    });

    testWidgets('a successful retry completes like a normal edit', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);
      await typeInto(tester, _password, 'rahasia panjang');

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
      expect(find.text('BCA · 1234567890'), findsOneWidget);
    });

    testWidgets('an empty password shows an error and sends nothing', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(labeledFieldError(tester, _password), 'Kata sandi wajib diisi.');
      expect(_dialog(), findsOneWidget);
      expect(repo.reauthentications, isEmpty);
      expect(repo.updated, hasLength(1));
    });

    final failures = <String, String>{
      'a wrong password': 'PASSWORD_INCORRECT',
      'too many attempts': 'TOO_MANY_LOGIN_ATTEMPTS',
    };

    for (final entry in failures.entries) {
      testWidgets('${entry.key} keeps the dialog open with the message', (
        tester,
      ) async {
        final repo = FakePropertyRepository(properties: [_melati()])
          ..reauthScript.always = ApiFailure(code: entry.value);
        await _openReauthDialog(tester, repo);
        await typeInto(tester, _password, 'salah');

        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();

        expect(_dialog(), findsOneWidget);
        expect(_inDialog(find.text(errorMessage(entry.value))), findsOneWidget);
        expect(repo.updated, hasLength(1));
        expect(snackBar('Perubahan tersimpan'), findsNothing);
      });
    }

    testWidgets('the password can be corrected after a failure', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..reauthScript.queue.add(const ApiFailure(code: 'PASSWORD_INCORRECT'));
      await _openReauthDialog(tester, repo);
      await typeInto(tester, _password, 'salah');
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      await typeInto(tester, _password, 'benar sekali');
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(repo.reauthentications, ['salah', 'benar sekali']);
      expect(repo.updated, hasLength(2));
      expect(_dialog(), findsNothing);
      expect(snackBar('Perubahan tersimpan'), findsOneWidget);
    });

    testWidgets(
      'a network failure of the re-authentication stays in the dialog',
      (tester) async {
        final repo = FakePropertyRepository(properties: [_melati()])
          ..reauthScript.always = const ApiFailure.network();
        await _openReauthDialog(tester, repo);
        await typeInto(tester, _password, 'rahasia panjang');

        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();

        expect(
          _inDialog(find.text(errorMessage('NETWORK_ERROR'))),
          findsOneWidget,
        );
      },
    );

    testWidgets('Batal closes the dialog and keeps the form and its values', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(_text(tester, _bankName), 'BCA');
      expect(_text(tester, _accountNumber), '1234567890');
      expect(_text(tester, _holder), 'Budi Santoso');
      expect(repo.reauthentications, isEmpty);
      expect(repo.updated, hasLength(1));
      expect(repo.properties.single.bankAccount, isNull);
      expect(snackBar('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('the form can be submitted again after Batal', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      repo.updateScript.queue.add(_reauthRequired);

      await _submitEdit(tester);

      expect(_dialog(), findsOneWidget);
      expect(repo.updated, hasLength(2));
    });

    testWidgets('a second failure with another code closes the dialog', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);
      repo.updateScript.queue.add(const ApiFailure(code: 'PROPERTY_READ_ONLY'));
      await typeInto(tester, _password, 'rahasia panjang');

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(find.text(errorMessage('PROPERTY_READ_ONLY')), findsOneWidget);
      expect(repo.updated, hasLength(2));
      expect(find.byType(PropertyFormScreen), findsOneWidget);
    });

    testWidgets('a second failure on a field shows next to that field', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()]);
      await _openReauthDialog(tester, repo);
      repo.updateScript.queue.add(
        const ApiFailure(
          code: 'VALIDATION_FAILED',
          field: 'bankAccount.accountNumber',
        ),
      );
      await typeInto(tester, _password, 'rahasia panjang');

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(
        labeledFieldError(tester, _accountNumber),
        errorMessage('VALIDATION_FAILED'),
      );
    });
  });

  group('structure', () {
    const labels = [_name, _address, _bankName, _accountNumber, _holder];

    testWidgets('wraps every field in a LabeledField with its visible text', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      for (final label in labels) {
        expect(labeledField(label), findsOneWidget);
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(LabeledField), findsNWidgets(labels.length));
    });

    testWidgets(
      'marks required fields (wajib) and leaves the bank fields bare',
      (tester) async {
        await _pumpAdd(tester, FakePropertyRepository());

        expect(find.text('Nama properti (wajib)'), findsOneWidget);
        expect(find.text('Alamat (wajib)'), findsOneWidget);
        expect(find.text('Nama bank'), findsOneWidget);
        expect(find.text('Nomor rekening'), findsOneWidget);
        expect(find.text('Nama pemilik rekening'), findsOneWidget);
        expect(find.textContaining('(wajib)'), findsNWidgets(2));
      },
    );

    testWidgets('draws no label inside any field', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      expectNoDecorationLabels(tester);
    });

    testWidgets('draws no label inside any field of the edit form', (
      tester,
    ) async {
      await _pumpEdit(
        tester,
        FakePropertyRepository(properties: [_melati(bank: bankAccount)]),
      );

      expect(find.byType(LabeledField), findsNWidgets(labels.length));
      expectNoDecorationLabels(tester);
    });

    testWidgets('puts each label above its field', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      for (final label in labels) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top));
      }
    });

    testWidgets('reads every field label once, on the field', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      for (final label in labels) {
        expectFieldNode(tester, label);
      }
    });

    testWidgets('keeps the required field errors on their field nodes', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      await _submitAdd(tester);

      expectFieldNode(tester, _name, error: 'Nama properti wajib diisi.');
      expectFieldNode(tester, _address, error: 'Alamat wajib diisi.');
    });

    testWidgets('keeps the bank errors on their field nodes', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());
      await _fillRequired(tester);
      await typeInto(tester, _bankName, 'BCA');

      await _submitAdd(tester);

      expectFieldNode(tester, _accountNumber, error: _bankRequired);
      expectFieldNode(tester, _holder, error: _bankRequired);
    });

    testWidgets('keeps a server field error on its field node', (tester) async {
      final repo = FakePropertyRepository()
        ..createScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
        );
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);

      await _submitAdd(tester);

      expectFieldNode(
        tester,
        _name,
        error: errorMessage('PROPERTY_NAME_TAKEN'),
      );
    });

    testWidgets('tapping a label focuses its field', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      await tester.tap(find.text(_address));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_address),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('the bank group heading stays a header above its fields', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      final heading = tester.getRect(find.text(_bankGroup));
      expect(
        heading.bottom,
        lessThanOrEqualTo(tester.getRect(find.text(_bankName)).top),
      );
      expect(
        heading.top,
        greaterThanOrEqualTo(tester.getRect(find.text(_address)).bottom),
      );
    });

    testWidgets('the bank group is not inside any card', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      for (final text in [_bankGroup, _bankHelper]) {
        expect(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(SectionCard),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(of: find.text(text), matching: find.byType(Card)),
          findsNothing,
        );
      }
    });

    testWidgets('the bank fields are not inside any card', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      for (final label in [_bankName, _accountNumber, _holder]) {
        expect(
          find.ancestor(
            of: fieldLabeled(label),
            matching: find.byType(SectionCard),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(of: fieldLabeled(label), matching: find.byType(Card)),
          findsNothing,
        );
      }
    });

    testWidgets('puts the add button in an ActionFooter', (tester) async {
      await _pumpAdd(tester, FakePropertyRepository());

      final footer = find.byType(ActionFooter);
      expect(footer, findsOneWidget);
      expect(
        find.descendant(of: footer, matching: find.text('Simpan Properti')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: footer, matching: anyButton()),
        findsOneWidget,
      );
    });

    testWidgets('puts the edit button in an ActionFooter', (tester) async {
      await _pumpEdit(tester, FakePropertyRepository(properties: [_melati()]));

      final footer = find.byType(ActionFooter);
      expect(footer, findsOneWidget);
      expect(
        find.descendant(of: footer, matching: find.text('Simpan Perubahan')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the busy button inside the ActionFooter', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..createScript.gate = Completer<void>();
      await _pumpAdd(tester, repo);
      await _fillRequired(tester);

      await tapAndPump(tester, find.text('Simpan Properti'));

      expect(
        find.descendant(
          of: find.byType(ActionFooter),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expectBusy(tester);
    });

    testWidgets('the footer is not part of the scrolling content', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository());

      expect(
        find.ancestor(
          of: find.byType(ActionFooter),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });

    testWidgets('keeps the footer on screen before and after scrolling', (
      tester,
    ) async {
      await _pumpAdd(tester, FakePropertyRepository(), largeText: true);
      final barTop = tester.getRect(find.byType(NavigationBar)).top;
      final before = tester.getRect(find.byType(ActionFooter));
      expect(before.bottom, closeTo(barTop, 0.5));
      expect(before.top, greaterThanOrEqualTo(0));
      expect(
        tester.getRect(find.text('Simpan Properti')).bottom,
        lessThanOrEqualTo(barTop),
      );

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(ActionFooter)), before);
      expect(find.text('Simpan Properti'), findsOneWidget);
    });

    testWidgets('keeps the footer on screen on the edit form at large text', (
      tester,
    ) async {
      await _pumpEdit(
        tester,
        FakePropertyRepository(properties: [_melati(bank: bankAccount)]),
        largeText: true,
      );
      final barTop = tester.getRect(find.byType(NavigationBar)).top;

      final footer = tester.getRect(find.byType(ActionFooter));
      expect(footer.bottom, closeTo(barTop, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows no footer while the property is loading', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.gate = Completer<void>();
      await _pumpEdit(tester, repo, settle: false);

      expect(find.byType(ActionFooter), findsNothing);
    });

    testWidgets('shows no footer when loading the property fails', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.always = const ApiFailure.network();
      await _pumpEdit(tester, repo);

      expect(find.byType(ActionFooter), findsNothing);
      expect(find.text('Simpan Perubahan'), findsNothing);
    });

    testWidgets('labels the dialog password field through a LabeledField', (
      tester,
    ) async {
      await _openReauthDialog(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      expect(
        find.descendant(of: _dialog(), matching: labeledField(_password)),
        findsOneWidget,
      );
      expect(_inDialog(find.text(_password)), findsOneWidget);
      expectNoDecorationLabels(tester);
    });

    testWidgets('keeps the dialog password error on the field node', (
      tester,
    ) async {
      await _openReauthDialog(
        tester,
        FakePropertyRepository(properties: [_melati()]),
      );

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expectFieldNode(tester, _password, error: 'Kata sandi wajib diisi.');
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the empty add form': (tester, large) =>
          _pumpAdd(tester, FakePropertyRepository(), largeText: large),
      'the add form with field errors': (tester, large) async {
        await _pumpAdd(tester, FakePropertyRepository(), largeText: large);
        await typeInto(tester, _bankName, 'BCA');
        await _submitAdd(tester);
      },
      'the add form with a server field error': (tester, large) async {
        final repo = FakePropertyRepository()
          ..createScript.queue.add(
            const ApiFailure(code: 'PROPERTY_NAME_TAKEN', field: 'name'),
          );
        await _pumpAdd(tester, repo, largeText: large);
        await _fillRequired(tester);
        await _submitAdd(tester);
      },
      'the add form with a banner': (tester, large) async {
        final repo = FakePropertyRepository()
          ..createScript.queue.add(
            const ApiFailure(code: 'PROPERTY_LIMIT_REACHED'),
          );
        await _pumpAdd(tester, repo, largeText: large);
        await _fillRequired(tester);
        await _submitAdd(tester);
      },
      'the add form in flight': (tester, large) async {
        final repo = FakePropertyRepository()
          ..createScript.gate = Completer<void>();
        await _pumpAdd(tester, repo, largeText: large);
        await _fillRequired(tester);
        await tapAndPump(tester, find.text('Simpan Properti'));
      },
      'the edit form': (tester, large) => _pumpEdit(
        tester,
        FakePropertyRepository(properties: [_melati(bank: bankAccount)]),
        largeText: large,
      ),
      'the edit form while loading': (tester, large) => _pumpEdit(
        tester,
        FakePropertyRepository(properties: [_melati()])
          ..getScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
      'the edit form after a loading failure': (tester, large) => _pumpEdit(
        tester,
        FakePropertyRepository(properties: [_melati()])
          ..getScript.always = const ApiFailure.network(),
        largeText: large,
      ),
      'the password dialog': (tester, large) async {
        final repo = FakePropertyRepository(properties: [_melati()]);
        repo.updateScript.queue.add(_reauthRequired);
        await _pumpEdit(tester, repo, largeText: large);
        await _fillBank(tester);
        await _submitEdit(tester);
      },
      'the password dialog with an empty password': (tester, large) async {
        final repo = FakePropertyRepository(properties: [_melati()]);
        repo.updateScript.queue.add(_reauthRequired);
        await _pumpEdit(tester, repo, largeText: large);
        await _fillBank(tester);
        await _submitEdit(tester);
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
      },
      'the password dialog with a failure': (tester, large) async {
        final repo = FakePropertyRepository(properties: [_melati()])
          ..updateScript.queue.add(_reauthRequired)
          ..reauthScript.always = const ApiFailure(code: 'PASSWORD_INCORRECT');
        await _pumpEdit(tester, repo, largeText: large);
        await _fillBank(tester);
        await _submitEdit(tester);
        await typeInto(tester, _password, 'salah');
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
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
