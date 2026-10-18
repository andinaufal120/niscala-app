//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Whether the Tenant has activated their account through the invitation.
class TenantAccountStatus {
  /// Instantiate a new enum with the provided [value].
  const TenantAccountStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const notActivated = TenantAccountStatus._(r'notActivated');
  static const active = TenantAccountStatus._(r'active');

  /// List of all possible values in this [enum][TenantAccountStatus].
  static const values = <TenantAccountStatus>[
    notActivated,
    active,
  ];

  static TenantAccountStatus? fromJson(dynamic value) => TenantAccountStatusTypeTransformer().decode(value);

  static List<TenantAccountStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantAccountStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantAccountStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TenantAccountStatus] to String,
/// and [decode] dynamic data back to [TenantAccountStatus].
class TenantAccountStatusTypeTransformer {
  factory TenantAccountStatusTypeTransformer() => _instance ??= const TenantAccountStatusTypeTransformer._();

  const TenantAccountStatusTypeTransformer._();

  String encode(TenantAccountStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a TenantAccountStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TenantAccountStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'notActivated': return TenantAccountStatus.notActivated;
        case r'active': return TenantAccountStatus.active;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [TenantAccountStatusTypeTransformer] instance.
  static TenantAccountStatusTypeTransformer? _instance;
}

