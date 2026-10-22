import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';

void main() {
  test('offers the camera and the gallery as sources', () {
    expect(ReceiptSource.values, unorderedEquals(ReceiptSource.values));
    expect(
      ReceiptSource.values.map((s) => s.name),
      containsAll(['camera', 'gallery']),
    );
    expect(ReceiptSource.values, hasLength(2));
  });

  test('a receipt file keeps its name and bytes', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    final file = ReceiptFile(name: 'bukti.jpg', bytes: bytes);

    expect(file.name, 'bukti.jpg');
    expect(file.bytes, bytes);
  });
}
