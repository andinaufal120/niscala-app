import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/semantics.dart';
import 'complaint_ui_helpers.dart';

/// The visible label of the description field, with its required marker.
const _label = 'Deskripsi keluhan (wajib)';

/// The helper text under the description field.
const _helper = 'Ceritakan masalahnya, minimal 10 karakter.';
const _send = 'Kirim Keluhan';
const _valid = 'Keran air di kamar mandi bocor.';

/// The label of the read-only room line shown to a tenant with one lease.
const _roomLine = 'Kamar';

/// The label of the required room choice shown to a tenant with several
/// leases.
const _roomGroup = 'Kamar (wajib)';

const _roomRequired = 'Pilih kamar.';
const _melati = 'Kos Melati · Kamar 08';
const _mawar = 'Kos Mawar · Kamar 12';

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  FakeLeaseRepository? leases,
  bool settle = true,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  repo,
  path: '/penyewa/keluhan/baru',
  leases: leases,
  settle: settle,
  largeText: largeText,
);

/// Opens the form of a tenant with the two leases of [makeTwoLeases].
Future<void> _openWithTwoLeases(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  bool largeText = false,
}) => _open(
  tester,
  repo,
  leases: FakeLeaseRepository(leases: makeTwoLeases()),
  largeText: largeText,
);

/// The radio choice labelled [label] in the room group.
Finder _roomChoice(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate(
    (widget) => widget is RadioListTile,
    description: 'RadioListTile',
  ),
);

Future<void> _chooseRoom(WidgetTester tester, String label) =>
    tapVisible(tester, _roomChoice(label));

