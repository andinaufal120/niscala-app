import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/billing/play_billing.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'subscription_ui_helpers.dart';

const _pay = 'Bayar';
const _confirm = 'Lanjut ke Google Play';

const _unavailable = 'Google Play tidak tersedia di perangkat ini.';

PlayPurchase _playPurchase(
  PlayPurchaseStatus status, {
  String productId = 'niscala_basic',
  String token = 'token-1',
}) => PlayPurchase(productId: productId, purchaseToken: token, status: status);

PlayPurchase _purchased({String token = 'token-1'}) =>
    _playPurchase(PlayPurchaseStatus.purchased, token: token);

/// A free subscription with an open Basic monthly order `o1`.
FakeSubscriptionRepository _withOpenOrder({
  SubscriptionOrder? order,
  Subscription? subscription,
}) => FakeSubscriptionRepository(
  subscription:
      subscription ??
      makeSubscription(openOrder: order ?? makeSubscriptionOrder()),
);

Future<void> _open(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions,
  FakePlayBilling billing, {
  bool largeText = false,
}) => pumpSubscriptionApp(
  tester,
  subscriptions,
  playBilling: billing,
  largeText: largeText,
);

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps Bayar on the open order.
Future<void> _tapPay(WidgetTester tester) => tap(tester, find.text(_pay));

/// Delivers [purchase] on the purchases stream and lets the UI settle.
Future<void> _deliver(
  WidgetTester tester,
  FakePlayBilling billing,
  PlayPurchase purchase,
) async {
  billing.emit(purchase);
  await tester.pumpAndSettle();
}

Future<void> _tapInSheet(WidgetTester tester, String label) async {
  await tester.ensureVisible(inSheet(find.text(label)));
  await tester.pump();
  await tester.tap(inSheet(find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> _confirmOrder(WidgetTester tester) =>
    _tapInSheet(tester, _confirm);

Future<void> _openOrderSheet(
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

Finder _sheet() => find.byType(BottomSheet);

void _expectNoSheet() => expect(_sheet(), findsNothing);

void _expectSheet(String title, String body, List<String> buttons) {
  expect(_sheet(), findsOneWidget);
  expect(inSheet(find.text(title)), findsOneWidget);
  expect(inSheet(find.text(body)), findsOneWidget);
  for (final button in buttons) {
    expect(inSheet(find.text(button)), findsOneWidget, reason: button);
  }
}

void _expectButtonSize(WidgetTester tester, String label) {
  final button = find.ancestor(
    of: inSheet(find.text(label)),
    matching: anyButton(),
  );
  expect(button, findsOneWidget, reason: label);
  expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
}

void _expectSuccess(String planName) => _expectSheet(
  'Pembayaran berhasil',
  'Paket $planName sekarang aktif.',
  ['Selesai'],
);

void _expectPending() => _expectSheet(
  'Menunggu pembayaran',
  'Selesaikan pembayaran Anda. Paket aktif setelah pembayaran diterima.',
  ['Cek lagi', 'Tutup'],
);

void _expectFailed() => _expectSheet(
  'Pembayaran gagal',
  'Paket tidak berubah. Anda bisa mencoba membayar lagi.',
  ['Bayar lagi', 'Tutup'],
);

void _expectExpired() => _expectSheet(
  'Pesanan kedaluwarsa',
  'Buat pesanan baru untuk membayar.',
  ['Bayar lagi', 'Tutup'],
);

void _expectCanceled() =>
    _expectSheet('Pembelian dibatalkan', 'Paket tidak berubah.', ['Tutup']);

void _expectError(String message) => _expectSheet(
  'Pembayaran belum bisa diselesaikan',
  message,
  ['Coba lagi', 'Tutup'],
);

void _expectBusy(WidgetTester tester) {
  expect(_sheet(), findsOneWidget);
  expect(inSheet(find.text('Memverifikasi pembayaran')), findsOneWidget);
  final indicator = inSheet(find.byType(CircularProgressIndicator));
  expect(indicator, findsOneWidget);
  expect(
    tester.widget<CircularProgressIndicator>(indicator).semanticsLabel,
    'Memproses',
  );
}

const _states = <String, ({String title, List<String> buttons})>{
  'busy': (title: 'Memverifikasi pembayaran', buttons: []),
  'success': (title: 'Pembayaran berhasil', buttons: ['Selesai']),
  'pending': (title: 'Menunggu pembayaran', buttons: ['Cek lagi', 'Tutup']),
  'failed': (title: 'Pembayaran gagal', buttons: ['Bayar lagi', 'Tutup']),
  'expired': (title: 'Pesanan kedaluwarsa', buttons: ['Bayar lagi', 'Tutup']),
  'canceled': (title: 'Pembelian dibatalkan', buttons: ['Tutup']),
  'error': (
    title: 'Pembayaran belum bisa diselesaikan',
    buttons: ['Coba lagi', 'Tutup'],
  ),
};

/// Pays the open order and brings the screen to the sheet of [state].
Future<void> _reach(
  WidgetTester tester,
  String state,
  FakeSubscriptionRepository subscriptions,
  FakePlayBilling billing,
) async {
  switch (state) {
    case 'busy':
      subscriptions.verifyScript.gate = Completer<void>();
      await _tapPay(tester);
      billing.emit(_purchased());
      await _frames(tester);
    case 'success':
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());
    case 'pending':
      subscriptions.verifyStatuses.add(OrderStatus.awaitingPayment);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());
    case 'failed':
      subscriptions.verifyStatuses.add(OrderStatus.failed);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());
    case 'expired':
      subscriptions.verifyStatuses.add(OrderStatus.expired);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());
    case 'canceled':
      await _tapPay(tester);
      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.canceled),
      );
    case 'error':
      subscriptions.verifyScript.always = const ApiFailure(
        code: 'GOOGLE_PLAY_UNREACHABLE',
        statusCode: 503,
      );
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());
    default:
      fail('unknown state $state');
  }
}

