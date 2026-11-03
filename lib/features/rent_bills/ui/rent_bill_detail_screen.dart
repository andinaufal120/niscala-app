import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala/features/rent_bills/ui/receipt_rejection_sheet.dart';
import 'package:niscala_api/api.dart';

const _notAwaitingVerificationCode = 'RENT_BILL_NOT_AWAITING_VERIFICATION';

/// One bill: its amount, status and payment, its receipt and the history of its
/// status changes. A bill awaiting verification can be verified or rejected.
class RentBillDetailScreen extends ConsumerStatefulWidget {
  const RentBillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<RentBillDetailScreen> createState() =>
      _RentBillDetailScreenState();
}

class _RentBillDetailScreenState extends ConsumerState<RentBillDetailScreen> {
  /// Set while a verification is sent, so that a second tap sends nothing.
  var _verifying = false;

  /// The failure of the last verification, or the conflict of a rejection,
  /// shown on the bill until the next review.
  String? _message;

  Future<void> _askVerification() async {
    if (_verifying) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Verifikasi Pembayaran',
      message: 'Bukti transfer sudah sesuai dan tagihan ditandai Lunas.',
      confirmLabel: 'Verifikasi',
    );
    if (confirmed && mounted) await _verify();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _message = null;
    });
    try {
      await ref
          .read(managementRentBillRepositoryProvider)
          .verifyReceipt(widget.billId);
    } on ApiFailure catch (failure) {
      _failed(failure);
      return;
    }
    _reviewed();
  }

  /// Rejects the receipt. A conflict is shown on the bill, so the prompt closes
  /// with it. Any other failure is rethrown for the prompt to show.
  Future<void> _reject(String reason) async {
    try {
      await ref
          .read(managementRentBillRepositoryProvider)
          .rejectReceipt(widget.billId, reason);
    } on ApiFailure catch (failure) {
      if (!_isConflict(failure)) rethrow;
      _failed(failure);
      return;
    }
    _reviewed();
  }

  bool _isConflict(ApiFailure failure) =>
      failure.statusCode == 409 || failure.code == _notAwaitingVerificationCode;

  /// Shows the failure on the bill. A conflict means the bill changed under the
  /// user, so the bill is loaded again.
  void _failed(ApiFailure failure) {
    if (!mounted) return;
    if (_isConflict(failure)) {
      ref.invalidate(rentBillDetailProvider(widget.billId));
    }
    setState(() {
      _verifying = false;
      _message = errorMessageFor(failure);
    });
  }

  /// Reloads the bill and every list that shows its status. This runs to the
  /// end even when the screen was left during the request.
  void _reviewed() {
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _message = null;
    });
    ref.invalidate(rentBillDetailProvider(widget.billId));
    ref.invalidate(tenantRentBillsProvider);
    ref.invalidate(awaitingVerificationProvider);
    ref.invalidate(paymentOverviewProvider);
  }

  Future<void> _askRejection() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ReceiptRejectionSheet(onConfirm: _reject),
  );

  @override
  Widget build(BuildContext context) {
    final bill = ref.watch(rentBillDetailProvider(widget.billId));
    final loaded = bill.value;
    final awaiting =
        loaded != null &&
        loaded.payment.status == PaymentStatus.awaitingVerification;
    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Tagihan'),
      body: bill.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(rentBillDetailProvider(widget.billId)),
        ),
        data: (bill) => SingleChildScrollView(
          padding: const EdgeInsets.all(NiscalaSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message != null) ...[
                FormMessage(_message!),
                const SizedBox(height: NiscalaSpacing.m),
              ],
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
      bottomNavigationBar: awaiting
          ? ActionFooter(
              primary: BusyButton(
                label: 'Verifikasi',
                busy: _verifying,
                onPressed: _askVerification,
              ),
              secondary: OutlinedButton(
                onPressed: _verifying ? null : _askRejection,
                child: const Text('Tolak'),
              ),
            )
          : null,
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
