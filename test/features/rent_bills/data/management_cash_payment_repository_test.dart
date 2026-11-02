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

/// A bill paid in cash on 2026-11-02, with one status change by Siti Pemilik.
Map<String, Object?> _paidBillJson({String id = 'b1'}) => {
  'id': id,
  'amount': 800000,
  'daysOverdue': 0,
  'dueDate': '2026-11-05',
  'periodStart': '2026-11-01',
  'periodEnd': '2026-11-30',
  'bankAccount': null,
  'payment': {
    'hasReceipt': false,
    'method': 'cash',
    'paidOn': '2026-11-02',
    'rejectionReason': null,
    'status': 'paid',
  },
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'room': {'id': 'r1', 'number': '08'},
  'tenant': {'id': 't1', 'name': 'Budi Santoso'},
  'statusChanges': [
    {
      'actorName': 'Siti Pemilik',
      'changedAt': '2026-11-02T03:00:00Z',
      'manual': true,
      'method': 'cash',
      'reason': null,
      'status': 'paid',
    },
  ],
  'isCurrent': true,
  'canUploadReceipt': false,
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

  Map<String, Object?> get body =>
      jsonDecode(request.body) as Map<String, Object?>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

/// Expects the body to name exactly the calendar day [expected], either as a
/// plain date or as the UTC midnight timestamp of that day, never as another
/// instant.
void _expectDay(_Harness h, DateTime expected) {
  expect(h.body.keys, ['receivedOn']);
  final sent = h.body['receivedOn']! as String;
  final plain = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (plain.hasMatch(sent)) {
    final month = expected.month.toString().padLeft(2, '0');
    final day = expected.day.toString().padLeft(2, '0');
    expect(sent, '${expected.year}-$month-$day');
    return;
  }
  final parsed = DateTime.parse(sent);
  expect(parsed.isUtc, isTrue, reason: sent);
  expect(parsed, DateTime.utc(expected.year, expected.month, expected.day));
}

void main() {
  group('recordCashPayment', () {
    test('posts to the cash payment of the bill', () async {
      final h = _Harness((_) => _ok(_paidBillJson(id: 'b9')));

      await h.repository.recordCashPayment('b9', DateTime(2026, 11, 2));

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/rent-bills/b9/cash-payment');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('sends a JSON body', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment('b1', DateTime(2026, 11, 2));

      expect(h.request.headers['content-type'], contains('application/json'));
      expect(h.body.keys, ['receivedOn']);
    });

    test('sends the calendar day of a local date', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment('b1', DateTime(2026, 10, 15));

      _expectDay(h, DateTime.utc(2026, 10, 15));
    });

    test('sends a single digit month and day as that calendar day', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment('b1', DateTime.utc(2026, 1, 5));

      _expectDay(h, DateTime.utc(2026, 1, 5));
    });

    test('keeps the calendar day of a local time late in the day', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment(
        'b1',
        DateTime(2026, 10, 15, 23, 30),
      );

      _expectDay(h, DateTime.utc(2026, 10, 15));
    });

    test('keeps the calendar day of a local time early in the day', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment('b1', DateTime(2026, 10, 15, 0, 1));

      _expectDay(h, DateTime.utc(2026, 10, 15));
    });

    test('keeps the calendar day of a UTC time late in the day', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment(
        'b1',
        DateTime.utc(2026, 10, 15, 23, 59),
      );

      _expectDay(h, DateTime.utc(2026, 10, 15));
    });

    test('keeps the calendar day across a month and year boundary', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      await h.repository.recordCashPayment(
        'b1',
        DateTime(2026, 12, 31, 23, 59),
      );

      _expectDay(h, DateTime.utc(2026, 12, 31));
    });

    test('returns the bill as the API has it after the change', () async {
      final h = _Harness((_) => _ok(_paidBillJson(id: 'b9')));

      final bill = await h.repository.recordCashPayment(
        'b9',
        DateTime(2026, 11, 2),
      );

      expect(bill.id, 'b9');
      expect(bill.amount, 800000);
      expect(bill.payment.status, PaymentStatus.paid);
      expect(bill.payment.method, PaymentMethod.cash);
      expect(bill.payment.paidOn!.day, 2);
      expect(bill.payment.paidOn!.month, 11);
      expect(bill.payment.hasReceipt, isFalse);
      expect(bill.tenant.name, 'Budi Santoso');
      expect(bill.room.number, '08');
      expect(bill.property.name, 'Kos Melati');
      expect(bill.canUploadReceipt, isFalse);
    });

    test('maps the status change of the payment', () async {
      final h = _Harness((_) => _ok(_paidBillJson()));

      final bill = await h.repository.recordCashPayment(
        'b1',
        DateTime(2026, 11, 2),
      );

      final change = bill.statusChanges.single;
      expect(change.status, PaymentStatus.paid);
      expect(change.method, PaymentMethod.cash);
      expect(change.manual, isTrue);
      expect(change.actorName, 'Siti Pemilik');
      expect(change.changedAt, DateTime.utc(2026, 11, 2, 3));
    });

    test('keeps the code and status of a missing bill', () async {
      final h = _Harness((_) => _error(404, 'RENT_BILL_NOT_FOUND'));

      await expectLater(
        h.repository.recordCashPayment('nope', DateTime(2026, 11, 2)),
        throwsA(_failure('RENT_BILL_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2026, 11, 2)),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code and status of a bill that cannot be paid', () async {
      final h = _Harness((_) => _error(409, 'RENT_BILL_NOT_PAYABLE'));

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2026, 11, 2)),
        throwsA(_failure('RENT_BILL_NOT_PAYABLE', status: 409)),
      );
    });

    test('keeps the code, field and status of a date in the future', () async {
      final h = _Harness(
        (_) => _error(422, 'RECEIVED_ON_IN_FUTURE', field: 'receivedOn'),
      );

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2099, 1, 1)),
        throwsA(
          _failure('RECEIVED_ON_IN_FUTURE', field: 'receivedOn', status: 422),
        ),
      );
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'receivedOn'),
      );

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2026, 11, 2)),
        throwsA(
          _failure('VALIDATION_FAILED', field: 'receivedOn', status: 422),
        ),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2026, 11, 2)),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2026, 11, 2)),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.recordCashPayment('b1', DateTime(2026, 11, 2)),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
