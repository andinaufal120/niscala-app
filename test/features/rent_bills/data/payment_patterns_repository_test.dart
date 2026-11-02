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

http.Response _error(int status, String code) => http.Response(
  jsonEncode({'code': code, 'field': null, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _patternJson({
  String tenantId = 't1',
  String tenantName = 'Budi Santoso',
  String roomNumber = '08',
  int onTimeCount = 5,
  int countedBillCount = 6,
  int averageDaysLate = 1,
  int arrears = 0,
  bool atRisk = false,
  String? summary,
  bool summaryWithheld = false,
}) => {
  'tenant': {'id': tenantId, 'name': tenantName},
  'room': {'id': 'room-$tenantId', 'number': roomNumber},
  'onTimeCount': onTimeCount,
  'countedBillCount': countedBillCount,
  'averageDaysLate': averageDaysLate,
  'arrears': arrears,
  'atRisk': atRisk,
  'summary': summary,
  'summaryWithheld': summaryWithheld,
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

Matcher _failure(String code, {int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('paymentPatterns', () {
    test('gets the payment patterns of the property', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.paymentPatterns('p7');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/properties/p7/payment-patterns');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('returns no patterns for a property without tenants', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.paymentPatterns('p1'), isEmpty);
    });

    test('returns the patterns in the order received', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _patternJson(tenantId: 't3', tenantName: 'Wati'),
            _patternJson(tenantId: 't1', tenantName: 'Budi Santoso'),
            _patternJson(tenantId: 't2', tenantName: 'Dewi Lestari'),
          ],
        }),
      );

      final patterns = await h.repository.paymentPatterns('p1');

      expect(patterns.map((p) => p.tenant.id), ['t3', 't1', 't2']);
    });

    test('maps the tenant, the room and the facts of a pattern', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _patternJson(
              tenantId: 't9',
              tenantName: 'Rina Putri',
              roomNumber: '15',
              onTimeCount: 2,
              countedBillCount: 5,
              averageDaysLate: 9,
              arrears: 1660000,
              atRisk: true,
              summary: 'Sering terlambat.',
            ),
          ],
        }),
      );

      final pattern = (await h.repository.paymentPatterns('p1')).single;

      expect(pattern.tenant.id, 't9');
      expect(pattern.tenant.name, 'Rina Putri');
      expect(pattern.room.number, '15');
      expect(pattern.onTimeCount, 2);
      expect(pattern.countedBillCount, 5);
      expect(pattern.averageDaysLate, 9);
      expect(pattern.arrears, 1660000);
      expect(pattern.atRisk, isTrue);
      expect(pattern.summary, 'Sering terlambat.');
      expect(pattern.summaryWithheld, isFalse);
    });

    test('keeps a missing summary as null', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_patternJson(summary: null)],
        }),
      );

      final pattern = (await h.repository.paymentPatterns('p1')).single;

      expect(pattern.summary, isNull);
      expect(pattern.summaryWithheld, isFalse);
    });

    test('keeps the withheld flag of a pattern', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_patternJson(summary: null, summaryWithheld: true)],
        }),
      );

      final pattern = (await h.repository.paymentPatterns('p1')).single;

      expect(pattern.summaryWithheld, isTrue);
    });

    test('keeps a pattern of a tenant without counted bills', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _patternJson(
              onTimeCount: 0,
              countedBillCount: 0,
              averageDaysLate: 0,
            ),
          ],
        }),
      );

      final pattern = (await h.repository.paymentPatterns('p1')).single;

      expect(pattern.onTimeCount, 0);
      expect(pattern.countedBillCount, 0);
    });

    test('keeps the code and status of a missing property', () async {
      final h = _Harness((_) => _error(404, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.paymentPatterns('nope'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'PROPERTY_NOT_FOUND'));

      await expectLater(
        h.repository.paymentPatterns('p1'),
        throwsA(_failure('PROPERTY_NOT_FOUND', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.paymentPatterns('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.paymentPatterns('p1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.paymentPatterns('p1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
