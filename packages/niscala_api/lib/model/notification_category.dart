//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// A group of notification types with one push switch.
class NotificationCategory {
  /// Instantiate a new enum with the provided [value].
  const NotificationCategory._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const billing = NotificationCategory._(r'billing');
  static const paymentStatus = NotificationCategory._(r'paymentStatus');
  static const complaintProgress = NotificationCategory._(r'complaintProgress');
  static const newComplaint = NotificationCategory._(r'newComplaint');
  static const receiptUpload = NotificationCategory._(r'receiptUpload');
  static const overdueBill = NotificationCategory._(r'overdueBill');
  static const accountActivity = NotificationCategory._(r'accountActivity');

  /// List of all possible values in this [enum][NotificationCategory].
  static const values = <NotificationCategory>[
    billing,
    paymentStatus,
    complaintProgress,
    newComplaint,
    receiptUpload,
    overdueBill,
    accountActivity,
  ];

  static NotificationCategory? fromJson(dynamic value) => NotificationCategoryTypeTransformer().decode(value);

  static List<NotificationCategory> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationCategory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationCategory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationCategory] to String,
/// and [decode] dynamic data back to [NotificationCategory].
class NotificationCategoryTypeTransformer {
  factory NotificationCategoryTypeTransformer() => _instance ??= const NotificationCategoryTypeTransformer._();

  const NotificationCategoryTypeTransformer._();

  String encode(NotificationCategory data) => data.value;

  /// Decodes a [dynamic value][data] to a NotificationCategory.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationCategory? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'billing': return NotificationCategory.billing;
        case r'paymentStatus': return NotificationCategory.paymentStatus;
        case r'complaintProgress': return NotificationCategory.complaintProgress;
        case r'newComplaint': return NotificationCategory.newComplaint;
        case r'receiptUpload': return NotificationCategory.receiptUpload;
        case r'overdueBill': return NotificationCategory.overdueBill;
        case r'accountActivity': return NotificationCategory.accountActivity;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotificationCategoryTypeTransformer] instance.
  static NotificationCategoryTypeTransformer? _instance;
}