/// Expects the choice to be a radio of a mutually exclusive group that
/// announces whether it is selected.
void _expectChoice(
  WidgetTester tester,
  String label, {
  required bool selected,
}) {
  final handle = tester.ensureSemantics();
  try {
    expect(
      tester.getSemantics(_roomChoice(label)),
      isSemantics(
        hasCheckedState: true,
        isChecked: selected,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  } finally {
    handle.dispose();
  }
}

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text(_send));

Future<void> _write(WidgetTester tester, String text) =>
    typeInto(tester, _label, text);

String? _error(WidgetTester tester) => labeledFieldError(tester, _label);

void main() {
  group('layout', () {
    testWidgets('is titled and shows the labelled description field', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());

      expect(find.byType(ComplaintFormScreen), findsOneWidget);
      expect(appBarTitle('Ajukan Keluhan'), findsOneWidget);
      expect(labeledField(_label), findsOneWidget);
      expect(fieldLabeled(_label), findsOneWidget);
      expect(find.text(_send), findsOneWidget);
    });

    testWidgets('starts empty without an error and states the minimum', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());

      expect(labeledTextField(tester, _label).controller!.text, isEmpty);
      expect(_error(tester), isNull);
      expect(find.text(_helper), findsOneWidget);
    });

    testWidgets('accepts several lines', (tester) async {
      await _open(tester, FakeComplaintRepository());

      final input = labeledTextField(tester, _label);
      expect(input.maxLines == null || input.maxLines! > 1, isTrue);
    });

    testWidgets('the submit button is at least 48 dp', (tester) async {
      await _open(tester, FakeComplaintRepository());

      expectTargetSize(tester, _send);
    });

    testWidgets('focusing the field does not submit or navigate', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);

      await tester.tap(fieldLabeled(_label));
      await tester.pumpAndSettle();

      expect(repo.submitCalls, 0);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('typing a valid text does not submit by itself', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);

      await _write(tester, _valid);

      expect(repo.submitCalls, 0);
    });
  });

  group('validation', () {
    testWidgets('an empty description is a field error and nothing is sent', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);

      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(_error(tester), isNot(messageOfCode('UNKNOWN')));
      expect(repo.submitCalls, 0);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('a blank description is a field error', (tester) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, '          \n    ');

      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
    });

    testWidgets('a description of 9 characters is a field error', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, '123456789');

      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
    });

    testWidgets('spaces around the text do not count towards the minimum', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, '    123456789    ');

      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
    });

    testWidgets('a description of exactly 10 characters is sent', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, '1234567890');

      await _submit(tester);

      expect(repo.submitted, ['1234567890']);
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
    });

    testWidgets('a description of 10 characters between spaces is sent', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, '   1234567890   ');

      await _submit(tester);

      expect(repo.submitted.single.trim(), '1234567890');
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
    });

    testWidgets('the field error is cleared by a valid resubmit', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _submit(tester);
      expect(_error(tester), isNotNull);

      await _write(tester, _valid);
      await _submit(tester);

      expect(repo.submitted, [_valid]);
      expect(find.byType(ComplaintFormScreen), findsNothing);
    });

    testWidgets('shows the field error as visible text next to the field', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());
      await _submit(tester);

      expect(find.text(_error(tester)!), findsOneWidget);
    });

    testWidgets('a too short description names the minimum of 10 characters', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, 'pendek');

      await _submit(tester);

      expect(_error(tester), contains('10'));
    });
  });

  group('maximum length', () {
    final exact = 'a' * 2000;
    final tooLong = 'a' * 2001;

    testWidgets('a description of exactly 2000 characters is sent', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, exact);

      await _submit(tester);

      expect(repo.submitted, [exact]);
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
    });

    testWidgets('a description of 2001 characters is a field error', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, tooLong);

      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
      expect(repo.complaints, isEmpty);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('the too long error names the limit of 2000 characters', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, tooLong);

      await _submit(tester);

      expect(_error(tester), contains('2000'));
      expect(find.text(_error(tester)!), findsOneWidget);
    });

    testWidgets('the too long error differs from the too short error', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, 'pendek');
      await _submit(tester);
      final tooShortError = _error(tester);

      await _write(tester, tooLong);
      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(_error(tester), isNot(tooShortError));
    });

    testWidgets(
      'spaces around 2000 characters do not count towards the limit',
      (tester) async {
        final repo = FakeComplaintRepository();
        await _open(tester, repo);
        await _write(tester, '     $exact     \n ');

        await _submit(tester);

        expect(repo.submitCalls, 1);
        expect(repo.submitted.single.trim(), exact);
        expect(currentPath(tester), '/penyewa/keluhan/new-1');
      },
    );

    testWidgets('spaces around 2001 characters still exceed the limit', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, '  $tooLong  ');

      await _submit(tester);

      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
    });

    testWidgets('an over-long description is kept in full in the field', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, tooLong);

      await _submit(tester);

      expect(labeledTextField(tester, _label).controller!.text, tooLong);
    });

    testWidgets('typing more than 2000 characters is not cut off', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());

      await _write(tester, 'a' * 2500);

      expect(labeledTextField(tester, _label).controller!.text, 'a' * 2500);
    });

    testWidgets('shortening the text to the limit and resubmitting sends it', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, tooLong);
      await _submit(tester);
      expect(_error(tester), isNotNull);

      await _write(tester, exact);
      await _submit(tester);

      expect(repo.submitted, [exact]);
      expect(find.byType(ComplaintFormScreen), findsNothing);
    });

    testWidgets('the button works again after the too long error', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, tooLong);

      await _submit(tester);

      expect(busyButton(), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_send)).onPressed,
        isNotNull,
      );
    });

    testWidgets('the too long error clears an earlier banner', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);

      await _write(tester, tooLong);
      await _submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(_error(tester), isNotNull);
    });

    testWidgets('keeps the too long error on the field node', (tester) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, tooLong);
      await _submit(tester);

      expectFieldNode(tester, _label, error: _error(tester)!);
    });

    testWidgets('an API field error on a long description keeps the text', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'description'),
        );
      await _open(tester, repo);
      await _write(tester, exact);

      await _submit(tester);

      expect(_error(tester), 'Keluhan tidak valid.');
      expect(labeledTextField(tester, _label).controller!.text, exact);
      expect(find.text('Keluhan tidak valid.'), findsOneWidget);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('meets the guidelines with the too long error', (tester) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, tooLong);
      await _submit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the too long error', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository(), largeText: true);
      await _write(tester, tooLong);
      await _submit(tester);

      expect(tester.takeException(), isNull);
      expect(_error(tester), isNotNull);
    });
  });

  group('success', () {
    testWidgets('saves the description and opens the new complaint at once', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(repo.submitted, [_valid]);
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
      final detail = tester.widget<TenantComplaintDetailScreen>(
        find.byType(TenantComplaintDetailScreen),
      );
      expect(detail.complaintId, 'new-1');
      expect(detail.submitted, isTrue);
    });

    testWidgets('shows the confirmation and the saved text', (tester) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text('Keluhan terkirim.'), findsOneWidget);
      expect(find.text(_valid), findsOneWidget);
      expect(statusSteps(), findsOneWidget);
    });

    testWidgets('does not wait for the AI to finish', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitState = ComplaintClassificationState.classifying;
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text('Keluhan terkirim.'), findsOneWidget);
      expect(statusBadge('Sedang Diklasifikasi'), findsOneWidget);
      expect(repo.submitCalls, 1);
    });

    testWidgets('the form is gone after saving', (tester) async {
      await _open(tester, FakeComplaintRepository());
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.byType(ComplaintFormScreen), findsNothing);
      expect(fieldLabeled(_label), findsNothing);
    });

    testWidgets('a classified result is still a success', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitState = null
        ..submitClassification = makeComplaintClassification();
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text('Keluhan terkirim.'), findsOneWidget);
      expect(find.text('Pipa dan air'), findsOneWidget);
    });

    for (final state in [
      ComplaintClassificationState.awaitingClassification,
      ComplaintClassificationState.notClassified,
    ]) {
      testWidgets('the complaint is saved when the state is $state', (
        tester,
      ) async {
        final repo = FakeComplaintRepository()..submitState = state;
        await _open(tester, repo);
        await _write(tester, _valid);

        await _submit(tester);

        expect(repo.complaints, hasLength(1));
        expect(find.text('Keluhan terkirim.'), findsOneWidget);
        expect(currentPath(tester), '/penyewa/keluhan/new-1');
        expect(find.byType(ComplaintFormScreen), findsNothing);
      });
    }

    testWidgets('the list shows the new complaint after going back', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await pumpComplaintApp(tester, repo);
      expect(find.text(_valid), findsNothing);

      await tester.tap(find.text('Ajukan Keluhan'));
      await tester.pumpAndSettle();
      await _write(tester, _valid);
      await _submit(tester);
      await pressBack(tester);

      expect(find.byType(TenantComplaintListScreen), findsOneWidget);
      expect(find.text(_valid), findsOneWidget);
      expect(repo.listCalls, greaterThanOrEqualTo(2));
    });
  });

  group('in flight', () {
    testWidgets('shows progress and disables the button while saving', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.gate = Completer<void>();
      await _open(tester, repo);
      await _write(tester, _valid);

      await tapAndPump(tester, find.text(_send));

      expectBusy(tester);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('a second tap while saving does not send again', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakeComplaintRepository()..submitScript.gate = gate;
      await _open(tester, repo);
      await _write(tester, _valid);

      await tapAndPump(tester, find.text(_send));
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.submitCalls, 1);
      expect(repo.complaints, hasLength(1));
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
    });

    testWidgets('the button works again after a failure', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);

      expect(busyButton(), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(buttonLabelled(_send)).onPressed,
        isNotNull,
      );
    });
  });

  group('failure', () {
    testWidgets('a field error from the API shows next to the field', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'description'),
        );
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(_error(tester), 'Keluhan tidak valid.');
      expect(labeledTextField(tester, _label).controller!.text, _valid);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
      expect(repo.complaints, isEmpty);
    });

    testWidgets(
      'a missing lease shows its Indonesian message and keeps the text',
      (tester) async {
        final repo = FakeComplaintRepository()
          ..submitScript.queue.add(const ApiFailure(code: 'NO_ACTIVE_LEASE'));
        await _open(tester, repo);
        await _write(tester, _valid);

        await _submit(tester);

        expect(
          find.text(
            'Anda belum memiliki masa sewa aktif. Hubungi pengelola kost.',
          ),
          findsOneWidget,
        );
        expect(_error(tester), isNull);
        expect(labeledTextField(tester, _label).controller!.text, _valid);
        expect(currentPath(tester), '/penyewa/keluhan/baru');
      },
    );

    testWidgets('a network failure shows its message and keeps the text', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(labeledTextField(tester, _label).controller!.text, _valid);
      expect(repo.complaints, isEmpty);
    });

    testWidgets('an unknown code shows the generic message', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('the banner is a live region that stays on screen', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);

      await tester.pump(const Duration(seconds: 30));

      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('retrying after a failure saves the complaint', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);

      await _submit(tester);

      expect(repo.submitCalls, 2);
      expect(repo.complaints, hasLength(1));
      expect(find.text('Keluhan terkirim.'), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('the banner goes away on the next submit', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network())
        ..submitScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);

      await _submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('a client side field error clears an earlier banner', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);

      await _write(tester, 'pendek');
      await _submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(_error(tester), isNotNull);
    });
  });

  group('with one lease', () {
    testWidgets('shows the room read-only with its property', (tester) async {
      await _open(tester, FakeComplaintRepository());

      expect(find.text(_roomLine), findsOneWidget);
      expect(find.text(_melati), findsOneWidget);
    });

    testWidgets('offers no room choice and no second input', (tester) async {
      await _open(tester, FakeComplaintRepository());

      expect(find.byType(RadioListTile), findsNothing);
      expect(find.byType(Radio), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(DropdownButtonFormField), findsNothing);
      expect(find.text(_roomGroup), findsNothing);
      expect(find.text(_roomRequired), findsNothing);
    });

    testWidgets('names the property and room of that lease', (tester) async {
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: FakeLeaseRepository(
          lease: makeCurrentLease(
            propertyName: 'Kos Anggrek',
            roomNumber: '21',
            roomId: 'r9',
          ),
        ),
      );

      expect(find.text('Kos Anggrek · Kamar 21'), findsOneWidget);
      expect(find.text(_melati), findsNothing);
    });

    testWidgets('sends the room of that lease with the description', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _open(
        tester,
        repo,
        leases: FakeLeaseRepository(lease: makeCurrentLease(roomId: 'r9')),
      );
      await _write(tester, _valid);

      await _submit(tester);

      expect(repo.submitted, [_valid]);
      expect(repo.submittedRoomIds, ['r9']);
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
    });

    testWidgets('does not need a choice before sending', (tester) async {
      final repo = FakeComplaintRepository();
      await _open(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text(_roomRequired), findsNothing);
      expect(repo.submitCalls, 1);
    });

    testWidgets('fetches the leases once', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease());
      await _open(tester, FakeComplaintRepository(), leases: leases);

      expect(leases.calls, 1);
    });

    testWidgets('tapping the read-only room changes nothing', (tester) async {
      await _open(tester, FakeComplaintRepository());

      await tester.tap(find.text(_melati));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(PopupMenuItem), findsNothing);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('puts the room above the description', (tester) async {
      await _open(tester, FakeComplaintRepository());

      expect(
        tester.getTopLeft(find.text(_melati)).dy,
        lessThan(tester.getTopLeft(find.text(_label)).dy),
      );
    });

    testWidgets('meets the guidelines', (tester) async {
      await _open(tester, FakeComplaintRepository());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: FakeLeaseRepository(
          lease: makeCurrentLease(
            propertyName: 'Kos Melati Indah Permai Sejahtera Bersama',
            roomNumber: 'A-12 Lantai Dua Sayap Timur',
          ),
        ),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Kos Melati Indah'), findsOneWidget);
    });
  });

  group('with several leases', () {
    testWidgets('asks which room the complaint is about, as required', (
      tester,
    ) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      expect(find.text(_roomGroup), findsOneWidget);
      expect(find.text(_roomLine), findsNothing);
    });

    testWidgets('offers one choice per lease in the order of the API', (
      tester,
    ) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      expect(find.byType(RadioListTile), findsNWidgets(2));
      expect(_roomChoice(_melati), findsOneWidget);
      expect(_roomChoice(_mawar), findsOneWidget);
      expect(
        tester.getTopLeft(_roomChoice(_melati)).dy,
        lessThan(tester.getTopLeft(_roomChoice(_mawar)).dy),
      );
    });

    testWidgets('keeps the order of the API when it is reversed', (
      tester,
    ) async {
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: FakeLeaseRepository(leases: makeTwoLeases().reversed.toList()),
      );

      expect(
        tester.getTopLeft(_roomChoice(_mawar)).dy,
        lessThan(tester.getTopLeft(_roomChoice(_melati)).dy),
      );
    });

    testWidgets('offers every lease when there are three', (tester) async {
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: FakeLeaseRepository(
          leases: [
            ...makeTwoLeases(),
            makeCurrentLease(
              tenantId: 't3',
              propertyId: 'p3',
              roomId: 'r3',
              propertyName: 'Kos Anggrek',
              roomNumber: '03',
            ),
          ],
        ),
      );

      expect(find.byType(RadioListTile), findsNWidgets(3));
      expect(_roomChoice('Kos Anggrek · Kamar 03'), findsOneWidget);
    });

    testWidgets('selects no room by default', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      _expectChoice(tester, _melati, selected: false);
      _expectChoice(tester, _mawar, selected: false);
      expect(find.text(_roomRequired), findsNothing);
    });

    testWidgets('selects only the room that is tapped', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      await _chooseRoom(tester, _mawar);

      _expectChoice(tester, _mawar, selected: true);
      _expectChoice(tester, _melati, selected: false);
    });

    testWidgets('moves the selection to another room', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());
      await _chooseRoom(tester, _mawar);

      await _chooseRoom(tester, _melati);

      _expectChoice(tester, _melati, selected: true);
      _expectChoice(tester, _mawar, selected: false);
    });

    testWidgets('choosing a room does not submit or navigate', (tester) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);

      await _chooseRoom(tester, _mawar);

      expect(repo.submitCalls, 0);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
    });

    testWidgets('sends nothing and names the missing room when none is '
        'chosen', (tester) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text(_roomRequired), findsOneWidget);
      expect(repo.submitCalls, 0);
      expect(repo.complaints, isEmpty);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
      expect(labeledTextField(tester, _label).controller!.text, _valid);
    });

    testWidgets('shows the room error and the description error together', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);

      await _submit(tester);

      expect(find.text(_roomRequired), findsOneWidget);
      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
    });

    testWidgets('a short description with a room is only a description '
        'error', (tester) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _melati);
      await _write(tester, 'pendek');

      await _submit(tester);

      expect(find.text(_roomRequired), findsNothing);
      expect(_error(tester), isNotNull);
      expect(repo.submitCalls, 0);
    });

    testWidgets('sends the room that was chosen', (tester) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);

      await _submit(tester);

      expect(repo.submitted, [_valid]);
      expect(repo.submittedRoomIds, ['r2']);
      expect(currentPath(tester), '/penyewa/keluhan/new-1');
    });

    testWidgets('sends the first room when it is chosen', (tester) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _melati);
      await _write(tester, _valid);

      await _submit(tester);

      expect(repo.submittedRoomIds, ['r1']);
    });

    testWidgets('sends the room chosen last', (tester) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _melati);
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);

      await _submit(tester);

      expect(repo.submittedRoomIds, ['r2']);
    });

    testWidgets('sends the room of the tenant record of a lease with the '
        'same room number', (tester) async {
      final repo = FakeComplaintRepository();
      await _open(
        tester,
        repo,
        leases: FakeLeaseRepository(
          leases: [
            makeCurrentLease(roomId: 'r1'),
            makeCurrentLease(
              tenantId: 't2',
              propertyId: 'p2',
              roomId: 'r5',
              propertyName: 'Kos Mawar',
            ),
          ],
        ),
      );
      await _chooseRoom(tester, 'Kos Mawar · Kamar 08');
      await _write(tester, _valid);

      await _submit(tester);

      expect(repo.submittedRoomIds, ['r5']);
    });

    testWidgets('clears the room error once a room is chosen and sent', (
      tester,
    ) async {
      final repo = FakeComplaintRepository();
      await _openWithTwoLeases(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);
      expect(find.text(_roomRequired), findsOneWidget);

      await _chooseRoom(tester, _melati);
      await _submit(tester);

      expect(find.text(_roomRequired), findsNothing);
      expect(repo.submittedRoomIds, ['r1']);
      expect(find.byType(ComplaintFormScreen), findsNothing);
    });

    testWidgets('keeps the chosen room after a network failure and sends it '
        'again', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network());
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);
      await _submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      _expectChoice(tester, _mawar, selected: true);

      await _submit(tester);

      expect(repo.submittedRoomIds, ['r2', 'r2']);
      expect(repo.complaints, hasLength(1));
    });

    testWidgets('shows a missing room from the API on the choice', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(
          const ApiFailure(code: 'ROOM_NOT_FOUND', field: 'roomId'),
        );
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text(messageOfCode('ROOM_NOT_FOUND')), findsOneWidget);
      expect(find.text(_roomRequired), findsNothing);
      expect(currentPath(tester), '/penyewa/keluhan/baru');
      expect(labeledTextField(tester, _label).controller!.text, _valid);
      _expectChoice(tester, _mawar, selected: true);
      expect(repo.complaints, isEmpty);
    });

    testWidgets('shows the API room error next to the choice, above the '
        'description', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(
          const ApiFailure(code: 'ROOM_NOT_FOUND', field: 'roomId'),
        );
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);
      await _submit(tester);

      final error = find.text(messageOfCode('ROOM_NOT_FOUND'));
      expect(
        tester.getTopLeft(error).dy,
        greaterThan(tester.getTopLeft(find.text(_roomGroup)).dy),
      );
      expect(
        tester.getTopLeft(error).dy,
        lessThan(tester.getTopLeft(find.text(_label)).dy),
      );
    });

    testWidgets('sends a corrected choice after the API room error', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(
          const ApiFailure(code: 'ROOM_NOT_FOUND', field: 'roomId'),
        );
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);
      await _submit(tester);

      await _chooseRoom(tester, _melati);
      await _submit(tester);

      expect(find.text(messageOfCode('ROOM_NOT_FOUND')), findsNothing);
      expect(repo.submittedRoomIds, ['r2', 'r1']);
    });

    testWidgets('shows a missing lease as a banner and keeps the room', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure(code: 'NO_ACTIVE_LEASE'));
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _melati);
      await _write(tester, _valid);

      await _submit(tester);

      expect(find.text(messageOfCode('NO_ACTIVE_LEASE')), findsOneWidget);
      _expectChoice(tester, _melati, selected: true);
    });

    testWidgets('disables sending while the complaint is saving', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.gate = Completer<void>();
      await _openWithTwoLeases(tester, repo);
      await _chooseRoom(tester, _melati);
      await _write(tester, _valid);

      await tapAndPump(tester, find.text(_send));

      expectBusy(tester);
      expect(repo.submitCalls, 1);
    });

    testWidgets('the room choices are at least 48 dp', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      final handle = tester.ensureSemantics();
      try {
        for (final label in [_melati, _mawar]) {
          final rect = tester.getSemantics(_roomChoice(label)).rect;
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.width, greaterThanOrEqualTo(48));
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('puts the room choice above the description', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      expect(
        tester.getTopLeft(find.text(_roomGroup)).dy,
        lessThan(tester.getTopLeft(find.text(_label)).dy),
      );
      expect(
        tester.getTopLeft(_roomChoice(_mawar)).dy,
        lessThan(tester.getTopLeft(find.text(_label)).dy),
      );
    });

    testWidgets('keeps the footer button reachable at large text', (
      tester,
    ) async {
      await _openWithTwoLeases(
        tester,
        FakeComplaintRepository(),
        largeText: true,
      );

      expectFooterAtBottom(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits the room error at large text', (tester) async {
      await _openWithTwoLeases(
        tester,
        FakeComplaintRepository(),
        largeText: true,
      );
      await _write(tester, _valid);
      await _submit(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_roomRequired), findsOneWidget);
    });

    testWidgets('meets the guidelines with no room chosen', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the room error', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());
      await _write(tester, _valid);
      await _submit(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a room chosen', (tester) async {
      await _openWithTwoLeases(tester, FakeComplaintRepository());
      await _chooseRoom(tester, _mawar);
      await _write(tester, _valid);

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('while the leases load', () {
    testWidgets('shows a labelled progress indicator and no form', (
      tester,
    ) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = Completer<void>();
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: leases,
        settle: false,
      );

      expectLoading(tester);
      expect(labeledField(_label), findsNothing);
      expect(appBarTitle('Ajukan Keluhan'), findsOneWidget);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('shows the form once they have loaded', (tester) async {
      final gate = Completer<void>();
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = gate;
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: leases,
        settle: false,
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(labeledField(_label), findsOneWidget);
      expect(find.text(_melati), findsOneWidget);
    });

    testWidgets('meets the guidelines', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = Completer<void>();
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: leases,
        settle: false,
      );

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('when the leases fail to load', () {
    testWidgets('shows the Indonesian message with a retry and no form', (
      tester,
    ) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.always = const ApiFailure.network();
      await _open(tester, FakeComplaintRepository(), leases: leases);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(labeledField(_label), findsNothing);
      expect(appBarTitle('Ajukan Keluhan'), findsOneWidget);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('fetches again and shows the form when retry is tapped', (
      tester,
    ) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.queue.add(const ApiFailure.network());
      await _open(tester, FakeComplaintRepository(), leases: leases);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(leases.calls, 2);
      expect(labeledField(_label), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('meets the guidelines', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.always = const ApiFailure.network();
      await _open(tester, FakeComplaintRepository(), leases: leases);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.always = const ApiFailure.network();
      await _open(
        tester,
        FakeComplaintRepository(),
        leases: leases,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('structure', () {
    testWidgets(
      'wraps the description in a LabeledField with its visible text',
      (tester) async {
        await _open(tester, FakeComplaintRepository());

        expect(labeledField(_label), findsOneWidget);
        expect(find.text(_label), findsOneWidget);
      },
    );

    testWidgets('draws no label inside the description field', (tester) async {
      await _open(tester, FakeComplaintRepository());

      expectNoDecorationLabels(tester);
    });

    testWidgets('puts the label above the field', (tester) async {
      await _open(tester, FakeComplaintRepository());

      final text = tester.getRect(find.text(_label));
      final input = tester.getRect(fieldLabeled(_label));
      expect(text.bottom, lessThanOrEqualTo(input.top));
    });

    testWidgets('reads the label once, on the field', (tester) async {
      await _open(tester, FakeComplaintRepository());

      expectFieldNode(tester, _label);
    });

    testWidgets('reads the helper text with the field', (tester) async {
      await _open(tester, FakeComplaintRepository());

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(fieldLabeled(_label));
        expect(announced(node), contains(_helper));
        expect(nodesAnnouncing(tester, _helper), hasLength(1));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('keeps the field error on the field node', (tester) async {
      await _open(tester, FakeComplaintRepository());
      await _submit(tester);

      expectFieldNode(tester, _label, error: _error(tester)!);
    });

    testWidgets('tapping the label focuses the field', (tester) async {
      await _open(tester, FakeComplaintRepository());

      await tester.tap(find.text(_label));
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: fieldLabeled(_label),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('puts the submit button in a pinned ActionFooter', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());

      expectPinnedFooter(tester, _send);
    });

    testWidgets('keeps the busy button inside the ActionFooter', (
      tester,
    ) async {
      final repo = FakeComplaintRepository()
        ..submitScript.gate = Completer<void>();
      await _open(tester, repo);
      await _write(tester, _valid);

      await tapAndPump(tester, find.text(_send));

      expect(
        find.descendant(
          of: find.byType(ActionFooter),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expectBusy(tester);
    });

    testWidgets('keeps the footer at the bottom at large text', (tester) async {
      await _open(tester, FakeComplaintRepository(), largeText: true);

      expectFooterAtBottom(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester)>{
      'initial': (tester) => _open(tester, FakeComplaintRepository()),
      'with a field error': (tester) async {
        await _open(tester, FakeComplaintRepository());
        await _submit(tester);
      },
      'with a banner': (tester) async {
        final repo = FakeComplaintRepository()
          ..submitScript.queue.add(const ApiFailure(code: 'NO_ACTIVE_LEASE'));
        await _open(tester, repo);
        await _write(tester, _valid);
        await _submit(tester);
      },
      'with a text': (tester) async {
        await _open(tester, FakeComplaintRepository());
        await _write(tester, _valid);
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines ${entry.key}', (tester) async {
        await entry.value(tester);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines while saving', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.gate = Completer<void>();
      await _open(tester, repo);
      await _write(tester, _valid);
      await tapAndPump(tester, find.text(_send));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size initially', (tester) async {
      await _open(tester, FakeComplaintRepository(), largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a field error', (tester) async {
      await _open(tester, FakeComplaintRepository(), largeText: true);
      await _submit(tester);

      expect(tester.takeException(), isNull);
      expect(_error(tester), isNotNull);
    });

    testWidgets('fits at large text size with a banner', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure(code: 'NO_ACTIVE_LEASE'));
      await _open(tester, repo, largeText: true);
      await _write(tester, _valid);
      await _submit(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with a long text', (tester) async {
      await _open(tester, FakeComplaintRepository(), largeText: true);

      await _write(tester, 'Keran bocor. ' * 30);

      expect(tester.takeException(), isNull);
    });
  });
}
