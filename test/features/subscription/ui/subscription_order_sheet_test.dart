import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'subscription_ui_helpers.dart';

const _confirm = 'Lanjut ke Google Play';
const _notAnUpgrade =
    'Paket yang dipilih harus lebih tinggi dari paket Anda saat ini.';

Future<void> _open(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions, {
  bool largeText = false,
}) => pumpSubscriptionApp(tester, subscriptions, largeText: largeText);

Future<void> _openSheet(
  WidgetTester tester,
  String button, {
  bool yearly = false,
}) async {
  if (yearly) {
    await tester.tap(filterChip('Tahunan'));
    await tester.pumpAndSettle();
  }
  await tap(tester, find.text(button));
  expect(orderSheet(), findsOneWidget);
}

Future<void> _confirmOrder(WidgetTester tester) async {
  await tester.ensureVisible(inSheet(find.text(_confirm)));
  await tester.pump();
  await tester.tap(inSheet(find.text(_confirm)));
  await tester.pumpAndSettle();
}

void main() {
  group('the sheet', () {
    testWidgets('does not show before a plan is chosen', (tester) async {
      await _open(tester, FakeSubscriptionRepository());

      expect(orderSheet(), findsNothing);
      expect(find.text('Ringkasan pesanan'), findsNothing);
    });

    testWidgets('opens for Basic with the monthly order summary', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);

      await _openSheet(tester, 'Pilih Basic');

      expect(inSheet(find.text('Ringkasan pesanan')), findsOneWidget);
      expect(inSheet(find.text('Paket')), findsOneWidget);
      expect(inSheet(find.text('Basic · Bulanan')), findsOneWidget);
      expect(inSheet(find.text('Batas properti')), findsOneWidget);
      expect(inSheet(find.text('Maksimal 3 properti')), findsOneWidget);
      expect(inSheet(find.text('Total')), findsOneWidget);
      expect(inSheet(find.text('Rp49.000/bulan')), findsOneWidget);
      expect(inSheet(find.text(_confirm)), findsOneWidget);
      expect(inSheet(find.text('Batal')), findsOneWidget);
    });

    testWidgets('shows the yearly summary of Pro for the selected period', (
      tester,
    ) async {
      await _open(tester, FakeSubscriptionRepository());

      await _openSheet(tester, 'Pilih Pro', yearly: true);

      expect(inSheet(find.text('Pro · Tahunan')), findsOneWidget);
      expect(
        inSheet(find.text('Jumlah properti tidak dibatasi')),
        findsOneWidget,
      );
      expect(inSheet(find.text('Rp1.290.000/tahun')), findsOneWidget);
    });

    testWidgets('shows the yearly summary of Basic', (tester) async {
      await _open(tester, FakeSubscriptionRepository());

      await _openSheet(tester, 'Pilih Basic', yearly: true);

      expect(inSheet(find.text('Basic · Tahunan')), findsOneWidget);
      expect(inSheet(find.text('Rp490.000/tahun')), findsOneWidget);
    });

    testWidgets('takes the property limit from the plan data', (tester) async {
      final subscriptions = FakeSubscriptionRepository(
        plans: [
          makeSubscriptionPlans()[0],
          makeSubscriptionPlan(
            code: PlanCode.basic,
            aiEnabled: true,
            maxProperties: 7,
            prices: makeSubscriptionPlans()[1].prices,
          ),
          makeSubscriptionPlans()[2],
        ],
      );
      await _open(tester, subscriptions);

      await _openSheet(tester, 'Pilih Basic');

      expect(inSheet(find.text('Maksimal 7 properti')), findsOneWidget);
    });

    testWidgets('lists the rows in order above the buttons', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic');

      final tops = [
        for (final text in [
          'Ringkasan pesanan',
          'Paket',
          'Batas properti',
          'Total',
          _confirm,
        ])
          tester.getTopLeft(inSheet(find.text(text))).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet().length, tops.length);
    });

    testWidgets('announces its title as a heading', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic');

      expectHeading(tester, 'Ringkasan pesanan');
    });

    testWidgets('opens from an active Basic subscription for Pro', (
      tester,
    ) async {
      await _open(
        tester,
        FakeSubscriptionRepository(subscription: makeActiveSubscription()),
      );

      await _openSheet(tester, 'Pilih Pro');

      expect(inSheet(find.text('Pro · Bulanan')), findsOneWidget);
      expect(inSheet(find.text('Rp129.000/bulan')), findsOneWidget);
    });

    testWidgets('opening it creates nothing', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);

      await _openSheet(tester, 'Pilih Basic');

      expect(subscriptions.createOrderCalls, 0);
    });
  });

  group('Batal', () {
    testWidgets('closes the sheet without creating an order', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await tester.tap(inSheet(find.text('Batal')));
      await tester.pumpAndSettle();

      expect(orderSheet(), findsNothing);
      expect(subscriptions.createOrderCalls, 0);
      expect(subscriptions.subscriptionCalls, 1);
      expect(find.text('Pilih Basic'), findsOneWidget);
    });

    testWidgets('lets the owner choose again with the same period', (
      tester,
    ) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic', yearly: true);
      await tester.tap(inSheet(find.text('Batal')));
      await tester.pumpAndSettle();

      await tap(tester, find.text('Pilih Pro'));

      expect(inSheet(find.text('Pro · Tahunan')), findsOneWidget);
    });
  });

  group('confirming', () {
    testWidgets('creates an order for the plan and the monthly period', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(subscriptions.createdOrders, hasLength(1));
      expect(subscriptions.createdOrders.single.planCode, PaidPlanCode.basic);
      expect(
        subscriptions.createdOrders.single.billingPeriod,
        SubscriptionPeriod.monthly,
      );
    });

    testWidgets('creates an order for the yearly period', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Pro', yearly: true);

      await _confirmOrder(tester);

      expect(subscriptions.createdOrders.single.planCode, PaidPlanCode.pro);
      expect(
        subscriptions.createdOrders.single.billingPeriod,
        SubscriptionPeriod.yearly,
      );
    });

    testWidgets('closes the sheet and reloads the subscription', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(orderSheet(), findsNothing);
      expect(subscriptions.subscriptionCalls, 2);
      expect(subscriptions.calls.last, 'subscription');
      expect(
        subscriptions.calls.indexOf('createOrder'),
        lessThan(subscriptions.calls.lastIndexOf('subscription')),
      );
    });

    testWidgets('shows the open order after the reload', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(
        find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the yearly Pro order after the reload', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Pro', yearly: true);

      await _confirmOrder(tester);

      expect(
        find.text('Pesanan paket Pro (Tahunan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });

    testWidgets('an active Basic owner can order Pro', (tester) async {
      final subscriptions = FakeSubscriptionRepository(
        subscription: makeActiveSubscription(),
      );
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Pro');

      await _confirmOrder(tester);

      expect(subscriptions.createdOrders.single.planCode, PaidPlanCode.pro);
      expect(
        find.text('Pesanan paket Pro (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });

    testWidgets('stays on the subscription screen', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(currentPath(tester), subscriptionPath);
    });

    testWidgets('does not pay: only one order is created', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(subscriptions.calls.where((c) => c.startsWith('order:')), isEmpty);
      expect(subscriptions.createOrderCalls, 1);
    });
  });

  group('errors', () {
    testWidgets('a plan that is not an upgrade shows its text in the sheet', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(
          code: 'SUBSCRIPTION_NOT_AN_UPGRADE',
          statusCode: 409,
        );
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(inSheet(find.text(_notAnUpgrade)), findsOneWidget);
      expect(orderSheet(), findsOneWidget);
    });

    testWidgets('any other code shows the mapped message in the sheet', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(
        inSheet(find.text(messageOfCode('INTERNAL_ERROR'))),
        findsOneWidget,
      );
      expect(orderSheet(), findsOneWidget);
    });

    testWidgets('a network failure shows its message in the sheet', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure.network();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(
        inSheet(find.text(messageOfCode('NETWORK_ERROR'))),
        findsOneWidget,
      );
    });

    testWidgets('an unknown code shows the generic message', (tester) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(
        inSheet(find.text('Terjadi kesalahan. Coba lagi.')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the summary and the buttons after a failure', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(inSheet(find.text('Basic · Bulanan')), findsOneWidget);
      expect(inSheet(find.text(_confirm)), findsOneWidget);
      expect(inSheet(find.text('Batal')), findsOneWidget);
      expect(subscriptions.subscriptionCalls, 1);
      expect(find.textContaining('menunggu pembayaran'), findsNothing);
    });

    testWidgets('the owner can try again after a failure', (tester) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.queue.add(const ApiFailure.network());
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await _confirmOrder(tester);

      await _confirmOrder(tester);

      expect(subscriptions.createOrderCalls, 2);
      expect(orderSheet(), findsNothing);
      expect(
        find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('Batal after a failure closes the sheet', (tester) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await _confirmOrder(tester);

      await tester.tap(inSheet(find.text('Batal')));
      await tester.pumpAndSettle();

      expect(orderSheet(), findsNothing);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsNothing);
    });

    testWidgets('an error shown earlier is gone when the sheet opens again', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.queue.add(const ApiFailure(code: 'INTERNAL_ERROR'));
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await _confirmOrder(tester);
      await tester.tap(inSheet(find.text('Batal')));
      await tester.pumpAndSettle();

      await tap(tester, find.text('Pilih Basic'));

      expect(inSheet(find.text(messageOfCode('INTERNAL_ERROR'))), findsNothing);
    });
  });

  group('while the order is being created', () {
    testWidgets('disables the button and shows progress', (tester) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.gate = Completer<void>();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await tester.tap(inSheet(find.text(_confirm)));
      await tester.pump();

      expectBusy(tester);
      expect(orderSheet(), findsOneWidget);
    });

    testWidgets('ignores a second tap', (tester) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.gate = Completer<void>();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');

      await tester.tap(inSheet(find.text(_confirm)));
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(subscriptions.createOrderCalls, 1);
    });

    testWidgets('closes the sheet once the order is created', (tester) async {
      final gate = Completer<void>();
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.gate = gate;
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await tester.tap(inSheet(find.text(_confirm)));
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();

      expect(orderSheet(), findsNothing);
      expect(subscriptions.createOrderCalls, 1);
      expect(
        find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });

    testWidgets('enables the button again after a failure', (tester) async {
      final gate = Completer<void>();
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.gate = gate
        ..createOrderScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await tester.tap(inSheet(find.text(_confirm)));
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.ancestor(
                of: inSheet(find.text(_confirm)),
                matching: anyButton(),
              ),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with the sheet open', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the sheet showing an error', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(
          code: 'SUBSCRIPTION_NOT_AN_UPGRADE',
        );
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await _confirmOrder(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while the order is created', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.gate = Completer<void>();
      await _open(tester, subscriptions);
      await _openSheet(tester, 'Pilih Basic');
      await tester.tap(inSheet(find.text(_confirm)));
      await tester.pump();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text with the sheet open', (tester) async {
      await _open(tester, FakeSubscriptionRepository(), largeText: true);

      await tap(tester, find.text('Pilih Basic'));

      expect(orderSheet(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text with the sheet showing an error', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(
          code: 'SUBSCRIPTION_NOT_AN_UPGRADE',
        );
      await _open(tester, subscriptions, largeText: true);
      await tap(tester, find.text('Pilih Basic'));

      await tester.tap(inSheet(find.text(_confirm)));
      await tester.pumpAndSettle();

      expect(inSheet(find.text(_notAnUpgrade)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('both sheet buttons are at least 48 dp', (tester) async {
      await _open(tester, FakeSubscriptionRepository());
      await _openSheet(tester, 'Pilih Basic');

      expectTargetSize(tester, _confirm);
      expectTargetSize(tester, 'Batal');
    });
  });
}
