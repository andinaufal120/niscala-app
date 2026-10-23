import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

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
    repository = ApiRoomRepository(rooms: RoomsApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiRoomRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _roomJson({
  String id = 'r1',
  String number = '08',
  bool occupied = false,
  bool editable = true,
  Object? lengthM = 3.5,
  Object? widthM = 4,
  List<String> facilities = const ['ac', 'kasur'],
}) => {
  'id': id,
  'propertyId': 'p1',
  'number': number,
  'baseRate': 800000,
  'occupancy': occupied ? 'occupied' : 'vacant',
  'lengthM': lengthM,
  'widthM': widthM,
  'facilities': facilities,
  'editable': editable,
  'lease': occupied
      ? {
          'tenantId': 't1',
          'tenantName': 'Budi Santoso',
          'tenantPhone': '081234567890',
          'rent': 750000,
          'startDate': '2026-01-01',
          'endDate': '2026-12-31',
        }
      : null,
};

Map<String, dynamic> _summaryJson({
  String id = 'r1',
  String number = '08',
  bool occupied = false,
}) => {
  'id': id,
  'number': number,
  'baseRate': 800000,
  'occupancy': occupied ? 'occupied' : 'vacant',
  'lengthM': 3.5,
  'widthM': 4,
  'facilities': ['ac'],
  'editable': true,
  'lease': occupied
      ? {'tenantName': 'Budi Santoso', 'endDate': '2026-12-31'}
      : null,
};

RoomInput _input({
  num? lengthM = 3.5,
  num? widthM = 4,
  List<String> facilities = const ['ac', 'kasur'],
}) => RoomInput(
  number: '08',
  baseRate: 800000,
  lengthM: lengthM,
  widthM: widthM,
  facilities: facilities,
);

void main() {
  group('list', () {
    test('gets the rooms of the property and unwraps the items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(occupied: true),
            _summaryJson(id: 'r2', number: '09'),
          ],
        }),
      );

      final result = await h.repository.list('p1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties/p1/rooms');
      expect(result.map((r) => r.id), ['r1', 'r2']);
      expect(result.first.number, '08');
      expect(result.first.baseRate, 800000);
      expect(result.first.occupancy, Occupancy.occupied);
      expect(result.first.lease!.tenantName, 'Budi Santoso');
      expect(result.first.lease!.endDate!.year, 2026);
      expect(result.first.lease!.endDate!.month, 12);
      expect(result.first.lease!.endDate!.day, 31);
      expect(result.first.lengthM, 3.5);
      expect(result.first.widthM, 4);
      expect(result.first.facilities, ['ac']);
      expect(result.first.editable, isTrue);
      expect(result.last.occupancy, Occupancy.vacant);
      expect(result.last.lease, isNull);
    });

    test('returns an empty list when the property has no rooms', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list('p1'), isEmpty);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.list('p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.list('p1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('get', () {
    test('gets one occupied room including its lease', () async {
      final h = _Harness((_) => _ok(_roomJson(occupied: true)));

      final result = await h.repository.get('r1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/rooms/r1');
      expect(result.id, 'r1');
      expect(result.propertyId, 'p1');
      expect(result.number, '08');
      expect(result.baseRate, 800000);
      expect(result.occupancy, Occupancy.occupied);
      expect(result.lengthM, 3.5);
      expect(result.widthM, 4);
      expect(result.facilities, ['ac', 'kasur']);
      expect(result.editable, isTrue);
      final lease = result.lease!;
      expect(lease.tenantId, 't1');
      expect(lease.tenantName, 'Budi Santoso');
      expect(lease.tenantPhone, '081234567890');
      expect(lease.rent, 750000);
      expect(lease.startDate!.year, 2026);
      expect(lease.startDate!.month, 1);
      expect(lease.endDate!.month, 12);
    });

    test('gets a vacant room without lease or dimensions', () async {
      final h = _Harness(
        (_) => _ok(_roomJson(lengthM: null, widthM: null, facilities: [])),
      );

      final result = await h.repository.get('r1');

      expect(result.occupancy, Occupancy.vacant);
      expect(result.lease, isNull);
      expect(result.lengthM, isNull);
      expect(result.widthM, isNull);
      expect(result.facilities, isEmpty);
    });

    test('reports a view-only room', () async {
      final h = _Harness((_) => _ok(_roomJson(editable: false)));

      expect((await h.repository.get('r1')).editable, isFalse);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'ROOM_NOT_FOUND'));

      await expectLater(
        h.repository.get('r1'),
        throwsA(_failure('ROOM_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.get('r1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('create', () {
    test('posts the input in camelCase to the property', () async {
      final h = _Harness((_) => _ok(_roomJson(), 201));

      final result = await h.repository.create('p1', _input());

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/properties/p1/rooms');
      expect(h.body['number'], '08');
      expect(h.body['baseRate'], 800000);
      expect(h.body['baseRate'], isA<int>());
      expect(h.body['lengthM'], 3.5);
      expect(h.body['widthM'], 4);
      expect(h.body['facilities'], ['ac', 'kasur']);
      expect(result.id, 'r1');
    });

    test('sends no dimensions and no facilities when there are none', () async {
      final h = _Harness((_) => _ok(_roomJson(), 201));

      await h.repository.create(
        'p1',
        _input(lengthM: null, widthM: null, facilities: const []),
      );

      expect(h.body['lengthM'], isNull);
      expect(h.body['widthM'], isNull);
      expect(h.body['facilities'], isEmpty);
    });

    test('keeps the code, field and status of a number conflict', () async {
      final h = _Harness(
        (_) => _error(409, 'ROOM_NUMBER_TAKEN', field: 'number'),
      );

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('ROOM_NUMBER_TAKEN', field: 'number', status: 409)),
      );
    });

    test('keeps the field of a facilities validation error', () async {
      final h = _Harness(
        (_) => _error(400, 'VALIDATION_FAILED', field: 'facilities'),
      );

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(
          _failure('VALIDATION_FAILED', field: 'facilities', status: 400),
        ),
      );
    });

    test('keeps the code of a room limit error', () async {
      final h = _Harness((_) => _error(403, 'ROOM_LIMIT_REACHED'));

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('ROOM_LIMIT_REACHED', status: 403)),
      );
    });

    test('keeps the code of a read-only property error', () async {
      final h = _Harness((_) => _error(403, 'PROPERTY_READ_ONLY'));

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('PROPERTY_READ_ONLY', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.create('p1', _input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('update', () {
    test('puts the full input to the room', () async {
      final h = _Harness((_) => _ok(_roomJson(number: '08')));

      final result = await h.repository.update('r1', _input());

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/rooms/r1');
      expect(h.body['number'], '08');
      expect(h.body['baseRate'], 800000);
      expect(h.body['lengthM'], 3.5);
      expect(h.body['widthM'], 4);
      expect(h.body['facilities'], ['ac', 'kasur']);
      expect(result.number, '08');
    });

    test('sends no dimensions when there are none', () async {
      final h = _Harness((_) => _ok(_roomJson()));

      await h.repository.update('r1', _input(lengthM: null, widthM: null));

      expect(h.body['lengthM'], isNull);
      expect(h.body['widthM'], isNull);
    });

    test('keeps the code and field of a number conflict', () async {
      final h = _Harness(
        (_) => _error(409, 'ROOM_NUMBER_TAKEN', field: 'number'),
      );

      await expectLater(
        h.repository.update('r1', _input()),
        throwsA(_failure('ROOM_NUMBER_TAKEN', field: 'number', status: 409)),
      );
    });

    test('keeps the code of a read-only room error', () async {
      final h = _Harness((_) => _error(403, 'ROOM_READ_ONLY'));

      await expectLater(
        h.repository.update('r1', _input()),
        throwsA(_failure('ROOM_READ_ONLY', status: 403)),
      );
    });

    test('keeps the field of a dimension validation error', () async {
      final h = _Harness(
        (_) => _error(400, 'VALIDATION_FAILED', field: 'lengthM'),
      );

      await expectLater(
        h.repository.update('r1', _input()),
        throwsA(_failure('VALIDATION_FAILED', field: 'lengthM', status: 400)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.update('r1', _input()),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('delete', () {
    test('sends a DELETE and completes on 204', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.delete('r1');

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/rooms/r1');
    });

    test('keeps the code and status of an active lease error', () async {
      final h = _Harness((_) => _error(409, 'ROOM_HAS_ACTIVE_LEASE'));

      await expectLater(
        h.repository.delete('r1'),
        throwsA(_failure('ROOM_HAS_ACTIVE_LEASE', status: 409)),
      );
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'ROOM_NOT_FOUND'));

      await expectLater(
        h.repository.delete('r1'),
        throwsA(_failure('ROOM_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.delete('r1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('facilitySuggestions', () {
    test('gets the tags of the property and unwraps the items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': ['ac', 'kamar mandi dalam'],
        }),
      );

      final result = await h.repository.facilitySuggestions('p1');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties/p1/facility-suggestions');
      expect(result, ['ac', 'kamar mandi dalam']);
    });

    test('returns an empty list when there are no suggestions', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.facilitySuggestions('p1'), isEmpty);
    });

    test('keeps the code and status of an error response', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.facilitySuggestions('p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.facilitySuggestions('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
