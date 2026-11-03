import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
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
    repository = ApiNotificationRepository(
      notifications: NotificationsApi(apiClient),
    );
  }

  final requests = <http.Request>[];
  late final ApiNotificationRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _billJson() => {
  'id': 'n1',
  'type': 'paymentStatusChanged',
  'createdAt': '2026-11-02T12:00:00Z',
  'read': false,
  'actorName': 'Siti Pemilik',
  'tenant': {'id': 't1', 'name': 'Budi Santoso'},
  'room': {'id': 'r1', 'number': '08'},
  'property': {'id': 'p1', 'name': 'Kos Melati'},
  'complaint': null,
  'rentBill': {
    'rentBillId': 'b1',
    'amount': 800000,
    'daysOverdue': 0,
    'dueDate': '2026-11-05',
    'periodStart': '2026-11-01',
    'periodEnd': '2026-11-30',
    'paymentStatus': 'rejected',
    'paymentMethod': null,
    'reason': 'Foto buram',
  },
};

Map<String, dynamic> _complaintJson({bool read = true}) => {
  'id': 'n2',
  'type': 'complaintStatusChanged',
  'createdAt': '2026-11-01T08:30:00Z',
  'read': read,
  'actorName': null,
  'tenant': null,
  'room': null,
  'property': null,
  'rentBill': null,
  'complaint': {
    'complaintId': 'c1',
    'description': 'Keran bocor',
    'status': 'inProgress',
    'handlingNote': 'Tukang datang besok',
    'category': 'Pipa dan air',
    'urgency': 'high',
  },
};

Map<String, dynamic> _settingJson(
  String category, {
  bool pushEnabled = true,
  String? urgencyScope,
}) => {
  'category': category,
  'pushEnabled': pushEnabled,
  'urgencyScope': urgencyScope,
};

NotificationSettingItem _item(
  NotificationCategory category, {
  bool pushEnabled = true,
  NotificationUrgencyScope? urgencyScope,
}) => NotificationSettingItem(
  category: category,
  pushEnabled: pushEnabled,
  urgencyScope: urgencyScope,
);

