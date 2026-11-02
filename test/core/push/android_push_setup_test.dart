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

  group('resource keep file', () {
    const path = 'android/app/src/main/res/raw/keep.xml';
    const toolsNamespace = 'http://schemas.android.com/tools';

    String content() {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'keep.xml must exist');
      return file.readAsStringSync();
    }

    /// Whether the tags of [xml] open and close in order, with one root.
    bool wellFormed(String xml) {
      final body = xml
          .replaceAll(RegExp(r'<\?[\s\S]*?\?>'), '')
          .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
      final stack = <String>[];
      var roots = 0;
      var position = 0;
      for (final m in RegExp(
        r'<(/?)([A-Za-z_][\w.:-]*)((?:\s+[\w.:-]+\s*=\s*(?:"[^"<]*"|' // attrs
        r"'[^'<]*'))*)\s*(/?)>",
      ).allMatches(body)) {
        if (body.substring(position, m.start).trim().isNotEmpty) return false;
        position = m.end;
        final closing = m.group(1) == '/';
        final selfClosing = m.group(4) == '/';
        final name = m.group(2)!;
        if (closing) {
          if (selfClosing || stack.isEmpty || stack.removeLast() != name) {
            return false;
          }
        } else {
          if (stack.isEmpty) roots++;
          if (!selfClosing) stack.add(name);
        }
      }
      return body.substring(position).trim().isEmpty &&
          stack.isEmpty &&
          roots == 1;
    }

    /// The comma-separated entries of the tools:keep attribute.
    List<String> keepEntries() {
      final match = RegExp(
        r'''<resources\b[^>]*\btools:keep\s*=\s*(?:"([^"]*)"|'([^']*)')''',
      ).firstMatch(content());
      expect(match, isNotNull, reason: 'tools:keep on <resources>');
      return (match!.group(1) ?? match.group(2)!)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    /// Whether [name] matches the glob [pattern], where `*` matches any run
    /// of characters and `?` a single one.
    bool globMatches(String pattern, String name) {
      final regex = pattern
          .split('')
          .map(
            (c) => switch (c) {
              '*' => '.*',
              '?' => '.',
              _ => RegExp.escape(c),
            },
          )
          .join();
      return RegExp('^$regex\$').hasMatch(name);
    }

    test('exists', () {
      expect(File(path).existsSync(), isTrue);
    });

    test('is well-formed XML', () {
      expect(wellFormed(content()), isTrue);
    });

    test('has a resources root element', () {
      final body = content()
          .replaceAll(RegExp(r'<\?[\s\S]*?\?>'), '')
          .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
          .trimLeft();

      expect(body, startsWith('<resources'));
      expect(body.trimRight(), anyOf(endsWith('/>'), endsWith('</resources>')));
    });

    test('declares the tools namespace on the root element', () {
      expect(
        RegExp(
          r'''<resources\b[^>]*\bxmlns:tools\s*=\s*(?:"http://schemas\.android\.com/tools"|'http://schemas\.android\.com/tools')''',
        ).hasMatch(content()),
        isTrue,
        reason: toolsNamespace,
      );
    });

    test('has a keep attribute with at least one entry', () {
      expect(keepEntries(), isNotEmpty);
    });

    test('keeps every notification title', () {
      final entries = keepEntries();

      for (final type in _types) {
        final name = '@string/notification_${type}_title';
        expect(
          entries.any((pattern) => globMatches(pattern, name)),
          isTrue,
          reason: name,
        );
      }
    });

    test('keeps every notification body', () {
      final entries = keepEntries();

      for (final type in _types) {
        final name = '@string/notification_${type}_body';
        expect(
          entries.any((pattern) => globMatches(pattern, name)),
          isTrue,
          reason: name,
        );
      }
    });

    test('does not keep all strings', () {
      final entries = keepEntries();

      for (final name in [
        '@string/app_name',
        '@string/some_other_string',
        '@string/x',
      ]) {
        expect(
          entries.any((pattern) => globMatches(pattern, name)),
          isFalse,
          reason: name,
        );
      }
    });

    test('does not use a bare wildcard entry', () {
      for (final entry in keepEntries()) {
        expect(entry, isNot('*'));
        expect(entry, isNot('@string/*'));
        expect(entry, isNot('@*/*'));
      }
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
