import 'package:niscala/core/format.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

/// The title of a notification and the line under it, when it has one.
typedef NotificationText = ({String title, String? body});

/// The Indonesian label of each push category in the settings.
const notificationCategoryLabels = <NotificationCategory, String>{
  NotificationCategory.billing: 'Tagihan dan pengingat',
  NotificationCategory.paymentStatus: 'Status pembayaran',
  NotificationCategory.complaintProgress: 'Perkembangan keluhan',
  NotificationCategory.newComplaint: 'Keluhan baru',
  NotificationCategory.receiptUpload: 'Bukti transfer baru',
  NotificationCategory.overdueBill: 'Tagihan terlambat',
  NotificationCategory.accountActivity: 'Aktivitas akun',
};

/// The short label of the kind of a notification, shown above its title.
String notificationTypeLabel(NotificationType type) => switch (type) {
  NotificationType.billIssued ||
  NotificationType.dueDateReminder ||
  NotificationType.billOverdue => 'Tagihan',
  NotificationType.paymentStatusChanged ||
  NotificationType.receiptUploaded ||
  NotificationType.cashPaymentRecorded => 'Pembayaran',
  NotificationType.complaintStatusChanged ||
  NotificationType.complaintSubmitted => 'Keluhan',
  NotificationType.tenantActivated ||
  NotificationType.managerActivated => 'Akun',
  _ => throw ArgumentError.value(type, 'type', 'Unknown notification type'),
};

/// The title and the line under the title of [n], as the role reads it.
/// [forManagement] is true for the Owner and the Manager, false for a Tenant.
NotificationText notificationText(
  Notification n, {
  required bool forManagement,
}) => switch (n.type) {
  NotificationType.billIssued => (
    title: 'Tagihan baru terbit',
    body: _billLine(n.rentBill),
  ),
  NotificationType.dueDateReminder => (
    title: 'Tagihan hampir jatuh tempo',
    body: _billLine(n.rentBill),
  ),
  NotificationType.billOverdue when forManagement => _overdueForManagement(n),
  NotificationType.billOverdue => _overdueForTenant(n),
  NotificationType.paymentStatusChanged => _paymentChanged(n.rentBill),
  NotificationType.complaintStatusChanged => _complaintChanged(n.complaint),
  NotificationType.complaintSubmitted => _complaintSubmitted(n),
  NotificationType.receiptUploaded => _receiptUploaded(n),
  NotificationType.cashPaymentRecorded => _cashPaymentRecorded(n),
  NotificationType.tenantActivated => _tenantActivated(n),
  NotificationType.managerActivated => _managerActivated(n),
  _ => throw ArgumentError.value(n.type, 'type', 'Unknown notification type'),
};

String _period(NotificationRentBill bill) =>
    '${formatDate(bill.periodStart)} - ${formatDate(bill.periodEnd)}';

/// The bill line that a tenant reads for a bill that is issued or due soon.
String? _billLine(NotificationRentBill? bill) => bill == null
    ? null
    : 'Tagihan ${_period(bill)} sebesar ${formatRupiah(bill.amount)}, '
          'jatuh tempo ${formatDate(bill.dueDate)}.';

NotificationText _overdueForTenant(Notification n) {
  final bill = n.rentBill;
  return (
    title: 'Tagihan lewat jatuh tempo',
    body: bill == null
        ? null
        : 'Tagihan ${_period(bill)} sebesar ${formatRupiah(bill.amount)} '
              'terlambat ${bill.daysOverdue} hari.',
  );
}

NotificationText _overdueForManagement(Notification n) {
  final bill = n.rentBill;
  return (
    title: '${n.tenant?.name ?? 'Penyewa'} terlambat membayar',
    body: _sentence([
      _roomOf(n),
      if (bill != null) formatRupiah(bill.amount),
      if (bill != null) 'terlambat ${bill.daysOverdue} hari',
    ]),
  );
}

NotificationText _paymentChanged(NotificationRentBill? bill) {
  if (bill == null) return (title: 'Status pembayaran diubah', body: null);
  final reason = bill.reason;
  final method = bill.paymentMethod;
  return switch (bill.paymentStatus) {
    PaymentStatus.paid => (
      title: 'Pembayaran lunas',
      body:
          'Tagihan ${_period(bill)} sebesar ${formatRupiah(bill.amount)} '
          'lunas${method == null ? '' : ' (${paymentMethodLabels[method]})'}.',
    ),
    PaymentStatus.rejected => (
      title: 'Bukti pembayaran ditolak',
      body: reason == null ? null : 'Alasan: $reason',
    ),
    _ => (
      title: 'Status pembayaran diubah',
      body:
          'Tagihan ${_period(bill)} kini '
          '${paymentStatusStyles[bill.paymentStatus]!.label}.'
          '${reason == null ? '' : ' Alasan: $reason'}',
    ),
  };
}

NotificationText _complaintChanged(NotificationComplaint? complaint) {
  if (complaint == null) return (title: 'Status keluhan diubah', body: null);
  final label = complaintStatusStyles[complaint.status]!.label;
  return (
    title: 'Keluhan ${label.toLowerCase()}',
    body: complaint.handlingNote ?? complaint.description,
  );
}

NotificationText _complaintSubmitted(Notification n) {
  final complaint = n.complaint;
  final category = complaint?.category;
  final urgency = complaint?.urgency;
  return (
    title: 'Keluhan baru',
    body: _joined([
      _roomOf(n),
      complaint?.description,
      if (category != null && urgency != null)
        '$category · urgensi ${complaintUrgencyStyles[urgency]!.label}',
    ]),
  );
}

NotificationText _receiptUploaded(Notification n) {
  final bill = n.rentBill;
  return (
    title: '${n.tenant?.name ?? 'Penyewa'} mengunggah bukti transfer',
    body: _sentence([
      _roomOf(n),
      if (bill != null) 'tagihan ${_period(bill)} ${formatRupiah(bill.amount)}',
    ]),
  );
}

NotificationText _cashPaymentRecorded(Notification n) {
  final bill = n.rentBill;
  return (
    title: '${n.actorName ?? 'Pengelola'} mencatat pembayaran tunai',
    body: _sentence([
      n.tenant?.name,
      _roomOf(n),
      if (bill != null) formatRupiah(bill.amount),
    ]),
  );
}

NotificationText _tenantActivated(Notification n) => (
  title: '${n.tenant?.name ?? 'Penyewa'} mengaktifkan akun',
  body: _sentence([_roomOf(n), n.property?.name]),
);

NotificationText _managerActivated(Notification n) {
  final property = n.property;
  return (
    title: '${n.actorName ?? 'Pengelola'} mengaktifkan akun pengelola',
    body: property == null ? null : 'Ia kini dapat mengelola ${property.name}.',
  );
}

String? _roomOf(Notification n) {
  final room = n.room;
  return room == null ? null : 'Kamar ${room.number}';
}

/// The non-empty [parts] joined with a middle dot, or null when none is left.
String? _joined(Iterable<String?> parts) {
  final shown = parts.nonNulls.toList();
  return shown.isEmpty ? null : shown.join(' · ');
}

/// [_joined] as a sentence that ends with a full stop.
String? _sentence(Iterable<String?> parts) {
  final line = _joined(parts);
  return line == null ? null : '$line.';
}
