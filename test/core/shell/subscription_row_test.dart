import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/action_card_row.dart';
import 'package:niscala/features/subscription/ui/subscription_screen.dart';
import 'package:niscala_api/api.dart';

import '../../features/account/ui/account_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _title = 'Langganan';
const _generic = 'Lihat paket dan langganan Anda';

Finder _row() =>
    find.ancestor(of: find.text(_title), matching: find.byType(ActionCardRow));

/// Shows the Akun tab of [role] with [subscriptions] behind the row.
Future<void> _open(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    subscriptions: subscriptions,
    accounts: FakeAccountRepository(),
    leases: FakeLeaseRepository(lease: makeCurrentLease()),
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, accountPath(role));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  group('the Langganan row of an owner', () {
    testWidgets('is shown with the icon', (tester) async {
      await _open(tester, FakeSubscriptionRepository());

      expect(find.text(_title), findsOneWidget);
      expect(_row(), findsOneWidget);
      expect(
        find.descendant(
          of: _row(),
          matching: find.byIcon(Icons.workspace_premium_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sits after the Notifikasi row', (tester) async {
      await _open(tester, FakeSubscriptionRepository());

      expect(
        tester.getTopLeft(find.text(_title)).dy,
        greaterThan(tester.getBottomLeft(find.text('Notifikasi')).dy),
      );
    });

    testWidgets('says Paket Gratis for a free subscription', (tester) async {
      await _open(tester, FakeSubscriptionRepository());

      expect(find.text('Paket Gratis'), findsOneWidget);
      expect(find.text(_generic), findsNothing);
    });

    testWidgets('names the plan and the end date of an active Basic plan', (
      tester,
    ) async {
      await _open(
        tester,
        FakeSubscriptionRepository(subscription: makeActiveSubscription()),
      );

      expect(
        find.text('Paket Basic · aktif hingga 15 Des 2026'),
        findsOneWidget,
      );
      expect(find.text('Paket Gratis'), findsNothing);
    });

    testWidgets('names the plan and the end date of an active Pro plan', (
      tester,
    ) async {
      await _open(
        tester,
        FakeSubscriptionRepository(
          subscription: makeActiveSubscription(
            planCode: PlanCode.pro,
            endDate: DateTime.utc(2027, 1, 5),
          ),
        ),
      );

      expect(find.text('Paket Pro · aktif hingga 5 Jan 2027'), findsOneWidget);
    });

    testWidgets('shows a generic subtitle while the subscription loads', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..subscriptionScript.gate = Completer<void>();
      await _open(tester, subscriptions, settle: false);

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_generic), findsOneWidget);
      expect(find.text('Paket Gratis'), findsNothing);
    });

    testWidgets('shows the generic subtitle when the subscription fails', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..subscriptionScript.always = const ApiFailure.network();
      await _open(tester, subscriptions);

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_generic), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('still opens the screen when the subscription failed', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..subscriptionScript.always = const ApiFailure.network();
      await _open(tester, subscriptions);

      await tapVisible(tester, find.text(_title));

      expect(currentPath(tester), '/akun/langganan');
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });

    testWidgets('keeps the rest of the tab when the subscription fails', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..subscriptionScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Perangkat aktif'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('fetches the subscription', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);

      expect(subscriptions.subscriptionCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('opens the Langganan screen above the tab', (tester) async {
      await _open(tester, FakeSubscriptionRepository());

      await tapVisible(tester, find.text(_title));

      expect(currentPath(tester), '/akun/langganan');
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('is one labelled button of at least 48 dp', (tester) async {
      await _open(
        tester,
        FakeSubscriptionRepository(subscription: makeActiveSubscription()),
      );

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text(_title));
        expect(node, isSemantics(isButton: true, hasTapAction: true));
        expect(node.label, startsWith(_title));
        expect(node.label, contains('Paket Basic · aktif hingga 15 Des 2026'));
        expect(node.rect.height, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });
  });

  group('the Akun tab of other roles', () {
    for (final role in [UserRole.manager, UserRole.tenant]) {
      testWidgets('shows a $role no Langganan row', (tester) async {
        final subscriptions = FakeSubscriptionRepository();
        await _open(tester, subscriptions, role: role);

        expect(find.text(_title), findsNothing);
        expect(find.text(_generic), findsNothing);
        expect(find.text('Paket Gratis'), findsNothing);
        expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
      });

      testWidgets('never loads the subscription for a $role', (tester) async {
        final subscriptions = FakeSubscriptionRepository();
        await _open(tester, subscriptions, role: role);

        expect(subscriptions.calls, isEmpty);
      });

      testWidgets('keeps the tab of a $role as it was', (tester) async {
        await _open(tester, FakeSubscriptionRepository(), role: role);

        expect(find.text('Notifikasi'), findsOneWidget);
        expect(find.text('Perangkat aktif'), findsOneWidget);
        expect(find.text('Hapus akun'), findsOneWidget);
      });
    }
  });

  group('accessibility', () {
    final states = <String, FakeSubscriptionRepository Function()>{
      'a free subscription': FakeSubscriptionRepository.new,
      'an active subscription': () =>
          FakeSubscriptionRepository(subscription: makeActiveSubscription()),
      'a failed subscription': () =>
          FakeSubscriptionRepository()
            ..subscriptionScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('the tab meets the guidelines with ${entry.key}', (
        tester,
      ) async {
        await _open(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('the tab fits at large text with ${entry.key}', (
        tester,
      ) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
        expect(find.text(_title), findsOneWidget);
      });
    }

    testWidgets('the tab fits at large text while the subscription loads', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..subscriptionScript.gate = Completer<void>();
      await _open(tester, subscriptions, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text(_generic), findsOneWidget);
    });
  });
}
