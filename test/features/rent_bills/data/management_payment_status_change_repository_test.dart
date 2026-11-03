import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _created(Object body) =>
    http.Response(jsonEncode(body), 201, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

/// A bill as the API returns it after a change to [status].
Map<String, Object?> _billJson({
  String id = 'b1',
  String status = 'paid',
  String? method = 'transfer',
  String? paidOn = '2026-11-02',
  String? rejectionReason,
}) => {
  'id': id,
  'amount': 800000,
  'daysOverdue': 0,
  'dueDate': '2026-11-05',
  'periodStart': '2026-11-01',
  'periodEnd': '2026-11-30',
  'bankAccount': null,
  'payment': {
    'hasReceipt': false,
    'method': method,
    'paidOn': paidOn,
    'rejectionReason': rejectionReason,
    'status': status,
  },
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'room': {'id': 'r1', 'number': '08'},
  'tenant': {'id': 't1', 'name': 'Budi Santoso'},
  'statusChanges': [
    {
      'actorName': 'Siti Pemilik',
      'changedAt': '2026-11-02T03:00:00Z',
      'manual': true,
      'method': method,
      'reason': 'Koreksi data',
      'status': status,
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

/// Expects the body to name exactly the calendar day [expected] as the date
/// received, either as a plain date or as the UTC midnight timestamp of that
/// day, never as another instant.
void _expectDay(_Harness h, DateTime expected) {
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
  group('changePaymentStatus', () {
    test('posts to the status changes of the bill', () async {
      final h = _Harness((_) => _created(_billJson(id: 'b9')));

      await h.repository.changePaymentStatus(
        'b9',
        status: PaymentStatus.rejected,
        reason: 'Koreksi data',
      );

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/rent-bills/b9/status-changes');
      expect(h.request.url.queryParameters, isEmpty);
    });

    test('sends a JSON body', () async {
      final h = _Harness((_) => _created(_billJson()));

      await h.repository.changePaymentStatus(
        'b1',
        status: PaymentStatus.unpaid,
        reason: 'Koreksi data',
      );

      expect(h.request.headers['content-type'], contains('application/json'));
      expect(h.body['status'], 'unpaid');
    });

    group('to unpaid', () {
      test('sends the status and the reason and nothing else', () async {
        final h = _Harness((_) => _created(_billJson(status: 'unpaid')));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Salah catat',
        );

        expect(h.body['status'], 'unpaid');
        expect(h.body['reason'], 'Salah catat');
        expect(h.body['method'], isNull);
        expect(h.body['receivedOn'], isNull);
      });

      test('sends no method or date even when they are given', () async {
        final h = _Harness((_) => _created(_billJson(status: 'unpaid')));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Salah catat',
          method: PaymentMethod.cash,
          receivedOn: DateTime(2026, 11, 2),
        );

        expect(h.body['method'], isNull);
        expect(h.body['receivedOn'], isNull);
      });
    });

    group('to rejected', () {
      test('sends the status and the reason and nothing else', () async {
        final h = _Harness((_) => _created(_billJson(status: 'rejected')));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.rejected,
          reason: 'Bukti palsu',
        );

        expect(h.body['status'], 'rejected');
        expect(h.body['reason'], 'Bukti palsu');
        expect(h.body['method'], isNull);
        expect(h.body['receivedOn'], isNull);
      });

      test('sends no method or date even when they are given', () async {
        final h = _Harness((_) => _created(_billJson(status: 'rejected')));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.rejected,
          reason: 'Bukti palsu',
          method: PaymentMethod.transfer,
          receivedOn: DateTime(2026, 11, 2),
        );

        expect(h.body['method'], isNull);
        expect(h.body['receivedOn'], isNull);
      });
    });

    group('to paid', () {
      for (final method in PaymentMethod.values) {
        test('sends the method ${method.value}', () async {
          final h = _Harness((_) => _created(_billJson()));

          await h.repository.changePaymentStatus(
            'b1',
            status: PaymentStatus.paid,
            reason: 'Sudah diterima',
            method: method,
            receivedOn: DateTime(2026, 11, 2),
          );

          expect(h.body['status'], 'paid');
          expect(h.body['reason'], 'Sudah diterima');
          expect(h.body['method'], method.value);
        });
      }

      test('sends the calendar day of a local date', () async {
        final h = _Harness((_) => _created(_billJson()));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Sudah diterima',
          method: PaymentMethod.cash,
          receivedOn: DateTime(2026, 10, 15),
        );

        _expectDay(h, DateTime.utc(2026, 10, 15));
      });

      test('sends a single digit month and day as that calendar day', () async {
        final h = _Harness((_) => _created(_billJson()));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Sudah diterima',
          method: PaymentMethod.cash,
          receivedOn: DateTime.utc(2026, 1, 5),
        );

        _expectDay(h, DateTime.utc(2026, 1, 5));
      });

      test('keeps the calendar day of a local time late in the day', () async {
        final h = _Harness((_) => _created(_billJson()));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Sudah diterima',
          method: PaymentMethod.cash,
          receivedOn: DateTime(2026, 10, 15, 23, 30),
        );

        _expectDay(h, DateTime.utc(2026, 10, 15));
      });

      test('keeps the calendar day of a local time early in the day', () async {
        final h = _Harness((_) => _created(_billJson()));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Sudah diterima',
          method: PaymentMethod.cash,
          receivedOn: DateTime(2026, 10, 15, 0, 1),
        );

        _expectDay(h, DateTime.utc(2026, 10, 15));
      });

      test('keeps the calendar day of a UTC time late in the day', () async {
        final h = _Harness((_) => _created(_billJson()));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Sudah diterima',
          method: PaymentMethod.cash,
          receivedOn: DateTime.utc(2026, 10, 15, 23, 59),
        );

        _expectDay(h, DateTime.utc(2026, 10, 15));
      });

      test('keeps the calendar day across a month and year boundary', () async {
        final h = _Harness((_) => _created(_billJson()));

        await h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Sudah diterima',
          method: PaymentMethod.cash,
          receivedOn: DateTime(2026, 12, 31, 23, 59),
        );

        _expectDay(h, DateTime.utc(2026, 12, 31));
      });
    });

    test('sends the reason as given, line breaks included', () async {
      final h = _Harness((_) => _created(_billJson(status: 'unpaid')));

      await h.repository.changePaymentStatus(
        'b1',
        status: PaymentStatus.unpaid,
        reason: 'Baris satu.\nBaris dua.',
      );

      expect(h.body['reason'], 'Baris satu.\nBaris dua.');
    });

    test('returns a paid bill as the API has it after the change', () async {
      final h = _Harness(
        (_) =>
            _created(_billJson(id: 'b9', method: 'cash', paidOn: '2026-11-03')),
      );

      final bill = await h.repository.changePaymentStatus(
        'b9',
        status: PaymentStatus.paid,
        reason: 'Koreksi data',
        method: PaymentMethod.cash,
        receivedOn: DateTime(2026, 11, 3),
      );

      expect(bill.id, 'b9');
      expect(bill.amount, 800000);
      expect(bill.payment.status, PaymentStatus.paid);
      expect(bill.payment.method, PaymentMethod.cash);
      expect(bill.payment.paidOn!.day, 3);
      expect(bill.payment.paidOn!.month, 11);
      expect(bill.tenant.name, 'Budi Santoso');
      expect(bill.room.number, '08');
      expect(bill.property.name, 'Kos Melati');
    });

    test('returns a rejected bill with its rejection reason', () async {
      final h = _Harness(
        (_) => _created(
          _billJson(
            status: 'rejected',
            method: null,
            paidOn: null,
            rejectionReason: 'Bukti palsu',
          ),
        ),
      );

      final bill = await h.repository.changePaymentStatus(
        'b1',
        status: PaymentStatus.rejected,
        reason: 'Bukti palsu',
      );

      expect(bill.payment.status, PaymentStatus.rejected);
      expect(bill.payment.rejectionReason, 'Bukti palsu');
      expect(bill.payment.method, isNull);
      expect(bill.payment.paidOn, isNull);
    });

    test('returns an unpaid bill without payment details', () async {
      final h = _Harness(
        (_) =>
            _created(_billJson(status: 'unpaid', method: null, paidOn: null)),
      );

      final bill = await h.repository.changePaymentStatus(
        'b1',
        status: PaymentStatus.unpaid,
        reason: 'Salah catat',
      );

      expect(bill.payment.status, PaymentStatus.unpaid);
      expect(bill.payment.method, isNull);
      expect(bill.payment.paidOn, isNull);
    });

    test('maps the status change of the payment', () async {
      final h = _Harness((_) => _created(_billJson()));

      final bill = await h.repository.changePaymentStatus(
        'b1',
        status: PaymentStatus.paid,
        reason: 'Koreksi data',
        method: PaymentMethod.transfer,
        receivedOn: DateTime(2026, 11, 2),
      );

      final change = bill.statusChanges.single;
      expect(change.status, PaymentStatus.paid);
      expect(change.method, PaymentMethod.transfer);
      expect(change.reason, 'Koreksi data');
      expect(change.manual, isTrue);
      expect(change.actorName, 'Siti Pemilik');
      expect(change.changedAt, DateTime.utc(2026, 11, 2, 3));
    });

    test('keeps the code and status of a missing bill', () async {
      final h = _Harness((_) => _error(404, 'RENT_BILL_NOT_FOUND'));

      await expectLater(
        h.repository.changePaymentStatus(
          'nope',
          status: PaymentStatus.unpaid,
          reason: 'Koreksi data',
        ),
        throwsA(_failure('RENT_BILL_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Koreksi data',
        ),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code, field and status of a missing reason', () async {
      final h = _Harness(
        (_) => _error(422, 'REASON_REQUIRED', field: 'reason'),
      );

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: ' ',
        ),
        throwsA(_failure('REASON_REQUIRED', field: 'reason', status: 422)),
      );
    });

    test('keeps the code, field and status of an unchanged status', () async {
      final h = _Harness(
        (_) => _error(422, 'STATUS_UNCHANGED', field: 'status'),
      );

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Koreksi data',
        ),
        throwsA(_failure('STATUS_UNCHANGED', field: 'status', status: 422)),
      );
    });

    test('keeps the code, field and status of a date in the future', () async {
      final h = _Harness(
        (_) => _error(422, 'RECEIVED_ON_IN_FUTURE', field: 'receivedOn'),
      );

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.paid,
          reason: 'Koreksi data',
          method: PaymentMethod.cash,
          receivedOn: DateTime(2099, 1, 1),
        ),
        throwsA(
          _failure('RECEIVED_ON_IN_FUTURE', field: 'receivedOn', status: 422),
        ),
      );
    });

    for (final field in ['method', 'receivedOn', 'reason', 'status']) {
      test('keeps the code, field and status of an invalid $field', () async {
        final h = _Harness(
          (_) => _error(422, 'VALIDATION_FAILED', field: field),
        );

        await expectLater(
          h.repository.changePaymentStatus(
            'b1',
            status: PaymentStatus.paid,
            reason: 'Koreksi data',
          ),
          throwsA(_failure('VALIDATION_FAILED', field: field, status: 422)),
        );
      });
    }

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Koreksi data',
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Koreksi data',
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.changePaymentStatus(
          'b1',
          status: PaymentStatus.unpaid,
          reason: 'Koreksi data',
        ),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
