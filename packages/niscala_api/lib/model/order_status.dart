//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Progress of a subscription order.
class OrderStatus {
  /// Instantiate a new enum with the provided [value].
  const OrderStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const awaitingPayment = OrderStatus._(r'awaitingPayment');
  static const succeeded = OrderStatus._(r'succeeded');
  static const failed = OrderStatus._(r'failed');
  static const expired = OrderStatus._(r'expired');

  /// List of all possible values in this [enum][OrderStatus].
  static const values = <OrderStatus>[
    awaitingPayment,
    succeeded,
    failed,
    expired,
  ];

  static OrderStatus? fromJson(dynamic value) => OrderStatusTypeTransformer().decode(value);

  static List<OrderStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OrderStatus] to String,
/// and [decode] dynamic data back to [OrderStatus].
class OrderStatusTypeTransformer {
  factory OrderStatusTypeTransformer() => _instance ??= const OrderStatusTypeTransformer._();

  const OrderStatusTypeTransformer._();

  String encode(OrderStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a OrderStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OrderStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'awaitingPayment': return OrderStatus.awaitingPayment;
        case r'succeeded': return OrderStatus.succeeded;
        case r'failed': return OrderStatus.failed;
        case r'expired': return OrderStatus.expired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OrderStatusTypeTransformer] instance.
  static OrderStatusTypeTransformer? _instance;
}

