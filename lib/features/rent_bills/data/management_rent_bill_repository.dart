import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Payment status of tenants as management sees it. Every method throws an
/// `ApiFailure` when the call fails.
abstract interface class ManagementRentBillRepository {
  /// The bill of each tenant of [propertyId] that covers [date], in the order
  /// the API returns them. Without [date] the API uses today.
  Future<PaymentOverview> overview(String propertyId, {DateTime? date});

  /// The bills that match the given filters, in the order the API returns
  /// them. A null filter is not sent.
  Future<List<RentBillSummary>> list({
    String? propertyId,
    String? tenantId,
    List<PaymentStatus>? statuses,
  });

  /// Accepts the transfer receipt of the bill, which then becomes paid. Returns
  /// the bill as the API has it after the change.
  Future<RentBill> verifyReceipt(String billId);

  /// Rejects the transfer receipt of the bill with [reason], sent as given.
  /// Returns the bill as the API has it after the change.
  Future<RentBill> rejectReceipt(String billId, String reason);

  /// Records that the bill was paid in cash, with [receivedOn] as the day the
  /// money was received. Only the calendar day of [receivedOn] is sent. Returns
  /// the bill as the API has it after the change.
  Future<RentBill> recordCashPayment(String billId, DateTime receivedOn);

  /// Sets the payment status of the bill by hand, with the [reason] sent as
  /// given. [method] and [receivedOn] are sent only for [PaymentStatus.paid];
  /// for it, only the calendar day of [receivedOn] is sent. Returns the bill as
  /// the API has it after the change.
  Future<RentBill> changePaymentStatus(
    String billId, {
    required PaymentStatus status,
    required String reason,
    PaymentMethod? method,
    DateTime? receivedOn,
  });

  /// The payment pattern of each tenant of [propertyId], in the order the API
  /// returns them.
  Future<List<PaymentPattern>> paymentPatterns(String propertyId);
}

final managementRentBillRepositoryProvider =
    Provider<ManagementRentBillRepository>((ref) {
      final client = ref.watch(apiClientProvider);
      return ApiManagementRentBillRepository(rentBills: RentBillsApi(client));
    });

/// The payment overview of one property on one day. Failures are not retried
/// in the background: the screen shows them and the user retries.
final paymentOverviewProvider =
    FutureProvider.family<
      PaymentOverview,
      ({String propertyId, DateTime date})
    >(
      (ref, request) => ref
          .watch(managementRentBillRepositoryProvider)
          .overview(request.propertyId, date: request.date),
      retry: (_, _) => null,
    );

/// Every bill of one tenant in one property. Failures are not retried in the
/// background, see [paymentOverviewProvider].
final tenantRentBillsProvider =
    FutureProvider.family<
      List<RentBillSummary>,
      ({String propertyId, String tenantId})
    >(
      (ref, request) => ref
          .watch(managementRentBillRepositoryProvider)
          .list(propertyId: request.propertyId, tenantId: request.tenantId),
      retry: (_, _) => null,
    );

/// The bills of one property that await verification. Failures are not retried
/// in the background, see [paymentOverviewProvider].
final awaitingVerificationProvider =
    FutureProvider.family<List<RentBillSummary>, String>(
      (ref, propertyId) => ref
          .watch(managementRentBillRepositoryProvider)
          .list(
            propertyId: propertyId,
            statuses: [PaymentStatus.awaitingVerification],
          ),
      retry: (_, _) => null,
    );

/// The payment patterns of one property. Released when no screen watches it, so
/// each opening of the screen asks for them again. Failures are not retried in
/// the background, see [paymentOverviewProvider].
final paymentPatternsProvider = FutureProvider.autoDispose
    .family<List<PaymentPattern>, String>(
      (ref, propertyId) => ref
          .watch(managementRentBillRepositoryProvider)
          .paymentPatterns(propertyId),
      retry: (_, _) => null,
    );

/// The bills of one property that can be paid in cash: unpaid or rejected.
/// Released when no screen watches it, so each opening of the payment flow
/// loads the bills again. Failures are not retried in the background, see
/// [paymentOverviewProvider].
final payableRentBillsProvider = FutureProvider.autoDispose
    .family<List<RentBillSummary>, String>(
      (ref, propertyId) => ref
          .watch(managementRentBillRepositoryProvider)
          .list(
            propertyId: propertyId,
            statuses: [PaymentStatus.unpaid, PaymentStatus.rejected],
          ),
      retry: (_, _) => null,
    );

class ApiManagementRentBillRepository implements ManagementRentBillRepository {
  ApiManagementRentBillRepository({required this.rentBills});

  final RentBillsApi rentBills;

  @override
  Future<PaymentOverview> overview(String propertyId, {DateTime? date}) =>
      _guard(() async {
        // The API takes a UTC midnight, so the calendar day is kept as it is
        // on the device, whatever the time of day.
        final day = date == null
            ? null
            : DateTime.utc(date.year, date.month, date.day);
        return (await rentBills.getPaymentOverview(propertyId, date: day))!;
      });

  @override
  Future<List<RentBillSummary>> list({
    String? propertyId,
    String? tenantId,
    List<PaymentStatus>? statuses,
  }) => _guard(() async {
    final response = await rentBills.listRentBills(
      propertyId: propertyId,
      tenantId: tenantId,
      paymentStatus: statuses,
    );
    return response!.items;
  });

  @override
  Future<RentBill> verifyReceipt(String billId) =>
      _guard(() async => (await rentBills.verifyReceipt(billId))!);

  @override
  Future<RentBill> rejectReceipt(String billId, String reason) => _guard(
    () async => (await rentBills.rejectReceipt(
      billId,
      ReceiptRejectionInput(reason: reason),
    ))!,
  );

  @override
  Future<RentBill> recordCashPayment(String billId, DateTime receivedOn) =>
      _guard(
        () async => (await rentBills.recordCashPayment(
          billId,
          CashPaymentInput(
            receivedOn: DateTime.utc(
              receivedOn.year,
              receivedOn.month,
              receivedOn.day,
            ),
          ),
        ))!,
      );

  @override
  Future<RentBill> changePaymentStatus(
    String billId, {
    required PaymentStatus status,
    required String reason,
    PaymentMethod? method,
    DateTime? receivedOn,
  }) => _guard(() async {
    final paid = status == PaymentStatus.paid;
    final day = receivedOn;
    return (await rentBills.changePaymentStatus(
      billId,
      PaymentStatusChangeInput(
        status: _statusInput(status),
        reason: reason,
        method: paid ? method : null,
        receivedOn: paid && day != null
            ? DateTime.utc(day.year, day.month, day.day)
            : null,
      ),
    ))!;
  });

  @override
  Future<List<PaymentPattern>> paymentPatterns(String propertyId) => _guard(
    () async => (await rentBills.getPaymentPatterns(propertyId))!.items,
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}

/// The wire value of [status]. Awaiting verification has none: it is set by
/// uploading a receipt, not by hand.
PaymentStatusChangeInputStatusEnum _statusInput(PaymentStatus status) {
  final input = PaymentStatusChangeInputStatusEnum.fromJson(status.value);
  if (input == null) {
    throw ArgumentError.value(status, 'status', 'cannot be set by hand');
  }
  return input;
}
