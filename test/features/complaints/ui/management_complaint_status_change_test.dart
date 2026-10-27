import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

const _markInProgress = 'Tandai Diproses';
const _markDone = 'Tandai Selesai';
const _inProgressTitle = 'Tandai keluhan sebagai Diproses?';
const _doneTitle = 'Tandai keluhan sebagai Selesai?';
const _confirmInProgress = 'Ya, Diproses';
const _confirmDone = 'Ya, Selesai';
const _cancel = 'Batal';
const _noteLabel = 'Catatan penanganan (opsional)';
const _noteHelper = 'Terlihat oleh penyewa';
const _conflictMessage = 'Status keluhan sudah diubah oleh pengguna lain.';
const _note = 'Tukang datang besok pagi.';
const _roles = [UserRole.owner, UserRole.manager];

const _notNext = ApiFailure(code: 'COMPLAINT_STATUS_NOT_NEXT', field: 'status');

Complaint _complaint(ComplaintStatus status) => makeComplaint(
  status: status,
  classificationState: ComplaintClassificationState.notClassified,
);

FakeComplaintRepository _repo([ComplaintStatus? status]) =>
    FakeComplaintRepository(
      complaints: [_complaint(status ?? ComplaintStatus.new_)],
    );

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  UserRole role = UserRole.owner,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  repo,
  role: role,
  path: '/keluhan/c1',
  largeText: largeText,
);

/// The modal sheet or dialog that asks to confirm the status change.
Finder _sheet() => find.byWidgetPredicate(
  (widget) => widget is BottomSheet || widget is Dialog,
  description: 'the status change sheet',
);

Finder _inSheet(Finder finder) =>
    find.descendant(of: _sheet(), matching: finder);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: anyButton());

Finder _field() => _inSheet(find.byType(TextField));

/// The sentence that tells the tenant is informed and the step is final.
Finder _explanation() => _inSheet(
  find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data != _noteHelper &&
        widget.data!.contains('penyewa') &&
        widget.data!.contains('tidak'),
    description: 'the explanation that the tenant is told and it is final',
  ),
);

ComplaintStatus _stepsStatus(WidgetTester tester) =>
    tester.widget<ComplaintStatusSteps>(statusSteps()).status;

Future<void> _openSheet(WidgetTester tester, String action) async {
  await tester.tap(_button(action));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester, String label) async {
  await tester.tap(_button(label));
  await tester.pumpAndSettle();
}

