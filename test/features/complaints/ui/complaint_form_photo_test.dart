import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'complaint_photo_helpers.dart';

const _label = 'Deskripsi keluhan (wajib)';
const _send = 'Kirim Keluhan';
const _valid = 'Keran air di kamar mandi bocor.';
const _formPath = '/penyewa/keluhan/baru';
const _detailPath = '/penyewa/keluhan/new-1';

({FakeComplaintRepository repo, FakeImageChooser picker}) _setup() =>
    (repo: FakeComplaintRepository(), picker: FakeImageChooser());

Future<void> _open(
  WidgetTester tester,
  ({FakeComplaintRepository repo, FakeImageChooser picker}) s, {
  FakeLeaseRepository? leases,
  bool largeText = false,
}) => pumpComplaintApp(
  tester,
  s.repo,
  path: _formPath,
  picker: s.picker,
  leases: leases,
  largeText: largeText,
);

Future<void> _write(WidgetTester tester, [String text = _valid]) =>
    typeInto(tester, _label, text);

Future<void> _submit(WidgetTester tester) =>
    tapVisible(tester, find.text(_send));

Future<void> _pick(
  WidgetTester tester,
  FakeImageChooser picker,
  PickedImage? file, {
  String source = galleryChoice,
}) => pickWith(tester, picker, find.text(photoTileText), file, source: source);

Finder _preview() => find.descendant(
  of: find.byType(ComplaintFormScreen),
  matching: find.byType(Image),
);

/// The calls that save a complaint or its photo, in order.
List<String> _saves(FakeComplaintRepository repo) => [
  for (final call in repo.calls)
    if (call == 'submit' || call.startsWith('uploadPhoto:')) call,
];

