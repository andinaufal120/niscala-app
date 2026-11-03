import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/push/push_messaging.dart';

void main() {
  group('PushOpened', () {
    test('holds the notification id and the type', () {
      const push = PushOpened(notificationId: 'n1', type: 'billIssued');

      expect(push.notificationId, 'n1');
      expect(push.type, 'billIssued');
    });

    test('reads both string entries of the message data', () {
      final push = PushOpened.fromData({
        'notificationId': 'n1',
        'type': 'receiptUploaded',
      });

      expect(push.notificationId, 'n1');
      expect(push.type, 'receiptUploaded');
    });

    test('leaves a missing entry null', () {
      final push = PushOpened.fromData({'type': 'billIssued'});

      expect(push.notificationId, isNull);
      expect(push.type, 'billIssued');
    });

    test('reads an empty data map as no entries', () {
      final push = PushOpened.fromData({});

      expect(push.notificationId, isNull);
      expect(push.type, isNull);
    });

    test('ignores entries that are not strings', () {
      final push = PushOpened.fromData({
        'notificationId': 42,
        'type': ['billIssued'],
      });

      expect(push.notificationId, isNull);
      expect(push.type, isNull);
    });

    test('ignores null entries', () {
      final push = PushOpened.fromData({'notificationId': null, 'type': null});

      expect(push.notificationId, isNull);
      expect(push.type, isNull);
    });

    test('ignores unrelated entries', () {
      final push = PushOpened.fromData({
        'notificationId': 'n1',
        'type': 'billIssued',
        'other': 'x',
      });

      expect(push.notificationId, 'n1');
      expect(push.type, 'billIssued');
    });
  });
}
