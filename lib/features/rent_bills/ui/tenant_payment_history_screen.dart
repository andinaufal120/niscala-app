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
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

/// Every bill of one tenant in one property, newest period first as the API
/// returns them.
class TenantPaymentHistoryScreen extends ConsumerWidget {
  const TenantPaymentHistoryScreen({
    super.key,
    required this.tenantId,
    required this.propertyId,
  });

  final String tenantId;

  /// The property the bills belong to, from the `properti` query parameter.
  /// Null when the link has none, in which case no bills can be asked for.
  final String? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyId = this.propertyId;
    return Scaffold(
      appBar: const DetailAppBar(title: 'Riwayat Pembayaran'),
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
          : _History(propertyId: propertyId, tenantId: tenantId),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.propertyId, required this.tenantId});

  final String propertyId;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (propertyId: propertyId, tenantId: tenantId);
    final bills = ref.watch(tenantRentBillsProvider(request));
    return bills.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
      error: (error, _) => ErrorView(
        message: errorMessageFor(error),
        onRetry: () => ref.invalidate(tenantRentBillsProvider(request)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(message: 'Belum ada riwayat pembayaran.');
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(NiscalaSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  items.first.tenant.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: NiscalaSpacing.s),
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

/// One bill: its amount and status, its period and due date. Opens the bill.
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
          title: Wrap(
            spacing: NiscalaSpacing.s,
            runSpacing: NiscalaSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatRupiah(bill.amount),
                style: theme.textTheme.titleLarge,
              ),
              PaymentBadge(bill.payment.status),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDate(bill.periodStart)} - '
                '${formatDate(bill.periodEnd)}',
              ),
              Text(
                'Jatuh tempo ${formatDate(bill.dueDate)}',
                style: theme.textTheme.bodySmall,
              ),
              if (bill.daysOverdue > 0)
                Text(
                  '${bill.daysOverdue} hari terlambat',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
