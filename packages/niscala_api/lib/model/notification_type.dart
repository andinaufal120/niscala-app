//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// The event a notification announces.
class NotificationType {
  /// Instantiate a new enum with the provided [value].
  const NotificationType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const billIssued = NotificationType._(r'billIssued');
  static const dueDateReminder = NotificationType._(r'dueDateReminder');
  static const billOverdue = NotificationType._(r'billOverdue');
  static const paymentStatusChanged = NotificationType._(r'paymentStatusChanged');
  static const complaintStatusChanged = NotificationType._(r'complaintStatusChanged');
  static const complaintSubmitted = NotificationType._(r'complaintSubmitted');
  static const receiptUploaded = NotificationType._(r'receiptUploaded');
  static const cashPaymentRecorded = NotificationType._(r'cashPaymentRecorded');
  static const tenantActivated = NotificationType._(r'tenantActivated');
  static const managerActivated = NotificationType._(r'managerActivated');

  /// List of all possible values in this [enum][NotificationType].
  static const values = <NotificationType>[
    billIssued,
    dueDateReminder,
    billOverdue,
    paymentStatusChanged,
    complaintStatusChanged,
    complaintSubmitted,
    receiptUploaded,
    cashPaymentRecorded,
    tenantActivated,
    managerActivated,
  ];

  static NotificationType? fromJson(dynamic value) => NotificationTypeTypeTransformer().decode(value);

  static List<NotificationType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationType] to String,
/// and [decode] dynamic data back to [NotificationType].
class NotificationTypeTypeTransformer {
  factory NotificationTypeTypeTransformer() => _instance ??= const NotificationTypeTypeTransformer._();

  const NotificationTypeTypeTransformer._();

  String encode(NotificationType data) => data.value;

  /// Decodes a [dynamic value][data] to a NotificationType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'billIssued': return NotificationType.billIssued;
        case r'dueDateReminder': return NotificationType.dueDateReminder;
        case r'billOverdue': return NotificationType.billOverdue;
        case r'paymentStatusChanged': return NotificationType.paymentStatusChanged;
        case r'complaintStatusChanged': return NotificationType.complaintStatusChanged;
        case r'complaintSubmitted': return NotificationType.complaintSubmitted;
        case r'receiptUploaded': return NotificationType.receiptUploaded;
        case r'cashPaymentRecorded': return NotificationType.cashPaymentRecorded;
        case r'tenantActivated': return NotificationType.tenantActivated;
        case r'managerActivated': return NotificationType.managerActivated;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotificationTypeTypeTransformer] instance.
  static NotificationTypeTypeTransformer? _instance;
}

