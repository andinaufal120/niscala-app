import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/dashboard/data/dashboard_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _propertyJson({
  String id = 'p1',
  String name = 'Kos Melati',
  int occupied = 1,
  int vacant = 1,
  int percentage = 50,
  List<Map<String, Object?>>? rooms,
}) => {
  'id': id,
  'name': name,
  'occupiedRoomCount': occupied,
  'vacantRoomCount': vacant,
  'roomCount': occupied + vacant,
  'occupancyPercentage': percentage,
  'rooms':
      rooms ??
      [
        {'id': 'r1', 'number': '01', 'occupancy': 'occupied'},
        {'id': 'r2', 'number': '02', 'occupancy': 'vacant'},
      ],
};

Map<String, Object?> _summaryJson({
  int properties = 1,
  int occupied = 1,
  int vacant = 1,
  int percentage = 50,
}) => {
  'propertyCount': properties,
  'occupiedRoomCount': occupied,
  'vacantRoomCount': vacant,
  'roomCount': occupied + vacant,
  'occupancyPercentage': percentage,
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
    repository = ApiDashboardRepository(dashboard: DashboardApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiDashboardRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('occupancyDashboard', () {
    test('gets the occupancy dashboard', () async {
      final h = _Harness(
        (_) => _ok({'items': [], 'summary': _summaryJson(properties: 0)}),
      );

      await h.repository.occupancyDashboard();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/occupancy-dashboard');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('maps the properties and their rooms in the order returned', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _propertyJson(
              id: 'p2',
              name: 'Kos Mawar',
              occupied: 3,
              vacant: 2,
              percentage: 60,
              rooms: [
                {'id': 'r9', 'number': 'B1', 'occupancy': 'vacant'},
                {'id': 'r8', 'number': 'A1', 'occupancy': 'occupied'},
              ],
            ),
            _propertyJson(id: 'p1', name: 'Kos Melati'),
          ],
          'summary': _summaryJson(properties: 2),
        }),
      );

      final dashboard = await h.repository.occupancyDashboard();

      expect(dashboard.items.map((p) => p.id), ['p2', 'p1']);
      final first = dashboard.items.first;
      expect(first.name, 'Kos Mawar');
      expect(first.occupiedRoomCount, 3);
      expect(first.vacantRoomCount, 2);
      expect(first.roomCount, 5);
      expect(first.occupancyPercentage, 60);
      expect(first.rooms.map((r) => r.id), ['r9', 'r8']);
      expect(first.rooms.map((r) => r.number), ['B1', 'A1']);
      expect(first.rooms.map((r) => r.occupancy), [
        Occupancy.vacant,
        Occupancy.occupied,
      ]);
    });

    test('maps the summary of all properties', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_propertyJson(), _propertyJson(id: 'p2')],
          'summary': _summaryJson(
            properties: 2,
            occupied: 7,
            vacant: 3,
            percentage: 70,
          ),
        }),
      );

      final summary = (await h.repository.occupancyDashboard()).summary;

      expect(summary.propertyCount, 2);
      expect(summary.occupiedRoomCount, 7);
      expect(summary.vacantRoomCount, 3);
      expect(summary.roomCount, 10);
      expect(summary.occupancyPercentage, 70);
    });

    test('keeps the figures as returned even when they disagree', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            {
              'id': 'p1',
              'name': 'Kos Melati',
              'occupiedRoomCount': 37,
              'vacantRoomCount': 12,
              'roomCount': 49,
              'occupancyPercentage': 88,
              'rooms': [
                {'id': 'r1', 'number': '01', 'occupancy': 'vacant'},
              ],
            },
          ],
          'summary': _summaryJson(properties: 1, occupied: 90, percentage: 64),
        }),
      );

      final dashboard = await h.repository.occupancyDashboard();

      expect(dashboard.items.single.occupiedRoomCount, 37);
      expect(dashboard.items.single.occupancyPercentage, 88);
      expect(dashboard.summary.occupiedRoomCount, 90);
      expect(dashboard.summary.occupancyPercentage, 64);
    });

    test('maps a property without rooms', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _propertyJson(occupied: 0, vacant: 0, percentage: 0, rooms: []),
          ],
          'summary': _summaryJson(occupied: 0, vacant: 0, percentage: 0),
        }),
      );

      final dashboard = await h.repository.occupancyDashboard();

      expect(dashboard.items.single.rooms, isEmpty);
      expect(dashboard.items.single.occupancyPercentage, 0);
    });

    test('maps an empty result', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [],
          'summary': _summaryJson(
            properties: 0,
            occupied: 0,
            vacant: 0,
            percentage: 0,
          ),
        }),
      );

      final dashboard = await h.repository.occupancyDashboard();

      expect(dashboard.items, isEmpty);
      expect(dashboard.summary.propertyCount, 0);
      expect(dashboard.summary.roomCount, 0);
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.occupancyDashboard(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.occupancyDashboard(),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.occupancyDashboard(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.occupancyDashboard(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.occupancyDashboard(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('keeps the error code of a server error with a body', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.occupancyDashboard(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('occupancyDashboardProvider', () {
    ProviderContainer containerWith(FakeDashboardRepository repository) {
      final container = ProviderContainer(
        overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('resolves to the dashboard of the repository', () async {
      final dashboard = makeOccupancyDashboard(
        items: [makePropertyOccupancy()],
        summary: makeOccupancySummary(),
      );
      final container = containerWith(
        FakeDashboardRepository(dashboard: dashboard),
      );

      expect(
        await container.read(occupancyDashboardProvider.future),
        dashboard,
      );
    });

    test('fetches once however often it is read', () async {
      final repository = FakeDashboardRepository();
      final container = containerWith(repository);

      await container.read(occupancyDashboardProvider.future);
      await container.read(occupancyDashboardProvider.future);

      expect(repository.calls, 1);
    });

    test('fetches again after it is invalidated', () async {
      final repository = FakeDashboardRepository();
      final container = containerWith(repository);
      await container.read(occupancyDashboardProvider.future);

      container.invalidate(occupancyDashboardProvider);
      await container.read(occupancyDashboardProvider.future);

      expect(repository.calls, 2);
    });

    test('exposes a failure of the repository', () async {
      final repository = FakeDashboardRepository()
        ..script.always = const ApiFailure(code: 'FORBIDDEN');
      final container = containerWith(repository);

      await expectLater(
        container.read(occupancyDashboardProvider.future),
        throwsA(_failure('FORBIDDEN')),
      );
    });

    test('does not retry a failure in the background', () async {
      final repository = FakeDashboardRepository()
        ..script.always = const ApiFailure.network();
      final container = containerWith(repository);
      container.listen(occupancyDashboardProvider, (_, _) {});

      await expectLater(
        container.read(occupancyDashboardProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(repository.calls, 1);
    });
  });
}
