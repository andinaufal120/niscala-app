import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/managers/ui/manager_detail_screen.dart';
import 'package:niscala/features/managers/ui/manager_form_screen.dart';
import 'package:niscala/features/managers/ui/manager_invitation_share_screen.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
import 'manager_ui_helpers.dart';

const _name = 'Nama lengkap (wajib)';
const _nickname = 'Nama panggilan (opsional)';
const _phone = 'Nomor telepon (WhatsApp) (wajib)';
const _group = 'Properti yang ditugaskan (wajib)';
const _save = 'Simpan';

const _invalidPhone = 'Nomor telepon tidak valid. Contoh: 0812-5520-4471.';
const _noProperty = 'Pilih minimal satu properti.';
const _nameLocked = 'Nama Pengelola yang sudah aktif tidak dapat diubah.';

FakeManagerRepository _repo() =>
    FakeManagerRepository(managers: sampleManagers());

Future<void> _open(
  WidgetTester tester,
  FakeManagerRepository repo, {
  FakePropertyRepository? properties,
  String propertyId = 'p1',
  bool settle = true,
  bool largeText = false,
}) => pumpManagerApp(
  tester,
  repo,
  properties: properties,
  path: '/properti/$propertyId/pengelola/tambah',
  settle: settle,
  largeText: largeText,
);

Future<void> _openEdit(
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
  path: '/properti/p1/pengelola/$managerId/ubah',
  settle: settle,
  largeText: largeText,
);

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text(_save));

Future<void> _tapFirstSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text(_save));
  await tester.pump();
  await tapAndPump(tester, find.text(_save));
}

/// Types a name and a phone number, and optionally a nickname.
Future<void> _fill(
  WidgetTester tester, {
  String name = 'Rina Putri',
  String phone = '0812-5520-4471',
  String? nickname,
}) async {
  await typeInto(tester, _name, name);
  await typeInto(tester, _phone, phone);
  if (nickname != null) await typeInto(tester, _nickname, nickname);
}

Future<void> _toggle(WidgetTester tester, String property) =>
    tapVisible(tester, propertyTile(property));

String _text(WidgetTester tester, String label) =>
    labeledTextField(tester, label).controller!.text;

void _expectErrors(WidgetTester tester, Map<String, String> errors) {
  for (final label in [_name, _nickname, _phone]) {
    expect(labeledFieldError(tester, label), errors[label], reason: label);
  }
}

