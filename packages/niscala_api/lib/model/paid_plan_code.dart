//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Plans that can be bought.
class PaidPlanCode {
  /// Instantiate a new enum with the provided [value].
  const PaidPlanCode._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const basic = PaidPlanCode._(r'basic');
  static const pro = PaidPlanCode._(r'pro');

  /// List of all possible values in this [enum][PaidPlanCode].
  static const values = <PaidPlanCode>[
    basic,
    pro,
  ];

  static PaidPlanCode? fromJson(dynamic value) => PaidPlanCodeTypeTransformer().decode(value);

  static List<PaidPlanCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaidPlanCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaidPlanCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaidPlanCode] to String,
/// and [decode] dynamic data back to [PaidPlanCode].
class PaidPlanCodeTypeTransformer {
  factory PaidPlanCodeTypeTransformer() => _instance ??= const PaidPlanCodeTypeTransformer._();

  const PaidPlanCodeTypeTransformer._();

  String encode(PaidPlanCode data) => data.value;

  /// Decodes a [dynamic value][data] to a PaidPlanCode.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaidPlanCode? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'basic': return PaidPlanCode.basic;
        case r'pro': return PaidPlanCode.pro;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PaidPlanCodeTypeTransformer] instance.
  static PaidPlanCodeTypeTransformer? _instance;
}

