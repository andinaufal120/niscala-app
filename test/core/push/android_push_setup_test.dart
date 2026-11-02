import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _types = [
  'billIssued',
  'dueDateReminder',
  'billOverdue',
  'paymentStatusChanged',
  'complaintStatusChanged',
  'complaintSubmitted',
  'receiptUploaded',
  'cashPaymentRecorded',
  'tenantActivated',
  'managerActivated',
];

/// The string resources of the file, by name.
Map<String, String> _strings() {
  final file = File('android/app/src/main/res/values/strings.xml');
  expect(file.existsSync(), isTrue, reason: 'strings.xml must exist');
  final xml = file.readAsStringSync();
  return {
    for (final m in RegExp(
      r'<string\s+[^>]*name="([^"]+)"[^>]*>([\s\S]*?)</string>',
    ).allMatches(xml))
      m.group(1)!: m.group(2)!.trim(),
  };
}

void main() {
  group('string resources', () {
    test('every notification type has a title', () {
      final strings = _strings();

      for (final type in _types) {
        expect(
          strings['notification_${type}_title'],
          isNotNull,
          reason: 'title of $type',
        );
        expect(
          strings['notification_${type}_title'],
          isNotEmpty,
          reason: 'title of $type',
        );
      }
    });

    test('every notification type has a body', () {
      final strings = _strings();

      for (final type in _types) {
        expect(
          strings['notification_${type}_body'],
          isNotNull,
          reason: 'body of $type',
        );
        expect(
          strings['notification_${type}_body'],
          isNotEmpty,
          reason: 'body of $type',
        );
      }
    });

    test('no text repeats its own resource name', () {
      final strings = _strings();

      for (final type in _types) {
        for (final part in ['title', 'body']) {
          final key = 'notification_${type}_$part';
          expect(strings[key], isNot(key), reason: key);
        }
      }
    });

    test('a title differs from the body of the same type', () {
      final strings = _strings();

      for (final type in _types) {
        expect(
          strings['notification_${type}_title'],
          isNot(strings['notification_${type}_body']),
          reason: type,
        );
      }
    });

    test('no text is left as a placeholder', () {
      final strings = _strings();

      for (final type in _types) {
        for (final part in ['title', 'body']) {
          final value = strings['notification_${type}_$part']!.toLowerCase();
          expect(value, isNot(contains('todo')), reason: '$type $part');
          expect(value, isNot(contains('lorem')), reason: '$type $part');
        }
      }
    });

    test('there is no title or body for a type the app does not know', () {
      final known = {
        for (final type in _types) ...[
          'notification_${type}_title',
          'notification_${type}_body',
        ],
      };

      final unknown = _strings().keys.where(
        (name) =>
            name.startsWith('notification_') &&
            (name.endsWith('_title') || name.endsWith('_body')) &&
            !known.contains(name),
      );

      expect(unknown, isEmpty);
    });
  });

  group('manifest', () {
    test('declares the permission to post notifications', () {
      final file = File('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue);

      expect(
        RegExp(
          r'<uses-permission[^>]*android:name="android\.permission\.POST_NOTIFICATIONS"',
        ).hasMatch(file.readAsStringSync()),
        isTrue,
      );
    });
  });

  group('pubspec', () {
    String dependencies() {
      final text = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(
        r'^dependencies:\s*\n((?:[ \t].*\n|\s*\n)*)',
        multiLine: true,
      ).firstMatch(text);
      expect(match, isNotNull, reason: 'dependencies section');
      return match!.group(1)!;
    }

    test('lists firebase_core as a dependency', () {
      expect(
        RegExp(r'^  firebase_core:', multiLine: true).hasMatch(dependencies()),
        isTrue,
      );
    });

    test('lists firebase_messaging as a dependency', () {
      expect(
        RegExp(
          r'^  firebase_messaging:',
          multiLine: true,
        ).hasMatch(dependencies()),
        isTrue,
      );
    });
  });
}
