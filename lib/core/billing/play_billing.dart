import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// How a Google Play purchase stands, as the app sees it.
enum PlayPurchaseStatus { pending, purchased, failed, canceled }

/// A purchase event of Google Play. [purchaseToken] is what the backend verifies.
class PlayPurchase {
  const PlayPurchase({
    required this.productId,
    required this.purchaseToken,
    required this.status,
  });

  final String productId;
  final String purchaseToken;
  final PlayPurchaseStatus status;
}

/// Google Play could not start or finish a purchase. [message] is Indonesian
/// and can be shown to the user as it is.
class PlayBillingException implements Exception {
  const PlayBillingException(this.message);

  final String message;
}

/// Google Play Billing: whether it is usable, buying a subscription, and the
/// purchase events of the device.
abstract interface class PlayBilling {
  /// Whether Google Play Billing is ready on this device.
  Future<bool> isAvailable();

  /// Emits each purchase event while someone listens.
  Stream<PlayPurchase> get purchases;

  /// Opens the Google Play sheet that buys the base plan [basePlanId] of the
  /// subscription [productId]. [obfuscatedAccountId] ties the purchase to the
  /// order. The outcome arrives on [purchases]. Throws a [PlayBillingException]
  /// when the plan cannot be bought.
  Future<void> purchase({
    required String productId,
    required String basePlanId,
    required String obfuscatedAccountId,
  });

  /// Marks [purchase] as delivered, once the backend has verified it.
  Future<void> complete(PlayPurchase purchase);
}

final playBillingProvider = Provider<PlayBilling>((ref) => InAppPlayBilling());

/// The message the plugin gives for a purchase the user cancelled.
const _userCanceledMessage = 'BillingResponse.userCanceled';

/// [PlayBilling] backed by the in_app_purchase plugin. The plugin is only
/// touched when a member is first used.
class InAppPlayBilling implements PlayBilling {
  /// The plugin's purchase details by token, so that [complete] can finish them.
  final _details = <String, PurchaseDetails>{};

  @override
  Future<bool> isAvailable() => InAppPurchase.instance.isAvailable();

  @override
  Stream<PlayPurchase> get purchases => InAppPurchase.instance.purchaseStream
      .expand((batch) => batch)
      .map(_toPlayPurchase);

  @override
  Future<void> purchase({
    required String productId,
    required String basePlanId,
    required String obfuscatedAccountId,
  }) async {
    final offer = await _basePlanOffer(productId, basePlanId);
    final started = await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: offer,
        applicationUserName: obfuscatedAccountId,
        offerToken: offer.offerToken,
      ),
    );
    if (!started) {
      throw const PlayBillingException(
        'Google Play tidak dapat membuka layar pembayaran. Coba lagi.',
      );
    }
  }

  @override
  Future<void> complete(PlayPurchase purchase) async {
    final details = _details[purchase.purchaseToken];
    if (details == null || !details.pendingCompletePurchase) return;
    try {
      await InAppPurchase.instance.completePurchase(details);
    } on InAppPurchaseException catch (error) {
      throw PlayBillingException(
        error.message ?? 'Pembelian belum bisa diselesaikan.',
      );
    }
  }

  PlayPurchase _toPlayPurchase(PurchaseDetails details) {
    final token = details.verificationData.serverVerificationData;
    _details[token] = details;
    return PlayPurchase(
      productId: details.productID,
      purchaseToken: token,
      status: _statusOf(details),
    );
  }

  /// The Google Play offer of [basePlanId] for [productId]. The base plan
  /// without a discount is preferred over a discounted offer of the same base
  /// plan.
  Future<GooglePlayProductDetails> _basePlanOffer(
    String productId,
    String basePlanId,
  ) async {
    final response = await InAppPurchase.instance.queryProductDetails({
      productId,
    });
    final offers = response.productDetails
        .whereType<GooglePlayProductDetails>()
        .where((details) => _planOf(details)?.basePlanId == basePlanId)
        .toList();
    final offer =
        offers
            .where((details) => _planOf(details)?.offerId == null)
            .firstOrNull ??
        offers.firstOrNull;
    if (response.error != null || offer == null) {
      throw const PlayBillingException(
        'Paket ini belum tersedia di Google Play.',
      );
    }
    return offer;
  }
}

PlayPurchaseStatus _statusOf(PurchaseDetails details) =>
    switch (details.status) {
      PurchaseStatus.pending => PlayPurchaseStatus.pending,
      PurchaseStatus.purchased ||
      PurchaseStatus.restored => PlayPurchaseStatus.purchased,
      PurchaseStatus.canceled => PlayPurchaseStatus.canceled,
      PurchaseStatus.error =>
        details.error?.message == _userCanceledMessage
            ? PlayPurchaseStatus.canceled
            : PlayPurchaseStatus.failed,
    };

/// The base plan and offer id of a subscription offer, or null for a one-time
/// product.
({String basePlanId, String? offerId})? _planOf(
  GooglePlayProductDetails details,
) {
  final index = details.subscriptionIndex;
  if (index == null) return null;
  final offer = details.productDetails.subscriptionOfferDetails![index];
  return (basePlanId: offer.basePlanId, offerId: offer.offerId);
}
