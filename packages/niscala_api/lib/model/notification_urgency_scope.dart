//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Which complaint urgencies are pushed for the newComplaint category.
class NotificationUrgencyScope {
  /// Instantiate a new enum with the provided [value].
  const NotificationUrgencyScope._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const allUrgencies = NotificationUrgencyScope._(r'allUrgencies');
  static const highOnly = NotificationUrgencyScope._(r'highOnly');

  /// List of all possible values in this [enum][NotificationUrgencyScope].
  static const values = <NotificationUrgencyScope>[
    allUrgencies,
    highOnly,
  ];

  static NotificationUrgencyScope? fromJson(dynamic value) => NotificationUrgencyScopeTypeTransformer().decode(value);

  static List<NotificationUrgencyScope> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationUrgencyScope>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationUrgencyScope.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationUrgencyScope] to String,
/// and [decode] dynamic data back to [NotificationUrgencyScope].
class NotificationUrgencyScopeTypeTransformer {
  factory NotificationUrgencyScopeTypeTransformer() => _instance ??= const NotificationUrgencyScopeTypeTransformer._();

  const NotificationUrgencyScopeTypeTransformer._();

  String encode(NotificationUrgencyScope data) => data.value;

  /// Decodes a [dynamic value][data] to a NotificationUrgencyScope.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationUrgencyScope? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'allUrgencies': return NotificationUrgencyScope.allUrgencies;
        case r'highOnly': return NotificationUrgencyScope.highOnly;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotificationUrgencyScopeTypeTransformer] instance.
  static NotificationUrgencyScopeTypeTransformer? _instance;
}

