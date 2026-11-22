//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// How often a lease is billed.
class BillingCycle {
  /// Instantiate a new enum with the provided [value].
  const BillingCycle._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const weekly = BillingCycle._(r'weekly');
  static const monthly = BillingCycle._(r'monthly');
  static const quarterly = BillingCycle._(r'quarterly');
  static const semiannual = BillingCycle._(r'semiannual');
  static const annual = BillingCycle._(r'annual');

  /// List of all possible values in this [enum][BillingCycle].
  static const values = <BillingCycle>[
    weekly,
    monthly,
    quarterly,
    semiannual,
    annual,
  ];

  static BillingCycle? fromJson(dynamic value) => BillingCycleTypeTransformer().decode(value);

  static List<BillingCycle> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BillingCycle>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BillingCycle.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BillingCycle] to String,
/// and [decode] dynamic data back to [BillingCycle].
class BillingCycleTypeTransformer {
  factory BillingCycleTypeTransformer() => _instance ??= const BillingCycleTypeTransformer._();

  const BillingCycleTypeTransformer._();

  String encode(BillingCycle data) => data.value;

  /// Decodes a [dynamic value][data] to a BillingCycle.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BillingCycle? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'weekly': return BillingCycle.weekly;
        case r'monthly': return BillingCycle.monthly;
        case r'quarterly': return BillingCycle.quarterly;
        case r'semiannual': return BillingCycle.semiannual;
        case r'annual': return BillingCycle.annual;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BillingCycleTypeTransformer] instance.
  static BillingCycleTypeTransformer? _instance;
}

