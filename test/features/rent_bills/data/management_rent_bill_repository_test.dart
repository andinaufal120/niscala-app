import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body) =>
    http.Response(jsonEncode(body), 200, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _summaryJson({
  String id = 'b1',
  String status = 'unpaid',
  int amount = 800000,
  int daysOverdue = 0,
  String tenantId = 't1',
  String tenantName = 'Budi Santoso',
  String roomNumber = '08',
}) => {
  'id': id,
  'amount': amount,
  'daysOverdue': daysOverdue,
  'dueDate': '2026-11-05',
  'periodStart': '2026-11-01',
  'periodEnd': '2026-11-30',
  'payment': {
    'hasReceipt': false,
    'method': null,
    'paidOn': null,
    'rejectionReason': null,
    'status': status,
  },
  'room': {'id': 'r1', 'number': roomNumber},
  'tenant': {'id': tenantId, 'name': tenantName},
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'isCurrent': true,
  'canUploadReceipt': false,
};

Map<String, Object?> _itemJson({
  required String tenantId,
  required String tenantName,
  required String roomNumber,
  Map<String, Object?>? bill,
}) => {
  'bill': bill,
  'room': {'id': 'room-$tenantId', 'number': roomNumber},
  'tenant': {'id': tenantId, 'name': tenantName},
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
    repository = ApiManagementRentBillRepository(
      rentBills: RentBillsApi(apiClient),
    );
  }

  final requests = <http.Request>[];
  late final ApiManagementRentBillRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('overview', () {
    test('gets the overview of the property', () async {
      final h = _Harness((_) => _ok({'date': '2026-11-02', 'items': []}));

      await h.repository.overview('p7');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties/p7/payment-overview');
    });

    test('sends no date when none is asked for', () async {
      final h = _Harness((_) => _ok({'date': '2026-11-02', 'items': []}));

      await h.repository.overview('p1');

      expect(h.request.url.queryParameters, isEmpty);
    });

    void expectSentMidnightUtc(_Harness h, DateTime expected) {
      expect(h.request.url.queryParameters.keys, ['date']);
      final sent = h.request.url.queryParameters['date']!;
      final parsed = DateTime.parse(sent);
      expect(parsed.isUtc, isTrue, reason: sent);
      expect(parsed, expected, reason: sent);
    }

    test('sends the date as the UTC midnight of that calendar day', () async {
      final h = _Harness((_) => _ok({'date': '2026-10-15', 'items': []}));

      await h.repository.overview('p1', date: DateTime(2026, 10, 15));

      expectSentMidnightUtc(h, DateTime.utc(2026, 10, 15));
    });

    test('sends a single digit month and day as that calendar day', () async {
      final h = _Harness((_) => _ok({'date': '2026-01-05', 'items': []}));

      await h.repository.overview('p1', date: DateTime.utc(2026, 1, 5));

      expectSentMidnightUtc(h, DateTime.utc(2026, 1, 5));
    });

    test('keeps the calendar day of a local time late in the day', () async {
      final h = _Harness((_) => _ok({'date': '2026-10-15', 'items': []}));

      await h.repository.overview('p1', date: DateTime(2026, 10, 15, 23, 30));

      expectSentMidnightUtc(h, DateTime.utc(2026, 10, 15));
    });

    test('keeps the calendar day of a local time early in the day', () async {
      final h = _Harness((_) => _ok({'date': '2026-10-15', 'items': []}));

      await h.repository.overview('p1', date: DateTime(2026, 10, 15, 0, 1));

      expectSentMidnightUtc(h, DateTime.utc(2026, 10, 15));
    });

    test('returns the date and the items in the order received', () async {
      final h = _Harness(
        (_) => _ok({
          'date': '2026-10-15',
          'items': [
            _itemJson(
              tenantId: 't3',
              tenantName: 'Rina Putri',
              roomNumber: '15',
              bill: _summaryJson(id: 'b3', tenantId: 't3'),
            ),
            _itemJson(
              tenantId: 't1',
              tenantName: 'Budi Santoso',
              roomNumber: '08',
              bill: _summaryJson(id: 'b1'),
            ),
            _itemJson(
              tenantId: 't2',
              tenantName: 'Dewi Lestari',
              roomNumber: '12',
            ),
          ],
        }),
      );

      final overview = await h.repository.overview('p1');

      expect(overview.date.year, 2026);
      expect(overview.date.month, 10);
      expect(overview.date.day, 15);
      expect(overview.items.map((i) => i.tenant.id), ['t3', 't1', 't2']);
    });

    test('maps the tenant, the room and the bill of an item', () async {
      final h = _Harness(
        (_) => _ok({
          'date': '2026-11-02',
          'items': [
            _itemJson(
              tenantId: 't1',
              tenantName: 'Budi Santoso',
              roomNumber: '08',
              bill: _summaryJson(
                id: 'b9',
                status: 'rejected',
                amount: 825000,
                daysOverdue: 4,
              ),
            ),
          ],
        }),
      );

      final item = (await h.repository.overview('p1')).items.single;

      expect(item.tenant.name, 'Budi Santoso');
      expect(item.room.number, '08');
      expect(item.bill!.id, 'b9');
      expect(item.bill!.amount, 825000);
      expect(item.bill!.daysOverdue, 4);
      expect(item.bill!.payment.status, PaymentStatus.rejected);
      expect(item.bill!.dueDate.day, 5);
    });

    test('keeps a tenant without a bill as an item with no bill', () async {
      final h = _Harness(
        (_) => _ok({
          'date': '2026-11-02',
          'items': [
            _itemJson(
              tenantId: 't2',
              tenantName: 'Dewi Lestari',
              roomNumber: '12',
            ),
          ],
        }),
      );

      final item = (await h.repository.overview('p1')).items.single;

      expect(item.bill, isNull);
      expect(item.tenant.name, 'Dewi Lestari');
    });

    for (final status in PaymentStatus.values) {
      test('maps the status ${status.value}', () async {
        final h = _Harness(
          (_) => _ok({
            'date': '2026-11-02',
            'items': [
              _itemJson(
                tenantId: 't1',
                tenantName: 'Budi Santoso',
                roomNumber: '08',
                bill: _summaryJson(status: status.value),
              ),
            ],
          }),
        );

        final item = (await h.repository.overview('p1')).items.single;

        expect(item.bill!.payment.status, status);
      });
    }

    test('returns no items for a property without tenants', () async {
      final h = _Harness((_) => _ok({'date': '2026-11-02', 'items': []}));

      expect((await h.repository.overview('p1')).items, isEmpty);
    });

    test('keeps the code and status of a missing property', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.overview('nope'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.overview('p1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'date'),
      );

      await expectLater(
        h.repository.overview('p1', date: DateTime(2026, 10, 15)),
        throwsA(_failure('VALIDATION_FAILED', field: 'date', status: 422)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.overview('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.overview('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.overview('p1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('list', () {
    test('gets the bills of a tenant of a property', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(propertyId: 'p1', tenantId: 't9');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/rent-bills');
      expect(h.request.url.queryParameters, {
        'propertyId': 'p1',
        'tenantId': 't9',
      });
    });

    test('sends only the filters that are given', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(propertyId: 'p1');

      expect(h.request.url.queryParameters.keys, ['propertyId']);
    });

    test('sends no filter when none is given', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list();

      expect(h.request.url.queryParameters, isEmpty);
    });

    test('sends the tenant filter alone', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(tenantId: 't9');

      expect(h.request.url.queryParameters.keys, ['tenantId']);
    });

    test('repeats the payment status parameter once per status', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(
        propertyId: 'p1',
        tenantId: 't1',
        statuses: [
          PaymentStatus.unpaid,
          PaymentStatus.awaitingVerification,
          PaymentStatus.rejected,
        ],
      );

      expect(h.request.url.queryParametersAll['paymentStatus'], [
        'unpaid',
        'awaitingVerification',
        'rejected',
      ]);
      expect(h.request.url.queryParametersAll['propertyId'], ['p1']);
      expect(h.request.url.queryParametersAll['tenantId'], ['t1']);
    });

    test('sends a single status once', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(
        propertyId: 'p1',
        tenantId: 't1',
        statuses: [PaymentStatus.paid],
      );

      expect(h.request.url.queryParametersAll['paymentStatus'], ['paid']);
    });

    test('sends no payment status when none is asked for', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(propertyId: 'p1', tenantId: 't1');

      expect(h.request.url.queryParameters.containsKey('paymentStatus'), false);
    });

    test('returns the bills in the order received', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(id: 'b3'),
            _summaryJson(id: 'b1'),
            _summaryJson(id: 'b2'),
          ],
        }),
      );

      final result = await h.repository.list(propertyId: 'p1', tenantId: 't1');

      expect(result.map((b) => b.id), ['b3', 'b1', 'b2']);
    });

    test('maps the fields of a summary', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_summaryJson(status: 'awaitingVerification', amount: 1)],
        }),
      );

      final b = (await h.repository.list(
        propertyId: 'p1',
        tenantId: 't1',
      )).single;

      expect(b.amount, 1);
      expect(b.payment.status, PaymentStatus.awaitingVerification);
      expect(b.dueDate.day, 5);
      expect(b.periodStart.day, 1);
      expect(b.periodEnd.day, 30);
      expect(b.tenant.name, 'Budi Santoso');
      expect(b.room.number, '08');
    });

    test('returns an empty list when there are no bills', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(
        await h.repository.list(propertyId: 'p1', tenantId: 't1'),
        isEmpty,
      );
    });

    test('keeps the code and status of a missing property', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.list(propertyId: 'nope', tenantId: 't1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.list(propertyId: 'p1', tenantId: 't1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'tenantId'),
      );

      await expectLater(
        h.repository.list(propertyId: 'p1', tenantId: 'not-a-uuid'),
        throwsA(_failure('VALIDATION_FAILED', field: 'tenantId', status: 422)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list(propertyId: 'p1', tenantId: 't1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.list(propertyId: 'p1', tenantId: 't1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.list(propertyId: 'p1', tenantId: 't1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
