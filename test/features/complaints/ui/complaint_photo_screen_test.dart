import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/complaints/ui/complaint_photo_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'complaint_photo_helpers.dart';

final _roles = {
  UserRole.tenant: '/penyewa/keluhan',
  UserRole.owner: '/keluhan',
};

FakeComplaintRepository _repo() => FakeComplaintRepository(
  complaints: [makeComplaint(hasPhoto: true)],
  photos: {'c1': tinyPng},
);

Future<void> _open(
  WidgetTester tester,
  FakeComplaintRepository repo, {
  UserRole role = UserRole.tenant,
  bool largeText = false,
  bool settle = true,
}) => pumpComplaintApp(
  tester,
  repo,
  role: role,
  path: '${_roles[role]}/c1/foto',
  largeText: largeText,
  settle: settle,
);

Finder _screen() => find.byType(ComplaintPhotoScreen);

Finder _shownImage() =>
    find.descendant(of: _screen(), matching: find.byType(Image));

List<String> _photoLabels(WidgetTester tester) => [
  for (final node in allSemanticsNodes(tester))
    if (node.label.startsWith('Foto keluhan, ')) node.label,
];

void main() {
  for (final entry in _roles.entries) {
    final role = entry.key;
    final name = role == UserRole.tenant ? 'tenant' : 'management';

    group('loaded for a $name', () {
      testWidgets('is titled Foto Keluhan and covers the navigation bar', (
        tester,
      ) async {
        await _open(tester, _repo(), role: role);

        expect(_screen(), findsOneWidget);
        expect(appBarTitle('Foto Keluhan'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('loads the photo and the complaint of the route', (
        tester,
      ) async {
        final repo = _repo();
        await _open(tester, repo, role: role);

        expect(repo.calls, contains('photo:c1'));
        expect(repo.calls, contains('get:c1'));
      });

      testWidgets('shows the photo as an image', (tester) async {
        await _open(tester, _repo(), role: role);
        await decodeImages(tester);

        expect(_shownImage(), findsOneWidget);
        expect(shownBytes(tester, _screen()), tinyPng);
        expect(find.byType(ErrorView), findsNothing);
      });

      testWidgets('labels the image with what it is and the sent date', (
        tester,
      ) async {
        await _open(tester, _repo(), role: role);
        await decodeImages(tester);

        final handle = tester.ensureSemantics();
        try {
          final labels = _photoLabels(tester);
          expect(labels, hasLength(1));
          expect(labels.single, contains(photoLabel));
        } finally {
          handle.dispose();
        }
      });

      testWidgets('Kembali returns to the complaint', (tester) async {
        await _open(tester, _repo(), role: role);

        await pressBack(tester);

        expect(_screen(), findsNothing);
        expect(
          find.byType(
            role == UserRole.tenant
                ? TenantComplaintDetailScreen
                : ManagementComplaintDetailScreen,
          ),
          findsOneWidget,
        );
        expect(currentPath(tester), '${entry.value}/c1');
      });

      testWidgets('shows a progress indicator labelled Memuat while loading', (
        tester,
      ) async {
        final repo = _repo()..photoScript.gate = Completer<void>();
        await _open(tester, repo, role: role, settle: false);

        expectLoading(tester);
        expect(_shownImage(), findsNothing);
      });

      testWidgets('shows a progress indicator while the complaint loads', (
        tester,
      ) async {
        final repo = _repo()..getScript.gate = Completer<void>();
        await _open(tester, repo, role: role, settle: false);

        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
        expect(_shownImage(), findsNothing);
      });
    });

    group('failure for a $name', () {
      testWidgets('shows the message of the failure and a retry', (
        tester,
      ) async {
        final repo = _repo()..photoScript.always = const ApiFailure.network();
        await _open(tester, repo, role: role);

        expect(
          find.descendant(of: _screen(), matching: find.byType(ErrorView)),
          findsOneWidget,
        );
        expect(
          find.text(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          ),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(_shownImage(), findsNothing);
      });

      testWidgets('a missing photo shows its message', (tester) async {
        final repo = _repo()..photos.clear();
        await _open(tester, repo, role: role);

        expect(find.text(photoNotFoundError), findsOneWidget);
        expect(_shownImage(), findsNothing);
      });

      testWidgets('a missing complaint shows its message', (tester) async {
        final repo = _repo()
          ..getScript.always = const ApiFailure(code: 'COMPLAINT_NOT_FOUND');
        await _open(tester, repo, role: role);

        expect(find.text('Keluhan tidak ditemukan.'), findsOneWidget);
        expect(_shownImage(), findsNothing);
      });

      testWidgets('Coba lagi loads the photo again', (tester) async {
        final repo = _repo()..photoScript.always = const ApiFailure.network();
        await _open(tester, repo, role: role);
        final before = repo.photoCalls;
        repo.photoScript.always = null;

        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();
        await decodeImages(tester);

        expect(repo.photoCalls, greaterThan(before));
        expect(find.text('Coba lagi'), findsNothing);
        expect(_shownImage(), findsOneWidget);
      });

      testWidgets('keeps the failure when the retry fails too', (tester) async {
        final repo = _repo()
          ..photoScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
        await _open(tester, repo, role: role);
        final before = repo.photoCalls;

        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();

        expect(
          find.text('Terjadi kesalahan pada server. Coba lagi.'),
          findsOneWidget,
        );
        expect(repo.photoCalls, greaterThan(before));
      });

      testWidgets('bytes that are not an image offer a reload', (tester) async {
        final repo = _repo()..photos['c1'] = Uint8List.fromList([1, 2, 3]);
        await _open(tester, repo, role: role);
        await decodeImages(tester);

        expect(find.text('Coba lagi'), findsOneWidget);
      });
    });

    group('accessibility for a $name', () {
      final states = <String, FakeComplaintRepository Function()>{
        'loaded': _repo,
        'failed': () =>
            _repo()..photoScript.always = const ApiFailure.network(),
        'without a photo': () => _repo()..photos.clear(),
      };

      for (final state in states.entries) {
        testWidgets('meets the guidelines when ${state.key}', (tester) async {
          await _open(tester, state.value(), role: role);
          await decodeImages(tester);

          await expectMeetsA11yGuidelines(tester);
        });

        testWidgets('fits at large text size when ${state.key}', (
          tester,
        ) async {
          await _open(tester, state.value(), role: role, largeText: true);
          await decodeImages(tester);

          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('meets the guidelines while loading', (tester) async {
        final repo = _repo()..photoScript.gate = Completer<void>();
        await _open(tester, repo, role: role, settle: false);

        await expectMeetsA11yGuidelines(tester);
      });
    });
  }

  group('after a replacement', () {
    testWidgetsWithSemantics('shows the newly uploaded photo, not the cached '
        'one', (tester) async {
      final first = pngPhoto(name: 'lama.png', length: 64);
      final second = pngPhoto(name: 'baru.png', length: 96);
      final repo = FakeComplaintRepository(
        complaints: [makeComplaint(hasPhoto: true)],
        photos: {'c1': first.bytes},
      );
      final picker = FakeImageChooser();
      await pumpComplaintApp(
        tester,
        repo,
        path: '/penyewa/keluhan/c1',
        picker: picker,
      );
      await openPhotoFromTile(tester);
      expect(shownBytes(tester, _screen()), first.bytes);
      await pressBack(tester);

      await pickWith(tester, picker, find.text(replacePhotoText), second);
      await openPhotoFromTile(tester);

      expect(repo.uploadedPhotos.single.image.bytes, second.bytes);
      expect(shownBytes(tester, _screen()), second.bytes);
    });

    testWidgetsWithSemantics('shows a photo added to a complaint that had '
        'none', (tester) async {
      final photo = pngPhoto(name: 'baru.png', length: 96);
      final repo = FakeComplaintRepository(complaints: [makeComplaint()]);
      final picker = FakeImageChooser();
      await pumpComplaintApp(
        tester,
        repo,
        path: '/penyewa/keluhan/c1',
        picker: picker,
      );

      await pickWith(tester, picker, find.text(addPhotoText), photo);
      await openPhotoFromTile(tester);

      expect(shownBytes(tester, _screen()), photo.bytes);
    });
  });
}
