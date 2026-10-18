//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Whether a room currently has an active lease.
class Occupancy {
  /// Instantiate a new enum with the provided [value].
  const Occupancy._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const occupied = Occupancy._(r'occupied');
  static const vacant = Occupancy._(r'vacant');

  /// List of all possible values in this [enum][Occupancy].
  static const values = <Occupancy>[
    occupied,
    vacant,
  ];

  static Occupancy? fromJson(dynamic value) => OccupancyTypeTransformer().decode(value);

  static List<Occupancy> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Occupancy>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Occupancy.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Occupancy] to String,
/// and [decode] dynamic data back to [Occupancy].
class OccupancyTypeTransformer {
  factory OccupancyTypeTransformer() => _instance ??= const OccupancyTypeTransformer._();

  const OccupancyTypeTransformer._();

  String encode(Occupancy data) => data.value;

  /// Decodes a [dynamic value][data] to a Occupancy.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Occupancy? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'occupied': return Occupancy.occupied;
        case r'vacant': return Occupancy.vacant;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OccupancyTypeTransformer] instance.
  static OccupancyTypeTransformer? _instance;
}

