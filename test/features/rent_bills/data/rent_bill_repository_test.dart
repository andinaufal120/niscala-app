import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

Map<String, Object?> _paymentJson({
  String status = 'unpaid',
  bool hasReceipt = false,
  String? rejectionReason,
}) => {
  'hasReceipt': hasReceipt,
  'method': null,
  'paidOn': null,
  'rejectionReason': rejectionReason,
  'status': status,
};

Map<String, Object?> _summaryJson({
  String id = 'b1',
  String status = 'unpaid',
  bool hasReceipt = false,
  String? rejectionReason,
  int daysOverdue = 0,
  bool isCurrent = true,
  bool canUploadReceipt = true,
}) => {
  'id': id,
  'amount': 800000,
  'daysOverdue': daysOverdue,
  'dueDate': '2026-11-05',
  'periodStart': '2026-11-01',
  'periodEnd': '2026-11-30',
  'payment': _paymentJson(
    status: status,
    hasReceipt: hasReceipt,
    rejectionReason: rejectionReason,
  ),
  'room': {'id': 'r1', 'number': '08'},
  'tenant': {'id': 't1', 'name': 'Budi Santoso'},
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'isCurrent': isCurrent,
  'canUploadReceipt': canUploadReceipt,
};

Map<String, Object?> _billJson({
  String id = 'b1',
  String status = 'unpaid',
  bool hasReceipt = false,
  bool isCurrent = true,
  bool canUploadReceipt = true,
  bool withBankAccount = true,
}) => {
  ..._summaryJson(
    id: id,
    status: status,
    hasReceipt: hasReceipt,
    isCurrent: isCurrent,
    canUploadReceipt: canUploadReceipt,
  ),
  'bankAccount': withBankAccount
      ? {
          'bankName': 'BCA',
          'accountNumber': '1234567890',
          'accountHolderName': 'Siti Pemilik',
        }
      : null,
  'statusChanges': <Object?>[],
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
    repository = ApiRentBillRepository(rentBills: RentBillsApi(apiClient));
  }

  final requests = <http.Request>[];
  late final ApiRentBillRepository repository;

  http.Request get request => requests.single;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

