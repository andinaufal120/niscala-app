import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/subscription/data/subscription_repository.dart';
import 'package:niscala/features/subscription/subscription_labels.dart';
import 'package:niscala_api/api.dart';

/// The summary of a plan order, shown as a bottom sheet. Confirming creates the
/// order only: the payment happens in Google Play.
class OrderSummarySheet extends ConsumerStatefulWidget {
  const OrderSummarySheet({
    super.key,
    required this.plan,
    required this.period,
  });

  final SubscriptionPlan plan;
  final SubscriptionPeriod period;

  @override
  ConsumerState<OrderSummarySheet> createState() => _OrderSummarySheetState();
}

class _OrderSummarySheetState extends ConsumerState<OrderSummarySheet> {
  var _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .createOrder(
            planCode: _paidPlanOf(widget.plan),
            billingPeriod: widget.period,
          );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    ref.invalidate(subscriptionProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;
    final period = widget.period;
    final error = _error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NiscalaSpacing.gutter,
        NiscalaSpacing.l,
        NiscalaSpacing.gutter,
        NiscalaSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Ringkasan pesanan',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: NiscalaSpacing.s),
            _SummaryRow(
              label: 'Paket',
              value: '${planName(plan.code.value)} · ${periodName(period)}',
            ),
            _SummaryRow(
              label: 'Batas properti',
              value: propertyLimitText(plan),
            ),
            _SummaryRow(label: 'Total', value: planPriceText(plan, period)),
            if (error != null) ...[formGap, FormMessage(error)],
            const SizedBox(height: NiscalaSpacing.s),
            BusyButton(
              label: 'Lanjut ke Google Play',
              busy: _busy,
              onPressed: _confirm,
            ),
            const SizedBox(height: NiscalaSpacing.s),
            OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The paid plan of a plan that can be bought, by its wire value.
PaidPlanCode _paidPlanOf(SubscriptionPlan plan) =>
    PaidPlanCode.values.firstWhere((code) => code.value == plan.code.value);

/// A label and its value on one line, read as one item.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NiscalaSpacing.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: NiscalaColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: NiscalaSpacing.m),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
