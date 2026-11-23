import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/billing/play_billing.dart';

import '../../helpers/fakes.dart';

void main() {
  group('PlayPurchaseStatus', () {
    test('has pending, purchased, failed and canceled', () {
      expect(PlayPurchaseStatus.values, hasLength(4));
      expect(
        PlayPurchaseStatus.values.map((s) => s.name),
        unorderedEquals(['pending', 'purchased', 'failed', 'canceled']),
      );
    });
  });

  group('PlayPurchase', () {
    test('keeps the product, the token and the status', () {
      const purchase = PlayPurchase(
        productId: 'niscala_basic',
        purchaseToken: 'token-1',
        status: PlayPurchaseStatus.purchased,
      );

      expect(purchase.productId, 'niscala_basic');
      expect(purchase.purchaseToken, 'token-1');
      expect(purchase.status, PlayPurchaseStatus.purchased);
    });
  });

  group('PlayBillingException', () {
    test('is an Exception that carries its message', () {
      const exception = PlayBillingException('Produk tidak ditemukan.');

      expect(exception, isA<Exception>());
      expect(exception.message, 'Produk tidak ditemukan.');
    });
  });

  group('playBillingProvider', () {
    test('can be replaced by a fake', () {
      final fake = FakePlayBilling();
      final container = ProviderContainer(
        overrides: [playBillingProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      expect(container.read(playBillingProvider), same(fake));
    });
  });
}
