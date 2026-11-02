import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/user_accounts/status_labels.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _statusLabels = {
  UserAccountStatus.active: 'Aktif',
  UserAccountStatus.inactive: 'Nonaktif',
  UserAccountStatus.deleted: 'Dihapus',
};

const _roleLabels = {
  UserRole.owner: 'Pemilik',
  UserRole.tenant: 'Penyewa',
  UserRole.manager: 'Pengelola',
  UserRole.admin: 'Admin',
};

void main() {
  group('userAccountStatusLabels', () {
    test('has an entry for every account status', () {
      expect(
        userAccountStatusLabels.keys,
        unorderedEquals(UserAccountStatus.values),
      );
    });

    for (final entry in _statusLabels.entries) {
      test('labels ${entry.key.value} as ${entry.value}', () {
        expect(userAccountStatusLabels[entry.key], entry.value);
      });
    }

    test('gives every status a different label', () {
      expect(
        userAccountStatusLabels.values.toSet(),
        hasLength(UserAccountStatus.values.length),
      );
    });
  });

  group('userRoleLabels', () {
    test('has an entry for every role', () {
      expect(userRoleLabels.keys, unorderedEquals(UserRole.values));
    });

    for (final entry in _roleLabels.entries) {
      test('labels ${entry.key.value} as ${entry.value}', () {
        expect(userRoleLabels[entry.key], entry.value);
      });
    }

    test('gives every role a different label', () {
      expect(userRoleLabels.values.toSet(), hasLength(UserRole.values.length));
    });
  });

  group('UserAccountStatusBadge', () {
    for (final entry in _statusLabels.entries) {
      testWidgets('shows ${entry.key.value} as a text badge', (tester) async {
        await tester.pumpWidget(themedApp(UserAccountStatusBadge(entry.key)));

        expect(
          find.descendant(
            of: find.byType(StatusBadge),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
      });

      testWidgets('announces ${entry.key.value} by its label', (tester) async {
        await tester.pumpWidget(themedApp(UserAccountStatusBadge(entry.key)));

        final handle = tester.ensureSemantics();
        try {
          expect(
            tester.getSemantics(find.byType(StatusBadge)),
            isSemantics(label: entry.value),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('shows an icon next to ${entry.key.value}', (tester) async {
        await tester.pumpWidget(themedApp(UserAccountStatusBadge(entry.key)));

        expect(
          tester.widget<StatusBadge>(find.byType(StatusBadge)).icon,
          isNotNull,
        );
      });
    }

    testWidgets('shows a different icon for every status', (tester) async {
      final icons = <IconData?>{};
      for (final status in UserAccountStatus.values) {
        await tester.pumpWidget(themedApp(UserAccountStatusBadge(status)));
        icons.add(tester.widget<StatusBadge>(find.byType(StatusBadge)).icon);
      }

      expect(icons, hasLength(UserAccountStatus.values.length));
    });

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        themedApp(
          Column(
            children: [
              for (final status in UserAccountStatus.values)
                UserAccountStatusBadge(status),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
