import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
import 'package:niscala/features/notifications/notification_copy.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

const _billTypes = {
  NotificationType.billIssued,
  NotificationType.dueDateReminder,
  NotificationType.billOverdue,
  NotificationType.paymentStatusChanged,
  NotificationType.receiptUploaded,
  NotificationType.cashPaymentRecorded,
};

const _complaintTypes = {
  NotificationType.complaintStatusChanged,
  NotificationType.complaintSubmitted,
};

/// One notification, read from the loaded list. It is marked read when it
/// opens, once; a failed request leaves it unread and is not shown.
class NotificationDetailScreen extends ConsumerStatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});

  final String notificationId;

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  /// Set once the list has been reloaded for a missing notification, so that
  /// an id that stays missing does not reload again.
  var _reloaded = false;

  /// Set once the read request has been sent for this visit.
  var _markRequested = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(notificationListProvider, (_, next) => _onList(next));
    // A list loaded earlier is already there. It is checked after this frame,
    // because the list may only be reloaded outside a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onList(ref.read(notificationListProvider));
    });
  }

  void _onList(AsyncValue<NotificationList> list) {
    final items = list.value?.items;
    if (items == null) return;
    final found = _find(items);
    if (found == null) {
      if (_reloaded) return;
      _reloaded = true;
      ref.invalidate(notificationListProvider);
      return;
    }
    if (found.read || _markRequested) return;
    _markRequested = true;
    _markRead();
  }

  Notification? _find(List<Notification> items) {
    final index = items.indexWhere((n) => n.id == widget.notificationId);
    return index < 0 ? null : items[index];
  }

  Future<void> _markRead() async {
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markRead(widget.notificationId);
    } on ApiFailure {
      // The notification stays unread in the list. Nothing is shown.
      return;
    }
    if (!mounted) return;
    ref.invalidate(notificationListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final forManagement = role != UserRole.tenant;
    final list = ref.watch(notificationListProvider);
    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Notifikasi'),
      body: list.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(notificationListProvider),
        ),
        data: (data) {
          final n = _find(data.items);
          if (n == null) {
            return const EmptyState(message: 'Notifikasi tidak ditemukan.');
          }
          return _details(n, forManagement: forManagement);
        },
      ),
    );
  }

  Widget _details(Notification n, {required bool forManagement}) {
    final theme = Theme.of(context);
    final text = notificationText(n, forManagement: forManagement);
    final body = text.body;
    final tenant = n.tenant;
    final room = n.room;
    final property = n.property;
    final actor = n.actorName;
    final bill = n.rentBill;
    final complaint = n.complaint;
    final facts = <Widget>[
      if (tenant != null) _Fact(label: 'Penyewa', child: Text(tenant.name)),
      if (room != null) _Fact(label: 'Kamar', child: Text(room.number)),
      if (property != null)
        _Fact(label: 'Properti', child: Text(property.name)),
      if (actor != null) _Fact(label: 'Dilakukan oleh', child: Text(actor)),
      if (bill != null) ...[
        _Fact(
          label: 'Periode',
          child: Text(
            '${formatDate(bill.periodStart)} - ${formatDate(bill.periodEnd)}',
          ),
        ),
        _Fact(label: 'Jumlah', child: Text(formatRupiah(bill.amount))),
        _Fact(label: 'Jatuh tempo', child: Text(formatDate(bill.dueDate))),
        _Fact(
          label: 'Status pembayaran',
          child: PaymentBadge(bill.paymentStatus),
        ),
        if (bill.paymentMethod case final method?)
          _Fact(
            label: 'Metode pembayaran',
            child: Text(paymentMethodLabels[method]!),
          ),
        if (bill.reason case final reason?)
          _Fact(label: 'Alasan', child: Text(reason)),
      ],
      if (complaint != null) ...[
        _Fact(label: 'Isi keluhan', child: Text(complaint.description)),
        _Fact(
          label: 'Status keluhan',
          child: ComplaintBadge.status(complaint.status),
        ),
        if (complaint.category case final category?)
          _Fact(label: 'Kategori', child: Text(category)),
        if (complaint.urgency case final urgency?)
          _Fact(label: 'Urgensi', child: ComplaintBadge.urgency(urgency)),
        if (complaint.handlingNote case final note?)
          _Fact(label: 'Catatan penanganan', child: Text(note)),
      ],
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificationTypeLabel(n.type),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: NiscalaSpacing.xs),
                Text(text.title, style: theme.textTheme.titleMedium),
                if (body != null) ...[
                  const SizedBox(height: NiscalaSpacing.s),
                  Text(body, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: NiscalaSpacing.s),
                Text(
                  'Diterima ${formatDate(n.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: NiscalaSpacing.m),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: facts,
              ),
            ),
          ],
          if (bill != null && _billTypes.contains(n.type)) ...[
            const SizedBox(height: NiscalaSpacing.m),
            FilledButton(
              onPressed: () => forManagement
                  ? context.push('/pembayaran/tagihan/${bill.rentBillId}')
                  : context.go('/penyewa/pembayaran'),
              child: const Text('Lihat tagihan'),
            ),
          ],
          if (complaint != null && _complaintTypes.contains(n.type)) ...[
            const SizedBox(height: NiscalaSpacing.m),
            FilledButton(
              onPressed: () => context.push(
                forManagement
                    ? '/keluhan/${complaint.complaintId}'
                    : '/penyewa/keluhan/${complaint.complaintId}',
              ),
              child: const Text('Lihat keluhan'),
            ),
          ],
        ],
      ),
    );
  }
}

/// A label above its value.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NiscalaSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          child,
        ],
      ),
    );
  }
}
