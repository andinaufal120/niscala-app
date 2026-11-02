import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

/// One bill, read only: its amount, status and payment, its receipt and the
/// history of its status changes.
class RentBillDetailScreen extends ConsumerWidget {
  const RentBillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(rentBillDetailProvider(billId));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Tagihan'),
      body: bill.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(rentBillDetailProvider(billId)),
        ),
        data: (bill) => SingleChildScrollView(
          padding: const EdgeInsets.all(NiscalaSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(child: _Summary(bill: bill)),
              if (bill.payment.hasReceipt) ...[
                const SizedBox(height: NiscalaSpacing.m),
                SectionCard(
                  title: 'Bukti transfer',
                  child: _Receipt(bill: bill),
                ),
              ],
              if (bill.statusChanges.isNotEmpty) ...[
                const SizedBox(height: NiscalaSpacing.m),
                SectionCard(
                  title: 'Riwayat Status',
                  child: _StatusChanges(changes: bill.statusChanges),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.bill});

  final RentBill bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = bill.payment;
    final method = payment.method;
    final paidOn = payment.paidOn;
    final reason = payment.rejectionReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: NiscalaSpacing.s,
          runSpacing: NiscalaSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(formatRupiah(bill.amount), style: theme.textTheme.titleLarge),
            PaymentBadge(payment.status),
          ],
        ),
        const SizedBox(height: NiscalaSpacing.m),
        _Fact(label: 'Penyewa', value: bill.tenant.name),
        _Fact(label: 'Kamar', value: bill.room.number),
        _Fact(
          label: 'Periode',
          value:
              '${formatDate(bill.periodStart)} - '
              '${formatDate(bill.periodEnd)}',
        ),
        _Fact(label: 'Jatuh tempo', value: formatDate(bill.dueDate)),
        if (bill.daysOverdue > 0)
          Text(
            '${bill.daysOverdue} hari terlambat',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        if (method != null)
          _Fact(
            label: 'Metode pembayaran',
            value: paymentMethodLabels[method]!,
          ),
        if (paidOn != null)
          _Fact(label: 'Tanggal dibayar', value: formatDate(paidOn)),
        if (reason != null && payment.status == PaymentStatus.rejected)
          _Fact(label: 'Alasan penolakan', value: reason),
      ],
    );
  }
}

/// A label above its value.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NiscalaSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// The receipt image of the bill, with its own failure and reload. The bill
/// stays on screen whatever happens to the image.
class _Receipt extends ConsumerWidget {
  const _Receipt({required this.bill});

  final RentBill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(receiptBytesProvider(bill.id));
    void reload() => ref.invalidate(receiptBytesProvider(bill.id));
    return switch (bytes) {
      AsyncError(:final error) => ErrorView(
        message: errorMessageFor(error),
        onRetry: reload,
      ),
      AsyncData(:final value) => Image.memory(
        value,
        semanticLabel:
            'Bukti transfer, ${bill.tenant.name}, '
            '${formatDate(bill.periodStart)} - ${formatDate(bill.periodEnd)}',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => ErrorView(
          message: 'Bukti transfer tidak dapat ditampilkan.',
          onRetry: reload,
        ),
      ),
      _ => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
    };
  }
}

/// The status changes of the bill, oldest first as the API returns them.
class _StatusChanges extends StatelessWidget {
  const _StatusChanges({required this.changes});

  final List<PaymentStatusChange> changes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in changes) ...[
          _StatusChangeEntry(change: change),
          const SizedBox(height: NiscalaSpacing.m),
        ],
      ],
    );
  }
}

class _StatusChangeEntry extends StatelessWidget {
  const _StatusChangeEntry({required this.change});

  final PaymentStatusChange change;

  @override
  Widget build(BuildContext context) {
    final actor = change.actorName;
    final reason = change.reason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: NiscalaSpacing.s,
          runSpacing: NiscalaSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PaymentBadge(change.status),
            Text(formatDate(change.changedAt.toLocal())),
          ],
        ),
        if (actor != null) Text('Diubah oleh $actor'),
        if (reason != null) Text(reason),
      ],
    );
  }
}
