import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../features/managers/ui/manager_ui_helpers.dart';
import '../helpers/fakes.dart';
import '../helpers/lifecycle.dart';

void _lifecycle(WidgetTester tester, AppLifecycleState state) =>
    moveLifecycleTo(tester.binding, state);

void main() {
  setUp(() {
    moveLifecycleTo(
      TestWidgetsFlutterBinding.ensureInitialized(),
      AppLifecycleState.resumed,
    );
  });

  group('screens without a QR code', () {
    final tenantPaths = <String, String>{
      'the home screen': '/',
      'the tenant list': '/properti/p1/penyewa',
      'the invitation share screen of a tenant':
          '/properti/p1/penyewa/t1/undangan',
    };

    for (final entry in tenantPaths.entries) {
      testWidgets('${entry.key} never touches the brightness', (tester) async {
        final brightness = FakeScreenBrightness();
        final repo = FakeTenantRepository(tenants: [makeTenant(id: 't1')]);
        await pumpTenantApp(
          tester,
          repo,
          path: entry.value,
          screenBrightness: brightness,
        );

        _lifecycle(tester, AppLifecycleState.paused);
        await tester.pump();
        _lifecycle(tester, AppLifecycleState.resumed);
        await tester.pump();

        expect(brightness.events, isEmpty);
      });
    }

    final managerPaths = <String, String>{
      'the manager list': '/properti/p1/pengelola',
      'the invitation share screen of a manager':
          '/properti/p1/pengelola/m1/undangan',
    };

    for (final entry in managerPaths.entries) {
      testWidgets('${entry.key} never touches the brightness', (tester) async {
        final brightness = FakeScreenBrightness();
        final repo = FakeManagerRepository(managers: [makeManager(id: 'm1')]);
        await pumpManagerApp(
          tester,
          repo,
          path: entry.value,
          screenBrightness: brightness,
        );

        _lifecycle(tester, AppLifecycleState.paused);
        await tester.pump();
        _lifecycle(tester, AppLifecycleState.resumed);
        await tester.pump();

        expect(brightness.events, isEmpty);
      });
    }

    testWidgets('a manager signed in to the app never touches it on login', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      await pumpTenantApp(
        tester,
        FakeTenantRepository(),
        role: UserRole.manager,
        path: '/',
        screenBrightness: brightness,
      );

      expect(brightness.events, isEmpty);
    });
  });

  group('moving between screens', () {
    testWidgets('going from the share screen to the code raises it once', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      final repo = FakeTenantRepository(tenants: [makeTenant(id: 't1')]);
      await pumpTenantApp(
        tester,
        repo,
        path: '/properti/p1/penyewa/t1/undangan',
        screenBrightness: brightness,
      );
      expect(brightness.events, isEmpty);

      goTo(tester, '/properti/p1/penyewa/t1/undangan/qr');
      await tester.pumpAndSettle();

      expect(brightness.events, ['raise']);
    });

    testWidgets('leaving the code for the tenant list restores it once', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      final repo = FakeTenantRepository(tenants: [makeTenant(id: 't1')]);
      await pumpTenantApp(
        tester,
        repo,
        path: '/properti/p1/penyewa/t1/undangan/qr',
        screenBrightness: brightness,
      );

      goTo(tester, '/properti/p1/penyewa');
      await tester.pumpAndSettle();

      expect(brightness.events, ['raise', 'restore']);
    });

    testWidgets('opening the code of a manager raises it once', (tester) async {
      final brightness = FakeScreenBrightness();
      final repo = FakeManagerRepository(managers: [makeManager(id: 'm1')]);
      await pumpManagerApp(
        tester,
        repo,
        path: '/properti/p1/pengelola/m1/undangan',
        screenBrightness: brightness,
      );
      expect(brightness.events, isEmpty);

      goTo(tester, '/properti/p1/pengelola/m1/undangan/qr');
      await tester.pumpAndSettle();

      expect(brightness.events, ['raise']);
    });

    testWidgets('leaving the code of a manager restores it once', (
      tester,
    ) async {
      final brightness = FakeScreenBrightness();
      final repo = FakeManagerRepository(managers: [makeManager(id: 'm1')]);
      await pumpManagerApp(
        tester,
        repo,
        path: '/properti/p1/pengelola/m1/undangan/qr',
        screenBrightness: brightness,
      );

      goTo(tester, '/properti/p1/pengelola');
      await tester.pumpAndSettle();

      expect(brightness.events, ['raise', 'restore']);
    });
  });
}