void main() {
  group('list', () {
    test('gets the bills and returns them in the order received', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(id: 'b3'),
            _summaryJson(id: 'b1'),
            _summaryJson(id: 'b2'),
          ],
        }),
      );

      final result = await h.repository.list(statuses: [PaymentStatus.unpaid]);

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/rent-bills');
      expect(result.map((b) => b.id), ['b3', 'b1', 'b2']);
    });

    test('repeats the payment status parameter once per status', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(
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
    });

    test('sends a single status for the history', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(statuses: [PaymentStatus.paid]);

      expect(h.request.url.queryParametersAll['paymentStatus'], ['paid']);
    });

    test('sends no other filter', () async {
      final h = _Harness((_) => _ok({'items': []}));

      await h.repository.list(statuses: [PaymentStatus.paid]);

      expect(h.request.url.queryParameters.keys, ['paymentStatus']);
    });

    test('maps the fields of a summary', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(
              status: 'rejected',
              hasReceipt: true,
              rejectionReason: 'Foto buram.',
              daysOverdue: 3,
            ),
          ],
        }),
      );

      final b = (await h.repository.list(
        statuses: [PaymentStatus.rejected],
      )).single;

      expect(b.amount, 800000);
      expect(b.daysOverdue, 3);
      expect(b.dueDate.year, 2026);
      expect(b.dueDate.month, 11);
      expect(b.dueDate.day, 5);
      expect(b.periodStart.day, 1);
      expect(b.periodEnd.day, 30);
      expect(b.payment.status, PaymentStatus.rejected);
      expect(b.payment.hasReceipt, isTrue);
      expect(b.payment.rejectionReason, 'Foto buram.');
      expect(b.room.number, '08');
      expect(b.tenant.name, 'Budi Santoso');
      expect(b.property.name, 'Kos Melati');
    });

    test('maps the current and uploadable flags', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _summaryJson(id: 'a'),
            _summaryJson(id: 'b', isCurrent: false, canUploadReceipt: false),
          ],
        }),
      );

      final result = await h.repository.list(statuses: [PaymentStatus.unpaid]);

      expect(result[0].isCurrent, isTrue);
      expect(result[0].canUploadReceipt, isTrue);
      expect(result[1].isCurrent, isFalse);
      expect(result[1].canUploadReceipt, isFalse);
    });

    for (final status in PaymentStatus.values) {
      test('maps the status ${status.value}', () async {
        final h = _Harness(
          (_) => _ok({
            'items': [_summaryJson(status: status.value)],
          }),
        );

        final b = (await h.repository.list(statuses: [status])).single;

        expect(b.payment.status, status);
      });
    }

    test('returns an empty list when there are no bills', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.list(statuses: [PaymentStatus.paid]), isEmpty);
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.list(statuses: [PaymentStatus.paid]),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list(statuses: [PaymentStatus.paid]),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.list(statuses: [PaymentStatus.paid]),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.list(statuses: [PaymentStatus.paid]),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('get', () {
    test('gets the bill by id and maps its detail', () async {
      final h = _Harness((_) => _ok(_billJson(id: 'b9')));

      final b = await h.repository.get('b9');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/rent-bills/b9');
      expect(b.id, 'b9');
      expect(b.amount, 800000);
      expect(b.payment.status, PaymentStatus.unpaid);
      expect(b.tenant.name, 'Budi Santoso');
      expect(b.property.name, 'Kos Melati');
      expect(b.isCurrent, isTrue);
      expect(b.canUploadReceipt, isTrue);
    });

    test('maps the bank account', () async {
      final h = _Harness((_) => _ok(_billJson()));

      final account = (await h.repository.get('b1')).bankAccount!;

      expect(account.bankName, 'BCA');
      expect(account.accountNumber, '1234567890');
      expect(account.accountHolderName, 'Siti Pemilik');
    });

    test('maps a bill whose property has no bank account', () async {
      final h = _Harness(
        (_) => _ok(_billJson(withBankAccount: false, canUploadReceipt: false)),
      );

      final b = await h.repository.get('b1');

      expect(b.bankAccount, isNull);
      expect(b.canUploadReceipt, isFalse);
    });

    test('converts a not found response to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'RENT_BILL_NOT_FOUND'));

      await expectLater(
        h.repository.get('nope'),
        throwsA(_failure('RENT_BILL_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.get('b1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 503));

      await expectLater(
        h.repository.get('b1'),
        throwsA(_failure('INTERNAL_ERROR', status: 503)),
      );
    });
  });

  group('uploadReceipt', () {
    final jpeg = ReceiptFile(
      name: 'bukti.jpg',
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4, 5]),
    );
    final png = ReceiptFile(
      name: 'bukti.png',
      bytes: Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        9,
        8,
        7,
      ]),
    );

    String bodyOf(http.Request request) => latin1.decode(request.bodyBytes);

    test('puts the file as multipart form data and returns the bill', () async {
      final h = _Harness(
        (_) => _ok(
          _billJson(
            status: 'awaitingVerification',
            hasReceipt: true,
            canUploadReceipt: false,
          ),
        ),
      );

      final b = await h.repository.uploadReceipt('b1', jpeg);

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/rent-bills/b1/receipt');
      expect(
        h.request.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      expect(b.payment.status, PaymentStatus.awaitingVerification);
      expect(b.payment.hasReceipt, isTrue);
      expect(b.canUploadReceipt, isFalse);
    });

    test('names the part file and keeps the file name and bytes', () async {
      final h = _Harness((_) => _ok(_billJson()));

      await h.repository.uploadReceipt('b1', jpeg);

      final body = bodyOf(h.request);
      expect(body, contains('name="file"'));
      expect(body, contains('filename="bukti.jpg"'));
      final payload = latin1.decode(jpeg.bytes);
      expect(body, contains(payload));
    });

    test('declares a JPEG file as image/jpeg', () async {
      final h = _Harness((_) => _ok(_billJson()));

      await h.repository.uploadReceipt('b1', jpeg);

      expect(
        bodyOf(h.request).toLowerCase(),
        contains('content-type: image/jpeg'),
      );
    });

    test('declares a PNG file as image/png', () async {
      final h = _Harness((_) => _ok(_billJson()));

      await h.repository.uploadReceipt('b1', png);

      final body = bodyOf(h.request);
      expect(body, contains('filename="bukti.png"'));
      expect(body.toLowerCase(), contains('content-type: image/png'));
    });

    final failures = <String, (int, String, String?)>{
      'a validation error on the file': (422, 'VALIDATION_FAILED', 'file'),
      'a wrong file type': (422, 'RECEIPT_TYPE_INVALID', 'file'),
      'a file that is too large': (413, 'RECEIPT_TOO_LARGE', 'file'),
      'a bill that cannot be uploaded to': (
        409,
        'RENT_BILL_NOT_UPLOADABLE',
        null,
      ),
      'a property without a bank account': (
        409,
        'PROPERTY_BANK_ACCOUNT_MISSING',
        null,
      ),
      'a missing bill': (404, 'RENT_BILL_NOT_FOUND', null),
      'a forbidden response': (403, 'FORBIDDEN', null),
    };
    for (final entry in failures.entries) {
      final (status, code, field) = entry.value;
      test('keeps the code, field and status of ${entry.key}', () async {
        final h = _Harness((_) => _error(status, code, field: field));

        await expectLater(
          h.repository.uploadReceipt('b1', jpeg),
          throwsA(_failure(code, field: field, status: status)),
        );
      });
    }

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.uploadReceipt('b1', jpeg),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('converts a client exception to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.uploadReceipt('b1', jpeg),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.uploadReceipt('b1', jpeg),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });

  group('receiptBytes', () {
    final image = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 250]);

    test('gets the image bytes of the bill unchanged', () async {
      final h = _Harness(
        (_) => http.Response.bytes(
          image,
          200,
          headers: {'content-type': 'image/png'},
        ),
      );

      final bytes = await h.repository.receiptBytes('b4');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/rent-bills/b4/receipt');
      expect(bytes, image);
    });

    test('converts a missing receipt to an ApiFailure', () async {
      final h = _Harness((_) => _error(404, 'RECEIPT_NOT_FOUND'));

      await expectLater(
        h.repository.receiptBytes('b1'),
        throwsA(_failure('RECEIPT_NOT_FOUND', status: 404)),
      );
    });

    test('converts a forbidden response to an ApiFailure', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.receiptBytes('b1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.receiptBytes('b1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });

    test('maps a server error without a body to INTERNAL_ERROR', () async {
      final h = _Harness((_) => http.Response('', 500));

      await expectLater(
        h.repository.receiptBytes('b1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });
  });
}
