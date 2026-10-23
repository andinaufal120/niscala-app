import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'property_ui_helpers.dart';

FakePropertyRepository _repo() => FakePropertyRepository(
  properties: [
    makeProperty(id: 'p1'),
    makeProperty(id: 'p2', name: 'Kos Mawar'),
  ],
);

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('property routes', () {
    testWidgets('/properti shows the list', (tester) async {
      await pumpPropertyApp(tester, _repo());

      expect(find.byType(PropertyListScreen), findsOneWidget);
    });

    testWidgets('/properti/tambah shows the add form', (tester) async {
      await pumpPropertyApp(tester, _repo(), path: '/properti/tambah');

      final form = tester.widget<PropertyFormScreen>(
        find.byType(PropertyFormScreen),
      );
      expect(form.propertyId, isNull);
      expect(currentPath(tester), '/properti/tambah');
    });

    testWidgets('/properti/:id shows the detail of that property', (
      tester,
    ) async {
      await pumpPropertyApp(tester, _repo(), path: '/properti/p2');

      final detail = tester.widget<PropertyDetailScreen>(
        find.byType(PropertyDetailScreen),
      );
      expect(detail.propertyId, 'p2');
      expect(detail.showBack, isTrue);
    });

    testWidgets('/properti/:id/ubah shows the edit form of that property', (
      tester,
    ) async {
      await pumpPropertyApp(tester, _repo(), path: '/properti/p2/ubah');

      final form = tester.widget<PropertyFormScreen>(
        find.byType(PropertyFormScreen),
      );
      expect(form.propertyId, 'p2');
    });

    for (final path in ['/properti', '/properti/tambah', '/properti/p1']) {
      testWidgets('$path keeps the Properti tab selected', (tester) async {
        await pumpPropertyApp(tester, _repo(), path: path);

        expect(_selectedTab(tester), 3);
      });
    }

    testWidgets('Kembali from the add form returns to the list', (
      tester,
    ) async {
      await pumpPropertyApp(tester, _repo(), path: '/properti/tambah');

      await pressBack(tester);

      expect(currentPath(tester), '/properti');
      expect(find.byType(PropertyListScreen), findsOneWidget);
    });

    testWidgets('Kembali from the edit form returns to the detail', (
      tester,
    ) async {
      await pumpPropertyApp(tester, _repo(), path: '/properti/p1/ubah');

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    testWidgets('Kembali from the detail returns to the list', (tester) async {
      await pumpPropertyApp(tester, _repo(), path: '/properti/p1');

      await pressBack(tester);

      expect(currentPath(tester), '/properti');
      expect(find.byType(PropertyListScreen), findsOneWidget);
    });

    for (final path in [
      '/properti',
      '/properti/tambah',
      '/properti/p1',
      '/properti/p1/ubah',
    ]) {
      testWidgets('a tenant opening $path is sent to the tenant home', (
        tester,
      ) async {
        final repo = _repo();
        await pumpPropertyApp(tester, repo, role: UserRole.tenant, path: path);

        expect(currentPath(tester), '/penyewa/beranda');
        expect(find.byType(PropertyListScreen), findsNothing);
        expect(find.byType(PropertyDetailScreen), findsNothing);
        expect(find.byType(PropertyFormScreen), findsNothing);
        expect(repo.calls, isEmpty);
      });
    }
  });
}
