import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// The Owner's subscription. Every method throws an `ApiFailure` when the call
/// fails.
abstract interface class SubscriptionRepository {
  Future<Subscription> subscription();

  /// The plans with their limits, AI availability and prices, in the order the
  /// API lists them.
  Future<List<SubscriptionPlan>> plans();

  /// Starts a purchase of a paid plan. The order waits for payment in Google
  /// Play.
  Future<SubscriptionOrder> createOrder({
    required PaidPlanCode planCode,
    required SubscriptionPeriod billingPeriod,
  });

  Future<SubscriptionOrder> order(String id);

  /// Schedules a downgrade at the end of the paid period. [keptPropertyIds] and
  /// [keptRoomIds] are the properties and rooms that stay editable.
  Future<ScheduledDowngrade> scheduleDowngrade({
    required PlanCode planCode,
    required List<String> keptPropertyIds,
    required List<String> keptRoomIds,
  });

  Future<void> cancelDowngrade();
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiSubscriptionRepository(subscriptions: SubscriptionsApi(client));
});

/// The Owner's subscription. Invalidate it after a change. Failures are not
/// retried in the background: the screen shows them and the user retries.
final subscriptionProvider = FutureProvider<Subscription>(
  (ref) => ref.watch(subscriptionRepositoryProvider).subscription(),
  retry: (_, _) => null,
);

/// The subscription plans. Failures are not retried in the background, see
/// [subscriptionProvider].
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).plans(),
  retry: (_, _) => null,
);

/// The day of [date] at UTC midnight. The API sends date-only values, which the
/// generated models read as local midnight; the day is kept, so it reads the
/// same wherever the app runs.
DateTime _utcDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

Subscription _withUtcDays(Subscription subscription) {
  final end = subscription.endDate;
  if (end != null) subscription.endDate = _utcDay(end);
  final downgrade = subscription.scheduledDowngrade;
  if (downgrade != null) {
    downgrade.effectiveDate = _utcDay(downgrade.effectiveDate);
  }
  return subscription;
}

ScheduledDowngrade _downgradeWithUtcDay(ScheduledDowngrade downgrade) {
  downgrade.effectiveDate = _utcDay(downgrade.effectiveDate);
  return downgrade;
}

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository({required this.subscriptions});

  final SubscriptionsApi subscriptions;

  @override
  Future<Subscription> subscription() => _guard(() async {
    return _withUtcDays((await subscriptions.getSubscription())!);
  });

  @override
  Future<List<SubscriptionPlan>> plans() => _guard(() async {
    return (await subscriptions.listSubscriptionPlans())!.items;
  });

  @override
  Future<SubscriptionOrder> createOrder({
    required PaidPlanCode planCode,
    required SubscriptionPeriod billingPeriod,
  }) => _guard(() async {
    return (await subscriptions.createSubscriptionOrder(
      SubscriptionOrderInput(planCode: planCode, billingPeriod: billingPeriod),
    ))!;
  });

  @override
  Future<SubscriptionOrder> order(String id) => _guard(() async {
    return (await subscriptions.getSubscriptionOrder(id))!;
  });

  @override
  Future<ScheduledDowngrade> scheduleDowngrade({
    required PlanCode planCode,
    required List<String> keptPropertyIds,
    required List<String> keptRoomIds,
  }) => _guard(() async {
    return _downgradeWithUtcDay(
      (await subscriptions.scheduleSubscriptionDowngrade(
        ScheduledDowngradeInput(
          planCode: planCode,
          keptPropertyIds: keptPropertyIds,
          keptRoomIds: keptRoomIds,
        ),
      ))!,
    );
  });

  @override
  Future<void> cancelDowngrade() =>
      _guard(() => subscriptions.cancelSubscriptionDowngrade());

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
