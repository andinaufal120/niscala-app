import 'package:niscala/core/format.dart';
import 'package:niscala_api/api.dart';

/// The one table of subscription labels. Every subscription screen reads its
/// names from here, so a plan has the same text everywhere. Plans are keyed by
/// their API wire value, which both `PlanCode` and `PaidPlanCode` carry.
const _planNames = {'free': 'Gratis', 'basic': 'Basic', 'pro': 'Pro'};

const _periodNames = {
  SubscriptionPeriod.monthly: 'Bulanan',
  SubscriptionPeriod.yearly: 'Tahunan',
};

const _periodUnits = {
  SubscriptionPeriod.monthly: 'bulan',
  SubscriptionPeriod.yearly: 'tahun',
};

const _statusNames = {
  SubscriptionStatus.free: 'Gratis',
  SubscriptionStatus.active: 'Aktif',
};

/// The name of the plan with the wire [code], such as `basic`.
String planName(String code) => _planNames[code]!;

String periodName(SubscriptionPeriod period) => _periodNames[period]!;

String statusName(SubscriptionStatus status) => _statusNames[status]!;

/// The price of [plan] for [period], such as "Rp49.000/bulan". The free plan
/// has no price and always reads "Rp0".
String planPriceText(SubscriptionPlan plan, SubscriptionPeriod period) {
  if (plan.code == PlanCode.free) return formatRupiah(0);
  final price = plan.prices.firstWhere((p) => p.billingPeriod == period);
  return '${formatRupiah(price.amount)}/${_periodUnits[period]!}';
}

String propertyLimitText(SubscriptionPlan plan) {
  final limit = plan.maxProperties;
  return limit == null
      ? 'Jumlah properti tidak dibatasi'
      : 'Maksimal $limit properti';
}

String roomLimitText(SubscriptionPlan plan) {
  final limit = plan.maxRoomsPerProperty;
  return limit == null
      ? 'Jumlah kamar tidak dibatasi'
      : 'Maksimal $limit kamar per properti';
}

/// The plan and, for an active subscription, its end date, such as "Paket Basic
/// · aktif hingga 15 Des 2026".
String subscriptionSummary(Subscription subscription) {
  final plan = 'Paket ${planName(subscription.planCode.value)}';
  final end = subscription.endDate;
  if (subscription.status != SubscriptionStatus.active || end == null) {
    return plan;
  }
  return '$plan · aktif hingga ${formatDate(end)}';
}
