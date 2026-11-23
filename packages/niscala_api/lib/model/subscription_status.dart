//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Whether a paid period is running.
class SubscriptionStatus {
  /// Instantiate a new enum with the provided [value].
  const SubscriptionStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const free = SubscriptionStatus._(r'free');
  static const active = SubscriptionStatus._(r'active');

  /// List of all possible values in this [enum][SubscriptionStatus].
  static const values = <SubscriptionStatus>[
    free,
    active,
  ];

  static SubscriptionStatus? fromJson(dynamic value) => SubscriptionStatusTypeTransformer().decode(value);

  static List<SubscriptionStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SubscriptionStatus] to String,
/// and [decode] dynamic data back to [SubscriptionStatus].
class SubscriptionStatusTypeTransformer {
  factory SubscriptionStatusTypeTransformer() => _instance ??= const SubscriptionStatusTypeTransformer._();

  const SubscriptionStatusTypeTransformer._();

  String encode(SubscriptionStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a SubscriptionStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SubscriptionStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'free': return SubscriptionStatus.free;
        case r'active': return SubscriptionStatus.active;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SubscriptionStatusTypeTransformer] instance.
  static SubscriptionStatusTypeTransformer? _instance;
}

