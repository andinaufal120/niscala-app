import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala/features/complaints/ui/complaint_photo_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'complaint_photo_helpers.dart';

const _detailPath = '/penyewa/keluhan/c1';

typedef _Setup = ({FakeComplaintRepository repo, FakeImageChooser picker});

/// A tenant with one complaint, which has a photo when [hasPhoto].
_Setup _setup({
  ComplaintStatus status = ComplaintStatus.new_,
  bool hasPhoto = false,
}) => (
  repo: FakeComplaintRepository(
    complaints: [makeComplaint(status: status, hasPhoto: hasPhoto)],
    photos: {if (hasPhoto) 'c1': tinyPng},
  ),
  picker: FakeImageChooser(),
);

Future<void> _open(
  WidgetTester tester,
  _Setup s, {
  bool largeText = false,
  bool settle = true,
}) => pumpComplaintApp(
  tester,
  s.repo,
  path: _detailPath,
  picker: s.picker,
  largeText: largeText,
  settle: settle,
);

Future<void> _pick(
  WidgetTester tester,
  _Setup s,
  String opener,
  PickedImage? file, {
  String source = galleryChoice,
}) => pickWith(tester, s.picker, find.text(opener), file, source: source);

final _statuses = {
  ComplaintStatus.new_: 'Baru',
  ComplaintStatus.inProgress: 'Diproses',
  ComplaintStatus.done: 'Selesai',
};

