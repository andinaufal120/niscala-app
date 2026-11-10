import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/image_chooser.dart';

import '../../../helpers/fakes.dart';
export 'complaint_ui_helpers.dart';

const maxPhotoBytes = 5 * 1024 * 1024;

const photoFieldLabel = 'Foto (opsional)';
const photoTileText = 'Ambil atau pilih foto';
const cameraChoice = 'Ambil dari kamera';
const galleryChoice = 'Pilih dari galeri';
const removePhotoText = 'Hapus foto';
const addPhotoText = 'Tambah foto';
const replacePhotoText = 'Ganti foto';

const photoTypeError = 'Foto harus JPG atau PNG.';
const photoSizeError = 'Ukuran foto maksimal 5 MB.';
const photoNotNewError =
    'Foto hanya bisa diubah selama keluhan berstatus Baru.';
const photoNotFoundError = 'Foto tidak ditemukan.';
const photoAccessDenied =
    'Tidak bisa mengakses kamera atau galeri. Periksa izin aplikasi.';
const photoUploadWarning =
    'Keluhan terkirim, tetapi foto belum terunggah. Coba lagi lewat Tambah foto.';

/// The assistive technology label of the photo of a complaint sent on
/// 18 Okt 2026, which is the date of the default [makeComplaint].
const photoLabel = 'Foto keluhan, 18 Okt 2026';

/// A valid PNG image, padded with zero bytes to [length] bytes when that is
/// longer than the image itself.
PickedImage pngPhoto({String name = 'keran.png', int? length}) {
  final size = length == null || length < tinyPng.length
      ? tinyPng.length
      : length;
  final bytes = Uint8List(size)..setAll(0, tinyPng);
  return PickedImage(name: name, bytes: bytes);
}

PickedImage _withHeader(String name, List<int> header, int length) {
  final bytes = Uint8List(length < header.length ? header.length : length)
    ..setAll(0, header);
  return PickedImage(name: name, bytes: bytes);
}

/// A file that starts like a JPEG image. It is not decodable.
PickedImage jpegPhoto({String name = 'keran.jpg', int length = 2048}) =>
    _withHeader(name, const [0xFF, 0xD8, 0xFF, 0xE0], length);

/// A PDF document, which is not an accepted photo type.
PickedImage pdfPhoto({String name = 'keran.pdf'}) =>
    _withHeader(name, '%PDF-1.4'.codeUnits, 2048);

/// A PDF document renamed to look like a JPEG.
PickedImage pdfNamedJpg() => pdfPhoto(name: 'keran.jpg');

/// A HEIC photo, which many Android cameras save.
PickedImage heicPhoto({String name = 'keran.heic'}) =>
    _withHeader(name, [0x00, 0x00, 0x00, 0x18, ...'ftypheic'.codeUnits], 2048);

/// A GIF image, which is not an accepted photo type.
PickedImage gifPhoto({String name = 'keran.gif'}) =>
    _withHeader(name, 'GIF89a'.codeUnits, 2048);

/// The photo tile of a complaint detail, found by its label for assistive
/// technology. [date] is the sent date as shown, such as `18 Okt 2026`. The
/// test must hold a semantics handle, as `testWidgetsWithSemantics` does.
Finder photoTile({String date = '18 Okt 2026'}) =>
    find.bySemanticsLabel(RegExp('Foto keluhan, $date'));

/// Taps the photo tile and lets the full-screen view open.
Future<void> openPhotoFromTile(WidgetTester tester) async {
  final tile = photoTile().first;
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

/// Taps [source] in the open choice of camera or gallery.
Future<void> chooseSource(WidgetTester tester, String source) async {
  await tester.tap(find.text(source));
  await tester.pumpAndSettle();
}

/// Taps [opener], then the [source] of the choice that opens, with [file]
/// queued as the answer of [picker].
Future<void> pickWith(
  WidgetTester tester,
  FakeImageChooser picker,
  Finder opener,
  PickedImage? file, {
  String source = galleryChoice,
}) async {
  picker.queue.add(file);
  await tester.ensureVisible(opener);
  await tester.pumpAndSettle();
  await tester.tap(opener);
  await tester.pumpAndSettle();
  await chooseSource(tester, source);
}

/// Lets the image codec finish, which runs outside of the fake clock.
Future<void> decodeImages(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// The bytes of the single image that [inside] contains.
Uint8List shownBytes(WidgetTester tester, Finder inside) {
  final image = tester
      .widget<Image>(find.descendant(of: inside, matching: find.byType(Image)))
      .image;
  return (image as MemoryImage).bytes;
}
