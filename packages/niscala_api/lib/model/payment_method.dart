//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// How a rent bill was paid.
class PaymentMethod {
  /// Instantiate a new enum with the provided [value].
  const PaymentMethod._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const transfer = PaymentMethod._(r'transfer');
  static const cash = PaymentMethod._(r'cash');

  /// List of all possible values in this [enum][PaymentMethod].
  static const values = <PaymentMethod>[
    transfer,
    cash,
  ];

  static PaymentMethod? fromJson(dynamic value) => PaymentMethodTypeTransformer().decode(value);

  static List<PaymentMethod> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentMethod>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentMethod.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentMethod] to String,
/// and [decode] dynamic data back to [PaymentMethod].
class PaymentMethodTypeTransformer {
  factory PaymentMethodTypeTransformer() => _instance ??= const PaymentMethodTypeTransformer._();

  const PaymentMethodTypeTransformer._();

  String encode(PaymentMethod data) => data.value;

  /// Decodes a [dynamic value][data] to a PaymentMethod.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentMethod? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'transfer': return PaymentMethod.transfer;
        case r'cash': return PaymentMethod.cash;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PaymentMethodTypeTransformer] instance.
  static PaymentMethodTypeTransformer? _instance;
}