void main() {
  group('the photo tile', () {
    testWidgetsWithSemantics('is shown for a complaint with a photo', (
      tester,
    ) async {
      await _open(tester, _setup(hasPhoto: true));

      expect(photoTile(), findsAtLeastNWidgets(1));
      expect(nodesAnnouncing(tester, photoLabel), hasLength(1));
    });

    testWidgetsWithSemantics(
      'is labelled with the date the complaint was sent',
      (tester) async {
        final s = (
          repo: FakeComplaintRepository(
            complaints: [
              makeComplaint(
                hasPhoto: true,
                createdAt: DateTime.utc(2026, 12, 1, 12),
              ),
            ],
            photos: {'c1': tinyPng},
          ),
          picker: FakeImageChooser(),
        );
        await _open(tester, s);

        expect(photoTile(date: '1 Des 2026'), findsAtLeastNWidgets(1));
        expect(
          nodesAnnouncing(tester, 'Foto keluhan, 1 Des 2026'),
          hasLength(1),
        );
        expect(nodesAnnouncing(tester, photoLabel), isEmpty);
      },
    );

    testWidgetsWithSemantics('has a target of at least 48 dp', (tester) async {
      await _open(tester, _setup(hasPhoto: true));

      final rect = tester.getSemantics(photoTile().first).rect;
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
    });

    testWidgetsWithSemantics('is absent for a complaint without a photo', (
      tester,
    ) async {
      await _open(tester, _setup());

      expect(photoTile(), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Foto keluhan')), findsNothing);
    });

    for (final entry in _statuses.entries) {
      testWidgetsWithSemantics('is shown when the status is ${entry.value}', (
        tester,
      ) async {
        await _open(tester, _setup(status: entry.key, hasPhoto: true));

        expect(photoTile(), findsAtLeastNWidgets(1));
      });

      testWidgetsWithSemantics(
        'opens the full-screen view when the status is ${entry.value}',
        (tester) async {
          final s = _setup(status: entry.key, hasPhoto: true);
          await _open(tester, s);

          await openPhotoFromTile(tester);

          expect(currentPath(tester), '$_detailPath/foto');
          expect(find.byType(ComplaintPhotoScreen), findsOneWidget);
          expect(find.byType(NavigationBar), findsNothing);
        },
      );
    }

    testWidgetsWithSemantics('Kembali from the full-screen view returns to '
        'the detail', (tester) async {
      await _open(tester, _setup(hasPhoto: true));
      await openPhotoFromTile(tester);

      await pressBack(tester);

      expect(currentPath(tester), _detailPath);
      expect(find.byType(TenantComplaintDetailScreen), findsOneWidget);
      expect(find.byType(ComplaintPhotoScreen), findsNothing);
    });

    testWidgetsWithSemantics('opening the photo changes nothing on the '
        'complaint', (tester) async {
      final s = _setup(hasPhoto: true);
      await _open(tester, s);

      await openPhotoFromTile(tester);

      expect(s.repo.uploadPhotoCalls, 0);
      expect(s.repo.statusCalls, 0);
    });
  });

  group('the photo actions', () {
    for (final entry in _statuses.entries) {
      final isNew = entry.key == ComplaintStatus.new_;

      testWidgets(
        '${entry.value} with a photo ${isNew ? 'offers Ganti foto' : 'offers no photo action'}',
        (tester) async {
          await _open(tester, _setup(status: entry.key, hasPhoto: true));

          expect(
            find.text(replacePhotoText),
            isNew ? findsOneWidget : findsNothing,
          );
          expect(find.text(addPhotoText), findsNothing);
        },
      );

      testWidgets(
        '${entry.value} without a photo ${isNew ? 'offers Tambah foto' : 'offers no photo action'}',
        (tester) async {
          await _open(tester, _setup(status: entry.key));

          expect(
            find.text(addPhotoText),
            isNew ? findsOneWidget : findsNothing,
          );
          expect(find.text(replacePhotoText), findsNothing);
        },
      );
    }

    testWidgets('Tambah foto has a target of at least 48 dp', (tester) async {
      await _open(tester, _setup());

      expectTargetSize(tester, addPhotoText);
    });

    testWidgets('Ganti foto has a target of at least 48 dp', (tester) async {
      await _open(tester, _setup(hasPhoto: true));

      expectTargetSize(tester, replacePhotoText);
    });

    testWidgets('opening the detail uploads nothing and asks for no photo', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      expect(s.repo.uploadPhotoCalls, 0);
      expect(s.picker.requested, isEmpty);
    });

    testWidgets('no photo action shows while the complaint loads', (
      tester,
    ) async {
      final s = _setup(hasPhoto: true);
      s.repo.getScript.gate = Completer<void>();
      await _open(tester, s, settle: false);

      expect(find.text(addPhotoText), findsNothing);
      expect(find.text(replacePhotoText), findsNothing);
    });

    testWidgets('no photo action shows when the complaint failed to load', (
      tester,
    ) async {
      final s = _setup(hasPhoto: true);
      s.repo.getScript.always = const ApiFailure.network();
      await _open(tester, s);

      expect(find.text(addPhotoText), findsNothing);
      expect(find.text(replacePhotoText), findsNothing);
    });
  });

  group('choosing the source', () {
    for (final opener in [addPhotoText, replacePhotoText]) {
      final hasPhoto = opener == replacePhotoText;

      testWidgets('$opener offers the camera and the gallery', (tester) async {
        final s = _setup(hasPhoto: hasPhoto);
        await _open(tester, s);

        await tester.tap(find.text(opener));
        await tester.pumpAndSettle();

        expect(find.text(cameraChoice), findsOneWidget);
        expect(find.text(galleryChoice), findsOneWidget);
        expectTargetSize(tester, cameraChoice);
        expectTargetSize(tester, galleryChoice);
        expect(s.picker.requested, isEmpty);
        expect(s.repo.uploadPhotoCalls, 0);
      });

      testWidgets('closing the choice after $opener changes nothing', (
        tester,
      ) async {
        final s = _setup(hasPhoto: hasPhoto);
        await _open(tester, s);
        await tester.tap(find.text(opener));
        await tester.pumpAndSettle();

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text(cameraChoice), findsNothing);
        expect(s.picker.requested, isEmpty);
        expect(s.repo.uploadPhotoCalls, 0);
        expect(find.text(opener), findsOneWidget);
      });

      testWidgets('the gallery after $opener asks for the gallery', (
        tester,
      ) async {
        final s = _setup(hasPhoto: hasPhoto);
        await _open(tester, s);

        await _pick(tester, s, opener, null);

        expect(s.picker.requested, [ImageOrigin.gallery]);
      });

      testWidgets('the camera after $opener asks for the camera', (
        tester,
      ) async {
        final s = _setup(hasPhoto: hasPhoto);
        await _open(tester, s);

        await _pick(tester, s, opener, null, source: cameraChoice);

        expect(s.picker.requested, [ImageOrigin.camera]);
      });

      testWidgets('cancelling the picker after $opener changes nothing', (
        tester,
      ) async {
        final s = _setup(hasPhoto: hasPhoto);
        await _open(tester, s);

        await _pick(tester, s, opener, null);

        expect(s.repo.uploadPhotoCalls, 0);
        expect(s.repo.getCalls, 1);
        expect(find.text(opener), findsOneWidget);
        for (final text in [
          photoTypeError,
          photoSizeError,
          photoAccessDenied,
        ]) {
          expect(find.text(text), findsNothing);
        }
      });
    }
  });

  group('adding a photo', () {
    testWidgets('uploads the chosen photo to the complaint at once', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      final photo = pngPhoto(name: 'keran.png', length: 4096);

      await _pick(tester, s, addPhotoText, photo);

      expect(s.repo.uploadedPhotos, hasLength(1));
      expect(s.repo.uploadedPhotos.single.id, 'c1');
      expect(s.repo.uploadedPhotos.single.image.name, 'keran.png');
      expect(s.repo.uploadedPhotos.single.image.bytes, photo.bytes);
    });

    testWidgets('a photo from the camera is uploaded too', (tester) async {
      final s = _setup();
      await _open(tester, s);
      final photo = jpegPhoto(name: 'kamera.jpg');

      await _pick(tester, s, addPhotoText, photo, source: cameraChoice);

      expect(s.repo.uploadedPhotos.single.image.bytes, photo.bytes);
      expect(s.picker.requested, [ImageOrigin.camera]);
    });

    testWidgets('refreshes the detail afterwards', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s, addPhotoText, pngPhoto());

      expect(s.repo.getCalls, 2);
      expect(s.repo.submitCalls, 0);
    });

    testWidgetsWithSemantics('then shows the photo tile and Ganti foto', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      expect(photoTile(), findsNothing);

      await _pick(tester, s, addPhotoText, pngPhoto());

      expect(photoTile(), findsAtLeastNWidgets(1));
      expect(find.text(replacePhotoText), findsOneWidget);
      expect(find.text(addPhotoText), findsNothing);
    });

    testWidgets('accepts a PNG of exactly 5 MB', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s, addPhotoText, pngPhoto(length: maxPhotoBytes));

      expect(s.repo.uploadPhotoCalls, 1);
      expect(find.text(photoSizeError), findsNothing);
    });

    testWidgets('shows progress while the photo uploads', (tester) async {
      final s = _setup();
      final gate = Completer<void>();
      s.repo.uploadPhotoScript.gate = gate;
      await _open(tester, s);
      s.picker.queue.add(pngPhoto());
      await tester.tap(find.text(addPhotoText));
      await tester.pumpAndSettle();
      await tester.tap(find.text(galleryChoice));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(s.repo.uploadPhotoCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(replacePhotoText), findsOneWidget);
    });
  });

  group('replacing a photo', () {
    testWidgets('uploads the chosen photo to the complaint', (tester) async {
      final s = _setup(hasPhoto: true);
      await _open(tester, s);
      final photo = pngPhoto(name: 'baru.png', length: 4096);

      await _pick(tester, s, replacePhotoText, photo);

      expect(s.repo.uploadedPhotos.single.id, 'c1');
      expect(s.repo.uploadedPhotos.single.image.name, 'baru.png');
      expect(s.repo.uploadedPhotos.single.image.bytes, photo.bytes);
      expect(s.repo.photos['c1'], photo.bytes);
    });

    testWidgetsWithSemantics('refreshes the detail and keeps the tile and '
        'Ganti foto', (tester) async {
      final s = _setup(hasPhoto: true);
      await _open(tester, s);

      await _pick(tester, s, replacePhotoText, pngPhoto(length: 4096));

      expect(s.repo.getCalls, 2);
      expect(photoTile(), findsAtLeastNWidgets(1));
      expect(find.text(replacePhotoText), findsOneWidget);
      expect(find.text(addPhotoText), findsNothing);
    });
  });

  group('a photo that is not accepted', () {
    final rejected = <String, (PickedImage Function(), String)>{
      'a PDF': (pdfPhoto, photoTypeError),
      'a PDF renamed to JPG': (pdfNamedJpg, photoTypeError),
      'a HEIC photo': (heicPhoto, photoTypeError),
      'a GIF image': (gifPhoto, photoTypeError),
      'an image over 5 MB': (
        () => pngPhoto(length: maxPhotoBytes + 1),
        photoSizeError,
      ),
    };

    for (final opener in [addPhotoText, replacePhotoText]) {
      for (final entry in rejected.entries) {
        final (file, message) = entry.value;

        testWidgets('${entry.key} after $opener shows $message and uploads '
            'nothing', (tester) async {
          final s = _setup(hasPhoto: opener == replacePhotoText);
          await _open(tester, s);

          await _pick(tester, s, opener, file());

          expect(find.text(message), findsOneWidget);
          expect(s.repo.uploadPhotoCalls, 0);
          expect(s.repo.getCalls, 1);
          expect(find.text(opener), findsOneWidget);
        });
      }
    }

    testWidgets('a later valid photo clears the message and uploads', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s, addPhotoText, pdfPhoto());
      expect(find.text(photoTypeError), findsOneWidget);

      await _pick(tester, s, addPhotoText, pngPhoto());

      expect(find.text(photoTypeError), findsNothing);
      expect(s.repo.uploadPhotoCalls, 1);
    });
  });

  group('denied camera or gallery access', () {
    final sources = {
      cameraChoice: PlatformException(code: 'camera_access_denied'),
      galleryChoice: PlatformException(code: 'photo_access_denied'),
    };
    for (final entry in sources.entries) {
      testWidgets('${entry.key} shows the access message and uploads nothing', (
        tester,
      ) async {
        final s = _setup();
        s.picker.failure = entry.value;
        await _open(tester, s);

        await _pick(tester, s, addPhotoText, null, source: entry.key);

        expect(find.text(photoAccessDenied), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(s.repo.uploadPhotoCalls, 0);
        expect(currentPath(tester), _detailPath);
      });
    }
  });

  group('when the upload fails', () {
    final messages = <String, (ApiFailure, String)>{
      'a wrong file type': (
        const ApiFailure(
          code: 'PHOTO_TYPE_INVALID',
          field: 'file',
          statusCode: 422,
        ),
        photoTypeError,
      ),
      'a wrong file type without a field': (
        const ApiFailure(code: 'PHOTO_TYPE_INVALID'),
        photoTypeError,
      ),
      'a file that is too large': (
        const ApiFailure(
          code: 'PHOTO_TOO_LARGE',
          field: 'file',
          statusCode: 413,
        ),
        photoSizeError,
      ),
      'a file that is too large without a field': (
        const ApiFailure(code: 'PHOTO_TOO_LARGE'),
        photoSizeError,
      ),
      'a network failure': (
        const ApiFailure.network(),
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      ),
      'a server error': (
        const ApiFailure(code: 'INTERNAL_ERROR', statusCode: 500),
        'Terjadi kesalahan pada server. Coba lagi.',
      ),
      'an unknown code': (
        const ApiFailure(code: 'SOMETHING_NEW'),
        'Terjadi kesalahan. Coba lagi.',
      ),
      'a missing complaint': (
        const ApiFailure(code: 'COMPLAINT_NOT_FOUND', statusCode: 404),
        'Keluhan tidak ditemukan.',
      ),
    };

    Future<_Setup> failing(WidgetTester tester, ApiFailure failure) async {
      final s = _setup();
      s.repo.uploadPhotoScript.queue.add(failure);
      await _open(tester, s);
      await _pick(tester, s, addPhotoText, pngPhoto(name: 'satu.png'));
      return s;
    }

    for (final entry in messages.entries) {
      final (failure, message) = entry.value;

      testWidgets('${entry.key} shows its Indonesian message', (tester) async {
        await failing(tester, failure);

        expect(find.text(message), findsOneWidget);
        expect(currentPath(tester), _detailPath);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the message stays on screen', (tester) async {
      await failing(tester, const ApiFailure.network());

      await tester.pump(const Duration(seconds: 30));

      expect(
        find.text(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the tenant can try again with another photo', (tester) async {
      final s = await failing(tester, const ApiFailure.network());
      final second = pngPhoto(name: 'dua.png', length: 3000);

      await _pick(tester, s, addPhotoText, second);

      expect(s.repo.uploadPhotoCalls, 2);
      expect(s.repo.uploadedPhotos.last.image.name, 'dua.png');
      expect(s.repo.uploadedPhotos.last.image.bytes, second.bytes);
      expect(find.text(replacePhotoText), findsOneWidget);
    });

    testWidgets('a successful retry clears the message', (tester) async {
      final s = await failing(tester, const ApiFailure.network());

      await _pick(tester, s, addPhotoText, pngPhoto());

      expect(
        find.text(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        ),
        findsNothing,
      );
    });

    testWidgets('a failed upload leaves no Ganti foto behind', (tester) async {
      await failing(tester, const ApiFailure.network());

      expect(find.text(addPhotoText), findsOneWidget);
      expect(find.text(replacePhotoText), findsNothing);
    });

    group('because the complaint is no longer new', () {
      const conflict = ApiFailure(code: 'COMPLAINT_NOT_NEW', statusCode: 409);

      Future<_Setup> conflicted(
        WidgetTester tester, {
        bool hasPhoto = false,
      }) async {
        final s = _setup(hasPhoto: hasPhoto);
        s.repo.uploadPhotoScript.queue.add(conflict);
        await _open(tester, s);
        s.repo.complaints[0] = makeComplaint(
          status: ComplaintStatus.inProgress,
          hasPhoto: hasPhoto,
        );
        await _pick(
          tester,
          s,
          hasPhoto ? replacePhotoText : addPhotoText,
          pngPhoto(),
        );
        return s;
      }

      testWidgets('shows its message', (tester) async {
        await conflicted(tester);

        expect(find.text(photoNotNewError), findsOneWidget);
      });

      testWidgets('loads the complaint again', (tester) async {
        final s = await conflicted(tester);

        expect(s.repo.getCalls, 2);
      });

      testWidgets('then offers no Tambah foto', (tester) async {
        await conflicted(tester);

        expect(find.text(addPhotoText), findsNothing);
        expect(find.text(replacePhotoText), findsNothing);
      });

      testWidgets('then offers no Ganti foto', (tester) async {
        await conflicted(tester, hasPhoto: true);

        expect(find.text(addPhotoText), findsNothing);
        expect(find.text(replacePhotoText), findsNothing);
      });

      testWidgets('then shows the new status', (tester) async {
        await conflicted(tester);

        expect(find.text('Diproses'), findsAtLeastNWidgets(1));
      });

      testWidgets('meets the guidelines', (tester) async {
        await conflicted(tester);

        await expectMeetsA11yGuidelines(tester);
      });
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'new without a photo': (tester, large) =>
          _open(tester, _setup(), largeText: large),
      'new with a photo': (tester, large) =>
          _open(tester, _setup(hasPhoto: true), largeText: large),
      'in progress with a photo': (tester, large) => _open(
        tester,
        _setup(status: ComplaintStatus.inProgress, hasPhoto: true),
        largeText: large,
      ),
      'done with a photo': (tester, large) => _open(
        tester,
        _setup(status: ComplaintStatus.done, hasPhoto: true),
        largeText: large,
      ),
      'done without a photo': (tester, large) =>
          _open(tester, _setup(status: ComplaintStatus.done), largeText: large),
      'with a rejected photo': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s, addPhotoText, pdfPhoto());
      },
      'with an upload error': (tester, large) async {
        final s = _setup(hasPhoto: true);
        s.repo.uploadPhotoScript.queue.add(const ApiFailure.network());
        await _open(tester, s, largeText: large);
        await _pick(tester, s, replacePhotoText, pngPhoto());
      },
      'with denied access': (tester, large) async {
        final s = _setup();
        s.picker.failure = PlatformException(code: 'camera_access_denied');
        await _open(tester, s, largeText: large);
        await _pick(tester, s, addPhotoText, null, source: cameraChoice);
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines ${entry.key}', (tester) async {
        await entry.value(tester, false);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while the choice is open', (
      tester,
    ) async {
      await _open(tester, _setup(hasPhoto: true));
      await tester.tap(find.text(replacePhotoText));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the photo uploads', (tester) async {
      final s = _setup();
      s.repo.uploadPhotoScript.gate = Completer<void>();
      await _open(tester, s);
      s.picker.queue.add(pngPhoto());
      await tester.tap(find.text(addPhotoText));
      await tester.pumpAndSettle();
      await tester.tap(find.text(galleryChoice));
      await tester.pump();
      await tester.pump();

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