void _expectHeader(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(find.text(text)), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

bool _nameIsLocked(WidgetTester tester) {
  final field = labeledTextField(tester, _name);
  return field.enabled == false || field.readOnly;
}

Uri _currentUri(WidgetTester tester) =>
    containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri;

void main() {
  group('add form layout', () {
    testWidgets('shows the title and the submit button', (tester) async {
      await _open(tester, _repo());

      expect(find.byType(ManagerFormScreen), findsOneWidget);
      expect(appBarTitle('Tambah Pengelola'), findsOneWidget);
      expect(find.text(_save), findsOneWidget);
    });

    testWidgets('is shown for the property of the path', (tester) async {
      await _open(tester, _repo());

      final form = tester.widget<ManagerFormScreen>(
        find.byType(ManagerFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.managerId, isNull);
    });

    testWidgets('loads the properties of the owner', (tester) async {
      final properties = ownerProperties();
      await _open(tester, _repo(), properties: properties);

      expect(properties.calls, contains('list'));
    });

    testWidgets('does not load any manager', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(repo.calls, isEmpty);
    });

    testWidgets('shows the three text fields empty, with their labels', (
      tester,
    ) async {
      await _open(tester, _repo());

      for (final label in [_name, _nickname, _phone]) {
        expect(labeledField(label), findsOneWidget, reason: label);
        expect(fieldLabeled(label), findsOneWidget, reason: label);
        expect(_text(tester, label), isEmpty, reason: label);
      }
    });

    testWidgets('marks required and optional fields in text', (tester) async {
      await _open(tester, _repo());

      expect(_name, endsWith('(wajib)'));
      expect(_phone, endsWith('(wajib)'));
      expect(_nickname, endsWith('(opsional)'));
      expect(_group, endsWith('(wajib)'));
    });

    testWidgets('titles the property group with a header', (tester) async {
      await _open(tester, _repo());

      expect(find.text(_group), findsOneWidget);
      _expectHeader(tester, _group);
    });

    testWidgets('does not ask for an email', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('Email'), findsNothing);
      expect(find.textContaining('email'), findsNothing);
    });

    testWidgets('offers one checkbox per property of the owner', (
      tester,
    ) async {
      await _open(tester, _repo());

      for (final name in ['Kos Melati', 'Kos Mawar', 'Kos Anggrek']) {
        expect(propertyTile(name), findsOneWidget, reason: name);
      }
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
    });

    testWidgets('pre-checks only the property the form was opened from', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(checkedProperties(tester), ['Kos Melati']);
    });

    testWidgets('another property in the path is the one pre-checked', (
      tester,
    ) async {
      await _open(tester, _repo(), propertyId: 'p2');

      expect(checkedProperties(tester), ['Kos Mawar']);
    });

    testWidgets('tapping a checkbox checks and unchecks the property', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _toggle(tester, 'Kos Anggrek');
      expect(checkedProperties(tester), ['Kos Melati', 'Kos Anggrek']);

      await _toggle(tester, 'Kos Anggrek');
      expect(checkedProperties(tester), ['Kos Melati']);
    });

    testWidgets('every checkbox is at least 48 dp', (tester) async {
      await _open(tester, _repo());

      for (final name in ['Kos Melati', 'Kos Mawar', 'Kos Anggrek']) {
        expectFinderTargetSize(tester, propertyTile(name));
      }
    });

    testWidgets('the phone field takes a phone keyboard', (tester) async {
      await _open(tester, _repo());

      expect(
        labeledTextField(tester, _phone).keyboardType,
        TextInputType.phone,
      );
    });

    testWidgets('puts the save button in a pinned ActionFooter', (
      tester,
    ) async {
      await _open(tester, _repo());

      expectPinnedFooter(tester, _save);
    });

    testWidgets('draws no label inside any field of the form', (tester) async {
      await _open(tester, _repo());

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts each label above its field', (tester) async {
      await _open(tester, _repo());

      for (final label in [_name, _nickname, _phone]) {
        final text = tester.getRect(find.text(label));
        final input = tester.getRect(fieldLabeled(label));
        expect(text.bottom, lessThanOrEqualTo(input.top), reason: label);
      }
    });

    testWidgets('reads every label once, on its field node', (tester) async {
      await _open(tester, _repo());

      for (final label in [_name, _nickname, _phone]) {
        expectFieldNode(tester, label);
      }
    });

    testWidgets('keeps the field errors on their field nodes', (tester) async {
      await _open(tester, _repo());

      await _submit(tester);

      expectFieldNode(tester, _name, error: 'Nama wajib diisi.');
      expectFieldNode(tester, _phone, error: 'Nomor telepon wajib diisi.');
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
  });

  group('loading the properties', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final properties = ownerProperties()..listScript.gate = Completer<void>();
      await _open(tester, _repo(), properties: properties, settle: false);

      expectLoading(tester);
      expect(appBarTitle('Tambah Pengelola'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('shows the Indonesian message of a failure and a retry', (
      tester,
    ) async {
      final properties = ownerProperties()
        ..listScript.always = const ApiFailure.network();
      await _open(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('Coba lagi loads the properties and shows the form', (
      tester,
    ) async {
      final properties = ownerProperties()
        ..listScript.queue.add(const ApiFailure.network());
      await _open(tester, _repo(), properties: properties);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(properties.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(fieldLabeled(_name), findsOneWidget);
      expect(checkedProperties(tester), ['Kos Melati']);
    });
  });

  group('add validation', () {
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

    testWidgets('no property asks to choose at least one', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _toggle(tester, 'Kos Melati');

      await _submit(tester);

      expect(find.text(_noProperty), findsOneWidget);
      expect(repo.created, isEmpty);
      _expectErrors(tester, {});
    });

    testWidgets('an empty form shows every required error', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _toggle(tester, 'Kos Melati');

      await _submit(tester);

      _expectErrors(tester, {
        _name: 'Nama wajib diisi.',
        _phone: 'Nomor telepon wajib diisi.',
      });
      expect(find.text(_noProperty), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('the property error names the cause and not a field label', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _fill(tester);
      await _toggle(tester, 'Kos Melati');

      await _submit(tester);

      expect(find.text(_noProperty), findsOneWidget);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
    });

    testWidgets('keeps everything typed after a validation error', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _fill(tester, name: '', nickname: 'Bu Rina');
      await _toggle(tester, 'Kos Anggrek');

      await _submit(tester);

      expect(_text(tester, _phone), '0812-5520-4471');
      expect(_text(tester, _nickname), 'Bu Rina');
      expect(checkedProperties(tester), ['Kos Melati', 'Kos Anggrek']);
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

    testWidgets('choosing a property after the error lets the form through', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _toggle(tester, 'Kos Melati');
      await _submit(tester);
      expect(repo.created, isEmpty);

      await _toggle(tester, 'Kos Mawar');
      await _submit(tester);

      expect(repo.created.single.propertyIds, ['p2']);
    });

    testWidgets('errors disappear once the next submit is valid', (
      tester,
    ) async {
      final repo = _repo()..createScript.gate = Completer<void>();
      await _open(tester, repo);
      await _toggle(tester, 'Kos Melati');
      await _submit(tester);
      await _fill(tester);
      await _toggle(tester, 'Kos Melati');

      await _tapFirstSave(tester);

      _expectErrors(tester, {});
      expect(find.text(_noProperty), findsNothing);
    });
  });

  group('add request', () {
    testWidgets('sends the name, phone and the pre-checked property', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(
        repo.created.single,
        ManagerInput(
          name: 'Rina Putri',
          phone: '0812-5520-4471',
          propertyIds: ['p1'],
        ),
      );
      expect(repo.created.single.nickname, isNull);
    });

    testWidgets('trims the name, nickname and phone', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(
        tester,
        name: '  Rina Putri  ',
        phone: '  081255204471  ',
        nickname: '  Bu Rina  ',
      );

      await _submit(tester);

      final input = repo.created.single;
      expect(input.name, 'Rina Putri');
      expect(input.nickname, 'Bu Rina');
      expect(input.phone, '081255204471');
    });

    testWidgets('a nickname of only spaces is sent as null', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester, nickname: '   ');

      await _submit(tester);

      expect(repo.created.single.nickname, isNull);
    });

    testWidgets('sends every checked property once', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _toggle(tester, 'Kos Anggrek');
      await _toggle(tester, 'Kos Mawar');

      await _submit(tester);

      expect(
        repo.created.single.propertyIds,
        unorderedEquals(['p1', 'p2', 'p3']),
      );
      expect(repo.created.single.propertyIds, hasLength(3));
    });

    testWidgets('does not send a property that was unchecked again', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _toggle(tester, 'Kos Mawar');
      await _toggle(tester, 'Kos Mawar');

      await _submit(tester);

      expect(repo.created.single.propertyIds, ['p1']);
    });

    testWidgets('sends the property of the owner other than the first', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);
      await _toggle(tester, 'Kos Melati');
      await _toggle(tester, 'Kos Anggrek');

      await _submit(tester);

      expect(repo.created.single.propertyIds, ['p3']);
    });
  });

  group('add in flight', () {
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

      expect(find.byType(ManagerFormScreen), findsOneWidget);
      expect(find.byType(ManagerInvitationShareScreen), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });
  });

  group('add success', () {
    testWidgets('opens the share screen of the new manager as new', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/new-1/undangan');
      expect(_currentUri(tester).queryParameters, {'baru': '1'});
      final share = tester.widget<ManagerInvitationShareScreen>(
        find.byType(ManagerInvitationShareScreen),
      );
      expect(share.propertyId, 'p1');
      expect(share.managerId, 'new-1');
      expect(share.isNew, isTrue);
      expect(find.byType(ManagerFormScreen), findsNothing);
    });

    testWidgets('Back does not return to the form', (tester) async {
      await _open(tester, _repo());
      await _fill(tester);
      await _submit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ManagerFormScreen), findsNothing);
    });

    testWidgets('the new manager is in the list after Selesai', (tester) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo);
      await tester.tap(find.text('Tambah Pengelola'));
      await tester.pumpAndSettle();
      await _fill(tester, name: 'Tono Wijaya');
      await _submit(tester);

      await tapVisible(tester, find.text('Selesai'));

      expect(find.byType(ManagerListScreen), findsOneWidget);
      expect(find.text('Tono Wijaya'), findsOneWidget);
    });

    testWidgets('the new manager shows its nickname in the list', (
      tester,
    ) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo);
      await tester.tap(find.text('Tambah Pengelola'));
      await tester.pumpAndSettle();
      await _fill(tester, name: 'Tono Wijaya', nickname: 'Pak Tono');
      await _submit(tester);

      await tapVisible(tester, find.text('Selesai'));

      expect(find.text('Pak Tono'), findsOneWidget);
    });

    testWidgets('a manager added to another property opens its share screen', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo, propertyId: 'p2');
      await _fill(tester);

      await _submit(tester);

      expect(currentPath(tester), '/properti/p2/pengelola/new-1/undangan');
      expect(repo.created.single.propertyIds, ['p2']);
    });
  });

  group('add failures', () {
    testWidgets('a phone error shows next to the phone', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      _expectErrors(tester, {_phone: 'Nomor telepon tidak valid.'});
      expect(find.byType(ManagerFormScreen), findsOneWidget);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
    });

    testWidgets('a name error shows next to the name', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'name'),
        );
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      _expectErrors(tester, {_name: 'Nama lengkap tidak valid.'});
      expect(find.byType(ManagerFormScreen), findsOneWidget);
    });

    for (final field in ['propertyIds.0', 'propertyIds.1']) {
      testWidgets('an unknown property at $field shows on the property group', (
        tester,
      ) async {
        final repo = _repo()
          ..createScript.queue.add(
            ApiFailure(code: 'PROPERTY_NOT_FOUND', field: field),
          );
        await _open(tester, repo);
        await _fill(tester);
        await _toggle(tester, 'Kos Mawar');

        await _submit(tester);

        expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
        expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
        _expectErrors(tester, {});
        expect(find.byType(ManagerFormScreen), findsOneWidget);
        expect(checkedProperties(tester), ['Kos Melati', 'Kos Mawar']);
      });
    }

    testWidgets('a field error keeps every typed value', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _open(tester, repo);
      await _fill(tester, nickname: 'Bu Rina');
      await _toggle(tester, 'Kos Anggrek');

      await _submit(tester);

      expect(_text(tester, _name), 'Rina Putri');
      expect(_text(tester, _nickname), 'Bu Rina');
      expect(_text(tester, _phone), '0812-5520-4471');
      expect(checkedProperties(tester), ['Kos Melati', 'Kos Anggrek']);
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

      await typeInto(tester, _phone, '081255204471');
      await _submit(tester);

      expect(repo.created, hasLength(2));
      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
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
      'a network failure': const ApiFailure.network(),
      'a server failure': const ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
      'a forbidden answer': const ApiFailure(code: 'FORBIDDEN'),
      'a validation error without a field': const ApiFailure(
        code: 'VALIDATION_FAILED',
      ),
      'a missing property without a field': const ApiFailure(
        code: 'PROPERTY_NOT_FOUND',
      ),
    };
    for (final entry in bannerCases.entries) {
      testWidgets('shows ${entry.key} in a banner and keeps the values', (
        tester,
      ) async {
        final repo = _repo()..createScript.queue.add(entry.value);
        await _open(tester, repo);
        await _fill(tester, nickname: 'Bu Rina');

        await _submit(tester);

        final message = errorMessageFor(entry.value);
        expect(find.text(message), findsOneWidget);
        expect(snackBar(message), findsNothing);
        _expectErrors(tester, {});
        expect(find.byType(ManagerFormScreen), findsOneWidget);
        expect(_text(tester, _name), 'Rina Putri');
        expect(_text(tester, _nickname), 'Bu Rina');
        expect(_text(tester, _phone), '0812-5520-4471');
        expect(checkedProperties(tester), ['Kos Melati']);
      });
    }

    testWidgets('announces the banner as a live region', (tester) async {
      final repo = _repo()
        ..createScript.queue.add(const ApiFailure(code: 'FORBIDDEN'));
      await _open(tester, repo);
      await _fill(tester);
      await _submit(tester);

      expectLiveRegion(tester, messageOfCode('FORBIDDEN'));
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

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
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

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
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
      expect(repo.created.first, repo.created.last);
      expect(find.byType(ManagerInvitationShareScreen), findsOneWidget);
    });

    testWidgets('a failure adds no manager', (tester) async {
      final repo = _repo()..createScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester);

      await _submit(tester);

      expect(repo.managers, hasLength(4));
    });
  });

  group('edit layout', () {
    testWidgets('shows the title and the submit button', (tester) async {
      await _openEdit(tester, _repo());

      expect(find.byType(ManagerFormScreen), findsOneWidget);
      expect(appBarTitle('Ubah Pengelola'), findsOneWidget);
      expect(find.text(_save), findsOneWidget);
      expect(find.text('Tambah Pengelola'), findsNothing);
    });

    testWidgets('is shown for the manager of the path', (tester) async {
      await _openEdit(tester, _repo(), managerId: 'm2');

      final form = tester.widget<ManagerFormScreen>(
        find.byType(ManagerFormScreen),
      );
      expect(form.propertyId, 'p1');
      expect(form.managerId, 'm2');
    });

    testWidgets('loads the manager and the properties of the owner', (
      tester,
    ) async {
      final repo = _repo();
      final properties = ownerProperties();
      await _openEdit(tester, repo, properties: properties);

      expect(repo.calls, contains('get:m1'));
      expect(properties.calls, contains('list'));
    });

    testWidgets('pre-fills the name, nickname and phone', (tester) async {
      await _openEdit(tester, _repo());

      expect(_text(tester, _name), 'Rina Putri');
      expect(_text(tester, _nickname), 'Bu Rina');
      expect(_text(tester, _phone), '081255204471');
    });

    testWidgets('leaves the nickname empty when there is none', (tester) async {
      await _openEdit(tester, _repo(), managerId: 'm3');

      expect(_text(tester, _name), 'Dewi Lestari');
      expect(_text(tester, _nickname), isEmpty);
    });

    testWidgets('checks the properties the manager is assigned to', (
      tester,
    ) async {
      await _openEdit(tester, _repo(), managerId: 'm2');

      expect(checkedProperties(tester), ['Kos Melati', 'Kos Mawar']);
    });

    testWidgets('checks only the assigned property, not the one of the path', (
      tester,
    ) async {
      await pumpManagerApp(
        tester,
        _repo(),
        path: '/properti/p1/pengelola/m4/ubah',
      );

      expect(checkedProperties(tester), ['Kos Mawar']);
    });

    testWidgets('an email is not asked for', (tester) async {
      await _openEdit(tester, _repo(), managerId: 'm2');

      expect(find.textContaining('Email'), findsNothing);
      expect(find.textContaining('email'), findsNothing);
    });

    testWidgets('a not activated manager can change the name', (tester) async {
      await _openEdit(tester, _repo());

      expect(_nameIsLocked(tester), isFalse);
      expect(find.text(_nameLocked), findsNothing);
    });

    testWidgets('an active manager cannot change the name', (tester) async {
      await _openEdit(tester, _repo(), managerId: 'm2');

      expect(_text(tester, _name), 'Agus Santoso');
      expect(_nameIsLocked(tester), isTrue);
    });

    testWidgets('an active manager sees why the name is locked', (
      tester,
    ) async {
      await _openEdit(tester, _repo(), managerId: 'm2');

      expect(
        find.descendant(
          of: labeledField(_name),
          matching: find.text(_nameLocked),
        ),
        findsOneWidget,
      );
      final handle = tester.ensureSemantics();
      try {
        expect(
          announced(tester.getSemantics(fieldLabeled(_name))),
          contains(_nameLocked),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an active manager can still change the other fields', (
      tester,
    ) async {
      await _openEdit(tester, _repo(), managerId: 'm2');

      for (final label in [_nickname, _phone]) {
        final field = labeledTextField(tester, label);
        expect(field.enabled, isNot(false), reason: label);
        expect(field.readOnly, isFalse, reason: label);
      }
    });

    testWidgets('puts the save button in a pinned ActionFooter', (
      tester,
    ) async {
      await _openEdit(tester, _repo());

      expectPinnedFooter(tester, _save);
    });

    testWidgets('draws no label inside any field of the form', (tester) async {
      await _openEdit(tester, _repo());

      expectNoDecorationLabels(tester);
    });
  });

  group('edit loading', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await _openEdit(tester, repo, settle: false);

      expectLoading(tester);
      expect(appBarTitle('Ubah Pengelola'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('shows the form once the manager is loaded', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..getScript.gate = gate;
      await _openEdit(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(_text(tester, _name), 'Rina Putri');
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
    });

    testWidgets('shows the message of a manager that does not exist', (
      tester,
    ) async {
      await _openEdit(tester, FakeManagerRepository());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Pengelola tidak ditemukan.'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });

    testWidgets('Coba lagi loads the manager again', (tester) async {
      final repo = _repo()..getScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.getCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(_text(tester, _name), 'Rina Putri');
    });

    testWidgets('shows a failure to load the properties with a retry', (
      tester,
    ) async {
      final properties = ownerProperties()
        ..listScript.always = const ApiFailure.network();
      await _openEdit(tester, _repo(), properties: properties);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(fieldLabeled(_name), findsNothing);
    });
  });

  group('edit validation', () {
    testWidgets('an emptied name of a not activated manager shows its error', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '');

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

    testWidgets('an invalid phone shows its error', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _phone, '12345');

      await _submit(tester);

      _expectErrors(tester, {_phone: _invalidPhone});
      expect(repo.updated, isEmpty);
    });

    testWidgets('no property asks to choose at least one', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await _toggle(tester, 'Kos Melati');

      await _submit(tester);

      expect(find.text(_noProperty), findsOneWidget);
      expect(repo.updated, isEmpty);
    });

    testWidgets('unchecking one of two properties is accepted', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, managerId: 'm2');
      await _toggle(tester, 'Kos Mawar');

      await _submit(tester);

      expect(repo.updated.single.input.propertyIds, ['p1']);
    });
  });

  group('edit request', () {
    testWidgets('puts the full resource to the manager', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _nickname, 'Ibu Rina');
      await typeInto(tester, _phone, '0813 7778 8899');
      await _toggle(tester, 'Kos Mawar');

      await _submit(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.id, 'm1');
      expect(
        repo.updated.single.input,
        ManagerInput(
          name: 'Rina Putri',
          nickname: 'Ibu Rina',
          phone: '0813 7778 8899',
          propertyIds: repo.updated.single.input.propertyIds,
        ),
      );
      expect(
        repo.updated.single.input.propertyIds,
        unorderedEquals(['p1', 'p2']),
      );
      expect(repo.created, isEmpty);
    });

    testWidgets('submitting without a change sends the current values', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);

      await _submit(tester);

      expect(
        repo.updated.single.input,
        ManagerInput(
          name: 'Rina Putri',
          nickname: 'Bu Rina',
          phone: '081255204471',
          propertyIds: ['p1'],
        ),
      );
    });

    testWidgets('a not activated manager can be renamed', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _name, '  Rina Putri Sari ');

      await _submit(tester);

      expect(repo.updated.single.input.name, 'Rina Putri Sari');
    });

    testWidgets('a cleared nickname is sent as null', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _nickname, '');

      await _submit(tester);

      expect(repo.updated.single.input.nickname, isNull);
    });

    testWidgets('an active manager keeps the name unchanged', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo, managerId: 'm2');
      await typeInto(tester, _nickname, 'Pak Agus');

      await _submit(tester);

      expect(repo.updated.single.id, 'm2');
      expect(repo.updated.single.input.name, 'Agus Santoso');
      expect(repo.updated.single.input.nickname, 'Pak Agus');
    });

    testWidgets('an active manager sends the properties it keeps', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo, managerId: 'm2');
      await _toggle(tester, 'Kos Anggrek');

      await _submit(tester);

      expect(
        repo.updated.single.input.propertyIds,
        unorderedEquals(['p1', 'p2', 'p3']),
      );
    });
  });

  group('edit in flight', () {
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

      expect(repo.updated, hasLength(1));
    });
  });

  group('edit success', () {
    testWidgets('goes back to the detail of the manager', (tester) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      await typeInto(tester, _nickname, 'Ibu Rina');

      await _submit(tester);

      expect(currentPath(tester), '/properti/p1/pengelola/m1');
      final detail = tester.widget<ManagerDetailScreen>(
        find.byType(ManagerDetailScreen),
      );
      expect(detail.managerId, 'm1');
      expect(find.byType(ManagerFormScreen), findsNothing);
    });

    testWidgets('the detail shows the refreshed data', (tester) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo, path: '/properti/p1/pengelola/m1');
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await typeInto(tester, _nickname, 'Ibu Rina');
      await typeInto(tester, _phone, '081300000001');

      await _submit(tester);

      expect(find.text('Ibu Rina'), findsOneWidget);
      expect(find.text('Bu Rina'), findsNothing);
      expect(find.textContaining('081300000001'), findsOneWidget);
      expect(find.textContaining('081255204471'), findsNothing);
    });

    testWidgets('the list shows the refreshed data too', (tester) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo);
      await tester.tap(find.text('Bu Rina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await typeInto(tester, _nickname, 'Ibu Rina');
      await _submit(tester);

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1/pengelola');
      expect(find.text('Ibu Rina'), findsOneWidget);
      expect(find.text('Bu Rina'), findsNothing);
      expect(repo.listCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('a manager removed from the property leaves its list', (
      tester,
    ) async {
      final repo = _repo();
      await pumpManagerApp(tester, repo, path: '/properti/p2/pengelola');
      await tester.tap(find.text('Agus Santoso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await _toggle(tester, 'Kos Mawar');
      await _submit(tester);

      await pressBack(tester);

      expect(find.text('Agus Santoso'), findsNothing);
    });

    testWidgets('Back from the detail does not return to the form', (
      tester,
    ) async {
      await _openEdit(tester, _repo());
      await _submit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ManagerFormScreen), findsNothing);
    });
  });

  group('edit failures', () {
    testWidgets('a name that cannot be changed shows next to the name', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'MANAGER_NAME_NOT_EDITABLE', field: 'name'),
        );
      await _openEdit(tester, repo);
      await typeInto(tester, _name, 'Nama Baru');

      await _submit(tester);

      _expectErrors(tester, {_name: _nameLocked});
      expect(find.byType(ManagerFormScreen), findsOneWidget);
      expect(_text(tester, _name), 'Nama Baru');
    });

    testWidgets('a phone error shows next to the phone', (tester) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
        );
      await _openEdit(tester, repo);

      await _submit(tester);

      _expectErrors(tester, {_phone: 'Nomor telepon tidak valid.'});
    });

    testWidgets('an unknown property shows on the property group', (
      tester,
    ) async {
      final repo = _repo()
        ..updateScript.queue.add(
          const ApiFailure(code: 'PROPERTY_NOT_FOUND', field: 'propertyIds.0'),
        );
      await _openEdit(tester, repo);

      await _submit(tester);

      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
      _expectErrors(tester, {});
    });

    testWidgets('a manager that is gone shows its message in a banner', (
      tester,
    ) async {
      final repo = _repo();
      await _openEdit(tester, repo);
      repo.managers.removeWhere((m) => m.id == 'm1');

      await _submit(tester);

      expect(find.text('Pengelola tidak ditemukan.'), findsOneWidget);
      expect(find.byType(ManagerFormScreen), findsOneWidget);
      _expectErrors(tester, {});
    });

    final bannerCases = <String, ApiFailure>{
      'a network failure': const ApiFailure.network(),
      'a server failure': const ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
    };
    for (final entry in bannerCases.entries) {
      testWidgets('shows ${entry.key} in a banner and keeps the values', (
        tester,
      ) async {
        final repo = _repo()..updateScript.queue.add(entry.value);
        await _openEdit(tester, repo);
        await typeInto(tester, _nickname, 'Ibu Rina');

        await _submit(tester);

        final message = errorMessageFor(entry.value);
        expect(find.text(message), findsOneWidget);
        expect(snackBar(message), findsNothing);
        expect(find.byType(ManagerFormScreen), findsOneWidget);
        expect(_text(tester, _nickname), 'Ibu Rina');
        expect(repo.managers.first.nickname, 'Bu Rina');
      });
    }

    testWidgets('a successful retry after a banner goes to the detail', (
      tester,
    ) async {
      final repo = _repo()..updateScript.queue.add(const ApiFailure.network());
      await _openEdit(tester, repo);
      await _submit(tester);

      await _submit(tester);

      expect(repo.updated, hasLength(2));
      expect(currentPath(tester), '/properti/p1/pengelola/m1');
    });
  });

  group('accessibility', () {
    Future<void> submitInFlight(WidgetTester tester) async {
      await tester.ensureVisible(find.text(_save));
      await tester.pump();
      await tapAndPump(tester, find.text(_save));
    }

    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the add form': (tester, large) =>
          _open(tester, _repo(), largeText: large),
      'the add form for another property': (tester, large) =>
          _open(tester, _repo(), propertyId: 'p2', largeText: large),
      'the add form while the properties load': (tester, large) => _open(
        tester,
        _repo(),
        properties: ownerProperties()..listScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
      'the add form after the properties failed to load': (tester, large) =>
          _open(
            tester,
            _repo(),
            properties: ownerProperties()
              ..listScript.always = const ApiFailure.network(),
            largeText: large,
          ),
      'the add form with every property checked': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _toggle(tester, 'Kos Mawar');
        await _toggle(tester, 'Kos Anggrek');
      },
      'the add form with required field errors': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _toggle(tester, 'Kos Melati');
        await _submit(tester);
      },
      'the add form with an invalid phone': (tester, large) async {
        await _open(tester, _repo(), largeText: large);
        await _fill(tester, phone: '12345');
        await _submit(tester);
      },
      'the add form with server field errors': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(
            const ApiFailure(code: 'VALIDATION_FAILED', field: 'phone'),
          );
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await _submit(tester);
      },
      'the add form with a property error from the server':
          (tester, large) async {
            final repo = _repo()
              ..createScript.queue.add(
                const ApiFailure(
                  code: 'PROPERTY_NOT_FOUND',
                  field: 'propertyIds.0',
                ),
              );
            await _open(tester, repo, largeText: large);
            await _fill(tester);
            await _submit(tester);
          },
      'the add form with a banner': (tester, large) async {
        final repo = _repo()
          ..createScript.queue.add(const ApiFailure(code: 'FORBIDDEN'));
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await _submit(tester);
      },
      'the add form in flight': (tester, large) async {
        final repo = _repo()..createScript.gate = Completer<void>();
        await _open(tester, repo, largeText: large);
        await _fill(tester);
        await submitInFlight(tester);
      },
      'the edit form of a not activated manager': (tester, large) =>
          _openEdit(tester, _repo(), largeText: large),
      'the edit form of an active manager': (tester, large) =>
          _openEdit(tester, _repo(), managerId: 'm2', largeText: large),
      'the edit form while the manager loads': (tester, large) => _openEdit(
        tester,
        _repo()..getScript.gate = Completer<void>(),
        settle: false,
        largeText: large,
      ),
      'the edit form after the manager failed to load': (tester, large) =>
          _openEdit(
            tester,
            _repo()..getScript.always = const ApiFailure.network(),
            largeText: large,
          ),
      'the edit form of a manager that does not exist': (tester, large) =>
          _openEdit(tester, FakeManagerRepository(), largeText: large),
      'the edit form with a name error from the server': (tester, large) async {
        final repo = _repo()
          ..updateScript.queue.add(
            const ApiFailure(code: 'MANAGER_NAME_NOT_EDITABLE', field: 'name'),
          );
        await _openEdit(tester, repo, largeText: large);
        await _submit(tester);
      },
      'the edit form with a banner': (tester, large) async {
        final repo = _repo()
          ..updateScript.queue.add(const ApiFailure.network());
        await _openEdit(tester, repo, largeText: large);
        await _submit(tester);
      },
      'the edit form in flight': (tester, large) async {
        final repo = _repo()..updateScript.gate = Completer<void>();
        await _openEdit(tester, repo, largeText: large);
        await submitInFlight(tester);
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
      await _open(tester, _repo(), largeText: true);
      final before = tester.getRect(find.byType(ActionFooter));
      expectFooterAtBottom(tester);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(ActionFooter)), before);
      expect(find.text(_save), findsOneWidget);
    });
  });
}
