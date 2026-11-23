import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/billing/play_billing.dart';
import 'package:niscala/features/subscription/data/subscription_repository.dart';
import 'package:niscala_api/api.dart';

const _unavailableMessage = 'Google Play tidak tersedia di perangkat ini.';

/// Where the payment of an order stands. The phases from [PaymentPhase.verifying]
/// on are shown in the payment sheet.
enum PaymentPhase {
  idle,
  paying,
  verifying,
  pending,
  succeeded,
  failed,
  expired,
  canceled,
  error,
}

/// The step that "Coba lagi" repeats after an [PaymentPhase.error].
enum PaymentStep { createOrder, purchase, verify }

class PaymentState {
  const PaymentState({
    this.phase = PaymentPhase.idle,
    this.order,
    this.purchase,
    this.message,
    this.retry,
  });

  final PaymentPhase phase;

  /// The order being paid, or the last one paid.
  final SubscriptionOrder? order;

  /// The Google Play purchase that the backend verifies.
  final PlayPurchase? purchase;

  /// The Indonesian message of an error.
  final String? message;

  final PaymentStep? retry;

  bool get showsSheet =>
      phase != PaymentPhase.idle && phase != PaymentPhase.paying;
}

/// Pays the Owner's subscription orders through Google Play and verifies each
/// purchase with the backend. It listens to Google Play while it is alive.
class SubscriptionPaymentController extends Notifier<PaymentState> {
  @override
  PaymentState build() {
    final subscription = ref
        .read(playBillingProvider)
        .purchases
        .listen(_onPurchase);
    ref.onDispose(subscription.cancel);
    return const PaymentState();
  }

  /// Starts the purchase of [order] in Google Play.
  void pay(SubscriptionOrder order) {
    if (_inFlight) return;
    _start(order);
  }

  /// Creates a new order for the plan and period of the last order, then starts
  /// its purchase.
  void payAgain() {
    if (_inFlight) return;
    _createAndPay(state.order!);
  }

  /// Verifies the purchase again with the same token.
  void verify() => _verify(state.order!, state.purchase!);

  /// Repeats the step that failed.
  void retry() {
    final order = state.order!;
    switch (state.retry!) {
      case PaymentStep.createOrder:
        _createAndPay(order);
      case PaymentStep.purchase:
        _start(order);
      case PaymentStep.verify:
        verify();
    }
  }

  /// Closes the sheet of the outcome.
  void dismiss() => state = const PaymentState();

  bool get _inFlight =>
      state.phase == PaymentPhase.paying ||
      state.phase == PaymentPhase.verifying;

  Future<void> _start(SubscriptionOrder order) async {
    state = PaymentState(phase: PaymentPhase.paying, order: order);
    final billing = ref.read(playBillingProvider);
    try {
      if (!await billing.isAvailable()) {
        _fail(
          order: order,
          message: _unavailableMessage,
          step: PaymentStep.purchase,
        );
        return;
      }
      await billing.purchase(
        productId: order.googlePlayProductId,
        basePlanId: order.googlePlayBasePlanId,
        obfuscatedAccountId: order.obfuscatedAccountId,
      );
    } on PlayBillingException catch (error) {
      _fail(order: order, message: error.message, step: PaymentStep.purchase);
      return;
    }
    // The outcome arrives on the purchase stream, which may be faster than this.
    if (state.phase == PaymentPhase.paying) state = PaymentState(order: order);
  }

  Future<void> _createAndPay(SubscriptionOrder previous) async {
    state = PaymentState(phase: PaymentPhase.paying, order: previous);
    try {
      final order = await ref
          .read(subscriptionRepositoryProvider)
          .createOrder(
            planCode: previous.planCode,
            billingPeriod: previous.billingPeriod,
          );
      ref.invalidate(subscriptionProvider);
      await _start(order);
    } on ApiFailure catch (failure) {
      _fail(
        order: previous,
        message: errorMessageFor(failure),
        step: PaymentStep.createOrder,
      );
    }
  }

  void _onPurchase(PlayPurchase purchase) {
    final order = _orderOf(purchase.productId);
    if (order == null) return;
    switch (purchase.status) {
      case PlayPurchaseStatus.pending || PlayPurchaseStatus.purchased:
        _verify(order, purchase);
      case PlayPurchaseStatus.failed:
        state = PaymentState(phase: PaymentPhase.failed, order: order);
      case PlayPurchaseStatus.canceled:
        state = PaymentState(phase: PaymentPhase.canceled, order: order);
    }
  }

  Future<void> _verify(SubscriptionOrder order, PlayPurchase purchase) async {
    state = PaymentState(
      phase: PaymentPhase.verifying,
      order: order,
      purchase: purchase,
    );
    try {
      final verified = await ref
          .read(subscriptionRepositoryProvider)
          .verifyPurchase(
            orderId: order.id,
            purchaseToken: purchase.purchaseToken,
          );
      ref.invalidate(subscriptionProvider);
      if (verified.status == OrderStatus.succeeded) {
        await _complete(purchase);
      }
      state = PaymentState(
        phase: _outcomeOf(verified.status),
        order: order,
        purchase: purchase,
      );
    } on ApiFailure catch (failure) {
      _fail(
        order: order,
        message: errorMessageFor(failure),
        step: PaymentStep.verify,
        purchase: purchase,
      );
    }
  }

  /// Acknowledges a verified purchase. A failure here leaves the verified
  /// outcome as it is.
  Future<void> _complete(PlayPurchase purchase) async {
    try {
      await ref.read(playBillingProvider).complete(purchase);
    } on PlayBillingException {
      // The backend has verified the purchase, so the outcome stands.
    }
  }

  void _fail({
    required SubscriptionOrder order,
    required String message,
    required PaymentStep step,
    PlayPurchase? purchase,
  }) {
    state = PaymentState(
      phase: PaymentPhase.error,
      order: order,
      purchase: purchase,
      message: message,
      retry: step,
    );
  }

  /// The order that a purchase of [productId] belongs to: the order being paid,
  /// or else the open order of the subscription.
  SubscriptionOrder? _orderOf(String productId) {
    for (final order in [state.order, _openOrder()]) {
      if (order != null && order.googlePlayProductId == productId) return order;
    }
    return null;
  }

  SubscriptionOrder? _openOrder() {
    final order = ref.read(subscriptionProvider).value?.openOrder;
    return order?.status == OrderStatus.awaitingPayment ? order : null;
  }
}

PaymentPhase _outcomeOf(OrderStatus status) {
  if (status == OrderStatus.succeeded) return PaymentPhase.succeeded;
  if (status == OrderStatus.failed) return PaymentPhase.failed;
  if (status == OrderStatus.expired) return PaymentPhase.expired;
  return PaymentPhase.pending;
}

/// The payment of the Owner's orders. It is alive while the subscription screen
/// is open.
final subscriptionPaymentProvider =
    NotifierProvider.autoDispose<SubscriptionPaymentController, PaymentState>(
      SubscriptionPaymentController.new,
    );