/// Pumps without settling, so a message that dismisses itself after a few
/// seconds is still on screen.
Future<void> _pumpBriefly(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('the status action', () {
    testWidgets('a new complaint offers Tandai Diproses only', (tester) async {
      await _open(tester, _repo());

      expect(_button(_markInProgress), findsOneWidget);
      expect(find.text(_markDone), findsNothing);
      expect(find.text('Ubah Status'), findsNothing);
    });

    testWidgets('a complaint in progress offers Tandai Selesai only', (
      tester,
    ) async {
      await _open(tester, _repo(ComplaintStatus.inProgress));

      expect(_button(_markDone), findsOneWidget);
      expect(find.text(_markInProgress), findsNothing);
    });

    testWidgets('a done complaint offers no status action at all', (
      tester,
    ) async {
      await _open(tester, _repo(ComplaintStatus.done));

      expect(find.text(_markInProgress), findsNothing);
      expect(find.text(_markDone), findsNothing);
      expect(actionButtons(), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    for (final role in _roles) {
      testWidgets('a $role sees the action', (tester) async {
        await _open(tester, _repo(), role: role);

        expect(_button(_markInProgress), findsOneWidget);
      });
    }

    for (final status in [ComplaintStatus.new_, ComplaintStatus.inProgress]) {
      testWidgets('the action for $status is at least 48 dp', (tester) async {
        await _open(tester, _repo(status));

        expectTargetSize(
          tester,
          status == ComplaintStatus.new_ ? _markInProgress : _markDone,
        );
      });
    }

    testWidgets('shows no action while the complaint is loading', (
      tester,
    ) async {
      final repo = _repo()..getScript.gate = Completer<void>();
      await pumpComplaintApp(
        tester,
        repo,
        role: UserRole.owner,
        path: '/keluhan/c1',
        settle: false,
      );

      expect(find.text(_markInProgress), findsNothing);
    });

    testWidgets('shows no action when the complaint failed to load', (
      tester,
    ) async {
      final repo = _repo()..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.text(_markInProgress), findsNothing);
      expect(find.text(_markDone), findsNothing);
    });

    testWidgets('opening the sheet calls nothing', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      await _openSheet(tester, _markInProgress);

      expect(repo.statusCalls, 0);
    });
  });

  group('the tenant', () {
    for (final status in ComplaintStatus.values) {
      testWidgets('has no status action on a $status complaint', (
        tester,
      ) async {
        await pumpComplaintApp(
          tester,
          _repo(status),
          path: '/penyewa/keluhan/c1',
        );

        expect(find.textContaining('Keran air di kamar mandi'), findsOneWidget);
        expect(find.text(_markInProgress), findsNothing);
        expect(find.text(_markDone), findsNothing);
        expect(find.text('Ubah Status'), findsNothing);
      });
    }
  });

  group('the sheet', () {
    testWidgets('asks to mark a new complaint as Diproses', (tester) async {
      await _open(tester, _repo());

      await _openSheet(tester, _markInProgress);

      expect(_sheet(), findsOneWidget);
      expect(_inSheet(find.text(_inProgressTitle)), findsOneWidget);
      expect(_inSheet(find.text(_confirmInProgress)), findsOneWidget);
      expect(_inSheet(find.text(_cancel)), findsOneWidget);
      expect(_inSheet(find.text(_confirmDone)), findsNothing);
    });

    testWidgets('asks to mark a complaint in progress as Selesai', (
      tester,
    ) async {
      await _open(tester, _repo(ComplaintStatus.inProgress));

      await _openSheet(tester, _markDone);

      expect(_inSheet(find.text(_doneTitle)), findsOneWidget);
      expect(_inSheet(find.text(_confirmDone)), findsOneWidget);
      expect(_inSheet(find.text(_cancel)), findsOneWidget);
      expect(_inSheet(find.text(_confirmInProgress)), findsNothing);
    });

    for (final status in [ComplaintStatus.new_, ComplaintStatus.inProgress]) {
      testWidgets('says the tenant is told and the step is final for $status', (
        tester,
      ) async {
        await _open(tester, _repo(status));

        await _openSheet(
          tester,
          status == ComplaintStatus.new_ ? _markInProgress : _markDone,
        );

        expect(_explanation(), findsOneWidget);
      });
    }

    testWidgets('has an empty multiline note field labelled as optional', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _openSheet(tester, _markInProgress);

      expect(_field(), findsOneWidget);
      expect(_inSheet(find.text(_noteLabel)), findsOneWidget);
      final field = tester.widget<TextField>(_field());
      expect(field.controller?.text ?? '', isEmpty);
      expect(field.maxLines, anyOf(isNull, greaterThan(1)));
    });

    testWidgets('tells the user that the note is visible to the tenant', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _openSheet(tester, _markInProgress);

      expect(_inSheet(find.text(_noteHelper)), findsOneWidget);
    });

    testWidgets('labels the note field for assistive technology', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, _repo());
        await _openSheet(tester, _markInProgress);

        expect(find.bySemanticsLabel(_noteLabel), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('both buttons are at least 48 dp', (tester) async {
      await _open(tester, _repo());

      await _openSheet(tester, _markInProgress);

      expectTargetSize(tester, _cancel);
      expectTargetSize(tester, _confirmInProgress);
    });

    testWidgets('is shown for a manager too', (tester) async {
      await _open(tester, _repo(), role: UserRole.manager);

      await _openSheet(tester, _markInProgress);

      expect(_inSheet(find.text(_confirmInProgress)), findsOneWidget);
    });
  });

  group('cancelling', () {
    testWidgets('Batal closes the sheet and calls nothing', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.statusCalls, 0);
      expect(repo.complaints.single.status, ComplaintStatus.new_);
      expect(_stepsStatus(tester), ComplaintStatus.new_);
      expect(_button(_markInProgress), findsOneWidget);
    });

    testWidgets('Batal calls nothing even after a note was typed', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(repo.statusCalls, 0);
      expect(find.text(_note), findsNothing);
    });

    testWidgets('tapping outside the sheet closes it without a call', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.statusCalls, 0);
    });

    testWidgets('reopening after a cancel shows an empty note field', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);
      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      await _openSheet(tester, _markInProgress);

      expect(tester.widget<TextField>(_field()).controller?.text ?? '', '');
    });

    testWidgets('does not refresh the complaint list', (tester) async {
      final repo = _repo();
      await pumpComplaintApp(tester, repo, role: UserRole.owner);
      await tester.tap(
        find.text('Keran air di kamar mandi bocor sejak kemarin.'),
      );
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/keluhan/c1');
      await _openSheet(tester, _markInProgress);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
    });
  });

  group('confirming', () {
    testWidgets('marks a new complaint as Diproses with the entered note', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);

      await _confirm(tester, _confirmInProgress);

      expect(repo.statusCalls, 1);
      expect(repo.statusChanged.single.id, 'c1');
      expect(repo.statusChanged.single.status, ComplaintStatus.inProgress);
      expect(repo.statusChanged.single.handlingNote, _note);
    });

    testWidgets('marks a complaint in progress as Selesai', (tester) async {
      final repo = _repo(ComplaintStatus.inProgress);
      await _open(tester, repo);
      await _openSheet(tester, _markDone);
      await tester.enterText(_field(), 'Sudah diperbaiki.');

      await _confirm(tester, _confirmDone);

      expect(repo.statusCalls, 1);
      expect(repo.statusChanged.single.status, ComplaintStatus.done);
      expect(repo.statusChanged.single.handlingNote, 'Sudah diperbaiki.');
    });

    testWidgets('sends no note when the field is left empty', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);

      await _confirm(tester, _confirmInProgress);

      expect(repo.statusChanged.single.handlingNote, isNull);
    });

    testWidgets('sends no note when the field holds only spaces', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), '   ');

      await _confirm(tester, _confirmInProgress);

      expect(repo.statusChanged.single.handlingNote, isNull);
    });

    testWidgets('closes the sheet and moves the steps forward', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);

      await _confirm(tester, _confirmInProgress);

      expect(_sheet(), findsNothing);
      expect(_stepsStatus(tester), ComplaintStatus.inProgress);
      expect(
        find.descendant(of: statusSteps(), matching: find.text('Diproses')),
        findsOneWidget,
      );
    });

    testWidgets('offers the next action after the change', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);

      await _confirm(tester, _confirmInProgress);

      expect(_button(_markDone), findsOneWidget);
      expect(find.text(_markInProgress), findsNothing);
    });

    testWidgets('shows the new status change with its note in the history', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);

      await _confirm(tester, _confirmInProgress);

      expect(find.text(_note), findsOneWidget);
      expect(find.textContaining('20 Okt 2026'), findsOneWidget);
    });

    testWidgets('offers no action once the complaint is done', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await _confirm(tester, _confirmInProgress);
      await _openSheet(tester, _markDone);
      expect(_inSheet(find.text(_doneTitle)), findsOneWidget);

      await _confirm(tester, _confirmDone);

      expect(repo.statusChanged.map((c) => c.status), [
        ComplaintStatus.inProgress,
        ComplaintStatus.done,
      ]);
      expect(_stepsStatus(tester), ComplaintStatus.done);
      expect(find.text(_markInProgress), findsNothing);
      expect(find.text(_markDone), findsNothing);
      expect(actionButtons(), findsNothing);
    });

    testWidgets('refreshes the complaint list', (tester) async {
      final repo = _repo();
      await pumpComplaintApp(tester, repo, role: UserRole.owner);
      await tester.tap(
        find.text('Keran air di kamar mandi bocor sejak kemarin.'),
      );
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/keluhan/c1');
      expect(repo.listCalls, 1);
      await _openSheet(tester, _markInProgress);

      await _confirm(tester, _confirmInProgress);

      expect(repo.listCalls, 2);
    });

    testWidgets('a manager can change the status too', (tester) async {
      final repo = _repo();
      await _open(tester, repo, role: UserRole.manager);
      await _openSheet(tester, _markInProgress);

      await _confirm(tester, _confirmInProgress);

      expect(repo.statusCalls, 1);
      expect(_stepsStatus(tester), ComplaintStatus.inProgress);
    });

    testWidgets('shows progress and sends once while the call is in flight', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..changeStatusScript.gate = gate;
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);

      await tester.tap(_button(_confirmInProgress));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_sheet(), findsOneWidget);
      expect(_inSheet(find.byType(CircularProgressIndicator)), findsOneWidget);
      final confirm = _button(_confirmInProgress);
      if (confirm.evaluate().isNotEmpty) {
        final button = tester.widget<ButtonStyleButton>(confirm);
        expect(button.onPressed, isNull);
        await tester.tap(confirm, warnIfMissed: false);
        await tester.pump();
      }
      expect(repo.statusCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.statusCalls, 1);
      expect(_sheet(), findsNothing);
      expect(_stepsStatus(tester), ComplaintStatus.inProgress);
    });
  });

  group('a conflict', () {
    Future<FakeComplaintRepository> conflict(WidgetTester tester) async {
      final repo = _repo();
      repo.changeStatusScript.queue.add(_notNext);
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);
      repo.complaints[0] = makeComplaint(
        status: ComplaintStatus.inProgress,
        classificationState: ComplaintClassificationState.notClassified,
        statusChanges: [
          statusChange(
            ComplaintStatus.inProgress,
            DateTime.utc(2026, 10, 19, 9),
            note: 'Dikerjakan pengguna lain.',
          ),
        ],
      );
      await tester.tap(_button(_confirmInProgress));
      await _pumpBriefly(tester);
      return repo;
    }

    testWidgets('closes the sheet', (tester) async {
      await conflict(tester);

      expect(_sheet(), findsNothing);
    });

    testWidgets('shows the Indonesian conflict message', (tester) async {
      await conflict(tester);

      expect(find.text(_conflictMessage), findsOneWidget);
      expect(find.textContaining('COMPLAINT_STATUS_NOT_NEXT'), findsNothing);
    });

    testWidgets('reloads the detail so it shows the current status', (
      tester,
    ) async {
      final repo = await conflict(tester);

      expect(repo.getCalls, 2);
      expect(_stepsStatus(tester), ComplaintStatus.inProgress);
      expect(find.text('Dikerjakan pengguna lain.'), findsOneWidget);
      expect(_button(_markDone), findsOneWidget);
      expect(find.text(_markInProgress), findsNothing);
    });

    testWidgets('does not send the change again', (tester) async {
      final repo = await conflict(tester);

      expect(repo.statusCalls, 1);
    });
  });

  group('while the change is in flight', () {
    /// Opens the sheet and confirms with the request held by [gate].
    Future<FakeComplaintRepository> inFlight(
      WidgetTester tester,
      Completer<void> gate, {
      ApiFailure? failure,
    }) async {
      final repo = _repo()..changeStatusScript.gate = gate;
      if (failure != null) repo.changeStatusScript.queue.add(failure);
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.tap(_button(_confirmInProgress));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.statusCalls, 1);
      return repo;
    }

    Future<void> tryBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    Future<void> tryBarrier(WidgetTester tester) async {
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    Future<void> tryDrag(WidgetTester tester) async {
      await tester.drag(_sheet(), const Offset(0, 600), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    final attempts = <String, Future<void> Function(WidgetTester)>{
      'the Android back action': tryBack,
      'a tap on the barrier': tryBarrier,
      'a drag down': tryDrag,
    };

    for (final entry in attempts.entries) {
      testWidgets('${entry.key} leaves the sheet open', (tester) async {
        final gate = Completer<void>();
        final repo = await inFlight(tester, gate);

        await entry.value(tester);

        expect(_sheet(), findsOneWidget);
        expect(
          _inSheet(find.byType(CircularProgressIndicator)),
          findsOneWidget,
        );
        expect(repo.statusCalls, 1);
        expect(_stepsStatus(tester), ComplaintStatus.new_);

        gate.complete();
        await tester.pumpAndSettle();

        expect(_sheet(), findsNothing);
        expect(repo.statusCalls, 1);
        expect(_stepsStatus(tester), ComplaintStatus.inProgress);
        expect(_button(_markDone), findsOneWidget);
      });

      testWidgets('${entry.key} cannot dismiss it before a conflict ends it', (
        tester,
      ) async {
        final gate = Completer<void>();
        final repo = await inFlight(tester, gate, failure: _notNext);
        repo.complaints[0] = makeComplaint(
          status: ComplaintStatus.inProgress,
          classificationState: ComplaintClassificationState.notClassified,
        );

        await entry.value(tester);

        expect(_sheet(), findsOneWidget);
        expect(find.text(_conflictMessage), findsNothing);

        gate.complete();
        await _pumpBriefly(tester);

        expect(_sheet(), findsNothing);
        expect(find.text(_conflictMessage), findsOneWidget);
        expect(repo.getCalls, 2);
        expect(_stepsStatus(tester), ComplaintStatus.inProgress);
      });

      testWidgets('${entry.key} dismisses the sheet again after a failure', (
        tester,
      ) async {
        final gate = Completer<void>();
        final repo = await inFlight(
          tester,
          gate,
          failure: const ApiFailure.network(),
        );
        gate.complete();
        await tester.pumpAndSettle();
        expect(
          _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
          findsOneWidget,
        );

        await entry.value(tester);

        expect(_sheet(), findsNothing);
        expect(repo.statusCalls, 1);
        expect(_stepsStatus(tester), ComplaintStatus.new_);
      });
    }
  });

  group('the status card', () {
    testWidgets('is a live region so a screen reader announces changes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, _repo(ComplaintStatus.inProgress));

        final card = tester.getSemantics(sectionCardOf('Status'));
        final chain = <SemanticsNode>[];
        for (
          SemanticsNode? node = tester.getSemantics(statusSteps());
          node != null;
          node = node.parent
        ) {
          chain.add(node);
        }
        final cardAt = chain.indexWhere((node) => node.id == card.id);
        final live = chain.indexWhere(
          (node) => containsSemantics(isLiveRegion: true).matches(node, {}),
        );

        expect(live, isNonNegative, reason: 'no live region around the steps');
        if (cardAt >= 0) {
          expect(live, lessThanOrEqualTo(cardAt));
        }
      } finally {
        handle.dispose();
      }
    });
  });

  group('another failure', () {
    const failures = {
      'a network failure': ApiFailure.network(),
      'a forbidden response': ApiFailure(code: 'FORBIDDEN'),
      'a missing complaint': ApiFailure(code: 'COMPLAINT_NOT_FOUND'),
      'a server error': ApiFailure(code: 'INTERNAL_ERROR'),
      'an unknown code': ApiFailure(code: 'SOMETHING_NEW'),
    };

    for (final entry in failures.entries) {
      testWidgets('${entry.key} keeps the sheet open with its message', (
        tester,
      ) async {
        final repo = _repo()..changeStatusScript.queue.add(entry.value);
        await _open(tester, repo);
        await _openSheet(tester, _markInProgress);

        await _confirm(tester, _confirmInProgress);

        expect(_sheet(), findsOneWidget);
        expect(
          _inSheet(find.text(messageOfCode(entry.value.code))),
          findsOneWidget,
        );
        expect(_inSheet(find.text(_conflictMessage)), findsNothing);
      });
    }

    testWidgets('changes nothing and keeps the typed note', (tester) async {
      final repo = _repo()
        ..changeStatusScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);
      final listCallsBefore = repo.listCalls;

      await _confirm(tester, _confirmInProgress);

      expect(repo.complaints.single.status, ComplaintStatus.new_);
      expect(_stepsStatus(tester), ComplaintStatus.new_);
      expect(tester.widget<TextField>(_field()).controller?.text, _note);
      expect(repo.listCalls, listCallsBefore);
    });

    testWidgets('lets the user retry and then succeeds', (tester) async {
      final repo = _repo()
        ..changeStatusScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);
      await _confirm(tester, _confirmInProgress);

      await _confirm(tester, _confirmInProgress);

      expect(repo.statusCalls, 2);
      expect(repo.statusChanged.last.handlingNote, _note);
      expect(_sheet(), findsNothing);
      expect(_stepsStatus(tester), ComplaintStatus.inProgress);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('the sheet can still be cancelled', (tester) async {
      final repo = _repo()
        ..changeStatusScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await _confirm(tester, _confirmInProgress);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.statusCalls, 1);
      expect(_stepsStatus(tester), ComplaintStatus.new_);
    });

    testWidgets('a failure of Selesai keeps the sheet open', (tester) async {
      final repo = _repo(ComplaintStatus.inProgress)
        ..changeStatusScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _openSheet(tester, _markDone);

      await _confirm(tester, _confirmDone);

      expect(_inSheet(find.text(_doneTitle)), findsOneWidget);
      expect(
        _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );
    });
  });

  group('accessibility', () {
    final screens = <String, FakeComplaintRepository Function()>{
      'with the action': () => _repo(),
      'with the action for Selesai': () => _repo(ComplaintStatus.inProgress),
      'done, without an action': () => _repo(ComplaintStatus.done),
    };

    for (final entry in screens.entries) {
      for (final role in _roles) {
        testWidgets('meets the guidelines ${entry.key} for a $role', (
          tester,
        ) async {
          await _open(tester, entry.value(), role: role);

          await expectMeetsA11yGuidelines(tester);
        });
      }

      testWidgets('fits at large text size ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    final sheets = <String, (ComplaintStatus, String)>{
      'for Diproses': (ComplaintStatus.new_, _markInProgress),
      'for Selesai': (ComplaintStatus.inProgress, _markDone),
    };

    for (final entry in sheets.entries) {
      testWidgets('meets the guidelines with the sheet open ${entry.key}', (
        tester,
      ) async {
        await _open(tester, _repo(entry.value.$1));
        await _openSheet(tester, entry.value.$2);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size with the sheet open ${entry.key}', (
        tester,
      ) async {
        await _open(tester, _repo(entry.value.$1), largeText: true);
        await _openSheet(tester, entry.value.$2);

        expect(tester.takeException(), isNull);
        expect(_sheet(), findsOneWidget);
      });
    }

    testWidgets('meets the guidelines with the sheet showing an error', (
      tester,
    ) async {
      final repo = _repo()
        ..changeStatusScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.enterText(_field(), _note);
      await _confirm(tester, _confirmInProgress);
      expect(
        _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the sheet showing an error', (
      tester,
    ) async {
      final repo = _repo()
        ..changeStatusScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, largeText: true);
      await _openSheet(tester, _markInProgress);
      await _confirm(tester, _confirmInProgress);

      expect(tester.takeException(), isNull);
      expect(
        _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );
    });

    testWidgets('meets the guidelines while the change is in flight', (
      tester,
    ) async {
      final repo = _repo()..changeStatusScript.gate = Completer<void>();
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.tap(_button(_confirmInProgress));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines after the conflict message', (
      tester,
    ) async {
      final repo = _repo();
      repo.changeStatusScript.queue.add(_notNext);
      await _open(tester, repo);
      await _openSheet(tester, _markInProgress);
      await tester.tap(_button(_confirmInProgress));
      await _pumpBriefly(tester);
      expect(find.text(_conflictMessage), findsOneWidget);

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
