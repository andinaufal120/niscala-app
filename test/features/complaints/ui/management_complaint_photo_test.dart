import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/complaints/ui/complaint_photo_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'complaint_photo_helpers.dart';

const _detailPath = '/keluhan/c1';

final _roles = [UserRole.owner, UserRole.manager];

({FakeComplaintRepository repo, FakeImageChooser picker}) _setup({
  ComplaintStatus status = ComplaintStatus.new_,
  bool hasPhoto = true,
  bool withheld = false,
}) => (
  repo: FakeComplaintRepository(
    complaints: [
      makeComplaint(
        status: status,
        hasPhoto: hasPhoto,
        classificationWithheld: withheld,
      ),
    ],
    photos: {if (hasPhoto) 'c1': tinyPng},
  ),
  picker: FakeImageChooser(),
);

Future<void> _open(
  WidgetTester tester,
  ({FakeComplaintRepository repo, FakeImageChooser picker}) s, {
  UserRole role = UserRole.owner,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  s.repo,
  role: role,
  path: _detailPath,
  picker: s.picker,
  largeText: largeText,
);

final _statuses = {
  ComplaintStatus.new_: 'Baru',
  ComplaintStatus.inProgress: 'Diproses',
  ComplaintStatus.done: 'Selesai',
};

void main() {
  for (final role in _roles) {
    final who = role == UserRole.owner ? 'an owner' : 'a manager';

    group('the photo tile for $who', () {
      testWidgetsWithSemantics('is shown when the complaint has a photo', (
        tester,
      ) async {
        await _open(tester, _setup(), role: role);

        expect(photoTile(), findsAtLeastNWidgets(1));
        expect(nodesAnnouncing(tester, photoLabel), hasLength(1));
      });

      testWidgetsWithSemantics('sits within the message of the tenant', (
        tester,
      ) async {
        await _open(tester, _setup(), role: role);

        expect(
          find.descendant(
            of: sectionCardOf('Pesan penyewa'),
            matching: photoTile(),
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.text(makeComplaint().description), findsOneWidget);
      });

      testWidgetsWithSemantics('has a target of at least 48 dp', (
        tester,
      ) async {
        await _open(tester, _setup(), role: role);

        final rect = tester.getSemantics(photoTile().first).rect;
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.width, greaterThanOrEqualTo(48));
      });

      testWidgetsWithSemantics('is absent when the complaint has no photo', (
        tester,
      ) async {
        await _open(tester, _setup(hasPhoto: false), role: role);

        expect(find.bySemanticsLabel(RegExp('Foto keluhan')), findsNothing);
        expect(find.text('Pesan penyewa'), findsOneWidget);
      });

      for (final entry in _statuses.entries) {
        testWidgetsWithSemantics('is shown when the status is ${entry.value}', (
          tester,
        ) async {
          await _open(tester, _setup(status: entry.key), role: role);

          expect(photoTile(), findsAtLeastNWidgets(1));
        });
      }

      testWidgetsWithSemantics('is shown when the classification is '
          'withheld', (tester) async {
        await _open(tester, _setup(withheld: true), role: role);

        expect(photoTile(), findsAtLeastNWidgets(1));
      });

      testWidgetsWithSemantics('opens the full-screen view', (tester) async {
        await _open(tester, _setup(), role: role);

        await openPhotoFromTile(tester);

        expect(currentPath(tester), '$_detailPath/foto');
        expect(find.byType(ComplaintPhotoScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgetsWithSemantics('Kembali from the full-screen view returns to '
          'the complaint', (tester) async {
        await _open(tester, _setup(), role: role);
        await openPhotoFromTile(tester);

        await pressBack(tester);

        expect(currentPath(tester), _detailPath);
        expect(find.byType(ManagementComplaintDetailScreen), findsOneWidget);
        expect(find.byType(ComplaintPhotoScreen), findsNothing);
      });

      testWidgetsWithSemantics('keeps the status action of a new complaint', (
        tester,
      ) async {
        await _open(tester, _setup(), role: role);

        expect(find.text('Tandai Diproses'), findsOneWidget);
        expect(photoTile(), findsAtLeastNWidgets(1));
      });
    });

    group('no photo action for $who', () {
      for (final entry in _statuses.entries) {
        for (final hasPhoto in [true, false]) {
          testWidgets('offers none when the status is ${entry.value} '
              '${hasPhoto ? 'with' : 'without'} a photo', (tester) async {
            final s = _setup(status: entry.key, hasPhoto: hasPhoto);
            await _open(tester, s, role: role);

            for (final text in [
              addPhotoText,
              replacePhotoText,
              removePhotoText,
              photoTileText,
            ]) {
              expect(find.text(text), findsNothing, reason: text);
            }
            expect(s.picker.requested, isEmpty);
            expect(s.repo.uploadPhotoCalls, 0);
          });
        }
      }
    });

    group('accessibility for $who', () {
      final states =
          <
            String,
            ({FakeComplaintRepository repo, FakeImageChooser picker}) Function()
          >{
            'new with a photo': _setup,
            'new without a photo': () => _setup(hasPhoto: false),
            'in progress with a photo': () =>
                _setup(status: ComplaintStatus.inProgress),
            'done with a photo': () => _setup(status: ComplaintStatus.done),
            'with a withheld classification and a photo': () =>
                _setup(withheld: true),
          };

      for (final entry in states.entries) {
        testWidgets('meets the guidelines when ${entry.key}', (tester) async {
          await _open(tester, entry.value(), role: role);

          await expectMeetsA11yGuidelines(tester);
        });

        testWidgets('fits at large text size when ${entry.key}', (
          tester,
        ) async {
          await _open(tester, entry.value(), role: role, largeText: true);

          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
