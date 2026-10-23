import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

/// The text and colour token of one payment status badge. The label is what
/// the user reads; the colours only reinforce it.
typedef PaymentBadgeStyle = ({
  String label,
  BadgeColors Function(NiscalaTokens) colors,
});

/// The one table of payment status labels. Every rent bill screen reads its
/// badges from this map, so a status has the same text everywhere.
final paymentStatusStyles = <PaymentStatus, PaymentBadgeStyle>{
  PaymentStatus.unpaid: (label: 'Belum Bayar', colors: (t) => t.paymentUnpaid),
  PaymentStatus.awaitingVerification: (
    label: 'Menunggu Verifikasi',
    colors: (t) => t.paymentAwaitingVerification,
  ),
  PaymentStatus.paid: (label: 'Lunas', colors: (t) => t.paymentPaid),
  PaymentStatus.rejected: (label: 'Ditolak', colors: (t) => t.paymentRejected),
};

/// A payment status as a text badge.
class PaymentBadge extends StatelessWidget {
  PaymentBadge(this.status, {super.key})
    : _style = paymentStatusStyles[status]!;

  final PaymentStatus status;
  final PaymentBadgeStyle _style;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: _style.label,
      colors: _style.colors(NiscalaTokens.of(context)),
    );
  }
}
