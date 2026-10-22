import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

const _labels = {
  PaymentStatus.unpaid: 'Belum Bayar',
  PaymentStatus.awaitingVerification: 'Menunggu Verifikasi',
  PaymentStatus.paid: 'Lunas',
  PaymentStatus.rejected: 'Ditolak',
};

BadgeColors _colorsOf(PaymentStatus status, NiscalaTokens t) => {
  PaymentStatus.unpaid: t.paymentUnpaid,
  PaymentStatus.awaitingVerification: t.paymentAwaitingVerification,
  PaymentStatus.paid: t.paymentPaid,
  PaymentStatus.rejected: t.paymentRejected,
}[status]!;

void main() {
  group('paymentStatusStyles', () {
    test('has an entry for every payment status', () {
      expect(paymentStatusStyles.keys, unorderedEquals(PaymentStatus.values));
    });

    for (final entry in _labels.entries) {
      test('labels ${entry.key.value} as ${entry.value}', () {
        expect(paymentStatusStyles[entry.key]!.label, entry.value);
      });

      test('colours ${entry.key.value} with its payment token', () {
        const tokens = NiscalaTokens();

        expect(
          paymentStatusStyles[entry.key]!.colors(tokens),
          _colorsOf(entry.key, tokens),
        );
      });
    }

    test('gives every status a different label', () {
      final labels = paymentStatusStyles.values.map((s) => s.label);
      expect(labels.toSet(), hasLength(PaymentStatus.values.length));
    });
  });

  group('PaymentBadge', () {
    for (final entry in _labels.entries) {
      testWidgets('shows ${entry.key.value} as a text badge', (tester) async {
        await tester.pumpWidget(themedApp(PaymentBadge(entry.key)));

        expect(
          find.descendant(
            of: find.byType(StatusBadge),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
      });

      testWidgets('announces ${entry.key.value} by its label', (tester) async {
        await tester.pumpWidget(themedApp(PaymentBadge(entry.key)));

        final handle = tester.ensureSemantics();
        try {
          expect(
            tester.getSemantics(find.byType(StatusBadge)),
            isSemantics(label: entry.value),
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('uses the colours of ${entry.key.value}', (tester) async {
        await tester.pumpWidget(themedApp(PaymentBadge(entry.key)));

        final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
        expect(badge.colors, _colorsOf(entry.key, const NiscalaTokens()));
      });
    }

    testWidgets('fits at large text size', (tester) async {
      await pumpAtLargeText(
        tester,
        themedApp(
          Column(
            children: [
              for (final status in PaymentStatus.values) PaymentBadge(status),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
