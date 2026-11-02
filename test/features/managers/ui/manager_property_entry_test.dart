import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/managers/ui/manager_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'manager_ui_helpers.dart';

Future<void> _open(
  WidgetTester tester, {
  UserRole role = UserRole.owner,
  bool largeText = false,
  FakeManagerRepository? managers,
}) => pumpManagerApp(
  tester,
  managers ?? FakeManagerRepository(managers: sampleManagers()),
  role: role,
  path: '/properti/p1',
  largeText: largeText,
);

void main() {
  group('the Pengelola entry on the property detail', () {
    testWidgets('an owner sees it, at least 48 dp', (tester) async {
      await _open(tester);

      expect(find.text('Pengelola'), findsOneWidget);
      expectTargetSize(tester, 'Pengelola');
    });

    testWidgets('an owner still sees the managers summary of the property', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Pengelola Kost'), findsOneWidget);
      expect(find.text('Pengelola'), findsOneWidget);
    });

    testWidgets('it opens the manager list of the property', (tester) async {
      final repo = FakeManagerRepository(managers: sampleManagers());
      await _open(tester, managers: repo);

      await tapVisible(tester, find.text('Pengelola'));

      expect(currentPath(tester), '/properti/p1/pengelola');
      final list = tester.widget<ManagerListScreen>(
        find.byType(ManagerListScreen),
      );
      expect(list.propertyId, 'p1');
      expect(repo.calls, contains('list:p1'));
    });

    testWidgets('Kembali from the list returns to the property detail', (
      tester,
    ) async {
      await _open(tester);
      await tapVisible(tester, find.text('Pengelola'));

      await pressBack(tester);

      expect(currentPath(tester), '/properti/p1');
    });

    testWidgets('a manager does not see it', (tester) async {
      await _open(tester, role: UserRole.manager);

      expect(find.text('Pengelola'), findsNothing);
    });

    testWidgets('a manager still sees the managers summary', (tester) async {
      await _open(tester, role: UserRole.manager);

      expect(find.text('Pengelola Kost'), findsOneWidget);
    });

    testWidgets('a manager does not load any manager', (tester) async {
      final repo = FakeManagerRepository(managers: sampleManagers());
      await _open(tester, role: UserRole.manager, managers: repo);

      expect(repo.calls, isEmpty);
    });
  });

  group('accessibility', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('meets the guidelines for a $role', (tester) async {
        await _open(tester, role: role);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size for a $role', (tester) async {
        await _open(tester, role: role, largeText: true);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
