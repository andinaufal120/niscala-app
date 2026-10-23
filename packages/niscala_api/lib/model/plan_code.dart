//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Subscription plans.
class PlanCode {
  /// Instantiate a new enum with the provided [value].
  const PlanCode._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const free = PlanCode._(r'free');
  static const basic = PlanCode._(r'basic');
  static const pro = PlanCode._(r'pro');

  /// List of all possible values in this [enum][PlanCode].
  static const values = <PlanCode>[
    free,
    basic,
    pro,
  ];

  static PlanCode? fromJson(dynamic value) => PlanCodeTypeTransformer().decode(value);

  static List<PlanCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlanCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlanCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlanCode] to String,
/// and [decode] dynamic data back to [PlanCode].
class PlanCodeTypeTransformer {
  factory PlanCodeTypeTransformer() => _instance ??= const PlanCodeTypeTransformer._();

  const PlanCodeTypeTransformer._();

  String encode(PlanCode data) => data.value;

  /// Decodes a [dynamic value][data] to a PlanCode.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlanCode? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'free': return PlanCode.free;
        case r'basic': return PlanCode.basic;
        case r'pro': return PlanCode.pro;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PlanCodeTypeTransformer] instance.
  static PlanCodeTypeTransformer? _instance;
}

