import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
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

Map<String, Object?> _complaintJson({
  String id = 'c1',
  String status = 'new',
  Map<String, Object?>? classification,
  String? classificationState,
}) => {
  'id': id,
  'description': 'Keran bocor di kamar mandi.',
  'status': status,
  'classification': classification,
  'classificationState': classificationState,
  'classificationWithheld': false,
  'createdAt': '2026-10-18T12:00:00Z',
  'hasPhoto': false,
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'room': {'id': 'r1', 'number': '08'},
  'statusChanges': <Map<String, Object?>>[],
  'tenantName': 'Budi Santoso',
};

Map<String, Object?> _manualJson({
  String category = 'Listrik',
  String urgency = 'high',
  Map<String, Object?>? original,
}) => {
  'category': category,
  'urgency': urgency,
  'suggestedAction': null,
  'classifiedByName': 'Siti Pemilik',
  'originalAiClassification': original,
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
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('categories', () {
    test(
      'gets the categories and returns them in the order received',
      () async {
        final h = _Harness(
          (_) => _ok({
            'items': ['Pipa dan air', 'Listrik', 'Furnitur'],
          }),
        );

        final result = await h.repository.categories();

        expect(h.request.method, 'GET');
        expect(h.request.url.path, '/complaint-categories');
        expect(result, ['Pipa dan air', 'Listrik', 'Furnitur']);
      },
    );

    test('returns an empty list when there are no categories', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.categories(), isEmpty);
    });

    test('sends exactly one request', () async {
      final h = _Harness(
        (_) => _ok({
          'items': ['Listrik'],
        }),
      );

      await h.repository.categories();

      expect(h.requests, hasLength(1));
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.categories(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.categories(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.categories(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.categories(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('classify', () {
    test('puts the category and urgency and returns the complaint', () async {
      final h = _Harness(
        (_) => _ok(_complaintJson(classification: _manualJson())),
      );

      final c = await h.repository.classify(
        'c1',
        category: 'Listrik',
        urgency: ComplaintUrgency.high,
      );

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/complaints/c1/classification');
      expect(h.body, {'category': 'Listrik', 'urgency': 'high'});
      expect(c.id, 'c1');
      expect(c.classification!.category, 'Listrik');
      expect(c.classification!.urgency, ComplaintUrgency.high);
      expect(c.classification!.classifiedByName, 'Siti Pemilik');
    });

    const wireValues = {
      ComplaintUrgency.low: 'low',
      ComplaintUrgency.medium: 'medium',
      ComplaintUrgency.high: 'high',
    };
    for (final entry in wireValues.entries) {
      test('sends the wire value ${entry.value} for ${entry.key}', () async {
        final h = _Harness(
          (_) => _ok(
            _complaintJson(classification: _manualJson(urgency: entry.value)),
          ),
        );

        final c = await h.repository.classify(
          'c1',
          category: 'Listrik',
          urgency: entry.key,
        );

        expect(h.body['urgency'], entry.value);
        expect(c.classification!.urgency, entry.key);
      });
    }

    test('puts the complaint id in the path', () async {
      final h = _Harness(
        (_) => _ok(_complaintJson(id: 'c42', classification: _manualJson())),
      );

      await h.repository.classify(
        'c42',
        category: 'Listrik',
        urgency: ComplaintUrgency.low,
      );

      expect(h.request.url.path, '/complaints/c42/classification');
    });

    test(
      'maps the original AI classification the correction replaced',
      () async {
        final h = _Harness(
          (_) => _ok(
            _complaintJson(
              classification: _manualJson(
                original: {
                  'category': 'Pipa dan air',
                  'urgency': 'medium',
                  'suggestedAction': 'Panggil tukang ledeng.',
                },
              ),
            ),
          ),
        );

        final c = await h.repository.classify(
          'c1',
          category: 'Listrik',
          urgency: ComplaintUrgency.high,
        );

        final original = c.classification!.originalAiClassification!;
        expect(original.category, 'Pipa dan air');
        expect(original.urgency, ComplaintUrgency.medium);
        expect(original.suggestedAction, 'Panggil tukang ledeng.');
      },
    );

    test('maps a classification without an original AI result', () async {
      final h = _Harness(
        (_) => _ok(_complaintJson(classification: _manualJson())),
      );

      final c = await h.repository.classify(
        'c1',
        category: 'Listrik',
        urgency: ComplaintUrgency.high,
      );

      expect(c.classification!.originalAiClassification, isNull);
    });

    test('keeps the code, field and status of an invalid category', () async {
      final h = _Harness(
        (_) => _error(422, 'COMPLAINT_CATEGORY_INVALID', field: 'category'),
      );

      await expectLater(
        h.repository.classify(
          'c1',
          category: 'Tidak ada',
          urgency: ComplaintUrgency.low,
        ),
        throwsA(
          _failure(
            'COMPLAINT_CATEGORY_INVALID',
            field: 'category',
            status: 422,
          ),
        ),
      );
    });

    test('converts a not found response to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'COMPLAINT_NOT_FOUND'));

      await expectLater(
        h.repository.classify(
          'nope',
          category: 'Listrik',
          urgency: ComplaintUrgency.low,
        ),
        throwsA(_failure('COMPLAINT_NOT_FOUND', status: 404)),
      );
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.classify(
          'c1',
          category: 'Listrik',
          urgency: ComplaintUrgency.low,
        ),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.classify(
          'c1',
          category: 'Listrik',
          urgency: ComplaintUrgency.low,
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.classify(
          'c1',
          category: 'Listrik',
          urgency: ComplaintUrgency.low,
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.classify(
          'c1',
          category: 'Listrik',
          urgency: ComplaintUrgency.low,
        ),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('sends exactly one request', () async {
      final h = _Harness(
        (_) => _ok(_complaintJson(classification: _manualJson())),
      );

      await h.repository.classify(
        'c1',
        category: 'Listrik',
        urgency: ComplaintUrgency.high,
      );

      expect(h.requests, hasLength(1));
    });
  });
}
