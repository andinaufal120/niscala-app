import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala_api/api.dart';

/// The `file` part of an upload of [image]. Its content type is the media type
/// of the bytes, so a misnamed file is still declared as what it is.
http.MultipartFile imageUploadPart(PickedImage image) {
  final type = imageMediaType(image.bytes) ?? 'application/octet-stream';
  return http.MultipartFile.fromBytes(
    'file',
    image.bytes,
    filename: image.name,
    contentType: MediaType.parse(type),
  );
}

/// The body of an image response, as received. A response with an error status
/// throws the [ApiException] for it instead.
Uint8List imageBytesOf(http.Response response) {
  if (response.statusCode >= 400) {
    throw ApiException(response.statusCode, response.body);
  }
  return response.bodyBytes;
}
