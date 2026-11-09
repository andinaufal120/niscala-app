import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Where an image is taken from.
enum ImageOrigin { camera, gallery }

/// An image chosen by the user.
class PickedImage {
  const PickedImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Lets the user take or choose an image.
abstract interface class ImageChooser {
  /// The image the user chose, or null when the user cancelled. A photo from
  /// the camera is already encoded as JPEG.
  Future<PickedImage?> pick(ImageOrigin source);
}

final imageChooserProvider = Provider<ImageChooser>(
  (ref) => DeviceImageChooser(),
);

/// Picks images with the device camera and gallery.
class DeviceImageChooser implements ImageChooser {
  final _picker = ImagePicker();

  @override
  Future<PickedImage?> pick(ImageOrigin source) async {
    // Setting a quality makes the plugin re-encode a camera photo as JPEG,
    // which the API accepts, where some cameras save HEIC.
    final image = switch (source) {
      ImageOrigin.camera => await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      ),
      ImageOrigin.gallery => await _picker.pickImage(
        source: ImageSource.gallery,
      ),
    };
    if (image == null) return null;
    return PickedImage(name: image.name, bytes: await image.readAsBytes());
  }
}

/// The media type of a JPEG or PNG image, read from its leading bytes, or null
/// for any other content.
String? imageMediaType(Uint8List bytes) {
  bool startsWith(List<int> header) =>
      bytes.length >= header.length &&
      header.indexed.every((entry) => bytes[entry.$1] == entry.$2);
  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  return null;
}

/// The largest image that can be sent, in bytes.
const maxImageBytes = 5 * 1024 * 1024;

/// Shown when the camera or the gallery cannot be used.
const imageAccessDeniedMessage =
    'Tidak bisa mengakses kamera atau galeri. Periksa izin aplikasi.';

/// Why an image cannot be sent.
enum ImageRejection { type, tooLarge }

/// The reason [image] cannot be sent, or null when it is a JPG or PNG of at
/// most [maxImageBytes]. The content decides the type, not the file name.
ImageRejection? imageRejection(PickedImage image) {
  if (imageMediaType(image.bytes) == null) return ImageRejection.type;
  if (image.bytes.length > maxImageBytes) return ImageRejection.tooLarge;
  return null;
}
