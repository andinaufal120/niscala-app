import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

/// The receipt image of one bill.
class ReceiptViewScreen extends ConsumerWidget {
  const ReceiptViewScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(rentBillDetailProvider(billId));
    final bytes = ref.watch(receiptBytesProvider(billId));
    void reload() {
      ref.invalidate(rentBillDetailProvider(billId));
      ref.invalidate(receiptBytesProvider(billId));
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Bukti Transfer'),
      body: switch ((bill, bytes)) {
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
          ErrorView(message: errorMessageFor(error), onRetry: reload),
        (AsyncData(value: final bill), AsyncData(value: final bytes)) =>
          Padding(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Center(
              child: Image.memory(
                bytes,
                semanticLabel: _label(bill),
                errorBuilder: (_, _, _) => ErrorView(
                  message: 'Bukti transfer tidak dapat ditampilkan.',
                  onRetry: reload,
                ),
              ),
            ),
          ),
        _ => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
      },
    );
  }

  String _label(RentBill bill) =>
      'Bukti transfer, ${bill.tenant.name}, '
      '${formatDate(bill.periodStart)} - ${formatDate(bill.periodEnd)}';
}
