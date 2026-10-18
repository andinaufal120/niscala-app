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

Map<String, Object?> _summaryJson({
  String id = 'c1',
  String status = 'new',
  Map<String, Object?>? classification,
  String? classificationState,
  bool withheld = false,
}) => {
  'id': id,
  'description': 'Keran bocor di kamar mandi.',
  'status': status,
  'classification': classification,
  'classificationState': classificationState,
  'classificationWithheld': withheld,
  'createdAt': '2026-10-18T12:00:00Z',
  'hasPhoto': false,
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'room': {'id': 'r1', 'number': '08'},
  'tenantName': 'Budi Santoso',
};

Map<String, Object?> _complaintJson({
  String id = 'c1',
  String status = 'new',
  Map<String, Object?>? classification,
  String? classificationState,
  bool withheld = false,
  List<Map<String, Object?>> statusChanges = const [],
}) => {
  ..._summaryJson(
    id: id,
    status: status,
    classification: classification,
    classificationState: classificationState,
    withheld: withheld,
  ),
  'statusChanges': statusChanges,
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
  group('list', () {
    test(
      'gets the complaints and returns them in the order received',
      () async {
        final h = _Harness(
          (_) => _ok({
            'items': [
              _summaryJson(id: 'c2', status: 'inProgress'),
              _summaryJson(id: 'c1'),
              _summaryJson(id: 'c3', status: 'done'),
            ],
          }),
        );

        final result = await h.repository.list();

        expect(h.request.method, 'GET');
        expect(h.request.url.path, '/complaints');
        expect(result.map((c) => c.id), ['c2', 'c1', 'c3']);
        expect(result.map((c) => c.status), [
          ComplaintStatus.inProgress,
          ComplaintStatus.new_,
          ComplaintStatus.done,
        ]);
      },
    );

    test('maps the fields of a summary', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_summaryJson()],
        }),
      );

      final c = (await h.repository.list()).single;

      expect(c.description, 'Keran bocor di kamar mandi.');
      expect(c.tenantName, 'Budi Santoso');
      expect(c.room.number, '08');
      expect(c.property.name, 'Kos Melati');
      expect(c.createdAt, DateTime.utc(2026, 10, 18, 12));
      expect(c.classification, isNull);
      expect(c.classificationState, isNull);
      expect(c.classificationWithheld, isFalse);
    });

    test('returns an empty list when there are no complaints', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list(), isEmpty);
    });

    test('maps a classification with its urgency', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(
              classification: {
                'category': 'Pipa dan air',
                'urgency': 'high',
                'suggestedAction': 'Panggil tukang ledeng.',
                'classifiedByName': null,
                'originalAiClassification': null,
              },
            ),
          ],
        }),
      );

      final c = (await h.repository.list()).single;

      expect(c.classification!.category, 'Pipa dan air');
      expect(c.classification!.urgency, ComplaintUrgency.high);
      expect(c.classification!.suggestedAction, 'Panggil tukang ledeng.');
      expect(c.classification!.classifiedByName, isNull);
    });

    test('maps a manual classification with the name of its author', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(
              classification: {
                'category': 'Listrik',
                'urgency': 'low',
                'suggestedAction': null,
                'classifiedByName': 'Siti Pemilik',
              },
            ),
          ],
        }),
      );

      final c = (await h.repository.list()).single;

      expect(c.classification!.classifiedByName, 'Siti Pemilik');
      expect(c.classification!.urgency, ComplaintUrgency.low);
      expect(c.classification!.suggestedAction, isNull);
    });

    const states = {
      'classifying': ComplaintClassificationState.classifying,
      'awaitingClassification':
          ComplaintClassificationState.awaitingClassification,
      'notClassified': ComplaintClassificationState.notClassified,
    };
    for (final entry in states.entries) {
      test('maps the classification state ${entry.key}', () async {
        final h = _Harness(
          (_) => _ok({
            'items': [_summaryJson(classificationState: entry.key)],
          }),
        );

        final c = (await h.repository.list()).single;

        expect(c.classificationState, entry.value);
        expect(c.classification, isNull);
      });
    }

    test('maps the withheld flag', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_summaryJson(withheld: true, classificationState: null)],
        }),
      );

      final c = (await h.repository.list()).single;

      expect(c.classificationWithheld, isTrue);
      expect(c.classification, isNull);
    });

    test('maps the wire value new to the new status', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_summaryJson(status: 'new')],
        }),
      );

      expect((await h.repository.list()).single.status, ComplaintStatus.new_);
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('get', () {
    test('gets the complaint by id and maps its detail', () async {
      final h = _Harness(
        (_) => _ok(
          _complaintJson(
            id: 'c9',
            status: 'inProgress',
            classificationState: 'classifying',
            statusChanges: [
              {
                'status': 'new',
                'changedAt': '2026-10-18T12:00:00Z',
                'handlingNote': null,
              },
              {
                'status': 'inProgress',
                'changedAt': '2026-10-19T08:30:00Z',
                'handlingNote': 'Tukang datang besok pagi.',
              },
            ],
          ),
        ),
      );

      final c = await h.repository.get('c9');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/complaints/c9');
      expect(c.id, 'c9');
      expect(c.status, ComplaintStatus.inProgress);
      expect(c.classificationState, ComplaintClassificationState.classifying);
      expect(c.statusChanges.map((s) => s.status), [
        ComplaintStatus.new_,
        ComplaintStatus.inProgress,
      ]);
      expect(c.statusChanges.first.handlingNote, isNull);
      expect(c.statusChanges.last.handlingNote, 'Tukang datang besok pagi.');
      expect(c.statusChanges.last.changedAt, DateTime.utc(2026, 10, 19, 8, 30));
    });

    test('maps a complaint without status changes', () async {
      final h = _Harness((_) => _ok(_complaintJson()));

      expect((await h.repository.get('c1')).statusChanges, isEmpty);
    });

    test('maps a withheld AI result', () async {
      final h = _Harness((_) => _ok(_complaintJson(withheld: true)));

      final c = await h.repository.get('c1');

      expect(c.classificationWithheld, isTrue);
      expect(c.classification, isNull);
    });

    test('converts a not found response to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'COMPLAINT_NOT_FOUND'));

      await expectLater(
        h.repository.get('nope'),
        throwsA(_failure('COMPLAINT_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.get('c1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 503));

      await expectLater(
        h.repository.get('c1'),
        throwsA(_failure('INTERNAL_ERROR', status: 503)),
      );
    });
  });

  group('submit', () {
    test('posts the description and returns the saved complaint', () async {
      final h = _Harness(
        (_) => _ok(
          _complaintJson(id: 'c5', classificationState: 'classifying'),
          201,
        ),
      );

      final c = await h.repository.submit('Keran bocor di kamar mandi.');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/complaints');
      expect(h.body, {'description': 'Keran bocor di kamar mandi.'});
      expect(c.id, 'c5');
      expect(c.status, ComplaintStatus.new_);
      expect(c.classificationState, ComplaintClassificationState.classifying);
    });

    test('sends the description exactly as given', () async {
      final h = _Harness((_) => _ok(_complaintJson(), 201));

      await h.repository.submit('Baris satu\nBaris dua dengan "kutip"');

      expect(h.body['description'], 'Baris satu\nBaris dua dengan "kutip"');
    });

    for (final state in ['awaitingClassification', 'notClassified']) {
      test('returns the complaint as saved when the state is $state', () async {
        final h = _Harness(
          (_) => _ok(_complaintJson(classificationState: state), 201),
        );

        final c = await h.repository.submit('Keran bocor di kamar mandi.');

        expect(c.id, 'c1');
        expect(c.classification, isNull);
        expect(c.classificationState?.value, state);
      });
    }

    test('returns a complaint that is already classified', () async {
      final h = _Harness(
        (_) => _ok(
          _complaintJson(
            classification: {
              'category': 'Pipa dan air',
              'urgency': 'medium',
              'suggestedAction': null,
              'classifiedByName': null,
            },
          ),
          201,
        ),
      );

      final c = await h.repository.submit('Keran bocor di kamar mandi.');

      expect(c.classification!.category, 'Pipa dan air');
      expect(c.classificationState, isNull);
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'description'),
      );

      await expectLater(
        h.repository.submit('pendek'),
        throwsA(
          _failure('VALIDATION_FAILED', field: 'description', status: 422),
        ),
      );
    });

    test('converts a missing lease to an ApiFailure', () async {
      final h = _Harness((_) => _error(409, 'NO_ACTIVE_LEASE'));

      await expectLater(
        h.repository.submit('Keran bocor di kamar mandi.'),
        throwsA(_failure('NO_ACTIVE_LEASE', status: 409)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.submit('Keran bocor di kamar mandi.'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.submit('Keran bocor di kamar mandi.'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.submit('Keran bocor di kamar mandi.'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
