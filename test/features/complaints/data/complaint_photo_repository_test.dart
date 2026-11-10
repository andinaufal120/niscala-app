import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _summaryJson({
  String id = 'c1',
  String status = 'new',
  bool hasPhoto = false,
}) => {
  'id': id,
  'description': 'Keran bocor di kamar mandi.',
  'status': status,
  'classification': null,
  'classificationState': null,
  'classificationWithheld': false,
  'createdAt': '2026-10-18T12:00:00Z',
  'hasPhoto': hasPhoto,
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'room': {'id': 'r1', 'number': '08'},
  'tenantName': 'Budi Santoso',
};

Map<String, Object?> _complaintJson({
  String id = 'c1',
  String status = 'new',
  bool hasPhoto = false,
}) => {
  ..._summaryJson(id: id, status: status, hasPhoto: hasPhoto),
  'statusChanges': <Object?>[],
};

class _Harness {
  _Harness(http.Response Function(http.Request request) respond) {
    _build(
      MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  _Harness.failing(Object error) {
    _build(
      MockClient((request) async {
        requests.add(request);
        throw error;
      }),
    );
  }

  void _build(http.Client client) {
    final apiClient = ApiClient(basePath: 'http://api.test')..client = client;
    repository = ApiComplaintRepository(complaints: ComplaintsApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiComplaintRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('hasPhoto', () {
    test('is read from a listed complaint', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(id: 'a', hasPhoto: true),
            _summaryJson(id: 'b'),
          ],
        }),
      );

      final result = await h.repository.list();

      expect(result.map((c) => c.hasPhoto), [true, false]);
    });

    test('is read from the detail of a complaint', () async {
      final h = _Harness((_) => _ok(_complaintJson(hasPhoto: true)));

      expect((await h.repository.get('c1')).hasPhoto, isTrue);
    });

    test('is false for a complaint without a photo', () async {
      final h = _Harness((_) => _ok(_complaintJson()));

      expect((await h.repository.get('c1')).hasPhoto, isFalse);
    });
  });

  group('uploadPhoto', () {
    final jpeg = PickedImage(
      name: 'keran.jpg',
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4, 5]),
    );
    final png = PickedImage(
      name: 'keran.png',
      bytes: Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        9,
        8,
        7,
      ]),
    );

    String bodyOf(http.Request request) => latin1.decode(request.bodyBytes);

    test(
      'puts the file as multipart form data and returns the complaint',
      () async {
        final h = _Harness(
          (_) => _ok(_complaintJson(id: 'c7', hasPhoto: true)),
        );

        final c = await h.repository.uploadPhoto('c7', jpeg);

        expect(h.request.method, 'PUT');
        expect(h.request.url.path, '/complaints/c7/photo');
        expect(
          h.request.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(c.id, 'c7');
        expect(c.hasPhoto, isTrue);
      },
    );

    test('names the part file and keeps the file name and bytes', () async {
      final h = _Harness((_) => _ok(_complaintJson(hasPhoto: true)));

      await h.repository.uploadPhoto('c1', jpeg);

      final body = bodyOf(h.request);
      expect(body, contains('name="file"'));
      expect(body, contains('filename="keran.jpg"'));
      expect(body, contains(latin1.decode(jpeg.bytes)));
    });

    test('declares a JPEG file as image/jpeg', () async {
      final h = _Harness((_) => _ok(_complaintJson(hasPhoto: true)));

      await h.repository.uploadPhoto('c1', jpeg);

      expect(
        bodyOf(h.request).toLowerCase(),
        contains('content-type: image/jpeg'),
      );
    });

    test('declares a PNG file as image/png', () async {
      final h = _Harness((_) => _ok(_complaintJson(hasPhoto: true)));

      await h.repository.uploadPhoto('c1', png);

      final body = bodyOf(h.request);
      expect(body, contains('filename="keran.png"'));
      expect(body.toLowerCase(), contains('content-type: image/png'));
    });

    test(
      'declares the type from the content, not from the file name',
      () async {
        final h = _Harness((_) => _ok(_complaintJson(hasPhoto: true)));
        final misnamed = PickedImage(name: 'keran.jpg', bytes: png.bytes);

        await h.repository.uploadPhoto('c1', misnamed);

        expect(
          bodyOf(h.request).toLowerCase(),
          contains('content-type: image/png'),
        );
      },
    );

    test('sends exactly one request', () async {
      final h = _Harness((_) => _ok(_complaintJson(hasPhoto: true)));

      await h.repository.uploadPhoto('c1', jpeg);

      expect(h.requests, hasLength(1));
    });

    final failures = <String, (int, String, String?)>{
      'a validation error on the file': (422, 'VALIDATION_FAILED', 'file'),
      'a wrong file type': (422, 'PHOTO_TYPE_INVALID', 'file'),
      'a file that is too large': (413, 'PHOTO_TOO_LARGE', 'file'),
      'a complaint that is no longer new': (409, 'COMPLAINT_NOT_NEW', null),
      'a missing complaint': (404, 'COMPLAINT_NOT_FOUND', null),
      'a forbidden response': (403, 'FORBIDDEN', null),
    };
    for (final entry in failures.entries) {
      final (status, code, field) = entry.value;
      test('keeps the code, field and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(status, code, field: field));

        await expectLater(
          h.repository.uploadPhoto('c1', jpeg),
          throwsA(_failure(code, field: field, status: status)),
        );
      });
    }

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.uploadPhoto('c1', jpeg),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.uploadPhoto('c1', jpeg),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.uploadPhoto('c1', jpeg),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('photo', () {
    final image = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 250]);

    test('gets the image bytes of the complaint unchanged', () async {
      final h = _Harness(
        (_) => http.Response.bytes(
          image,
          200,
          headers: {'content-type': 'image/png'},
        ),
      );

      final bytes = await h.repository.photo('c4');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/complaints/c4/photo');
      expect(bytes, image);
    });

    test('keeps the bytes of a JPEG that are not valid text', () async {
      final jpeg = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x80,
        0xC3,
        0x28,
      ]);
      final h = _Harness(
        (_) => http.Response.bytes(
          jpeg,
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      );

      expect(await h.repository.photo('c1'), jpeg);
    });

    test('sends exactly one request', () async {
      final h = _Harness((_) => http.Response.bytes(image, 200));

      await h.repository.photo('c1');

      expect(h.requests, hasLength(1));
    });

    test('converts a missing photo to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'PHOTO_NOT_FOUND'));

      await expectLater(
        h.repository.photo('c1'),
        throwsA(_failure('PHOTO_NOT_FOUND', status: 404)),
      );
    });

    test('converts a missing complaint to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'COMPLAINT_NOT_FOUND'));

      await expectLater(
        h.repository.photo('nope'),
        throwsA(_failure('COMPLAINT_NOT_FOUND', status: 404)),
      );
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.photo('c1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.photo('c1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.photo('c1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.photo('c1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
