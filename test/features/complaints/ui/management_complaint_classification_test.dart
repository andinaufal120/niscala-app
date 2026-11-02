import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'complaint_ui_helpers.dart';

const _change = 'Ubah';
const _classify = 'Klasifikasikan';
const _sheetTitle = 'Klasifikasi keluhan';
const _save = 'Simpan';
const _cancel = 'Batal';
const _categoryLabel = 'Kategori';
const _urgencyLabel = 'Urgensi';
const _correctionNote = 'Koreksi Anda disimpan bersama hasil asli AI.';
const _invalidCategoryMessage =
    'Kategori tidak valid. Pilih kategori dari daftar.';
const _classifier = 'Siti Pemilik';
const _description = 'Keran air di kamar mandi bocor sejak kemarin.';
const _roles = [UserRole.owner, UserRole.manager];

const _urgencyLabels = {
  ComplaintUrgency.low: 'Rendah',
  ComplaintUrgency.medium: 'Sedang',
  ComplaintUrgency.high: 'Tinggi',
};

const _invalidCategory = ApiFailure(
  code: 'COMPLAINT_CATEGORY_INVALID',
  field: 'category',
);

/// An AI classification: Pipa dan air, Tinggi.
Complaint _ai({ComplaintStatus status = ComplaintStatus.new_}) => makeComplaint(
  status: status,
  classification: makeComplaintClassification(
    category: 'Pipa dan air',
    urgency: ComplaintUrgency.high,
    suggestedAction: 'Panggil tukang ledeng.',
  ),
);

/// A manual classification: Listrik, Rendah, replacing an AI result when
/// [original] is true.
Complaint _manual({bool original = false}) => makeComplaint(
  classification: makeComplaintClassification(
    category: 'Listrik',
    urgency: ComplaintUrgency.low,
    suggestedAction: null,
    classifiedByName: _classifier,
    originalAiClassification: original
        ? AiComplaintClassification(
            category: 'Pipa dan air',
            suggestedAction: 'Panggil tukang ledeng.',
            urgency: ComplaintUrgency.high,
          )
        : null,
  ),
);

Complaint _state(
  ComplaintClassificationState state, {
  ComplaintStatus status = ComplaintStatus.new_,
}) => makeComplaint(status: status, classificationState: state);

Complaint _withheld() => makeComplaint(classificationWithheld: true);

FakeComplaintRepository _repo(Complaint complaint) =>
    FakeComplaintRepository(complaints: [complaint]);

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

/// Opens the complaint from the list, so the list is read behind it.
Future<void> _openFromList(
  WidgetTester tester,
  FakeComplaintRepository repo,
) async {
  await pumpComplaintApp(tester, repo, role: UserRole.owner);
  await tester.tap(find.text(_description));
  await tester.pumpAndSettle();
  expect(currentPath(tester), '/keluhan/c1');
}

/// The modal sheet or dialog that collects the classification.
Finder _sheet() => find.byWidgetPredicate(
  (widget) => widget is BottomSheet || widget is Dialog,
  description: 'the classification sheet',
);

Finder _inSheet(Finder finder) =>
    find.descendant(of: _sheet(), matching: finder);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: anyButton());

String? _textOf(Widget widget) =>
    widget is Text ? widget.data ?? widget.textSpan?.toPlainText() : null;

/// The visible label of a sheet field: [name], optionally marked as required.
Finder _fieldLabel(String name) => _inSheet(
  find.byWidgetPredicate((widget) {
    final text = _textOf(widget);
    return text == name || text == '$name (wajib)';
  }, description: 'the label $name'),
);

/// The category selector of the sheet: a dropdown of any Material kind.
Finder _categorySelector() => _inSheet(
  find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField ||
        widget is DropdownButton ||
        widget is DropdownMenu,
    description: 'the category dropdown',
  ),
);

/// Whether the closed category selector shows [category] as its value.
Finder _categoryShown(String category) => _inSheet(
  find.byWidgetPredicate((widget) {
    if (widget is Text) return _textOf(widget) == category;
    if (widget is EditableText) return widget.controller.text == category;
    return false;
  }, description: 'the selected category $category'),
);

