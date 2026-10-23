import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Where a receipt image is taken from.
enum ReceiptSource { camera, gallery }

/// A receipt image chosen by the user.
class ReceiptFile {
  const ReceiptFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Lets the user take or choose a receipt image.
abstract interface class ReceiptPicker {
  /// The image the user chose, or null when the user cancelled. A photo from
  /// the camera is already encoded as JPEG.
  Future<ReceiptFile?> pick(ReceiptSource source);
}

final receiptPickerProvider = Provider<ReceiptPicker>(
  (ref) => DeviceReceiptPicker(),
);

/// Picks images with the device camera and gallery.
class DeviceReceiptPicker implements ReceiptPicker {
  final _picker = ImagePicker();

  @override
  Future<ReceiptFile?> pick(ReceiptSource source) async {
    // Setting a quality makes the plugin re-encode a camera photo as JPEG,
    // which the API accepts, where some cameras save HEIC.
    final image = switch (source) {
      ReceiptSource.camera => await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      ),
      ReceiptSource.gallery => await _picker.pickImage(
        source: ImageSource.gallery,
      ),
    };
    if (image == null) return null;
    return ReceiptFile(name: image.name, bytes: await image.readAsBytes());
  }
}

/// The media type of a JPEG or PNG image, read from its leading bytes, or null
/// for any other content.
String? receiptMediaType(Uint8List bytes) {
  bool startsWith(List<int> header) =>
      bytes.length >= header.length &&
      header.indexed.every((entry) => bytes[entry.$1] == entry.$2);
  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  return null;
}
