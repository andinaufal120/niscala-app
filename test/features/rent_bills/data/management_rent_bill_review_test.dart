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

Map<String, Object?> _billJson({
  String id = 'b1',
  String status = 'paid',
  String? method = 'transfer',
  String? paidOn = '2026-11-07',
  String? rejectionReason,
  bool hasReceipt = true,
  List<Map<String, Object?>> statusChanges = const [],
}) => {
  'id': id,
  'amount': 800000,
  'daysOverdue': 0,
  'dueDate': '2026-11-05',
  'periodStart': '2026-11-01',
  'periodEnd': '2026-11-30',
  'payment': {
    'hasReceipt': hasReceipt,
    'method': method,
    'paidOn': paidOn,
    'rejectionReason': rejectionReason,
    'status': status,
  },
  'room': {'id': 'r1', 'number': '08'},
  'tenant': {'id': 't1', 'name': 'Budi Santoso'},
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'isCurrent': true,
  'canUploadReceipt': false,
  'bankAccount': null,
  'statusChanges': statusChanges,
};

Map<String, Object?> _changeJson({
  required String status,
  String? method,
  String? reason,
}) => {
  'status': status,
  'changedAt': '2026-11-07T03:00:00Z',
  'actorName': 'Siti Pemilik',
  'manual': true,
  'method': method,
  'reason': reason,
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
  group('verifyReceipt', () {
    test('posts to the verification of the bill without a body', () async {
      final h = _Harness((_) => _ok(_billJson(id: 'b7')));

      await h.repository.verifyReceipt('b7');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/rent-bills/b7/verification');
      expect(h.request.url.queryParameters, isEmpty);
      expect(h.request.body, isEmpty);
    });

    test('returns the paid bill with its payment', () async {
      final h = _Harness(
        (_) => _ok(
          _billJson(
            id: 'b7',
            statusChanges: [_changeJson(status: 'paid', method: 'transfer')],
          ),
        ),
      );

      final bill = await h.repository.verifyReceipt('b7');

      expect(bill.id, 'b7');
      expect(bill.payment.status, PaymentStatus.paid);
      expect(bill.payment.method, PaymentMethod.transfer);
      expect(bill.payment.paidOn!.day, 7);
      expect(bill.payment.paidOn!.month, 11);
      expect(bill.tenant.name, 'Budi Santoso');
      expect(bill.statusChanges.single.status, PaymentStatus.paid);
      expect(bill.statusChanges.single.actorName, 'Siti Pemilik');
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.verifyReceipt('b1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code and status of a missing bill', () async {
      final h = _Harness((_) => _error(404, 'RENT_BILL_NOT_FOUND'));

      await expectLater(
        h.repository.verifyReceipt('nope'),
        throwsA(_failure('RENT_BILL_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a conflict', () async {
      final h = _Harness(
        (_) => _error(409, 'RENT_BILL_NOT_AWAITING_VERIFICATION'),
      );

      await expectLater(
        h.repository.verifyReceipt('b1'),
        throwsA(_failure('RENT_BILL_NOT_AWAITING_VERIFICATION', status: 409)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.verifyReceipt('b1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.verifyReceipt('b1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.verifyReceipt('b1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('rejectReceipt', () {
    test('posts the reason to the rejection of the bill', () async {
      final h = _Harness(
        (_) => _ok(_billJson(id: 'b7', status: 'rejected', method: null)),
      );

      await h.repository.rejectReceipt('b7', 'Nominal tidak sesuai.');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/rent-bills/b7/rejection');
      expect(h.request.url.queryParameters, isEmpty);
      expect(h.request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(h.request.body), {'reason': 'Nominal tidak sesuai.'});
    });

    test('sends the reason as given', () async {
      final h = _Harness(
        (_) => _ok(_billJson(status: 'rejected', method: null)),
      );

      await h.repository.rejectReceipt('b1', 'Buram,\nulangi.');

      expect(jsonDecode(h.request.body), {'reason': 'Buram,\nulangi.'});
    });

    test('returns the rejected bill with its reason', () async {
      final h = _Harness(
        (_) => _ok(
          _billJson(
            id: 'b7',
            status: 'rejected',
            method: null,
            paidOn: null,
            rejectionReason: 'Nominal tidak sesuai.',
            statusChanges: [
              _changeJson(status: 'rejected', reason: 'Nominal tidak sesuai.'),
            ],
          ),
        ),
      );

      final bill = await h.repository.rejectReceipt(
        'b7',
        'Nominal tidak sesuai.',
      );

      expect(bill.id, 'b7');
      expect(bill.payment.status, PaymentStatus.rejected);
      expect(bill.payment.rejectionReason, 'Nominal tidak sesuai.');
      expect(bill.payment.method, isNull);
      expect(bill.payment.paidOn, isNull);
      expect(bill.statusChanges.single.reason, 'Nominal tidak sesuai.');
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.rejectReceipt('b1', 'x'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code and status of a missing bill', () async {
      final h = _Harness((_) => _error(404, 'RENT_BILL_NOT_FOUND'));

      await expectLater(
        h.repository.rejectReceipt('nope', 'x'),
        throwsA(_failure('RENT_BILL_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a conflict', () async {
      final h = _Harness(
        (_) => _error(409, 'RENT_BILL_NOT_AWAITING_VERIFICATION'),
      );

      await expectLater(
        h.repository.rejectReceipt('b1', 'x'),
        throwsA(_failure('RENT_BILL_NOT_AWAITING_VERIFICATION', status: 409)),
      );
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'reason'),
      );

      await expectLater(
        h.repository.rejectReceipt('b1', ' '),
        throwsA(_failure('VALIDATION_FAILED', field: 'reason', status: 422)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.rejectReceipt('b1', 'x'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.rejectReceipt('b1', 'x'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.rejectReceipt('b1', 'x'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