void main() {
  group('the Bayar button', () {
    testWidgets('shows on an open order that awaits payment', (tester) async {
      await _open(tester, _withOpenOrder(), FakePlayBilling());

      expect(find.text(_pay), findsOneWidget);
      expect(
        find.ancestor(of: find.text(_pay), matching: anyButton()),
        findsOneWidget,
      );
    });

    testWidgets('shows below the line that names the order', (tester) async {
      await _open(tester, _withOpenOrder(), FakePlayBilling());

      expect(
        tester
            .getTopLeft(
              find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
            )
            .dy,
        lessThan(tester.getTopLeft(find.text(_pay)).dy),
      );
    });

    testWidgets('does not show without an open order', (tester) async {
      await _open(tester, FakeSubscriptionRepository(), FakePlayBilling());

      expect(find.text(_pay), findsNothing);
    });

    for (final status in [
      OrderStatus.failed,
      OrderStatus.expired,
      OrderStatus.succeeded,
    ]) {
      testWidgets('does not show for an open order that is ${status.value}', (
        tester,
      ) async {
        await _open(
          tester,
          _withOpenOrder(order: makeSubscriptionOrder(status: status)),
          FakePlayBilling(),
        );

        expect(find.text(_pay), findsNothing);
      });
    }

    testWidgets('does nothing until it is tapped', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);

      expect(billing.availabilityChecks, 0);
      expect(billing.purchaseCalls, 0);
      expect(subscriptions.verifyCalls, 0);
      _expectNoSheet();
    });

    testWidgets('starts the purchase of the product of the open order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);

      await _tapPay(tester);

      expect(billing.availabilityChecks, 1);
      expect(billing.purchaseRequests, hasLength(1));
      expect(billing.purchaseRequests.single.productId, 'niscala_basic');
      expect(billing.purchaseRequests.single.basePlanId, 'monthly');
      expect(
        billing.purchaseRequests.single.obfuscatedAccountId,
        'obfuscated-o1',
      );
    });

    testWidgets('starts the purchase of a yearly Pro order', (tester) async {
      final billing = FakePlayBilling();
      await _open(
        tester,
        _withOpenOrder(
          order: makeSubscriptionOrder(
            id: 'o9',
            planCode: PaidPlanCode.pro,
            billingPeriod: SubscriptionPeriod.yearly,
          ),
        ),
        billing,
      );

      await _tapPay(tester);

      expect(billing.purchaseRequests.single.productId, 'niscala_pro');
      expect(billing.purchaseRequests.single.basePlanId, 'yearly');
      expect(
        billing.purchaseRequests.single.obfuscatedAccountId,
        'obfuscated-o9',
      );
    });

    testWidgets('checks availability before it starts the purchase', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);

      await _tapPay(tester);

      expect(billing.availabilityChecks, 1);
      expect(billing.purchaseCalls, 1);
    });

    testWidgets('shows no sheet while the Google Play sheet has the outcome', (
      tester,
    ) async {
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, FakePlayBilling());

      await _tapPay(tester);

      _expectNoSheet();
      expect(subscriptions.verifyCalls, 0);
      expect(subscriptions.createOrderCalls, 0);
    });

    testWidgets('does not create another order', (tester) async {
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, FakePlayBilling());

      await _tapPay(tester);

      expect(subscriptions.createOrderCalls, 0);
    });

    testWidgets('two quick taps start one purchase', (tester) async {
      final billing = FakePlayBilling()..purchaseGate = Completer<void>();
      await _open(tester, _withOpenOrder(), billing);

      await tester.tap(find.text(_pay));
      await tester.tap(find.text(_pay));
      billing.purchaseGate!.complete();
      await tester.pumpAndSettle();

      expect(billing.purchaseCalls, 1);
    });

    testWidgets('a tap while the purchase starts is ignored', (tester) async {
      final billing = FakePlayBilling()..purchaseGate = Completer<void>();
      await _open(tester, _withOpenOrder(), billing);

      await tester.tap(find.text(_pay));
      await tester.pump();
      await tester.tap(find.text(_pay), warnIfMissed: false);
      await tester.pump();
      billing.purchaseGate!.complete();
      await tester.pumpAndSettle();

      expect(billing.purchaseCalls, 1);
    });
  });

  group('starting the purchase', () {
    testWidgets('says Google Play is unavailable and never purchases', (
      tester,
    ) async {
      final billing = FakePlayBilling()..available = false;
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);

      await _tapPay(tester);

      _expectError(_unavailable);
      expect(billing.purchaseCalls, 0);
      expect(subscriptions.verifyCalls, 0);
    });

    testWidgets('Tutup closes the unavailable message and keeps Bayar', (
      tester,
    ) async {
      final billing = FakePlayBilling()..available = false;
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);

      await _tapInSheet(tester, 'Tutup');

      _expectNoSheet();
      expect(find.text(_pay), findsOneWidget);
      expect(billing.purchaseCalls, 0);
    });

    testWidgets('shows the message of a PlayBillingException', (tester) async {
      final billing = FakePlayBilling()
        ..purchaseFailure = const PlayBillingException(
          'Produk tidak ditemukan di Google Play.',
        );
      await _open(tester, _withOpenOrder(), billing);

      await _tapPay(tester);

      _expectError('Produk tidak ditemukan di Google Play.');
      expect(billing.purchaseCalls, 1);
    });

    testWidgets('shows the message for an unknown product', (tester) async {
      final billing = FakePlayBilling()
        ..purchaseFailure = const PlayBillingException(
          'Paket tidak dikenal oleh Google Play.',
        );
      await _open(tester, _withOpenOrder(), billing);

      await _tapPay(tester);

      _expectError('Paket tidak dikenal oleh Google Play.');
    });

    testWidgets('Coba lagi starts the purchase again', (tester) async {
      final billing = FakePlayBilling()
        ..purchaseFailures.add(const PlayBillingException('Gagal membuka.'));
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      _expectError('Gagal membuka.');

      await _tapInSheet(tester, 'Coba lagi');

      expect(billing.purchaseCalls, 2);
      expect(
        billing.purchaseRequests.last.obfuscatedAccountId,
        'obfuscated-o1',
      );
      expect(billing.purchaseRequests.last.productId, 'niscala_basic');
      _expectNoSheet();
      expect(subscriptions.createOrderCalls, 0);
    });

    testWidgets('Coba lagi shows the failure again when it repeats', (
      tester,
    ) async {
      final billing = FakePlayBilling()
        ..purchaseFailure = const PlayBillingException('Gagal membuka.');
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);

      await _tapInSheet(tester, 'Coba lagi');

      _expectError('Gagal membuka.');
      expect(billing.purchaseCalls, 2);
    });
  });

  group('the order sheet', () {
    testWidgets('continues into the purchase of the new order', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions, billing);
      await _openOrderSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(orderSheet(), findsNothing);
      expect(subscriptions.createOrderCalls, 1);
      expect(billing.purchaseRequests, hasLength(1));
      expect(billing.purchaseRequests.single.productId, 'niscala_basic');
      expect(billing.purchaseRequests.single.basePlanId, 'monthly');
      expect(
        billing.purchaseRequests.single.obfuscatedAccountId,
        'obfuscated-new-1',
      );
    });

    testWidgets('continues into the yearly Pro purchase', (tester) async {
      final billing = FakePlayBilling();
      await _open(tester, FakeSubscriptionRepository(), billing);
      await _openOrderSheet(tester, 'Pilih Pro', yearly: true);

      await _confirmOrder(tester);

      expect(billing.purchaseRequests.single.productId, 'niscala_pro');
      expect(billing.purchaseRequests.single.basePlanId, 'yearly');
      expect(
        billing.purchaseRequests.single.obfuscatedAccountId,
        'obfuscated-new-1',
      );
    });

    testWidgets('does not start a purchase when the order fails', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = FakeSubscriptionRepository()
        ..createOrderScript.always = const ApiFailure(
          code: 'SUBSCRIPTION_NOT_AN_UPGRADE',
        );
      await _open(tester, subscriptions, billing);
      await _openOrderSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      expect(billing.availabilityChecks, 0);
      expect(billing.purchaseCalls, 0);
      expect(orderSheet(), findsOneWidget);
    });

    testWidgets('two quick taps create one order and start one purchase', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions, billing);
      await _openOrderSheet(tester, 'Pilih Basic');
      await tester.ensureVisible(inSheet(find.text(_confirm)));
      await tester.pump();

      await tester.tap(inSheet(find.text(_confirm)));
      await tester.tap(inSheet(find.text(_confirm)), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(subscriptions.createOrderCalls, 1);
      expect(billing.purchaseCalls, 1);
    });

    testWidgets('says Google Play is unavailable after the order exists', (
      tester,
    ) async {
      final billing = FakePlayBilling()..available = false;
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions, billing);
      await _openOrderSheet(tester, 'Pilih Basic');

      await _confirmOrder(tester);

      _expectError(_unavailable);
      expect(billing.purchaseCalls, 0);
      await _tapInSheet(tester, 'Tutup');
      expect(
        find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
      expect(find.text(_pay), findsOneWidget);
    });

    testWidgets('pays a monthly Basic order end to end', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions, billing);
      await _openOrderSheet(tester, 'Pilih Basic');
      await _confirmOrder(tester);

      await _deliver(tester, billing, _purchased());

      expect(subscriptions.verifications, [
        (orderId: 'new-1', purchaseToken: 'token-1'),
      ]);
      _expectSuccess('Basic');
      await _tapInSheet(tester, 'Selesai');
      _expectNoSheet();
      expect(find.text('Status: Aktif'), findsOneWidget);
      expect(find.text('Periode: Bulanan'), findsOneWidget);
    });

    testWidgets('pays a yearly Pro order end to end', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions, billing);
      await _openOrderSheet(tester, 'Pilih Pro', yearly: true);
      await _confirmOrder(tester);

      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.purchased, productId: 'niscala_pro'),
      );

      _expectSuccess('Pro');
      await _tapInSheet(tester, 'Selesai');
      expect(find.text('Periode: Tahunan'), findsOneWidget);
      expect(find.text('Paket Pro'), findsAtLeastNWidgets(1));
    });
  });

  group('a purchase that went through', () {
    for (final status in [
      PlayPurchaseStatus.purchased,
      PlayPurchaseStatus.pending,
    ]) {
      testWidgets('a ${status.name} purchase is verified with its token', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _tapPay(tester);

        await _deliver(tester, billing, _playPurchase(status, token: 'tok-7'));

        expect(subscriptions.verifications, [
          (orderId: 'o1', purchaseToken: 'tok-7'),
        ]);
      });
    }

    testWidgets('shows a busy sheet while the backend verifies', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.gate = Completer<void>();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      billing.emit(_purchased());
      await _frames(tester);

      _expectBusy(tester);
      expect(subscriptions.verifyCalls, 1);
    });

    testWidgets('the busy sheet cannot be dismissed', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.gate = Completer<void>();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      billing.emit(_purchased());
      await _frames(tester);

      await tester.tapAt(const Offset(4, 4));
      await _frames(tester);
      expect(_sheet(), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _frames(tester);
      expect(_sheet(), findsOneWidget);
      _expectBusy(tester);
    });

    testWidgets('the busy sheet gives way to the outcome', (tester) async {
      final billing = FakePlayBilling();
      final gate = Completer<void>();
      final subscriptions = _withOpenOrder()..verifyScript.gate = gate;
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      billing.emit(_purchased());
      await _frames(tester);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Memverifikasi pembayaran'), findsNothing);
      _expectSuccess('Basic');
    });

    testWidgets('ignores events of other products while the owner pays', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(
        tester,
        billing,
        _playPurchase(
          PlayPurchaseStatus.purchased,
          productId: 'niscala_pro',
          token: 'other',
        ),
      );

      expect(subscriptions.verifyCalls, 0);
      _expectNoSheet();

      await _deliver(tester, billing, _purchased());
      expect(subscriptions.verifications, [
        (orderId: 'o1', purchaseToken: 'token-1'),
      ]);
    });
  });

  group('a verified purchase that succeeded', () {
    testWidgets('shows the success sheet with the plan name', (tester) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      _expectSuccess('Basic');
      expect(inSheet(find.text('Tutup')), findsNothing);
    });

    testWidgets('names a Pro order Pro', (tester) async {
      final billing = FakePlayBilling();
      await _open(
        tester,
        _withOpenOrder(
          order: makeSubscriptionOrder(planCode: PaidPlanCode.pro),
        ),
        billing,
      );
      await _tapPay(tester);

      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.purchased, productId: 'niscala_pro'),
      );

      _expectSuccess('Pro');
    });

    testWidgets('completes the purchase with Google Play', (tester) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased(token: 'tok-3'));

      expect(billing.completed, hasLength(1));
      expect(billing.completed.single.purchaseToken, 'tok-3');
      expect(billing.completed.single.productId, 'niscala_basic');
    });

    testWidgets('still succeeds when completing fails', (tester) async {
      final billing = FakePlayBilling()
        ..completeFailure = const PlayBillingException('Gagal menyelesaikan.');
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      expect(billing.completed, hasLength(1));
      _expectSuccess('Basic');
      expect(find.text('Gagal menyelesaikan.'), findsNothing);
    });

    testWidgets('reloads the subscription once', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      expect(subscriptions.subscriptionCalls, 1);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      expect(subscriptions.subscriptionCalls, 2);
      expect(
        subscriptions.calls.indexOf('verifyPurchase'),
        lessThan(subscriptions.calls.lastIndexOf('subscription')),
      );
    });

    testWidgets('Selesai closes the sheet on the updated screen', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Selesai');

      _expectNoSheet();
      expect(find.text('Status: Aktif'), findsOneWidget);
      expect(find.text('Paket Basic'), findsAtLeastNWidgets(1));
      expect(find.text('Aktif hingga 23 Des 2026'), findsOneWidget);
      expect(find.text(_pay), findsNothing);
      expect(find.textContaining('menunggu pembayaran'), findsNothing);
    });

    testWidgets('purchases nothing more and creates no order', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      expect(billing.purchaseCalls, 1);
      expect(subscriptions.createOrderCalls, 0);
      expect(subscriptions.verifyCalls, 1);
    });
  });

  group('a verified purchase that still awaits payment', () {
    for (final status in [
      PlayPurchaseStatus.purchased,
      PlayPurchaseStatus.pending,
    ]) {
      testWidgets('shows the pending sheet for a ${status.name} purchase', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder()
          ..verifyStatuses.add(OrderStatus.awaitingPayment);
        await _open(tester, subscriptions, billing);
        await _tapPay(tester);

        await _deliver(tester, billing, _playPurchase(status));

        _expectPending();
        expect(billing.completed, isEmpty);
      });
    }

    testWidgets('Tutup closes the sheet and keeps the open order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.add(OrderStatus.awaitingPayment);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Tutup');

      _expectNoSheet();
      expect(find.text(_pay), findsOneWidget);
      expect(find.text('Status: Gratis'), findsOneWidget);
    });

    testWidgets('Cek lagi verifies again with the same token', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.addAll([
          OrderStatus.awaitingPayment,
          OrderStatus.succeeded,
        ]);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased(token: 'tok-5'));

      await _tapInSheet(tester, 'Cek lagi');

      expect(subscriptions.verifications, [
        (orderId: 'o1', purchaseToken: 'tok-5'),
        (orderId: 'o1', purchaseToken: 'tok-5'),
      ]);
      _expectSuccess('Basic');
      expect(billing.completed.single.purchaseToken, 'tok-5');
      expect(billing.purchaseCalls, 1);
    });

    testWidgets('Cek lagi can be repeated while the payment is pending', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.addAll([
          OrderStatus.awaitingPayment,
          OrderStatus.awaitingPayment,
          OrderStatus.succeeded,
        ]);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Cek lagi');
      _expectPending();
      expect(subscriptions.verifyCalls, 2);

      await _tapInSheet(tester, 'Cek lagi');
      _expectSuccess('Basic');
      expect(subscriptions.verifyCalls, 3);
      expect(billing.completed, hasLength(1));
    });

    testWidgets('Cek lagi shows a failed outcome', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.addAll([
          OrderStatus.awaitingPayment,
          OrderStatus.failed,
        ]);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Cek lagi');

      _expectFailed();
      expect(billing.completed, isEmpty);
    });

    testWidgets('Cek lagi shows a failure of the verification', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.add(OrderStatus.awaitingPayment)
        ..verifyScript.queue.addAll([
          null,
          const ApiFailure(code: 'GOOGLE_PLAY_UNREACHABLE', statusCode: 503),
        ]);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Cek lagi');

      _expectError(messageOfCode('GOOGLE_PLAY_UNREACHABLE'));
    });
  });

  group('a verified purchase that failed or expired', () {
    testWidgets('a failed order shows the failed sheet', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.add(OrderStatus.failed);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      _expectFailed();
      expect(billing.completed, isEmpty);
    });

    testWidgets('an expired order shows the expired sheet', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.add(OrderStatus.expired);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      _expectExpired();
      expect(billing.completed, isEmpty);
    });

    for (final status in [OrderStatus.failed, OrderStatus.expired]) {
      testWidgets('Tutup closes the ${status.value} sheet', (tester) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder()..verifyStatuses.add(status);
        await _open(tester, subscriptions, billing);
        await _tapPay(tester);
        await _deliver(tester, billing, _purchased());

        await _tapInSheet(tester, 'Tutup');

        _expectNoSheet();
        expect(find.byType(BottomSheet), findsNothing);
        expect(subscriptions.createOrderCalls, 0);
      });

      testWidgets(
        'Bayar lagi after ${status.value} creates the same order again and '
        'starts the purchase',
        (tester) async {
          final billing = FakePlayBilling();
          final subscriptions = _withOpenOrder(
            order: makeSubscriptionOrder(
              planCode: PaidPlanCode.pro,
              billingPeriod: SubscriptionPeriod.yearly,
            ),
          )..verifyStatuses.add(status);
          await _open(tester, subscriptions, billing);
          await _tapPay(tester);
          await _deliver(
            tester,
            billing,
            _playPurchase(
              PlayPurchaseStatus.purchased,
              productId: 'niscala_pro',
            ),
          );

          await _tapInSheet(tester, 'Bayar lagi');

          expect(subscriptions.createdOrders, hasLength(1));
          expect(subscriptions.createdOrders.single.planCode, PaidPlanCode.pro);
          expect(
            subscriptions.createdOrders.single.billingPeriod,
            SubscriptionPeriod.yearly,
          );
          expect(billing.purchaseRequests, hasLength(2));
          expect(billing.purchaseRequests.last.productId, 'niscala_pro');
          expect(billing.purchaseRequests.last.basePlanId, 'yearly');
          expect(
            billing.purchaseRequests.last.obfuscatedAccountId,
            'obfuscated-new-1',
          );
          _expectNoSheet();
        },
      );
    }

    testWidgets('a retry after Bayar lagi verifies the new order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyStatuses.addAll([OrderStatus.failed, OrderStatus.succeeded]);
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());
      await _tapInSheet(tester, 'Bayar lagi');

      await _deliver(tester, billing, _purchased(token: 'token-2'));

      expect(subscriptions.verifications.last, (
        orderId: 'new-1',
        purchaseToken: 'token-2',
      ));
      _expectSuccess('Basic');
    });
  });

  group('a verification that fails', () {
    for (final code in [
      'GOOGLE_PLAY_UNREACHABLE',
      'SUBSCRIPTION_ORDER_CLOSED',
      'PURCHASE_TOKEN_IN_USE',
      'PURCHASE_TOKEN_INVALID',
      'PURCHASE_PRODUCT_MISMATCH',
      'NETWORK_ERROR',
      'INTERNAL_ERROR',
    ]) {
      testWidgets('shows the Indonesian message of $code', (tester) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder()
          ..verifyScript.always = ApiFailure(code: code, statusCode: 409);
        await _open(tester, subscriptions, billing);
        await _tapPay(tester);

        await _deliver(tester, billing, _purchased());

        _expectError(messageOfCode(code));
        expect(billing.completed, isEmpty);
      });
    }

    testWidgets('never shows the English message of the API', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.always = const ApiFailure(
          code: 'GOOGLE_PLAY_UNREACHABLE',
          statusCode: 503,
        );
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _purchased());

      expect(inSheet(find.textContaining('unreachable')), findsNothing);
      expect(
        inSheet(find.text(messageOfCode('GOOGLE_PLAY_UNREACHABLE'))),
        findsOneWidget,
      );
    });

    testWidgets('Coba lagi verifies again with the same token', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.queue.add(
          const ApiFailure(code: 'GOOGLE_PLAY_UNREACHABLE', statusCode: 503),
        );
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased(token: 'tok-8'));

      await _tapInSheet(tester, 'Coba lagi');

      expect(subscriptions.verifications, [
        (orderId: 'o1', purchaseToken: 'tok-8'),
        (orderId: 'o1', purchaseToken: 'tok-8'),
      ]);
      expect(billing.purchaseCalls, 1);
      _expectSuccess('Basic');
    });

    testWidgets('Coba lagi shows the failure again when it repeats', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.always = const ApiFailure(
          code: 'GOOGLE_PLAY_UNREACHABLE',
          statusCode: 503,
        );
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Coba lagi');

      _expectError(messageOfCode('GOOGLE_PLAY_UNREACHABLE'));
      expect(subscriptions.verifyCalls, 2);
    });

    testWidgets('Tutup closes the sheet and keeps the open order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.always = const ApiFailure(
          code: 'SUBSCRIPTION_ORDER_CLOSED',
          statusCode: 409,
        );
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      await _tapInSheet(tester, 'Tutup');

      _expectNoSheet();
      expect(find.text('Status: Gratis'), findsOneWidget);
    });
  });

  group('a purchase that did not go through', () {
    testWidgets('a failed purchase shows the failed sheet', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(tester, billing, _playPurchase(PlayPurchaseStatus.failed));

      _expectFailed();
      expect(subscriptions.verifyCalls, 0);
      expect(billing.completed, isEmpty);
    });

    testWidgets('Bayar lagi after a failed purchase creates a new order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(tester, billing, _playPurchase(PlayPurchaseStatus.failed));

      await _tapInSheet(tester, 'Bayar lagi');

      expect(subscriptions.createdOrders.single.planCode, PaidPlanCode.basic);
      expect(billing.purchaseCalls, 2);
    });

    testWidgets('a canceled purchase shows the canceled sheet', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);

      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.canceled),
      );

      _expectCanceled();
      expect(subscriptions.verifyCalls, 0);
      expect(subscriptions.createOrderCalls, 0);
      expect(billing.completed, isEmpty);
    });

    testWidgets('Tutup closes the canceled sheet and keeps Bayar', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);
      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.canceled),
      );

      await _tapInSheet(tester, 'Tutup');

      _expectNoSheet();
      expect(find.text(_pay), findsOneWidget);
      expect(
        find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });

    testWidgets('Bayar can pay again after a canceled purchase', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.canceled),
      );
      await _tapInSheet(tester, 'Tutup');

      await _tapPay(tester);
      await _deliver(tester, billing, _purchased());

      expect(billing.purchaseCalls, 2);
      expect(subscriptions.createOrderCalls, 0);
      _expectSuccess('Basic');
    });

    testWidgets('the canceled sheet has no way to pay again', (tester) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);
      await _tapPay(tester);
      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.canceled),
      );

      expect(inSheet(find.text('Bayar lagi')), findsNothing);
      expect(inSheet(find.text('Coba lagi')), findsNothing);
    });
  });

  group('purchases that arrive without a tap', () {
    for (final status in [
      PlayPurchaseStatus.pending,
      PlayPurchaseStatus.purchased,
    ]) {
      testWidgets('verifies a ${status.name} purchase of the open order', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder()
          ..verifyStatuses.add(OrderStatus.awaitingPayment);
        await _open(tester, subscriptions, billing);

        await _deliver(tester, billing, _playPurchase(status, token: 'tok-2'));

        expect(subscriptions.verifications, [
          (orderId: 'o1', purchaseToken: 'tok-2'),
        ]);
        expect(billing.purchaseCalls, 0);
        _expectPending();
      });
    }

    testWidgets('shows the success sheet when the order succeeded', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);

      await _deliver(tester, billing, _purchased());

      _expectSuccess('Basic');
      expect(billing.completed, hasLength(1));
      expect(subscriptions.subscriptionCalls, 2);
    });

    testWidgets('shows a busy sheet while it verifies', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder()
        ..verifyScript.gate = Completer<void>();
      await _open(tester, subscriptions, billing);

      billing.emit(_purchased());
      await _frames(tester);

      _expectBusy(tester);
    });

    testWidgets('ignores a purchase when there is no open order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = FakeSubscriptionRepository();
      await _open(tester, subscriptions, billing);

      await _deliver(tester, billing, _purchased());

      expect(subscriptions.verifyCalls, 0);
      expect(billing.purchaseCalls, 0);
      expect(billing.completed, isEmpty);
      _expectNoSheet();
    });

    testWidgets('ignores a purchase of another product than the open order', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);

      await _deliver(
        tester,
        billing,
        _playPurchase(
          PlayPurchaseStatus.purchased,
          productId: 'niscala_pro',
          token: 'other',
        ),
      );

      expect(subscriptions.verifyCalls, 0);
      expect(billing.completed, isEmpty);
      _expectNoSheet();
    });

    testWidgets('ignores a purchase of an unknown product', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);

      await _deliver(
        tester,
        billing,
        _playPurchase(PlayPurchaseStatus.pending, productId: 'something_else'),
      );

      expect(subscriptions.verifyCalls, 0);
      _expectNoSheet();
    });

    testWidgets('listens to purchases while the screen is open', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      await _open(tester, _withOpenOrder(), billing);

      expect(billing.hasListener, isTrue);
    });
  });

  group('the result sheets', () {
    for (final entry in _states.entries.where((e) => e.key != 'busy')) {
      testWidgets('${entry.key} announces its title as a heading', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, entry.key, subscriptions, billing);

        expectHeading(tester, entry.value.title);
      });

      testWidgets('${entry.key} has buttons of at least 48 dp', (tester) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, entry.key, subscriptions, billing);

        for (final button in entry.value.buttons) {
          _expectButtonSize(tester, button);
        }
      });

      testWidgets('${entry.key} is a modal bottom sheet over the screen', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, entry.key, subscriptions, billing);

        expect(_sheet(), findsOneWidget);
        expect(find.byType(ModalBarrier), findsWidgets);
      });
    }

    testWidgets('busy announces its title as a heading', (tester) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _reach(tester, 'busy', subscriptions, billing);

      expectHeading(tester, 'Memverifikasi pembayaran');
    });

    for (final state in _states.keys.where((s) => s != 'busy')) {
      testWidgets('$state shows no English term or null', (tester) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, state, subscriptions, billing);

        for (final term in [
          'Payment',
          'Purchase',
          'Order',
          'Subscription',
          'Failed',
          'Canceled',
          'Error',
          'null',
        ]) {
          expect(inSheet(find.textContaining(term)), findsNothing);
        }
      });
    }
  });

  group('the system Back press', () {
    Future<void> back(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    for (final state in ['failed', 'expired']) {
      testWidgets('closes the $state sheet like its Tutup button', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, state, subscriptions, billing);

        await back(tester);

        _expectNoSheet();
        expect(find.text('Langganan'), findsOneWidget);
      });
    }

    for (final state in ['pending', 'canceled', 'error']) {
      testWidgets('closes the $state sheet like its Tutup button', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, state, subscriptions, billing);

        await back(tester);

        _expectNoSheet();
        expect(find.text('Langganan'), findsOneWidget);
        expect(find.text(_pay), findsOneWidget);
      });

      testWidgets('after the $state sheet, Bayar starts a fresh purchase', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, state, subscriptions, billing);
        await back(tester);
        expect(billing.purchaseCalls, 1);

        await _tapPay(tester);

        expect(billing.purchaseCalls, 2);
        expect(billing.availabilityChecks, 2);
      });

      testWidgets('after the $state sheet, a later purchase opens a sheet', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, state, subscriptions, billing);
        await back(tester);
        subscriptions.verifyScript.always = null;
        subscriptions.verifyStatuses.clear();
        final before = subscriptions.verifyCalls;

        await _deliver(tester, billing, _purchased(token: 'token-2'));

        expect(subscriptions.verifyCalls, before + 1);
        expect(subscriptions.verifications.last, (
          orderId: 'o1',
          purchaseToken: 'token-2',
        ));
        _expectSuccess('Basic');
      });
    }

    testWidgets('closes the success sheet like its Selesai button', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _reach(tester, 'success', subscriptions, billing);

      await back(tester);

      _expectNoSheet();
      expect(find.text('Langganan'), findsOneWidget);
      expect(find.text('Status: Aktif'), findsOneWidget);
    });

    testWidgets('after the success sheet, a new order can be paid', (
      tester,
    ) async {
      final billing = FakePlayBilling();
      final subscriptions = _withOpenOrder();
      await _open(tester, subscriptions, billing);
      await _reach(tester, 'success', subscriptions, billing);
      await back(tester);

      await _openOrderSheet(tester, 'Pilih Pro');
      await _confirmOrder(tester);
      await _deliver(
        tester,
        billing,
        _playPurchase(
          PlayPurchaseStatus.purchased,
          productId: 'niscala_pro',
          token: 'token-9',
        ),
      );

      expect(billing.purchaseCalls, 2);
      expect(subscriptions.verifications.last, (
        orderId: 'new-1',
        purchaseToken: 'token-9',
      ));
      _expectSuccess('Pro');
    });

    testWidgets('does nothing while the busy sheet is open', (tester) async {
      final billing = FakePlayBilling();
      final gate = Completer<void>();
      final subscriptions = _withOpenOrder()..verifyScript.gate = gate;
      await _open(tester, subscriptions, billing);
      await _tapPay(tester);
      billing.emit(_purchased());
      await _frames(tester);

      await tester.binding.handlePopRoute();
      await _frames(tester);

      _expectBusy(tester);
      expect(find.text('Langganan'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      _expectSuccess('Basic');
      expect(subscriptions.verifyCalls, 1);
    });
  });

  group('the sheet titles', () {
    for (final entry in _states.entries) {
      testWidgets('announce the ${entry.key} title as a live region', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, entry.key, subscriptions, billing);

        final handle = tester.ensureSemantics();
        try {
          expect(
            tester.getSemantics(inSheet(find.text(entry.value.title))),
            isSemantics(isHeader: true, isLiveRegion: true),
          );
        } finally {
          handle.dispose();
        }
      });
    }
  });

  group('accessibility', () {
    for (final entry in _states.entries) {
      testWidgets('meets the guidelines in the ${entry.key} state', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing);
        await _reach(tester, entry.key, subscriptions, billing);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text in the ${entry.key} state', (
        tester,
      ) async {
        final billing = FakePlayBilling();
        final subscriptions = _withOpenOrder();
        await _open(tester, subscriptions, billing, largeText: true);
        await _reach(tester, entry.key, subscriptions, billing);

        expect(tester.takeException(), isNull);
        expect(_sheet(), findsOneWidget);
        expect(inSheet(find.text(entry.value.title)), findsOneWidget);
        for (final button in entry.value.buttons) {
          await tester.ensureVisible(inSheet(find.text(button)));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('the screen with an open order meets the guidelines', (
      tester,
    ) async {
      await _open(tester, _withOpenOrder(), FakePlayBilling());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('the screen with an open order fits at large text', (
      tester,
    ) async {
      await _open(tester, _withOpenOrder(), FakePlayBilling(), largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text(_pay), findsOneWidget);
    });

    testWidgets('Bayar has a spoken label that starts with its text', (
      tester,
    ) async {
      await _open(tester, _withOpenOrder(), FakePlayBilling());

      expect(semanticsLabelOf(tester, _pay), startsWith(_pay));
    });
  });
}
