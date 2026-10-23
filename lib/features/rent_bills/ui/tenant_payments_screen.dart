import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

const _payments = '/penyewa/pembayaran';

/// The tenant's rent bills: the ones that still need action, or the paid ones.
class TenantPaymentsScreen extends ConsumerStatefulWidget {
  const TenantPaymentsScreen({super.key});

  @override
  ConsumerState<TenantPaymentsScreen> createState() =>
      _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends ConsumerState<TenantPaymentsScreen> {
  var _history = false;

  @override
  Widget build(BuildContext context) {
    final provider = _history ? paidRentBillsProvider : activeRentBillsProvider;
    final bills = ref.watch(provider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Pembayaran'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NiscalaSpacing.gutter,
              NiscalaSpacing.s,
              NiscalaSpacing.gutter,
              NiscalaSpacing.s,
            ),
            child: Wrap(
              spacing: NiscalaSpacing.s,
              runSpacing: NiscalaSpacing.s,
              children: [
                ChoiceChip(
                  label: const Text('Tagihan aktif'),
                  selected: !_history,
                  onSelected: (_) => setState(() => _history = false),
                ),
                ChoiceChip(
                  label: const Text('Riwayat'),
                  selected: _history,
                  onSelected: (_) => setState(() => _history = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: bills.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
              ),
              error: (error, _) => ErrorView(
                message: errorMessageFor(error),
                onRetry: () => ref.invalidate(provider),
              ),
              data: (items) => items.isEmpty
                  ? EmptyState(
                      message: _history
                          ? 'Belum ada riwayat pembayaran.'
                          : 'Tidak ada tagihan aktif.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
                      children: [
                        for (final bill in items) ...[
                          _BillCard(bill: bill),
                          const SizedBox(height: NiscalaSpacing.s),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One bill. The facts read as one item; the actions stay separate controls.
class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill});

  final RentBillSummary bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = bill.payment.status;
    final reason = bill.payment.rejectionReason;
    final canPayCash =
        !bill.canUploadReceipt &&
        (status == PaymentStatus.unpaid || status == PaymentStatus.rejected);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NiscalaSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: NiscalaSpacing.s,
                    runSpacing: NiscalaSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatRupiah(bill.amount),
                        style: theme.textTheme.titleLarge,
                      ),
                      PaymentBadge(status),
                    ],
                  ),
                  const SizedBox(height: NiscalaSpacing.xs),
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
                      'Terlambat ${bill.daysOverdue} hari',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  if (status == PaymentStatus.rejected && reason != null)
                    Text('Alasan ditolak: $reason'),
                  if (canPayCash) const Text('Bayar tunai ke pengelola kost'),
                ],
              ),
            ),
            if (bill.canUploadReceipt) ...[
              const SizedBox(height: NiscalaSpacing.m),
              FilledButton(
                onPressed: () => context.go('$_payments/unggah/${bill.id}'),
                child: Text(
                  status == PaymentStatus.rejected
                      ? 'Unggah ulang bukti'
                      : 'Transfer sekarang',
                ),
              ),
            ],
            if (status == PaymentStatus.awaitingVerification) ...[
              const SizedBox(height: NiscalaSpacing.m),
              OutlinedButton(
                onPressed: () => context.go('$_payments/bukti/${bill.id}'),
                child: const Text('Lihat bukti'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
