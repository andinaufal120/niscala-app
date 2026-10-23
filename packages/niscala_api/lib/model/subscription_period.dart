//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// How often a paid plan is billed.
class SubscriptionPeriod {
  /// Instantiate a new enum with the provided [value].
  const SubscriptionPeriod._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const monthly = SubscriptionPeriod._(r'monthly');
  static const yearly = SubscriptionPeriod._(r'yearly');

  /// List of all possible values in this [enum][SubscriptionPeriod].
  static const values = <SubscriptionPeriod>[
    monthly,
    yearly,
  ];

  static SubscriptionPeriod? fromJson(dynamic value) => SubscriptionPeriodTypeTransformer().decode(value);

  static List<SubscriptionPeriod> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionPeriod>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionPeriod.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SubscriptionPeriod] to String,
/// and [decode] dynamic data back to [SubscriptionPeriod].
class SubscriptionPeriodTypeTransformer {
  factory SubscriptionPeriodTypeTransformer() => _instance ??= const SubscriptionPeriodTypeTransformer._();

  const SubscriptionPeriodTypeTransformer._();

  String encode(SubscriptionPeriod data) => data.value;

  /// Decodes a [dynamic value][data] to a SubscriptionPeriod.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SubscriptionPeriod? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'monthly': return SubscriptionPeriod.monthly;
        case r'yearly': return SubscriptionPeriod.yearly;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SubscriptionPeriodTypeTransformer] instance.
  static SubscriptionPeriodTypeTransformer? _instance;
}

