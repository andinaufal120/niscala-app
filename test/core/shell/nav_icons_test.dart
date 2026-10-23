import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

Future<List<NavigationDestination>> _destinations(
  WidgetTester tester,
  UserRole role,
) async {
  await tester.pumpWidget(
    buildTestApp(store: InMemorySessionStore(storedSession(role: role))),
  );
  await tester.pumpAndSettle();
  return tester
      .widgetList<NavigationDestination>(find.byType(NavigationDestination))
      .toList();
}

IconData? _iconOf(NavigationDestination destination) {
  final icon = destination.icon;
  return icon is Icon ? icon.icon : null;
}

void main() {
  group('management tabs use outline icons', () {
    const expected = {
      'Beranda': Icons.home_outlined,
      'Keluhan': Icons.build_outlined,
      'Pembayaran': Icons.credit_card_outlined,
      'Properti': Icons.apartment_outlined,
      'Akun': Icons.person_outline,
    };

    for (final role in [UserRole.owner, UserRole.manager]) {
      for (final entry in expected.entries) {
        testWidgets('$role: ${entry.key}', (tester) async {
          final destinations = await _destinations(tester, role);

          final destination = destinations.firstWhere(
            (d) => d.label == entry.key,
          );
          expect(_iconOf(destination), entry.value);
        });
      }
    }

    testWidgets('keeps the five tabs in order', (tester) async {
      final destinations = await _destinations(tester, UserRole.owner);

      expect(destinations.map((d) => d.label), expected.keys);
      expect(destinations.map(_iconOf), expected.values);
    });
  });

  group('tenant tabs use outline icons', () {
    const expected = {
      'Beranda': Icons.home_outlined,
      'Keluhan': Icons.build_outlined,
      'Pembayaran': Icons.credit_card_outlined,
      'Akun': Icons.person_outline,
    };

    for (final entry in expected.entries) {
      testWidgets(entry.key, (tester) async {
        final destinations = await _destinations(tester, UserRole.tenant);

        final destination = destinations.firstWhere(
          (d) => d.label == entry.key,
        );
        expect(_iconOf(destination), entry.value);
      });
    }

    testWidgets('keeps the four tabs in order', (tester) async {
      final destinations = await _destinations(tester, UserRole.tenant);

      expect(destinations.map((d) => d.label), expected.keys);
      expect(destinations.map(_iconOf), expected.values);
    });
  });

  group('tab labels', () {
    testWidgets('are visible under the icons', (tester) async {
      await _destinations(tester, UserRole.owner);

      for (final label in [
        'Beranda',
        'Keluhan',
        'Pembayaran',
        'Properti',
        'Akun',
      ]) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
    });
  });
}
