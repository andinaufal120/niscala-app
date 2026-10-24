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
  String billingCycle = 'monthly',
  String? startDate = '2026-01-01',
  String? endDate = '2026-12-31',
  num? lengthM = 3.5,
  num? widthM = 4,
  List<String> facilities = const ['ac', 'kasur'],
}) => {
  'billingCycle': billingCycle,
  'startDate': startDate,
  'endDate': endDate,
  'rent': 750000,
  'property': {
    'id': 'p1',
    'name': 'Kos Melati',
    'address': 'Jl. Melati 1, Bandung',
  },
  'room': {
    'id': 'r1',
    'number': '08',
    'lengthM': lengthM,
    'widthM': widthM,
    'facilities': facilities,
  },
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
  group('myLease', () {
    test('gets the lease of the caller', () async {
      final h = _Harness((_) => _ok({'lease': _leaseJson()}));

      await h.repository.myLease();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/me/lease');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('maps the fields of the lease', () async {
      final h = _Harness((_) => _ok({'lease': _leaseJson()}));

      final lease = (await h.repository.myLease())!;

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

    for (final cycle in BillingCycle.values) {
      test('maps the billing cycle ${cycle.value}', () async {
        final h = _Harness(
          (_) => _ok({'lease': _leaseJson(billingCycle: cycle.value)}),
        );

        expect((await h.repository.myLease())!.billingCycle, cycle);
      });
    }

    test('maps a lease without dates, dimensions and facilities', () async {
      final h = _Harness(
        (_) => _ok({
          'lease': _leaseJson(
            startDate: null,
            endDate: null,
            lengthM: null,
            widthM: null,
            facilities: const [],
          ),
        }),
      );

      final lease = (await h.repository.myLease())!;

      expect(lease.startDate, isNull);
      expect(lease.endDate, isNull);
      expect(lease.room.lengthM, isNull);
      expect(lease.room.widthM, isNull);
      expect(lease.room.facilities, isEmpty);
    });

    test('returns null when the tenant has no lease', () async {
      final h = _Harness((_) => _ok({'lease': null}));

      expect(await h.repository.myLease(), isNull);
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.myLease(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts an invalid access token to an ApiFailure', () async {
      final h = _Harness((_) => _error(401, 'ACCESS_TOKEN_INVALID'));

      await expectLater(
        h.repository.myLease(),
        throwsA(_failure('ACCESS_TOKEN_INVALID', status: 401)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.myLease(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.myLease(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.myLease(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('myLeaseProvider', () {
    ProviderContainer containerWith(FakeLeaseRepository repository) {
      final container = ProviderContainer(
        overrides: [leaseRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('resolves to the lease of the repository', () async {
      final lease = makeCurrentLease();
      final container = containerWith(FakeLeaseRepository(lease: lease));

      expect(await container.read(myLeaseProvider.future), lease);
    });

    test('resolves to null when there is no lease', () async {
      final container = containerWith(FakeLeaseRepository());

      expect(await container.read(myLeaseProvider.future), isNull);
    });

    test('fetches once however often it is read', () async {
      final repository = FakeLeaseRepository(lease: makeCurrentLease());
      final container = containerWith(repository);

      await container.read(myLeaseProvider.future);
      await container.read(myLeaseProvider.future);

      expect(repository.calls, 1);
    });

    test('fetches again after it is invalidated', () async {
      final repository = FakeLeaseRepository(lease: makeCurrentLease());
      final container = containerWith(repository);
      await container.read(myLeaseProvider.future);

      container.invalidate(myLeaseProvider);
      await container.read(myLeaseProvider.future);

      expect(repository.calls, 2);
    });

    test('exposes a failure of the repository', () async {
      final repository = FakeLeaseRepository()
        ..script.always = const ApiFailure(code: 'INTERNAL_ERROR');
      final container = containerWith(repository);

      await expectLater(
        container.read(myLeaseProvider.future),
        throwsA(_failure('INTERNAL_ERROR')),
      );
    });

    test('does not retry a failure in the background', () async {
      final repository = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      final container = containerWith(repository);
      container.listen(myLeaseProvider, (_, _) {});

      await expectLater(
        container.read(myLeaseProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(repository.calls, 1);
    });
  });
}