void main() {
  group('layout', () {
    testWidgets('offers an optional photo with a tile to take or pick one', (
      tester,
    ) async {
      await _open(tester, _setup());

      expect(find.text(photoFieldLabel), findsOneWidget);
      expect(find.text(photoTileText), findsOneWidget);
      expectTargetSize(tester, photoTileText);
    });

    testWidgets('starts without a preview, a remove action or an error', (
      tester,
    ) async {
      await _open(tester, _setup());

      expect(_preview(), findsNothing);
      expect(find.text(removePhotoText), findsNothing);
      for (final text in [photoTypeError, photoSizeError, photoAccessDenied]) {
        expect(find.text(text), findsNothing);
      }
    });

    testWidgets('does not ask for a photo before the tile is tapped', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      expect(s.picker.requested, isEmpty);
      expect(find.text(cameraChoice), findsNothing);
      expect(find.text(galleryChoice), findsNothing);
    });

    testWidgets('puts the photo below the room and keeps the send button '
        'pinned', (tester) async {
      await _open(tester, _setup());

      expect(
        tester.getTopLeft(find.text('Kos Melati · Kamar 08')).dy,
        lessThan(tester.getTopLeft(find.text(photoFieldLabel)).dy),
      );
      expectPinnedFooter(tester, _send);
    });
  });

  group('choosing the source', () {
    testWidgets('the tile offers the camera and the gallery', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await tester.tap(find.text(photoTileText));
      await tester.pumpAndSettle();

      expect(find.text(cameraChoice), findsOneWidget);
      expect(find.text(galleryChoice), findsOneWidget);
      expectTargetSize(tester, cameraChoice);
      expectTargetSize(tester, galleryChoice);
      expect(s.picker.requested, isEmpty);
    });

    testWidgets('the gallery choice asks for the gallery', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, null);

      expect(s.picker.requested, [ImageOrigin.gallery]);
    });

    testWidgets('the camera choice asks for the camera', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, null, source: cameraChoice);

      expect(s.picker.requested, [ImageOrigin.camera]);
    });

    testWidgets('closing the choice without choosing changes nothing', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await tester.tap(find.text(photoTileText));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text(cameraChoice), findsNothing);
      expect(find.text(galleryChoice), findsNothing);
      expect(s.picker.requested, isEmpty);
      expect(_preview(), findsNothing);
      expect(find.text(photoTileText), findsOneWidget);
      expect(currentPath(tester), _formPath);
    });

    testWidgets('choosing the source does not send the complaint', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, pngPhoto());

      expect(s.repo.submitCalls, 0);
      expect(s.repo.uploadPhotoCalls, 0);
      expect(currentPath(tester), _formPath);
    });
  });

  group('picking', () {
    testWidgets('cancelling the picker changes nothing', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, null);

      expect(_preview(), findsNothing);
      expect(find.text(removePhotoText), findsNothing);
      expect(find.text(photoTileText), findsOneWidget);
      for (final text in [photoTypeError, photoSizeError, photoAccessDenied]) {
        expect(find.text(text), findsNothing);
      }
    });

    testWidgets('shows a preview of the chosen image and a remove action', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      final photo = pngPhoto();

      await _pick(tester, s.picker, photo);

      expect(_preview(), findsOneWidget);
      expect(shownBytes(tester, find.byType(ComplaintFormScreen)), photo.bytes);
      expect(find.text(removePhotoText), findsOneWidget);
      expectTargetSize(tester, removePhotoText);
      for (final text in [photoTypeError, photoSizeError]) {
        expect(find.text(text), findsNothing);
      }
    });

    testWidgets('a photo from the camera shows a preview too', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, pngPhoto(), source: cameraChoice);

      expect(_preview(), findsOneWidget);
      expect(s.picker.requested, [ImageOrigin.camera]);
    });

    testWidgets('choosing a photo does not send anything', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, pngPhoto());

      expect(_saves(s.repo), isEmpty);
    });

    final accepted = <String, PickedImage Function()>{
      'a PNG file': pngPhoto,
      'a JPG file': jpegPhoto,
      'a JPEG with an upper case extension': () => jpegPhoto(name: 'FOTO.JPEG'),
      'a PNG of exactly 5 MB': () => pngPhoto(length: maxPhotoBytes),
      'a JPG of exactly 5 MB': () => jpegPhoto(length: maxPhotoBytes),
    };
    for (final entry in accepted.entries) {
      testWidgets('accepts ${entry.key}', (tester) async {
        final s = _setup();
        await _open(tester, s);

        await _pick(tester, s.picker, entry.value());

        expect(find.text(photoTypeError), findsNothing);
        expect(find.text(photoSizeError), findsNothing);
        expect(find.text(removePhotoText), findsOneWidget);
      });
    }

    final wrongType = <String, PickedImage Function()>{
      'a PDF': pdfPhoto,
      'a PDF renamed to JPG': pdfNamedJpg,
      'a HEIC photo': heicPhoto,
      'a GIF image': gifPhoto,
    };
    for (final entry in wrongType.entries) {
      testWidgets('rejects ${entry.key} with the type message', (tester) async {
        final s = _setup();
        await _open(tester, s);

        await _pick(tester, s.picker, entry.value());

        expect(find.text(photoTypeError), findsOneWidget);
        expect(find.text(photoSizeError), findsNothing);
        expect(_preview(), findsNothing);
        expect(find.text(removePhotoText), findsNothing);
        expect(_saves(s.repo), isEmpty);
      });

      testWidgets('does not keep ${entry.key}', (tester) async {
        final s = _setup();
        await _open(tester, s);
        await _pick(tester, s.picker, entry.value());
        await _write(tester);

        await _submit(tester);

        expect(s.repo.submitCalls, 1);
        expect(s.repo.uploadPhotoCalls, 0);
      });
    }

    testWidgets('rejects an image over 5 MB with the size message', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, pngPhoto(length: maxPhotoBytes + 1));

      expect(find.text(photoSizeError), findsOneWidget);
      expect(find.text(photoTypeError), findsNothing);
      expect(_preview(), findsNothing);
      expect(find.text(removePhotoText), findsNothing);
    });

    testWidgets('does not keep an image over 5 MB', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, jpegPhoto(length: maxPhotoBytes + 1));
      await _write(tester);

      await _submit(tester);

      expect(s.repo.submitCalls, 1);
      expect(s.repo.uploadPhotoCalls, 0);
    });

    testWidgets('shows a rejection next to the photo, below its label', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, pdfPhoto());

      expect(
        tester.getTopLeft(find.text(photoTypeError)).dy,
        greaterThan(tester.getTopLeft(find.text(photoFieldLabel)).dy),
      );
    });

    testWidgets('announces a rejection as a live region', (tester) async {
      final s = _setup();
      await _open(tester, s);

      await _pick(tester, s.picker, pdfPhoto());

      expectLiveRegion(tester, photoTypeError);
    });

    testWidgets('a rejection leaves the description untouched', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _write(tester);

      await _pick(tester, s.picker, pdfPhoto());

      expect(labeledTextField(tester, _label).controller!.text, _valid);
      expect(labeledFieldError(tester, _label), isNull);
    });

    testWidgets('a valid photo clears the earlier rejection', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pdfPhoto());
      expect(find.text(photoTypeError), findsOneWidget);

      await _pick(tester, s.picker, pngPhoto());

      expect(find.text(photoTypeError), findsNothing);
      expect(_preview(), findsOneWidget);
    });

    testWidgets('a different rejection replaces the earlier one', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pdfPhoto());

      await _pick(tester, s.picker, pngPhoto(length: maxPhotoBytes + 1));

      expect(find.text(photoTypeError), findsNothing);
      expect(find.text(photoSizeError), findsOneWidget);
    });
  });

  group('denied camera or gallery access', () {
    final sources = {
      cameraChoice: (
        PlatformException(code: 'camera_access_denied'),
        ImageOrigin.camera,
      ),
      galleryChoice: (
        PlatformException(code: 'photo_access_denied'),
        ImageOrigin.gallery,
      ),
    };
    for (final entry in sources.entries) {
      final (error, origin) = entry.value;

      testWidgets('${entry.key} shows the access message', (tester) async {
        final s = _setup();
        s.picker.failure = error;
        await _open(tester, s);

        await _pick(tester, s.picker, null, source: entry.key);

        expect(s.picker.requested, [origin]);
        expect(find.text(photoAccessDenied), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(_preview(), findsNothing);
        expect(currentPath(tester), _formPath);
      });

      testWidgets('${entry.key} announces the access message', (tester) async {
        final s = _setup();
        s.picker.failure = error;
        await _open(tester, s);

        await _pick(tester, s.picker, null, source: entry.key);

        expectLiveRegion(tester, photoAccessDenied);
      });
    }

    testWidgets('denied access still lets the complaint be sent without a '
        'photo', (tester) async {
      final s = _setup();
      s.picker.failure = PlatformException(code: 'camera_access_denied');
      await _open(tester, s);
      await _pick(tester, s.picker, null, source: cameraChoice);
      await _write(tester);

      await _submit(tester);

      expect(_saves(s.repo), ['submit']);
      expect(currentPath(tester), _detailPath);
    });
  });

  group('removing the photo', () {
    testWidgets('Hapus foto removes the preview and brings back the tile', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());

      await tapVisible(tester, find.text(removePhotoText));

      expect(_preview(), findsNothing);
      expect(find.text(removePhotoText), findsNothing);
      expect(find.text(photoTileText), findsOneWidget);
    });

    testWidgets('removing the photo sends nothing and does not navigate', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());

      await tapVisible(tester, find.text(removePhotoText));

      expect(_saves(s.repo), isEmpty);
      expect(currentPath(tester), _formPath);
    });

    testWidgets('a complaint sent after removing the photo has no upload', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await tapVisible(tester, find.text(removePhotoText));
      await _write(tester);

      await _submit(tester);

      expect(_saves(s.repo), ['submit']);
    });

    testWidgets('another photo can be chosen after removing the first', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto(name: 'satu.png'));
      await tapVisible(tester, find.text(removePhotoText));
      final second = pngPhoto(name: 'dua.png', length: 4096);
      await _pick(tester, s.picker, second);
      await _write(tester);

      await _submit(tester);

      expect(s.repo.uploadedPhotos, hasLength(1));
      expect(s.repo.uploadedPhotos.single.image.name, 'dua.png');
      expect(s.repo.uploadedPhotos.single.image.bytes, second.bytes);
    });

    testWidgets('removing a photo keeps the description', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _write(tester);
      await _pick(tester, s.picker, pngPhoto());

      await tapVisible(tester, find.text(removePhotoText));

      expect(labeledTextField(tester, _label).controller!.text, _valid);
    });
  });

  group('sending without a photo', () {
    testWidgets('creates the complaint and uploads nothing', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _write(tester);

      await _submit(tester);

      expect(_saves(s.repo), ['submit']);
      expect(s.repo.uploadedPhotos, isEmpty);
      expect(currentPath(tester), _detailPath);
      expect(find.text('Keluhan terkirim.'), findsOneWidget);
    });
  });

  group('sending with a photo', () {
    testWidgets('creates the complaint first, then uploads the photo to it', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      final photo = pngPhoto(name: 'keran-bocor.png', length: 4096);
      await _pick(tester, s.picker, photo);
      await _write(tester);

      await _submit(tester);

      expect(_saves(s.repo), ['submit', 'uploadPhoto:new-1']);
      expect(s.repo.submitted, [_valid]);
      expect(s.repo.uploadedPhotos, hasLength(1));
      expect(s.repo.uploadedPhotos.single.id, 'new-1');
      expect(s.repo.uploadedPhotos.single.image.name, 'keran-bocor.png');
      expect(s.repo.uploadedPhotos.single.image.bytes, photo.bytes);
    });

    testWidgets('a JPEG from the camera is uploaded as chosen', (tester) async {
      final s = _setup();
      await _open(tester, s);
      final photo = jpegPhoto(name: 'kamera.jpg');
      await _pick(tester, s.picker, photo, source: cameraChoice);
      await _write(tester);

      await _submit(tester);

      expect(s.repo.uploadedPhotos.single.image.name, 'kamera.jpg');
      expect(s.repo.uploadedPhotos.single.image.bytes, photo.bytes);
    });

    testWidgets('lands on the detail with the confirmation', (tester) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await _submit(tester);

      expect(currentPath(tester), _detailPath);
      expect(find.byType(ComplaintFormScreen), findsNothing);
      final detail = tester.widget<TenantComplaintDetailScreen>(
        find.byType(TenantComplaintDetailScreen),
      );
      expect(detail.complaintId, 'new-1');
      expect(detail.submitted, isTrue);
      expect(find.text('Keluhan terkirim.'), findsOneWidget);
      expect(find.text(photoUploadWarning), findsNothing);
    });

    testWidgetsWithSemantics('the detail shows the uploaded photo', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await _submit(tester);

      expect(photoTile(), findsAtLeastNWidgets(1));
    });

    testWidgets('does not upload before the complaint is saved', (
      tester,
    ) async {
      final s = _setup();
      final gate = Completer<void>();
      s.repo.submitScript.gate = gate;
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await tapAndPump(tester, find.text(_send));
      await tester.pump();

      expect(s.repo.submitCalls, 1);
      expect(s.repo.uploadPhotoCalls, 0);
      gate.complete();
      await tester.pumpAndSettle();
      expect(s.repo.uploadPhotoCalls, 1);
    });

    testWidgets('shows progress until the photo is uploaded', (tester) async {
      final s = _setup();
      final gate = Completer<void>();
      s.repo.uploadPhotoScript.gate = gate;
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await tapAndPump(tester, find.text(_send));
      await tester.pump();
      await tester.pump();

      expectBusy(tester);
      expect(currentPath(tester), _formPath);
      expect(s.repo.uploadPhotoCalls, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(currentPath(tester), _detailPath);
    });

    testWidgets('taps while the photo uploads do not create a second '
        'complaint or upload', (tester) async {
      final s = _setup();
      final gate = Completer<void>();
      s.repo.uploadPhotoScript.gate = gate;
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await tapAndPump(tester, find.text(_send));
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();

      expect(s.repo.submitCalls, 1);
      expect(s.repo.uploadPhotoCalls, 1);
      expect(s.repo.complaints, hasLength(1));
    });

    testWidgets('a failed create uploads nothing and keeps the photo', (
      tester,
    ) async {
      final s = _setup();
      s.repo.submitScript.queue.add(const ApiFailure.network());
      await _open(tester, s);
      final photo = pngPhoto();
      await _pick(tester, s.picker, photo);
      await _write(tester);

      await _submit(tester);

      expect(s.repo.uploadPhotoCalls, 0);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(currentPath(tester), _formPath);
      expect(shownBytes(tester, find.byType(ComplaintFormScreen)), photo.bytes);
    });

    testWidgets('retrying a failed create saves once and uploads once', (
      tester,
    ) async {
      final s = _setup();
      s.repo.submitScript.queue.add(const ApiFailure.network());
      await _open(tester, s);
      final photo = pngPhoto(length: 3000);
      await _pick(tester, s.picker, photo);
      await _write(tester);
      await _submit(tester);

      await _submit(tester);

      expect(_saves(s.repo), ['submit', 'submit', 'uploadPhoto:new-1']);
      expect(s.repo.complaints, hasLength(1));
      expect(s.repo.uploadedPhotos.single.image.bytes, photo.bytes);
      expect(currentPath(tester), _detailPath);
    });

    testWidgets('an invalid description uploads nothing and keeps the photo', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester, 'pendek');

      await _submit(tester);

      expect(_saves(s.repo), isEmpty);
      expect(labeledFieldError(tester, _label), isNotNull);
      expect(find.text(removePhotoText), findsOneWidget);
    });

    testWidgets('with several leases it uploads to the complaint of the room '
        'chosen', (tester) async {
      final s = _setup();
      await _open(
        tester,
        s,
        leases: FakeLeaseRepository(leases: makeTwoLeases()),
      );
      await tapVisible(
        tester,
        find.ancestor(
          of: find.text('Kos Mawar · Kamar 12'),
          matching: find.byWidgetPredicate((w) => w is RadioListTile),
        ),
      );
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await _submit(tester);

      expect(s.repo.submittedRoomIds, ['r2']);
      expect(_saves(s.repo), ['submit', 'uploadPhoto:new-1']);
    });

    testWidgets('a missing room with a photo sends and uploads nothing', (
      tester,
    ) async {
      final s = _setup();
      await _open(
        tester,
        s,
        leases: FakeLeaseRepository(leases: makeTwoLeases()),
      );
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);

      await _submit(tester);

      expect(find.text('Pilih kamar.'), findsOneWidget);
      expect(_saves(s.repo), isEmpty);
    });
  });

  group('when the photo fails to upload', () {
    final failures = <String, ApiFailure>{
      'a network failure': const ApiFailure.network(),
      'a photo that is too large': const ApiFailure(
        code: 'PHOTO_TOO_LARGE',
        field: 'file',
        statusCode: 413,
      ),
      'a photo of the wrong type': const ApiFailure(
        code: 'PHOTO_TYPE_INVALID',
        field: 'file',
        statusCode: 422,
      ),
      'a server error': const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      ),
      'an unknown code': const ApiFailure(code: 'SOMETHING_NEW'),
    };

    Future<({FakeComplaintRepository repo, FakeImageChooser picker})> failed(
      WidgetTester tester,
      ApiFailure failure, {
      bool largeText = false,
    }) async {
      final s = _setup();
      s.repo.uploadPhotoScript.queue.add(failure);
      await _open(tester, s, largeText: largeText);
      await _pick(tester, s.picker, pngPhoto(name: 'satu.png'));
      await _write(tester);
      await _submit(tester);
      return s;
    }

    for (final entry in failures.entries) {
      testWidgets('${entry.key} keeps the complaint and opens its detail with '
          'a warning', (tester) async {
        final s = await failed(tester, entry.value);

        expect(s.repo.complaints, hasLength(1));
        expect(s.repo.submitCalls, 1);
        expect(currentPath(tester), _detailPath);
        expect(find.byType(ComplaintFormScreen), findsNothing);
        expect(find.byType(TenantComplaintDetailScreen), findsOneWidget);
        expect(find.text(photoUploadWarning), findsOneWidget);
      });
    }

    testWidgets('the warning replaces the plain confirmation', (tester) async {
      await failed(tester, const ApiFailure.network());

      expect(find.text('Keluhan terkirim.'), findsNothing);
    });

    testWidgets('the warning stays on screen', (tester) async {
      await failed(tester, const ApiFailure.network());

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(photoUploadWarning), findsOneWidget);
    });

    testWidgets('the detail offers Tambah foto and no Ganti foto', (
      tester,
    ) async {
      await failed(tester, const ApiFailure.network());

      expect(find.text(addPhotoText), findsOneWidget);
      expect(find.text(replacePhotoText), findsNothing);
    });

    testWidgetsWithSemantics('the detail shows no photo tile', (tester) async {
      await failed(tester, const ApiFailure.network());

      expect(photoTile(), findsNothing);
    });

    testWidgets('Tambah foto uploads a newly chosen photo without creating '
        'the complaint again', (tester) async {
      final s = await failed(tester, const ApiFailure.network());
      final second = pngPhoto(name: 'dua.png', length: 5000);

      await pickWith(tester, s.picker, find.text(addPhotoText), second);

      expect(s.repo.submitCalls, 1);
      expect(s.repo.uploadPhotoCalls, 2);
      expect(s.repo.uploadedPhotos.last.id, 'new-1');
      expect(s.repo.uploadedPhotos.last.image.name, 'dua.png');
      expect(s.repo.uploadedPhotos.last.image.bytes, second.bytes);
      expect(s.repo.complaints, hasLength(1));
    });

    testWidgets('Tambah foto uploads nothing until a photo is chosen', (
      tester,
    ) async {
      final s = await failed(tester, const ApiFailure.network());

      await tester.tap(find.text(addPhotoText));
      await tester.pumpAndSettle();

      expect(s.repo.uploadPhotoCalls, 1);
      expect(s.picker.requested, [ImageOrigin.gallery]);
    });

    testWidgets('meets the guidelines on the detail with the warning', (
      tester,
    ) async {
      await failed(tester, const ApiFailure.network());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size on the detail with the warning', (
      tester,
    ) async {
      await failed(tester, const ApiFailure.network(), largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text(photoUploadWarning), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'initial': (tester, large) => _open(tester, _setup(), largeText: large),
      'with a chosen photo': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, pngPhoto());
      },
      'with a type error': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, pdfPhoto());
      },
      'with a size error': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, pngPhoto(length: maxPhotoBytes + 1));
      },
      'with denied access': (tester, large) async {
        final s = _setup();
        s.picker.failure = PlatformException(code: 'photo_access_denied');
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, null);
      },
      'with a chosen photo and a field error': (tester, large) async {
        final s = _setup();
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, pngPhoto());
        await _submit(tester);
      },
      'with a chosen photo and a banner': (tester, large) async {
        final s = _setup();
        s.repo.submitScript.queue.add(const ApiFailure.network());
        await _open(tester, s, largeText: large);
        await _pick(tester, s.picker, pngPhoto());
        await _write(tester);
        await _submit(tester);
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
      final s = _setup();
      await _open(tester, s);
      await tester.tap(find.text(photoTileText));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while the choice is open', (
      tester,
    ) async {
      final s = _setup();
      await _open(tester, s, largeText: true);
      await tester.ensureVisible(find.text(photoTileText));
      await tester.pumpAndSettle();
      await tester.tap(find.text(photoTileText));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines while the photo uploads', (tester) async {
      final s = _setup();
      s.repo.uploadPhotoScript.gate = Completer<void>();
      await _open(tester, s);
      await _pick(tester, s.picker, pngPhoto());
      await _write(tester);
      await tapAndPump(tester, find.text(_send));
      await tester.pump();

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
