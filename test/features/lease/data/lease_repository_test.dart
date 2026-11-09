import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
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

Map<String, Object?> _leaseJson({
  String tenantId = 't1',
  String propertyId = 'p1',
  String propertyName = 'Kos Melati',
  String roomId = 'r1',
  String roomNumber = '08',
  String billingCycle = 'monthly',
  String? startDate = '2026-01-01',
  String? endDate = '2026-12-31',
  num? lengthM = 3.5,
  num? widthM = 4,
  List<String> facilities = const ['ac', 'kasur'],
}) => {
  'tenantId': tenantId,
  'billingCycle': billingCycle,
  'startDate': startDate,
  'endDate': endDate,
  'rent': 750000,
  'property': {
    'id': propertyId,
    'name': propertyName,
    'address': 'Jl. Melati 1, Bandung',
  },
  'room': {
    'id': roomId,
    'number': roomNumber,
    'lengthM': lengthM,
    'widthM': widthM,
    'facilities': facilities,
  },
};

Map<String, Object?> _list(List<Map<String, Object?>> items) => {
  'items': items,
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
    repository = ApiLeaseRepository(tenants: TenantsApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiLeaseRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('myLeases', () {
    test('gets the leases of the caller', () async {
      final h = _Harness((_) => _ok(_list([_leaseJson()])));

      await h.repository.myLeases();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/me/leases');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('maps the fields of the lease', () async {
      final h = _Harness((_) => _ok(_list([_leaseJson()])));

      final lease = (await h.repository.myLeases()).single;

      expect(lease.tenantId, 't1');
      expect(lease.billingCycle, BillingCycle.monthly);
      expect(lease.rent, 750000);
      expect(lease.startDate!.year, 2026);
      expect(lease.startDate!.month, 1);
      expect(lease.startDate!.day, 1);
      expect(lease.endDate!.year, 2026);
      expect(lease.endDate!.month, 12);
      expect(lease.endDate!.day, 31);
      expect(lease.property.id, 'p1');
      expect(lease.property.name, 'Kos Melati');
      expect(lease.property.address, 'Jl. Melati 1, Bandung');
      expect(lease.room.id, 'r1');
      expect(lease.room.number, '08');
      expect(lease.room.lengthM, 3.5);
      expect(lease.room.widthM, 4);
      expect(lease.room.facilities, ['ac', 'kasur']);
    });

    test('returns every lease in the order of the API', () async {
      final h = _Harness(
        (_) => _ok(
          _list([
            _leaseJson(
              tenantId: 't2',
              propertyId: 'p2',
              propertyName: 'Kos Mawar',
              roomId: 'r2',
              roomNumber: '12',
            ),
            _leaseJson(),
            _leaseJson(tenantId: 't3', roomId: 'r3', roomNumber: '03'),
          ]),
        ),
      );

      final leases = await h.repository.myLeases();

      expect(leases.map((l) => l.tenantId), ['t2', 't1', 't3']);
      expect(leases.map((l) => l.property.name), [
        'Kos Mawar',
        'Kos Melati',
        'Kos Melati',
      ]);
      expect(leases.map((l) => l.room.number), ['12', '08', '03']);
      expect(leases.map((l) => l.room.id), ['r2', 'r1', 'r3']);
    });

    for (final cycle in BillingCycle.values) {
      test('maps the billing cycle ${cycle.value}', () async {
        final h = _Harness(
          (_) => _ok(_list([_leaseJson(billingCycle: cycle.value)])),
        );

        expect((await h.repository.myLeases()).single.billingCycle, cycle);
      });
    }

    test('maps a lease without dates, dimensions and facilities', () async {
      final h = _Harness(
        (_) => _ok(
          _list([
            _leaseJson(
              startDate: null,
              endDate: null,
              lengthM: null,
              widthM: null,
              facilities: const [],
            ),
          ]),
        ),
      );

      final lease = (await h.repository.myLeases()).single;

      expect(lease.startDate, isNull);
      expect(lease.endDate, isNull);
      expect(lease.room.lengthM, isNull);
      expect(lease.room.widthM, isNull);
      expect(lease.room.facilities, isEmpty);
    });

    test('returns an empty list when the tenant has no lease', () async {
      final h = _Harness((_) => _ok(_list(const [])));

      expect(await h.repository.myLeases(), isEmpty);
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.myLeases(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.myLeases(),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.myLeases(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.myLeases(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.myLeases(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('myLeasesProvider', () {
    ProviderContainer containerWith(FakeLeaseRepository repository) {
      final container = ProviderContainer(
        overrides: [leaseRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('resolves to the leases of the repository in order', () async {
      final leases = makeTwoLeases();
      final container = containerWith(FakeLeaseRepository(leases: leases));

      expect(await container.read(myLeasesProvider.future), leases);
    });

    test('resolves to an empty list when there is no lease', () async {
      final container = containerWith(FakeLeaseRepository());

      expect(await container.read(myLeasesProvider.future), isEmpty);
    });

    test('fetches once however often it is read', () async {
      final repository = FakeLeaseRepository(lease: makeCurrentLease());
      final container = containerWith(repository);

      await container.read(myLeasesProvider.future);
      await container.read(myLeasesProvider.future);

      expect(repository.calls, 1);
    });

    test('fetches again after it is invalidated', () async {
      final repository = FakeLeaseRepository(lease: makeCurrentLease());
      final container = containerWith(repository);
      await container.read(myLeasesProvider.future);

      container.invalidate(myLeasesProvider);
      await container.read(myLeasesProvider.future);

      expect(repository.calls, 2);
    });

    test('exposes a failure of the repository', () async {
      final repository = FakeLeaseRepository()
        ..script.always = const ApiFailure(code: 'INTERNAL_ERROR');
      final container = containerWith(repository);

      await expectLater(
        container.read(myLeasesProvider.future),
        throwsA(_failure('INTERNAL_ERROR')),
      );
    });

    test('does not retry a failure in the background', () async {
      final repository = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      final container = containerWith(repository);
      container.listen(myLeasesProvider, (_, _) {});

      await expectLater(
        container.read(myLeasesProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(repository.calls, 1);
    });
  });
}
