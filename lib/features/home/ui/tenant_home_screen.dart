import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
import 'package:niscala/features/lease/ui/lease_card.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

const _payments = '/penyewa/pembayaran';
const _complaintForm = '/penyewa/keluhan/baru';
const _upload = 'Unggah bukti transfer';
const _cashNote = 'Bayar tunai langsung ke pengelola sebelum jatuh tempo.';
const _history = 'Lihat riwayat pembayaran';
const _noBills = 'Tidak ada tagihan aktif.';
const _noComplaints = 'Belum ada keluhan.';

/// The tenant's home: a greeting with the room, the first active bill and the
/// latest complaint. The lease decides whether the bill and complaint sections
/// exist. Each section loads and fails on its own.
class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lease = ref.watch(myLeaseProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Beranda'),
          Expanded(
            child: lease.when(
              loading: () => const Center(
                child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
              ),
              error: (error, _) => ErrorView(
                message: errorMessageFor(error),
                onRetry: () => ref.invalidate(myLeaseProvider),
              ),
              data: (lease) => ListView(
                padding: const EdgeInsets.all(NiscalaSpacing.gutter),
                children: [
                  _Greeting(lease: lease),
                  const SizedBox(height: NiscalaSpacing.l),
                  if (lease == null)
                    Text(
                      noActiveLeaseMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  else ...[
                    const _BillSection(),
                    const SizedBox(height: NiscalaSpacing.l),
                    const _ComplaintSection(),
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

/// The account name, and the property and room when there is a lease.
class _Greeting extends ConsumerWidget {
  const _Greeting({required this.lease});

  final CurrentLease? lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(myAccountProvider).value?.name;
    final lease = this.lease;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null ? 'Halo' : 'Halo, $name',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (lease != null)
          Text('${lease.property.name} · Kamar ${lease.room.number}'),
      ],
    );
  }
}

/// The first active bill, or the note that there is none, and the link to the
/// payment history.
class _BillSection extends ConsumerWidget {
  const _BillSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(activeRentBillsProvider);
    return SectionCard(
      title: 'Tagihan aktif',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bills.when(
            loading: () => const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
            ),
            error: (error, _) => ErrorView(
              message: errorMessageFor(error),
              onRetry: () => ref.invalidate(activeRentBillsProvider),
            ),
            data: (items) => items.isEmpty
                ? Text(_noBills, style: Theme.of(context).textTheme.bodyLarge)
                : _FirstBill(bill: items.first),
          ),
          const SizedBox(height: NiscalaSpacing.s),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(_payments),
              child: const Text(_history),
            ),
          ),
        ],
      ),
    );
  }
}

/// The facts of one bill, then its action once the bill detail, which holds
/// the property's bank account, has loaded.
class _FirstBill extends ConsumerWidget {
  const _FirstBill({required this.bill});

  final RentBillSummary bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detail = ref.watch(rentBillDetailProvider(bill.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: NiscalaSpacing.s,
          runSpacing: NiscalaSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(formatRupiah(bill.amount), style: theme.textTheme.titleLarge),
            PaymentBadge(bill.payment.status),
          ],
        ),
        const SizedBox(height: NiscalaSpacing.xs),
        Text('Jatuh tempo ${formatDate(bill.dueDate)}'),
        if (bill.daysOverdue > 0)
          Text(
            'Terlambat ${bill.daysOverdue} hari',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        const SizedBox(height: NiscalaSpacing.m),
        detail.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => ErrorView(
            message: errorMessageFor(error),
            onRetry: () => ref.invalidate(rentBillDetailProvider(bill.id)),
          ),
          data: (full) =>
              _BillAction(bill: bill, hasBankAccount: full.bankAccount != null),
        ),
      ],
    );
  }
}

/// The upload action when the bill is uploadable and the property has a bank
/// account. Without a bank account, a bill still owed gets the cash note.
class _BillAction extends StatelessWidget {
  const _BillAction({required this.bill, required this.hasBankAccount});

  final RentBillSummary bill;
  final bool hasBankAccount;

  @override
  Widget build(BuildContext context) {
    if (hasBankAccount) {
      if (!bill.canUploadReceipt) return const SizedBox.shrink();
      return FilledButton(
        onPressed: () => context.go('$_payments/unggah/${bill.id}'),
        child: const Text(_upload),
      );
    }
    final status = bill.payment.status;
    final owed =
        status == PaymentStatus.unpaid || status == PaymentStatus.rejected;
    return owed ? const Text(_cashNote) : const SizedBox.shrink();
  }
}

/// The latest complaint with its status, and its category once classified.
/// Tapping it opens the complaint. The handling note comes from its detail.
class _ComplaintSection extends ConsumerWidget {
  const _ComplaintSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(complaintListProvider);
    return SectionCard(
      title: 'Keluhan saya',
      trailing: FilledButton(
        onPressed: () => context.go(_complaintForm),
        child: const Text('Ajukan'),
      ),
      child: complaints.when(
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(complaintListProvider),
        ),
        data: (items) => items.isEmpty
            ? Text(_noComplaints, style: Theme.of(context).textTheme.bodyLarge)
            : _LatestComplaint(complaint: items.first),
      ),
    );
  }
}

class _LatestComplaint extends ConsumerWidget {
  const _LatestComplaint({required this.complaint});

  final ComplaintSummary complaint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classification = complaint.classification;
    final state = complaint.classificationState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => context.go('/penyewa/keluhan/${complaint.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(complaint.description),
              const SizedBox(height: NiscalaSpacing.xs),
              Wrap(
                spacing: NiscalaSpacing.s,
                runSpacing: NiscalaSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ComplaintBadge.status(complaint.status),
                  if (classification != null)
                    Text(classification.category)
                  else if (state != null)
                    ComplaintBadge.classification(state),
                ],
              ),
            ],
          ),
        ),
        _HandlingNote(complaintId: complaint.id),
      ],
    );
  }
}

/// The handling note of the latest status change of a complaint, if it has one.
class _HandlingNote extends ConsumerWidget {
  const _HandlingNote({required this.complaintId});

  final String complaintId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(complaintDetailProvider(complaintId));
    return detail.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => ErrorView(
        message: errorMessageFor(error),
        onRetry: () => ref.invalidate(complaintDetailProvider(complaintId)),
      ),
      data: (full) {
        final changes = full.statusChanges;
        final note = changes.isEmpty ? null : changes.last.handlingNote;
        return note == null
            ? const SizedBox.shrink()
            : Text('Catatan penanganan: $note');
      },
    );
  }
}
