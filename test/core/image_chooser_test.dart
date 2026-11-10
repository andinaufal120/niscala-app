import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/image_chooser.dart';

void main() {
  test('offers the camera and the gallery as sources', () {
    expect(ImageOrigin.values, unorderedEquals(ImageOrigin.values));
    expect(
      ImageOrigin.values.map((s) => s.name),
      containsAll(['camera', 'gallery']),
    );
    expect(ImageOrigin.values, hasLength(2));
  });

  test('a receipt file keeps its name and bytes', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    final file = PickedImage(name: 'bukti.jpg', bytes: bytes);

    expect(file.name, 'bukti.jpg');
    expect(file.bytes, bytes);
  });
}
