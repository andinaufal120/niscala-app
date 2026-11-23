import 'package:flutter/material.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/subscription/subscription_labels.dart';
import 'package:niscala_api/api.dart';

/// The plan, status and renewal of the subscription, with its scheduled
/// downgrade and open order. [error] is a failed cancellation.
class CurrentStatus extends StatelessWidget {
  const CurrentStatus({
    super.key,
    required this.subscription,
    required this.cancelling,
    required this.onCancelDowngrade,
    this.error,
  });

  final Subscription subscription;
  final bool cancelling;
  final VoidCallback onCancelDowngrade;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = subscription.status == SubscriptionStatus.active;
    final end = subscription.endDate;
    final period = subscription.billingPeriod;
    final downgrade = subscription.scheduledDowngrade;
    final order = subscription.openOrder;
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Paket ${planName(subscription.planCode.value)}',
          style: theme.textTheme.titleMedium,
        ),
        Text('Status: ${statusName(subscription.status)}'),
        if (active && end != null) Text('Aktif hingga ${formatDate(end)}'),
        if (active && period != null) Text('Periode: ${periodName(period)}'),
        if (active)
          Text(
            'Perpanjangan otomatis: ${subscription.autoRenew ? 'Aktif' : 'Tidak aktif'}',
          ),
        Text('Properti terpakai: ${subscription.propertyCount}'),
        if (downgrade != null) ...[
          formGap,
          Text(
            'Turun ke paket ${planName(downgrade.planCode.value)} mulai '
            '${formatDate(downgrade.effectiveDate)}',
          ),
          const SizedBox(height: NiscalaSpacing.s),
          OutlinedButton(
            onPressed: cancelling ? null : onCancelDowngrade,
            child: const Text('Batalkan penurunan paket'),
          ),
        ],
        if (order != null && order.status == OrderStatus.awaitingPayment) ...[
          formGap,
          Text(
            'Pesanan paket ${planName(order.planCode.value)} '
            '(${periodName(order.billingPeriod)}) menunggu pembayaran.',
          ),
        ],
        if (error != null) ...[formGap, FormMessage(error)],
      ],
    );
  }
}

/// One plan with its limits, AI features and the price of [period]. A current
/// plan is marked `Paket Anda`; [action] is the button of the plan, if any.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.period,
    required this.isCurrent,
    this.action,
  });

  final SubscriptionPlan plan;
  final SubscriptionPeriod period;
  final bool isCurrent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = this.action;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrent ? NiscalaColors.primary : NiscalaColors.divider,
          width: isCurrent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(NiscalaRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NiscalaSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    planName(plan.code.value),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isCurrent)
                  Text(
                    'Paket Anda',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: NiscalaColors.primary,
                    ),
                  ),
              ],
            ),
            Text(
              planPriceText(plan, period),
              style: theme.textTheme.titleSmall,
            ),
            Text(propertyLimitText(plan)),
            Text(roomLimitText(plan)),
            if (plan.aiEnabled) ...[
              const Text('Klasifikasi keluhan AI'),
              const Text('Ringkasan pola pembayaran AI'),
            ] else
              const Text('Tanpa fitur AI'),
            if (action != null) ...[formGap, action],
          ],
        ),
      ),
    );
  }
}