ButtonStyleButton _saveButton(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(_button(_save));

bool _canSave(WidgetTester tester) => _saveButton(tester).onPressed != null;

Future<void> _openSheet(WidgetTester tester, String action) async {
  await tester.tap(_button(action));
  await tester.pumpAndSettle();
}

Future<void> _chooseCategory(WidgetTester tester, String category) async {
  await tester.tap(_categorySelector().first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(category).last);
  await tester.pumpAndSettle();
}

Future<void> _chooseUrgency(
  WidgetTester tester,
  ComplaintUrgency urgency,
) async {
  await tester.tap(_inSheet(find.text(_urgencyLabels[urgency]!)));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(_button(_save));
  await tester.pumpAndSettle();
}

/// Expects exactly [selected] of the urgency radios to be checked, or none.
void _expectUrgency(WidgetTester tester, ComplaintUrgency? selected) {
  final handle = tester.ensureSemantics();
  try {
    for (final entry in _urgencyLabels.entries) {
      expect(
        tester.getSemantics(_inSheet(find.text(entry.value))),
        isSemantics(hasCheckedState: true, isChecked: entry.key == selected),
        reason:
            '${entry.value} is ${entry.key == selected ? '' : 'not '}'
            'checked',
      );
    }
  } finally {
    handle.dispose();
  }
}

/// Opens the sheet of [repo]'s complaint from its card and fills in
/// [category] and [urgency].
Future<void> _fill(
  WidgetTester tester,
  String action, {
  String category = 'Listrik',
  ComplaintUrgency urgency = ComplaintUrgency.medium,
}) async {
  await _openSheet(tester, action);
  await _chooseCategory(tester, category);
  await _chooseUrgency(tester, urgency);
}

/// Pumps without settling, so a spinner or a self-dismissing message is still
/// on screen.
Future<void> _pumpFor(WidgetTester tester, int milliseconds) async {
  for (var i = 0; i < milliseconds ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _card(Finder finder) =>
    find.descendant(of: sectionCardOf('Klasifikasi'), matching: finder);

void main() {
  group('the classification actions', () {
    for (final role in _roles) {
      testWidgets('a $role sees Ubah on an AI classification', (tester) async {
        await _open(tester, _repo(_ai()), role: role);

        expect(_button(_change), findsOneWidget);
        expect(find.text(_classify), findsNothing);
      });

      testWidgets('a $role sees Klasifikasikan on a state', (tester) async {
        await _open(
          tester,
          _repo(_state(ComplaintClassificationState.notClassified)),
          role: role,
        );

        expect(_button(_classify), findsOneWidget);
        expect(find.text(_change), findsNothing);
      });
    }

    testWidgets('Ubah is offered on a manual classification', (tester) async {
      await _open(tester, _repo(_manual()));

      expect(_button(_change), findsOneWidget);
    });

    testWidgets('Ubah is offered on a manual classification with an original', (
      tester,
    ) async {
      await _open(tester, _repo(_manual(original: true)));

      expect(_button(_change), findsOneWidget);
    });

    for (final state in ComplaintClassificationState.values) {
      testWidgets('Klasifikasikan is offered while the state is $state', (
        tester,
      ) async {
        await _open(tester, _repo(_state(state)));

        expect(_button(_classify), findsOneWidget);
        expect(find.text(_change), findsNothing);
      });
    }

    testWidgets('Klasifikasikan is offered while classifying beside Segarkan', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.classifying)),
      );

      expect(_button(_classify), findsOneWidget);
      expect(_button('Segarkan'), findsOneWidget);
    });

    testWidgets('Klasifikasikan is offered when the AI result is withheld', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      expect(_button(_classify), findsOneWidget);
      expect(find.text(_change), findsNothing);
    });

    testWidgets('Ubah sits inside the Klasifikasi card', (tester) async {
      await _open(tester, _repo(_ai()));

      expect(_card(find.text(_change)), findsOneWidget);
    });

    testWidgets('Klasifikasikan sits inside the Klasifikasi card', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      expect(_card(find.text(_classify)), findsOneWidget);
    });

    for (final status in ComplaintStatus.values) {
      testWidgets('Ubah is still offered when the complaint is $status', (
        tester,
      ) async {
        await _open(tester, _repo(_ai(status: status)));

        expect(_button(_change), findsOneWidget);
      });

      testWidgets('Klasifikasikan is still offered when it is $status', (
        tester,
      ) async {
        await _open(
          tester,
          _repo(
            _state(ComplaintClassificationState.notClassified, status: status),
          ),
        );

        expect(_button(_classify), findsOneWidget);
      });
    }

    for (final action in [_change, _classify]) {
      testWidgets('$action is at least 48 dp', (tester) async {
        await _open(
          tester,
          _repo(
            action == _change
                ? _ai()
                : _state(ComplaintClassificationState.notClassified),
          ),
        );

        expectTargetSize(tester, action);
      });
    }

    testWidgets('are not shown while the complaint is loading', (tester) async {
      final repo = _repo(_ai())..getScript.gate = Completer<void>();
      await pumpComplaintApp(
        tester,
        repo,
        role: UserRole.owner,
        path: '/keluhan/c1',
        settle: false,
      );

      expect(find.text(_change), findsNothing);
      expect(find.text(_classify), findsNothing);
    });

    testWidgets('are not shown when the complaint failed to load', (
      tester,
    ) async {
      final repo = _repo(_ai())..getScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.text(_change), findsNothing);
      expect(find.text(_classify), findsNothing);
    });

    testWidgets('opening the sheet calls nothing', (tester) async {
      final repo = _repo(_ai());
      await _open(tester, repo);

      await _openSheet(tester, _change);

      expect(repo.classifyCalls, 0);
    });
  });

  group('the tenant', () {
    final complaints = {
      'an AI classification': _ai(),
      'a manual classification': _manual(original: true),
      'a state': _state(ComplaintClassificationState.notClassified),
      'a withheld result': _withheld(),
      'a done complaint': _state(
        ComplaintClassificationState.awaitingClassification,
        status: ComplaintStatus.done,
      ),
    };

    for (final entry in complaints.entries) {
      testWidgets('has no classification action on ${entry.key}', (
        tester,
      ) async {
        final repo = _repo(entry.value);
        await pumpComplaintApp(tester, repo, path: '/penyewa/keluhan/c1');

        expect(find.textContaining('Keran air di kamar mandi'), findsOneWidget);
        expect(find.text(_change), findsNothing);
        expect(find.text(_classify), findsNothing);
        expect(repo.categoriesCalls, 0);
      });
    }
  });

  group('the sheet', () {
    testWidgets('is titled Klasifikasi keluhan', (tester) async {
      await _open(tester, _repo(_ai()));

      await _openSheet(tester, _change);

      expect(_sheet(), findsOneWidget);
      expect(_inSheet(find.text(_sheetTitle)), findsOneWidget);
    });

    testWidgets('is opened by Klasifikasikan too', (tester) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.notClassified)),
      );

      await _openSheet(tester, _classify);

      expect(_inSheet(find.text(_sheetTitle)), findsOneWidget);
    });

    testWidgets('is opened by Klasifikasikan when the result is withheld', (
      tester,
    ) async {
      await _open(tester, _repo(_withheld()));

      await _openSheet(tester, _classify);

      expect(_inSheet(find.text(_sheetTitle)), findsOneWidget);
    });

    testWidgets('is shown for a manager too', (tester) async {
      await _open(tester, _repo(_ai()), role: UserRole.manager);

      await _openSheet(tester, _change);

      expect(_inSheet(find.text(_sheetTitle)), findsOneWidget);
    });

    testWidgets('has the labelled Kategori selector and Urgensi group', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      await _openSheet(tester, _change);

      expect(_fieldLabel(_categoryLabel), findsOneWidget);
      expect(_categorySelector(), findsWidgets);
      expect(_fieldLabel(_urgencyLabel), findsOneWidget);
      for (final label in _urgencyLabels.values) {
        expect(_inSheet(find.text(label)), findsOneWidget);
      }
    });

    testWidgets('has Batal and Simpan of at least 48 dp', (tester) async {
      await _open(tester, _repo(_ai()));

      await _openSheet(tester, _change);

      expect(_button(_cancel), findsOneWidget);
      expect(_button(_save), findsOneWidget);
      expectTargetSize(tester, _cancel);
      expectTargetSize(tester, _save);
    });

    testWidgets('offers every category of the API', (tester) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified))
        ..categoryList = ['Pipa dan air', 'Listrik', 'Furnitur', 'Atap'];
      await _open(tester, repo);
      await _openSheet(tester, _classify);

      await tester.tap(_categorySelector().first);
      await tester.pumpAndSettle();

      for (final category in repo.categoryList) {
        expect(find.text(category), findsWidgets);
      }
      expect(repo.categoriesCalls, 1);
    });

    testWidgets('pre-selects the category and urgency of an AI result', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      await _openSheet(tester, _change);

      expect(_categoryShown('Pipa dan air'), findsOneWidget);
      _expectUrgency(tester, ComplaintUrgency.high);
      expect(_canSave(tester), isTrue);
    });

    testWidgets('pre-selects the values of a manual classification', (
      tester,
    ) async {
      await _open(tester, _repo(_manual()));

      await _openSheet(tester, _change);

      expect(_categoryShown('Listrik'), findsOneWidget);
      _expectUrgency(tester, ComplaintUrgency.low);
      expect(_canSave(tester), isTrue);
    });

    final empty = {
      'classifying': _state(ComplaintClassificationState.classifying),
      'awaiting classification': _state(
        ComplaintClassificationState.awaitingClassification,
      ),
      'not classified': _state(ComplaintClassificationState.notClassified),
      'withheld': _withheld(),
    };
    for (final entry in empty.entries) {
      testWidgets('selects nothing and cannot save when ${entry.key}', (
        tester,
      ) async {
        final repo = _repo(entry.value);
        await _open(tester, repo);

        await _openSheet(tester, _classify);

        for (final category in repo.categoryList) {
          expect(_categoryShown(category), findsNothing);
        }
        _expectUrgency(tester, null);
        expect(_canSave(tester), isFalse);
      });
    }

    testWidgets('notes that a correction is kept with the original AI result', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      await _openSheet(tester, _change);

      expect(_inSheet(find.text(_correctionNote)), findsOneWidget);
    });

    testWidgets('shows the same note when a manual classification exists', (
      tester,
    ) async {
      await _open(tester, _repo(_manual()));

      await _openSheet(tester, _change);

      expect(_inSheet(find.text(_correctionNote)), findsOneWidget);
    });

    for (final entry in empty.entries) {
      testWidgets('shows no correction note when ${entry.key}', (tester) async {
        await _open(tester, _repo(entry.value));

        await _openSheet(tester, _classify);

        expect(find.text(_correctionNote), findsNothing);
      });
    }

    testWidgets('keeps Simpan disabled until the urgency is chosen', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.notClassified)),
      );
      await _openSheet(tester, _classify);

      await _chooseCategory(tester, 'Listrik');

      expect(_canSave(tester), isFalse);
    });

    testWidgets('keeps Simpan disabled until the category is chosen', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.notClassified)),
      );
      await _openSheet(tester, _classify);

      await _chooseUrgency(tester, ComplaintUrgency.high);

      expect(_canSave(tester), isFalse);
    });

    testWidgets('enables Simpan once both are chosen', (tester) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified));
      await _open(tester, repo);
      await _fill(tester, _classify);

      expect(_canSave(tester), isTrue);
      expect(repo.classifyCalls, 0);
    });

    testWidgets('choosing another urgency moves the selection', (tester) async {
      await _open(tester, _repo(_ai()));
      await _openSheet(tester, _change);

      await _chooseUrgency(tester, ComplaintUrgency.low);

      _expectUrgency(tester, ComplaintUrgency.low);
    });

    testWidgets('choosing another category replaces the shown one', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));
      await _openSheet(tester, _change);

      await _chooseCategory(tester, 'Furnitur');

      expect(_categoryShown('Furnitur'), findsOneWidget);
      expect(_categoryShown('Pipa dan air'), findsNothing);
    });
  });

  group('cancelling', () {
    testWidgets('Batal closes the sheet and calls nothing', (tester) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _openSheet(tester, _change);
      await _chooseCategory(tester, 'Listrik');

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.classifyCalls, 0);
      expect(_card(find.text('Pipa dan air')), findsOneWidget);
    });

    testWidgets('tapping outside the sheet closes it without a call', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _openSheet(tester, _change);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.classifyCalls, 0);
    });

    testWidgets('the Android back action closes the sheet without a call', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _openSheet(tester, _change);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.classifyCalls, 0);
      expect(currentPath(tester), '/keluhan/c1');
    });

    testWidgets('reopening after a cancel shows the current values again', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));
      await _openSheet(tester, _change);
      await _chooseCategory(tester, 'Listrik');
      await _chooseUrgency(tester, ComplaintUrgency.low);
      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      await _openSheet(tester, _change);

      expect(_categoryShown('Pipa dan air'), findsOneWidget);
      _expectUrgency(tester, ComplaintUrgency.high);
    });

    testWidgets('does not refresh the complaint list', (tester) async {
      final repo = _repo(_ai());
      await _openFromList(tester, repo);
      await _openSheet(tester, _change);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
    });
  });

  group('saving', () {
    testWidgets('classifies the complaint with the chosen values', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified));
      await _open(tester, repo);
      await _fill(
        tester,
        _classify,
        category: 'Listrik',
        urgency: ComplaintUrgency.high,
      );

      await _tapSave(tester);

      expect(repo.classifyCalls, 1);
      expect(repo.classified.single.id, 'c1');
      expect(repo.classified.single.category, 'Listrik');
      expect(repo.classified.single.urgency, ComplaintUrgency.high);
    });

    for (final entry in _urgencyLabels.entries) {
      testWidgets('sends the urgency ${entry.value}', (tester) async {
        final repo = _repo(_state(ComplaintClassificationState.notClassified));
        await _open(tester, repo);
        await _fill(tester, _classify, urgency: entry.key);

        await _tapSave(tester);

        expect(repo.classified.single.urgency, entry.key);
      });
    }

    testWidgets('corrects only the urgency of an AI result', (tester) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _openSheet(tester, _change);
      await _chooseUrgency(tester, ComplaintUrgency.low);

      await _tapSave(tester);

      expect(repo.classified.single.category, 'Pipa dan air');
      expect(repo.classified.single.urgency, ComplaintUrgency.low);
    });

    testWidgets('corrects only the category of an AI result', (tester) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _openSheet(tester, _change);
      await _chooseCategory(tester, 'Furnitur');

      await _tapSave(tester);

      expect(repo.classified.single.category, 'Furnitur');
      expect(repo.classified.single.urgency, ComplaintUrgency.high);
    });

    testWidgets('saving the unchanged values still calls the API', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _openSheet(tester, _change);

      await _tapSave(tester);

      expect(repo.classifyCalls, 1);
      expect(repo.classified.single.category, 'Pipa dan air');
      expect(repo.classified.single.urgency, ComplaintUrgency.high);
      expect(_sheet(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closes the sheet and shows the manual classification', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified));
      await _open(tester, repo);
      await _fill(
        tester,
        _classify,
        category: 'Listrik',
        urgency: ComplaintUrgency.high,
      );

      await _tapSave(tester);

      expect(_sheet(), findsNothing);
      expect(_card(find.text('Listrik')), findsOneWidget);
      expect(statusBadge('Tinggi'), findsOneWidget);
      expect(find.text('Diklasifikasi oleh $_classifier'), findsOneWidget);
      expect(statusBadge('Belum Diklasifikasi'), findsNothing);
    });

    testWidgets('shows no AI disclaimer for the manual classification', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      expect(aiDisclaimer(), findsOneWidget);
      await _fill(tester, _change, category: 'Listrik');

      await _tapSave(tester);

      expect(aiDisclaimer(), findsNothing);
    });

    testWidgets('offers Ubah instead of Klasifikasikan afterwards', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified));
      await _open(tester, repo);
      await _fill(tester, _classify);

      await _tapSave(tester);

      expect(_button(_change), findsOneWidget);
      expect(find.text(_classify), findsNothing);
    });

    testWidgets('replaces the withheld note by the manual classification', (
      tester,
    ) async {
      final repo = _repo(_withheld());
      await _open(tester, repo);
      expect(subscriptionNote(), findsOneWidget);
      await _fill(tester, _classify, category: 'Furnitur');

      await _tapSave(tester);

      expect(subscriptionNote(), findsNothing);
      expect(_card(find.text('Furnitur')), findsOneWidget);
      expect(find.text('Diklasifikasi oleh $_classifier'), findsOneWidget);
    });

    testWidgets('replaces the classifying state and its refresh action', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.classifying));
      await _open(tester, repo);
      await _fill(tester, _classify);

      await _tapSave(tester);

      expect(statusBadge('Sedang Diklasifikasi'), findsNothing);
      expect(find.text('Segarkan'), findsNothing);
      expect(_card(find.text('Listrik')), findsOneWidget);
    });

    testWidgets('shows the original AI result that was replaced', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      expect(find.textContaining('Hasil asli AI'), findsNothing);
      await _fill(
        tester,
        _change,
        category: 'Listrik',
        urgency: ComplaintUrgency.low,
      );

      await _tapSave(tester);

      expect(
        _card(find.text('Hasil asli AI: Pipa dan air, tinggi')),
        findsOneWidget,
      );
      expect(_card(find.text('Listrik')), findsOneWidget);
      expect(statusBadge('Rendah'), findsOneWidget);
    });

    testWidgets('keeps showing the original AI result after a second change', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _fill(tester, _change, category: 'Listrik');
      await _tapSave(tester);

      await _fill(
        tester,
        _change,
        category: 'Furnitur',
        urgency: ComplaintUrgency.low,
      );
      await _tapSave(tester);

      expect(repo.classifyCalls, 2);
      expect(_card(find.text('Furnitur')), findsOneWidget);
      expect(
        _card(find.text('Hasil asli AI: Pipa dan air, tinggi')),
        findsOneWidget,
      );
    });

    testWidgets('shows no original AI result when there was none', (
      tester,
    ) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified));
      await _open(tester, repo);
      await _fill(tester, _classify);

      await _tapSave(tester);

      expect(find.textContaining('Hasil asli AI'), findsNothing);
    });

    testWidgets('shows the original AI result of a loaded correction', (
      tester,
    ) async {
      await _open(tester, _repo(_manual(original: true)));

      expect(
        _card(find.text('Hasil asli AI: Pipa dan air, tinggi')),
        findsOneWidget,
      );
      expect(find.text('Diklasifikasi oleh $_classifier'), findsOneWidget);
      expect(aiDisclaimer(), findsNothing);
    });

    testWidgets('shows no original AI result on a plain manual one', (
      tester,
    ) async {
      await _open(tester, _repo(_manual()));

      expect(find.textContaining('Hasil asli AI'), findsNothing);
    });

    testWidgets('shows no original AI result on an AI classification', (
      tester,
    ) async {
      await _open(tester, _repo(_ai()));

      expect(find.textContaining('Hasil asli AI'), findsNothing);
    });

    testWidgets('keeps the status and the message in place', (tester) async {
      final repo = _repo(_ai(status: ComplaintStatus.inProgress));
      await _open(tester, repo);
      await _fill(tester, _change);

      await _tapSave(tester);

      expect(
        tester.widget<ComplaintStatusSteps>(statusSteps()).status,
        ComplaintStatus.inProgress,
      );
      expect(find.text(_description), findsOneWidget);
    });

    testWidgets('refreshes the complaint list', (tester) async {
      final repo = _repo(_ai());
      await _openFromList(tester, repo);
      expect(repo.listCalls, 1);
      await _fill(tester, _change);

      await _tapSave(tester);

      expect(repo.listCalls, 2);
    });

    for (final role in _roles) {
      testWidgets('a $role can classify', (tester) async {
        final repo = _repo(_state(ComplaintClassificationState.notClassified));
        await _open(tester, repo, role: role);
        await _fill(tester, _classify);

        await _tapSave(tester);

        expect(repo.classifyCalls, 1);
        expect(find.text('Diklasifikasi oleh $_classifier'), findsOneWidget);
      });
    }

    testWidgets('a done complaint can be classified', (tester) async {
      final repo = _repo(
        _state(
          ComplaintClassificationState.awaitingClassification,
          status: ComplaintStatus.done,
        ),
      );
      await _open(tester, repo);
      await _fill(tester, _classify);

      await _tapSave(tester);

      expect(repo.classifyCalls, 1);
      expect(_card(find.text('Listrik')), findsOneWidget);
      expect(find.text('Tandai Diproses'), findsNothing);
      expect(find.text('Tandai Selesai'), findsNothing);
    });

    testWidgets('shows progress and sends once while the call is in flight', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo(_ai())..classifyScript.gate = gate;
      await _open(tester, repo);
      await _fill(tester, _change);

      await tester.tap(_button(_save));
      await tester.pump();
      await _pumpFor(tester, 100);

      expect(_sheet(), findsOneWidget);
      expect(_inSheet(find.byType(CircularProgressIndicator)), findsOneWidget);
      final saveButton = _button(_save);
      if (saveButton.evaluate().isNotEmpty) {
        expect(_saveButton(tester).onPressed, isNull);
        await tester.tap(saveButton, warnIfMissed: false);
        await tester.pump();
      }
      expect(repo.classifyCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.classifyCalls, 1);
      expect(_sheet(), findsNothing);
      expect(_card(find.text('Listrik')), findsOneWidget);
    });
  });

  group('an invalid category', () {
    Future<FakeComplaintRepository> rejected(WidgetTester tester) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(_invalidCategory);
      await _open(tester, repo);
      await _fill(
        tester,
        _change,
        category: 'Furnitur',
        urgency: ComplaintUrgency.low,
      );
      await _tapSave(tester);
      return repo;
    }

    testWidgets('keeps the sheet open', (tester) async {
      await rejected(tester);

      expect(_sheet(), findsOneWidget);
    });

    testWidgets('shows the Indonesian message in the sheet', (tester) async {
      await rejected(tester);

      expect(_inSheet(find.text(_invalidCategoryMessage)), findsOneWidget);
      expect(find.textContaining('COMPLAINT_CATEGORY_INVALID'), findsNothing);
    });

    testWidgets('shows the message next to the category field', (tester) async {
      await rejected(tester);

      final category = topOf(tester, _fieldLabel(_categoryLabel));
      final message = topOf(
        tester,
        _inSheet(find.text(_invalidCategoryMessage)),
      );
      final urgency = topOf(tester, _fieldLabel(_urgencyLabel));
      expect(category, lessThan(message));
      expect(message, lessThan(urgency));
    });

    testWidgets('keeps the chosen category and urgency', (tester) async {
      await rejected(tester);

      expect(_categoryShown('Furnitur'), findsOneWidget);
      _expectUrgency(tester, ComplaintUrgency.low);
    });

    testWidgets('changes nothing on the screen behind', (tester) async {
      final repo = await rejected(tester);

      expect(repo.complaints.single.classification!.category, 'Pipa dan air');
      expect(_card(find.text('Pipa dan air')), findsOneWidget);
    });

    testWidgets('lets the user retry and then succeeds', (tester) async {
      final repo = await rejected(tester);

      await _tapSave(tester);

      expect(repo.classifyCalls, 2);
      expect(repo.classified.last.category, 'Furnitur');
      expect(repo.classified.last.urgency, ComplaintUrgency.low);
      expect(_sheet(), findsNothing);
      expect(_card(find.text('Furnitur')), findsOneWidget);
    });

    testWidgets('does not refresh the complaint list', (tester) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(_invalidCategory);
      await _openFromList(tester, repo);
      await _fill(tester, _change);
      final listCallsBefore = repo.listCalls;

      await _tapSave(tester);

      expect(repo.listCalls, listCallsBefore);
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
        final repo = _repo(_ai());
        repo.classifyScript.queue.add(entry.value);
        await _open(tester, repo);
        await _fill(tester, _change);

        await _tapSave(tester);

        expect(_sheet(), findsOneWidget);
        expect(
          _inSheet(find.text(messageOfCode(entry.value.code))),
          findsOneWidget,
        );
        expect(_inSheet(find.text(_invalidCategoryMessage)), findsNothing);
      });
    }

    testWidgets('keeps the chosen values and changes nothing', (tester) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(
        tester,
        _change,
        category: 'Furnitur',
        urgency: ComplaintUrgency.low,
      );
      final listCallsBefore = repo.listCalls;

      await _tapSave(tester);

      expect(_categoryShown('Furnitur'), findsOneWidget);
      _expectUrgency(tester, ComplaintUrgency.low);
      expect(repo.complaints.single.classification!.category, 'Pipa dan air');
      expect(_card(find.text('Pipa dan air')), findsOneWidget);
      expect(repo.listCalls, listCallsBefore);
    });

    testWidgets('lets the user retry and then succeeds', (tester) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester, _change, category: 'Furnitur');
      await _tapSave(tester);

      await _tapSave(tester);

      expect(repo.classifyCalls, 2);
      expect(repo.classified.last.category, 'Furnitur');
      expect(_sheet(), findsNothing);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(_card(find.text('Furnitur')), findsOneWidget);
    });

    testWidgets('the sheet can still be cancelled', (tester) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester, _change);
      await _tapSave(tester);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(repo.classifyCalls, 1);
      expect(_card(find.text('Pipa dan air')), findsOneWidget);
    });
  });

  group('the categories', () {
    testWidgets('show progress in the sheet while loading', (tester) async {
      final gate = Completer<void>();
      final repo = _repo(_ai())..categoriesScript.gate = gate;
      await _open(tester, repo);

      await tester.tap(_button(_change));
      await _pumpFor(tester, 500);

      expect(_sheet(), findsOneWidget);
      expect(_inSheet(find.text(_sheetTitle)), findsOneWidget);
      expect(_inSheet(find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(_button(_save), findsOneWidget);
      expect(_canSave(tester), isFalse);
      expect(repo.classifyCalls, 0);

      gate.complete();
      await tester.pumpAndSettle();

      expect(_inSheet(find.byType(CircularProgressIndicator)), findsNothing);
      expect(_categoryShown('Pipa dan air'), findsOneWidget);
      expect(_canSave(tester), isTrue);
    });

    testWidgets('can be dismissed while loading', (tester) async {
      final gate = Completer<void>();
      final repo = _repo(_ai())..categoriesScript.gate = gate;
      await _open(tester, repo);
      await tester.tap(_button(_change));
      await _pumpFor(tester, 500);

      await tester.tap(_button(_cancel));
      await _pumpFor(tester, 600);

      expect(_sheet(), findsNothing);
      gate.complete();
      await _pumpFor(tester, 600);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failing to load show the message and Coba lagi', (
      tester,
    ) async {
      final repo = _repo(_ai())
        ..categoriesScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await _openSheet(tester, _change);

      expect(_sheet(), findsOneWidget);
      expect(
        _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );
      expect(_button('Coba lagi'), findsOneWidget);
      expect(_inSheet(find.text('Coba lagi')), findsOneWidget);
    });

    testWidgets('failing to load keep Simpan disabled', (tester) async {
      final repo = _repo(_ai())
        ..categoriesScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await _openSheet(tester, _change);

      expect(_button(_save), findsOneWidget);
      expect(_canSave(tester), isFalse);
      expect(repo.classifyCalls, 0);
    });

    testWidgets('a forbidden response shows its own message', (tester) async {
      final repo = _repo(_ai())
        ..categoriesScript.always = const ApiFailure(code: 'FORBIDDEN');
      await _open(tester, repo);

      await _openSheet(tester, _change);

      expect(_inSheet(find.text(messageOfCode('FORBIDDEN'))), findsOneWidget);
    });

    testWidgets('Coba lagi loads the categories again', (tester) async {
      final repo = _repo(_state(ComplaintClassificationState.notClassified));
      repo.categoriesScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _openSheet(tester, _classify);
      expect(repo.categoriesCalls, 1);

      await tester.tap(_button('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.categoriesCalls, 2);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      await _chooseCategory(tester, 'Listrik');
      await _chooseUrgency(tester, ComplaintUrgency.low);
      expect(_canSave(tester), isTrue);
      await _tapSave(tester);
      expect(repo.classified.single.category, 'Listrik');
    });

    testWidgets('failing to load leave the sheet cancellable', (tester) async {
      final repo = _repo(_ai())
        ..categoriesScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _openSheet(tester, _change);

      await tester.tap(_button(_cancel));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
    });
  });

  group('dismissing the sheet while the save is in flight', () {
    /// Opens the complaint from the list, then saves with the request held by
    /// [gate].
    Future<FakeComplaintRepository> inFlight(
      WidgetTester tester,
      Completer<void> gate, {
      ApiFailure? failure,
    }) async {
      final repo = _repo(_ai())..classifyScript.gate = gate;
      if (failure != null) repo.classifyScript.queue.add(failure);
      await _openFromList(tester, repo);
      await _fill(tester, _change, category: 'Listrik');
      await tester.tap(_button(_save));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.classifyCalls, 1);
      expect(_inSheet(find.byType(CircularProgressIndicator)), findsOneWidget);
      return repo;
    }

    Future<void> back(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await _pumpFor(tester, 600);
    }

    Future<void> barrier(WidgetTester tester) async {
      await tester.tapAt(const Offset(2, 2));
      await _pumpFor(tester, 600);
    }

    Future<void> drag(WidgetTester tester) async {
      await tester.drag(_sheet(), const Offset(0, 600), warnIfMissed: false);
      await _pumpFor(tester, 600);
    }

    final dismissals = <String, Future<void> Function(WidgetTester)>{
      'the Android back action': back,
      'a tap on the barrier': barrier,
      'a drag down': drag,
    };

    for (final entry in dismissals.entries) {
      testWidgets('${entry.key} closes the sheet', (tester) async {
        final gate = Completer<void>();
        final repo = await inFlight(tester, gate);

        await entry.value(tester);

        expect(_sheet(), findsNothing);
        expect(repo.classifyCalls, 1);
        expect(tester.takeException(), isNull);

        gate.complete();
        await _pumpFor(tester, 600);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key} still lets a success update the detail', (
        tester,
      ) async {
        final gate = Completer<void>();
        final repo = await inFlight(tester, gate);
        await entry.value(tester);

        gate.complete();
        await _pumpFor(tester, 600);

        expect(_sheet(), findsNothing);
        expect(repo.classifyCalls, 1);
        expect(_card(find.text('Listrik')), findsOneWidget);
        expect(find.text('Diklasifikasi oleh $_classifier'), findsOneWidget);
        expect(aiDisclaimer(), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key} still lets a success refresh the list', (
        tester,
      ) async {
        final gate = Completer<void>();
        final repo = await inFlight(tester, gate);
        final listCallsBefore = repo.listCalls;
        await entry.value(tester);

        gate.complete();
        await _pumpFor(tester, 600);

        expect(repo.listCalls, greaterThan(listCallsBefore));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key} still lets a failure end without an error', (
        tester,
      ) async {
        final gate = Completer<void>();
        final repo = await inFlight(
          tester,
          gate,
          failure: const ApiFailure.network(),
        );
        await entry.value(tester);

        gate.complete();
        await _pumpFor(tester, 600);

        expect(_sheet(), findsNothing);
        expect(repo.classifyCalls, 1);
        expect(_card(find.text('Pipa dan air')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('accessibility', () {
    final screens = <String, FakeComplaintRepository Function()>{
      'with an AI classification': () => _repo(_ai()),
      'with a manual classification': () => _repo(_manual()),
      'with a manual classification that replaced an AI result': () =>
          _repo(_manual(original: true)),
      'classifying': () =>
          _repo(_state(ComplaintClassificationState.classifying)),
      'awaiting classification': () =>
          _repo(_state(ComplaintClassificationState.awaitingClassification)),
      'not classified': () =>
          _repo(_state(ComplaintClassificationState.notClassified)),
      'withheld': () => _repo(_withheld()),
      'done and not classified': () => _repo(
        _state(
          ComplaintClassificationState.notClassified,
          status: ComplaintStatus.done,
        ),
      ),
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

    final sheets = <String, (FakeComplaintRepository Function(), String)>{
      'for a correction': (() => _repo(_ai()), _change),
      'for a manual correction': (
        () => _repo(_manual(original: true)),
        _change,
      ),
      'for a state': (
        () => _repo(_state(ComplaintClassificationState.notClassified)),
        _classify,
      ),
      'for a withheld result': (() => _repo(_withheld()), _classify),
    };

    for (final entry in sheets.entries) {
      testWidgets('meets the guidelines with the sheet open ${entry.key}', (
        tester,
      ) async {
        await _open(tester, entry.value.$1());
        await _openSheet(tester, entry.value.$2);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size with the sheet open ${entry.key}', (
        tester,
      ) async {
        await _open(tester, entry.value.$1(), largeText: true);
        await _openSheet(tester, entry.value.$2);

        expect(tester.takeException(), isNull);
        expect(_sheet(), findsOneWidget);
        expect(_button(_save), findsOneWidget);
      });
    }

    testWidgets('meets the guidelines with the choices filled in', (
      tester,
    ) async {
      await _open(
        tester,
        _repo(_state(ComplaintClassificationState.notClassified)),
      );
      await _fill(tester, _classify);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the sheet showing a field error', (
      tester,
    ) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(_invalidCategory);
      await _open(tester, repo);
      await _fill(tester, _change);
      await _tapSave(tester);
      expect(_inSheet(find.text(_invalidCategoryMessage)), findsOneWidget);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets(
      'fits at large text size with the sheet showing a field error',
      (tester) async {
        final repo = _repo(_ai());
        repo.classifyScript.queue.add(_invalidCategory);
        await _open(tester, repo, largeText: true);
        await _fill(tester, _change);
        await _tapSave(tester);

        expect(tester.takeException(), isNull);
        expect(_inSheet(find.text(_invalidCategoryMessage)), findsOneWidget);
      },
    );

    testWidgets('meets the guidelines with the sheet showing an error', (
      tester,
    ) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _fill(tester, _change);
      await _tapSave(tester);
      expect(
        _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the sheet showing an error', (
      tester,
    ) async {
      final repo = _repo(_ai());
      repo.classifyScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, largeText: true);
      await _fill(tester, _change);
      await _tapSave(tester);

      expect(tester.takeException(), isNull);
      expect(
        _inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );
    });

    testWidgets('meets the guidelines while the categories load', (
      tester,
    ) async {
      final repo = _repo(_ai())..categoriesScript.gate = Completer<void>();
      await _open(tester, repo);
      await tester.tap(_button(_change));
      await _pumpFor(tester, 500);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while the categories load', (
      tester,
    ) async {
      final repo = _repo(_ai())..categoriesScript.gate = Completer<void>();
      await _open(tester, repo, largeText: true);
      await tester.tap(_button(_change));
      await _pumpFor(tester, 500);

      expect(tester.takeException(), isNull);
      expect(_sheet(), findsOneWidget);
    });

    testWidgets('meets the guidelines when the categories failed to load', (
      tester,
    ) async {
      final repo = _repo(_ai())
        ..categoriesScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _openSheet(tester, _change);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size when the categories failed', (
      tester,
    ) async {
      final repo = _repo(_ai())
        ..categoriesScript.always = const ApiFailure.network();
      await _open(tester, repo, largeText: true);
      await _openSheet(tester, _change);

      expect(tester.takeException(), isNull);
      expect(_inSheet(find.text('Coba lagi')), findsOneWidget);
    });

    testWidgets('meets the guidelines while the save is in flight', (
      tester,
    ) async {
      final repo = _repo(_ai())..classifyScript.gate = Completer<void>();
      await _open(tester, repo);
      await _fill(tester, _change);
      await tester.tap(_button(_save));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines after a manual classification', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo);
      await _fill(tester, _change, category: 'Listrik');
      await _tapSave(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size after a manual classification', (
      tester,
    ) async {
      final repo = _repo(_ai());
      await _open(tester, repo, largeText: true);
      await _fill(tester, _change, category: 'Listrik');
      await _tapSave(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Hasil asli AI: Pipa dan air, tinggi'), findsOneWidget);
    });
  });
}