void main() {
  group('list', () {
    test('gets the notifications with the unread count', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_billJson(), _complaintJson()],
          'unreadCount': 1,
        }),
      );

      final result = await h.repository.list();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/notifications');
      expect(h.request.url.queryParameters, isEmpty);
      expect(result.unreadCount, 1);
      expect(result.items.map((n) => n.id), ['n1', 'n2']);
    });

    test('keeps the order of the response', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_complaintJson(), _billJson()],
          'unreadCount': 1,
        }),
      );

      final result = await h.repository.list();

      expect(result.items.map((n) => n.id), ['n2', 'n1']);
    });

    test('maps the bill facts, the place and the actor', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_billJson()],
          'unreadCount': 1,
        }),
      );

      final n = (await h.repository.list()).items.single;

      expect(n.type, NotificationType.paymentStatusChanged);
      expect(n.read, isFalse);
      expect(n.createdAt.toUtc(), DateTime.utc(2026, 11, 2, 12));
      expect(n.actorName, 'Siti Pemilik');
      expect(n.tenant!.name, 'Budi Santoso');
      expect(n.room!.number, '08');
      expect(n.property!.name, 'Kos Melati');
      expect(n.complaint, isNull);
      final bill = n.rentBill!;
      expect(bill.rentBillId, 'b1');
      expect(bill.amount, 800000);
      expect(bill.daysOverdue, 0);
      expect(bill.dueDate.day, 5);
      expect(bill.periodStart.day, 1);
      expect(bill.periodEnd.day, 30);
      expect(bill.paymentStatus, PaymentStatus.rejected);
      expect(bill.paymentMethod, isNull);
      expect(bill.reason, 'Foto buram');
    });

    test('maps the complaint facts and leaves absent facts null', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [_complaintJson()],
          'unreadCount': 0,
        }),
      );

      final n = (await h.repository.list()).items.single;

      expect(n.type, NotificationType.complaintStatusChanged);
      expect(n.read, isTrue);
      expect(n.rentBill, isNull);
      expect(n.tenant, isNull);
      expect(n.room, isNull);
      expect(n.property, isNull);
      expect(n.actorName, isNull);
      final complaint = n.complaint!;
      expect(complaint.complaintId, 'c1');
      expect(complaint.description, 'Keran bocor');
      expect(complaint.status, ComplaintStatus.inProgress);
      expect(complaint.handlingNote, 'Tukang datang besok');
      expect(complaint.category, 'Pipa dan air');
      expect(complaint.urgency, ComplaintUrgency.high);
    });

    test('returns an empty list when there are no notifications', () async {
      final h = _Harness((_) => _ok({'items': [], 'unreadCount': 0}));

      final result = await h.repository.list();

      expect(result.items, isEmpty);
      expect(result.unreadCount, 0);
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.list(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('markRead', () {
    test('posts to the read path of the notification', () async {
      final h = _Harness((_) => _ok(_complaintJson()));

      final result = await h.repository.markRead('n2');

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/notifications/n2/read');
      expect(result.id, 'n2');
      expect(result.read, isTrue);
    });

    test('keeps the code and status of a not found error', () async {
      final h = _Harness((_) => _error(404, 'NOTIFICATION_NOT_FOUND'));

      await expectLater(
        h.repository.markRead('n2'),
        throwsA(_failure('NOTIFICATION_NOT_FOUND', status: 404)),
      );
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.markRead('n2'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.markRead('n2'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.markRead('n2'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('markAllRead', () {
    test('posts to the read-all path and returns without a body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.markAllRead();

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/notifications/read-all');
    });

    test('also accepts a success response with a body', () async {
      final h = _Harness((_) => _ok({'items': [], 'unreadCount': 0}));

      await h.repository.markAllRead();

      expect(h.request.url.path, '/notifications/read-all');
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.markAllRead(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.markAllRead(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.markAllRead(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('registerPushToken', () {
    test('puts the token to the push token path and returns without a '
        'body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.registerPushToken('fcm-token-1');

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/me/push-token');
      expect(h.body, {'token': 'fcm-token-1'});
    });

    test('sends the token unchanged', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.registerPushToken('abc:APA91b-_/+=xyz');

      expect(h.body, {'token': 'abc:APA91b-_/+=xyz'});
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.registerPushToken('fcm-token-1'),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_ERROR', field: 'token'),
      );

      await expectLater(
        h.repository.registerPushToken(''),
        throwsA(_failure('VALIDATION_ERROR', field: 'token', status: 422)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.registerPushToken('fcm-token-1'),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.registerPushToken('fcm-token-1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('settings', () {
    test('gets the settings of the categories of the caller', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _settingJson('newComplaint', urgencyScope: 'highOnly'),
            _settingJson('receiptUpload', pushEnabled: false),
          ],
        }),
      );

      final result = await h.repository.settings();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/me/notification-settings');
      expect(result.items, hasLength(2));
      expect(result.items.first.category, NotificationCategory.newComplaint);
      expect(result.items.first.pushEnabled, isTrue);
      expect(
        result.items.first.urgencyScope,
        NotificationUrgencyScope.highOnly,
      );
      expect(result.items.last.category, NotificationCategory.receiptUpload);
      expect(result.items.last.pushEnabled, isFalse);
      expect(result.items.last.urgencyScope, isNull);
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.settings(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.settings(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(http.ClientException('broken'));

      await expectLater(
        h.repository.settings(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('updateSettings', () {
    test('puts exactly the given items', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _settingJson('billing', pushEnabled: false),
            _settingJson('newComplaint', urgencyScope: 'highOnly'),
          ],
        }),
      );

      final result = await h.repository.updateSettings([
        _item(NotificationCategory.billing, pushEnabled: false),
        _item(
          NotificationCategory.newComplaint,
          urgencyScope: NotificationUrgencyScope.highOnly,
        ),
      ]);

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/me/notification-settings');
      expect(h.request.headers['content-type'], contains('application/json'));
      final items = (h.body['items'] as List).cast<Map<String, dynamic>>();
      expect(items, hasLength(2));
      expect(items.first['category'], 'billing');
      expect(items.first['pushEnabled'], isFalse);
      expect(items.first['urgencyScope'], isNull);
      expect(items.last['category'], 'newComplaint');
      expect(items.last['pushEnabled'], isTrue);
      expect(items.last['urgencyScope'], 'highOnly');
      expect(result.items.map((i) => i.category), [
        NotificationCategory.billing,
        NotificationCategory.newComplaint,
      ]);
      expect(result.items.first.pushEnabled, isFalse);
    });

    test(
      'sends the all urgencies scope of the new complaint category',
      () async {
        final h = _Harness(
          (_) => _ok({
            'items': [
              _settingJson('newComplaint', urgencyScope: 'allUrgencies'),
            ],
          }),
        );

        await h.repository.updateSettings([
          _item(
            NotificationCategory.newComplaint,
            urgencyScope: NotificationUrgencyScope.allUrgencies,
          ),
        ]);

        final items = (h.body['items'] as List).cast<Map<String, dynamic>>();
        expect(items.single['urgencyScope'], 'allUrgencies');
      },
    );

    test('sends no urgency scope for the other categories', () async {
      final h = _Harness(
        (_) => _ok({
          'items': [
            _settingJson('receiptUpload'),
            _settingJson('overdueBill'),
            _settingJson('accountActivity'),
          ],
        }),
      );

      await h.repository.updateSettings([
        _item(NotificationCategory.receiptUpload),
        _item(NotificationCategory.overdueBill),
        _item(NotificationCategory.accountActivity, pushEnabled: false),
      ]);

      final items = (h.body['items'] as List).cast<Map<String, dynamic>>();
      expect(items.map((i) => i['category']), [
        'receiptUpload',
        'overdueBill',
        'accountActivity',
      ]);
      expect(items.map((i) => i['urgencyScope']), everyElement(isNull));
      expect(items.map((i) => i['pushEnabled']), [true, true, false]);
    });

    test('keeps the code, field and status of a validation error', () async {
      final h = _Harness(
        (_) => _error(422, 'VALIDATION_FAILED', field: 'items'),
      );

      await expectLater(
        h.repository.updateSettings([_item(NotificationCategory.billing)]),
        throwsA(_failure('VALIDATION_FAILED', field: 'items', status: 422)),
      );
    });

    test('keeps the code and status of a forbidden error', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.updateSettings([_item(NotificationCategory.billing)]),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a server error to an ApiFailure', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.updateSettings([_item(NotificationCategory.billing)]),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.updateSettings([_item(NotificationCategory.billing)]),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
