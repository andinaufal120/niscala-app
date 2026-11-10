import 'package:flutter/material.dart';
import 'package:niscala/core/image_chooser.dart';

/// Asks whether the image comes from the camera or the gallery. Resolves to
/// null when the sheet is dismissed without a choice.
Future<ImageOrigin?> chooseImageSource(BuildContext context) {
  return showModalBottomSheet<ImageOrigin>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Ambil dari kamera'),
          onTap: () => Navigator.pop(sheetContext, ImageOrigin.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Pilih dari galeri'),
          onTap: () => Navigator.pop(sheetContext, ImageOrigin.gallery),
        ),
      ],
    ),
  );
}
