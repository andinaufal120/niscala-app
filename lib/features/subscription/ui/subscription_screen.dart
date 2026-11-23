import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/filter_chip_row.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/subscription/data/subscription_repository.dart';
import 'package:niscala/features/subscription/subscription_labels.dart';
import 'package:niscala/features/subscription/ui/order_summary_sheet.dart';
import 'package:niscala/features/subscription/ui/subscription_widgets.dart';
import 'package:niscala_api/api.dart';

const _subscriptionPath = '/akun/langganan';

const _googlePlayNote =
    'Pembayaran dan perpanjangan otomatis dikelola Google Play. Batalkan '
    'kapan saja, paket tetap aktif sampai akhir periode.';

/// The Owner's subscription: the current plan, its scheduled downgrade and open
/// order, and the plans the Owner can buy or downgrade to.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  var _period = SubscriptionPeriod.monthly;
  var _showLower = false;
  var _cancelling = false;
  String? _error;

  Future<void> _cancelDowngrade() async {
    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      await ref.read(subscriptionRepositoryProvider).cancelDowngrade();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    ref.invalidate(subscriptionProvider);
    setState(() => _cancelling = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Penurunan paket dibatalkan')));
  }

  void _openOrder(SubscriptionPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderSummarySheet(plan: plan, period: _period),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    final plans = ref.watch(subscriptionPlansProvider);
    return Scaffold(
      appBar: const DetailAppBar(title: 'Langganan'),
      body: _body(subscription, plans),
    );
  }

  Widget _body(
    AsyncValue<Subscription> subscription,
    AsyncValue<List<SubscriptionPlan>> plans,
  ) {
    if (subscription.hasError) {
      return ErrorView(
        message: errorMessageFor(subscription.error!),
        onRetry: () => ref.invalidate(subscriptionProvider),
      );
    }
    if (plans.hasError) {
      return ErrorView(
        message: errorMessageFor(plans.error!),
        onRetry: () => ref.invalidate(subscriptionPlansProvider),
      );
    }
    final current = subscription.value;
    final planList = plans.value;
    if (current == null || planList == null) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(_googlePlayNote),
          formGap,
          SectionCard(
            title: 'Status saat ini',
            child: CurrentStatus(
              subscription: current,
              cancelling: _cancelling,
              onCancelDowngrade: _cancelDowngrade,
              error: _error,
            ),
          ),
          formGap,
          SectionCard(
            title: 'Pilih paket',
            child: _plansSection(current, planList),
          ),
        ],
      ),
    );
  }

  /// The period choice and the plans. Plans at or above the current one come
  /// first; the lower plans sit behind a toggle.
  Widget _plansSection(Subscription current, List<SubscriptionPlan> plans) {
    final currentRank = PlanCode.values.indexOf(current.planCode);
    bool isAtOrAbove(SubscriptionPlan plan) =>
        PlanCode.values.indexOf(plan.code) >= currentRank;
    final higher = plans.where(isAtOrAbove).toList();
    final lower = plans.where((plan) => !isAtOrAbove(plan)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChipRow(
          chips: [
            for (final period in SubscriptionPeriod.values)
              ChoiceChip(
                label: Text(periodName(period)),
                selected: _period == period,
                onSelected: (_) => setState(() => _period = period),
              ),
          ],
        ),
        for (final plan in higher) ...[
          formGap,
          PlanCard(
            plan: plan,
            period: _period,
            isCurrent: plan.code == current.planCode,
            action: plan.code == current.planCode
                ? null
                : FilledButton(
                    onPressed: () => _openOrder(plan),
                    child: Text('Pilih ${planName(plan.code.value)}'),
                  ),
          ),
        ],
        if (lower.isNotEmpty) ...[
          formGap,
          TextButton(
            onPressed: () => setState(() => _showLower = !_showLower),
            child: Text(
              _showLower
                  ? 'Sembunyikan paket lebih rendah (${lower.length})'
                  : 'Lihat paket lebih rendah (${lower.length})',
            ),
          ),
          if (_showLower)
            for (final plan in lower) ...[
              formGap,
              PlanCard(
                plan: plan,
                period: _period,
                isCurrent: false,
                action: OutlinedButton(
                  onPressed: () => context.go(
                    '$_subscriptionPath/turunkan?paket=${plan.code.value}',
                  ),
                  child: Text('Turunkan ke ${planName(plan.code.value)}'),
                ),
              ),
            ],
        ],
      ],
    );
  }
}
