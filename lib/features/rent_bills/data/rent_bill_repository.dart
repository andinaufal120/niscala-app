import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala_api/api.dart';

/// Rent bills and their transfer receipts. Every method throws an `ApiFailure`
/// when the call fails.
abstract interface class RentBillRepository {
  /// The caller's bills whose payment status is one of [statuses], in the order
  /// the API returns them.
  Future<List<RentBillSummary>> list({required List<PaymentStatus> statuses});

  Future<RentBill> get(String id);

  /// Attaches [file] as the transfer receipt of the bill, which then awaits
  /// verification.
  Future<RentBill> uploadReceipt(String id, ReceiptFile file);

  /// The receipt image of the bill, as received.
  Future<Uint8List> receiptBytes(String id);
}

final rentBillRepositoryProvider = Provider<RentBillRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiRentBillRepository(rentBills: RentBillsApi(client));
});

/// The bills that still need action: unpaid, awaiting verification or
/// rejected. Invalidate it after a change. Failures are not retried in the
/// background: the screen shows them and the user retries.
final activeRentBillsProvider = FutureProvider<List<RentBillSummary>>(
  (ref) => ref
      .watch(rentBillRepositoryProvider)
      .list(
        statuses: [
          PaymentStatus.unpaid,
          PaymentStatus.awaitingVerification,
          PaymentStatus.rejected,
        ],
      ),
  retry: (_, _) => null,
);

/// The paid bills. Failures are not retried in the background, see
/// [activeRentBillsProvider].
final paidRentBillsProvider = FutureProvider<List<RentBillSummary>>(
  (ref) => ref
      .watch(rentBillRepositoryProvider)
      .list(statuses: [PaymentStatus.paid]),
  retry: (_, _) => null,
);

/// One bill. Invalidate it after a change. Failures are not retried in the
/// background, see [activeRentBillsProvider].
final rentBillDetailProvider = FutureProvider.family<RentBill, String>(
  (ref, id) => ref.watch(rentBillRepositoryProvider).get(id),
  retry: (_, _) => null,
);

/// The receipt image of one bill. Failures are not retried in the background,
/// see [activeRentBillsProvider].
final receiptBytesProvider = FutureProvider.family<Uint8List, String>(
  (ref, id) => ref.watch(rentBillRepositoryProvider).receiptBytes(id),
  retry: (_, _) => null,
);

class ApiRentBillRepository implements RentBillRepository {
  ApiRentBillRepository({required this.rentBills});

  final RentBillsApi rentBills;

  @override
  Future<List<RentBillSummary>> list({required List<PaymentStatus> statuses}) =>
      _guard(() async {
        return (await rentBills.listRentBills(paymentStatus: statuses))!.items;
      });

  @override
  Future<RentBill> get(String id) => _guard(() async {
    return (await rentBills.getRentBill(id))!;
  });

  @override
  Future<RentBill> uploadReceipt(String id, ReceiptFile file) =>
      _guard(() async {
        final type = receiptMediaType(file.bytes) ?? 'application/octet-stream';
        final part = http.MultipartFile.fromBytes(
          'file',
          file.bytes,
          filename: file.name,
          contentType: MediaType.parse(type),
        );
        return (await rentBills.uploadReceipt(id, part))!;
      });

  @override
  Future<Uint8List> receiptBytes(String id) => _guard(() async {
    final response = await rentBills.getReceiptWithHttpInfo(id);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.bodyBytes;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
