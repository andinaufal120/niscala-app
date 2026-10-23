import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

const _label = 'Deskripsi keluhan (wajib)';
const _send = 'Kirim Keluhan';
const _valid = 'Keran air di kamar mandi bocor.';

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  repo,
  path: '/penyewa/keluhan/baru',
  largeText: largeText,
);

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text(_send));

Future<void> _write(WidgetTester tester, String text) =>
    type(tester, _label, text);

String? _error(WidgetTester tester) => fieldError(tester, _label);

void main() {
  group('layout', () {
    testWidgets('is titled and shows the labelled description field', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());

      expect(find.byType(ComplaintFormScreen), findsOneWidget);
      expect(appBarTitle('Ajukan Keluhan'), findsOneWidget);
      expect(textField(tester, _label).decoration?.labelText, _label);
      expect(find.text(_send), findsOneWidget);
    });

    testWidgets('starts empty without an error and states the minimum', (
      tester,
    ) async {
      await _open(tester, FakeComplaintRepository());

      expect(textField(tester, _label).controller!.text, isEmpty);
      expect(_error(tester), isNull);
      expect(textField(tester, _label).decoration?.helperText, contains('10'));
    });

    testWidgets('accepts several lines', (tester) async {
      await _open(tester, FakeComplaintRepository());

      final input = textField(tester, _label);
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

      await tester.tap(field(_label));
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
      expect(_error(tester), isNot(errorMessage('UNKNOWN')));
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
      expect(statusBadge('Baru'), findsOneWidget);
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
      expect(field(_label), findsNothing);
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

      expect(_error(tester), errorMessage('VALIDATION_FAILED'));
      expect(textField(tester, _label).controller!.text, _valid);
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
        expect(textField(tester, _label).controller!.text, _valid);
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

      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(textField(tester, _label).controller!.text, _valid);
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

      expectLiveRegion(tester, errorMessage('NETWORK_ERROR'));
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
      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('the banner goes away on the next submit', (tester) async {
      final repo = FakeComplaintRepository()
        ..submitScript.queue.add(const ApiFailure.network())
        ..submitScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));
      await _open(tester, repo);
      await _write(tester, _valid);
      await _submit(tester);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);

      await _submit(tester);

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
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

      expect(find.text(errorMessage('NETWORK_ERROR')), findsNothing);
      expect(_error(tester), isNotNull);
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
