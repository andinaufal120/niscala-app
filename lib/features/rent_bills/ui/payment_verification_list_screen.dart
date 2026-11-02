import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

/// The bills of one property that await verification, in the order the API
/// returns them. A row opens the bill.
class PaymentVerificationListScreen extends ConsumerWidget {
  const PaymentVerificationListScreen({super.key, required this.propertyId});

  /// The property the bills belong to, from the `properti` query parameter.
  /// Null when the link has none, in which case no bills can be asked for.
  final String? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyId = this.propertyId;
    return Scaffold(
      appBar: const DetailAppBar(title: 'Menunggu Verifikasi'),
      body: propertyId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(NiscalaSpacing.gutter),
                child: Text(
                  'Properti tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          : _Rows(propertyId: propertyId),
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(awaitingVerificationProvider(propertyId));
    return bills.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
      error: (error, _) => ErrorView(
        message: errorMessageFor(error),
        onRetry: () => ref.invalidate(awaitingVerificationProvider(propertyId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            message: 'Tidak ada pembayaran yang menunggu verifikasi.',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(NiscalaSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final bill in items) ...[
                _BillRow(bill: bill),
                const SizedBox(height: NiscalaSpacing.s),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One bill awaiting verification: the tenant, the room, the period and the
/// amount. Opens the bill.
class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill});

  final RentBillSummary bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.push('/pembayaran/tagihan/${bill.id}'),
          title: Text(bill.tenant.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kamar ${bill.room.number}'),
              Text(
                '${formatDate(bill.periodStart)} - '
                '${formatDate(bill.periodEnd)}',
              ),
              const SizedBox(height: NiscalaSpacing.xs),
              Text(
                formatRupiah(bill.amount),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
