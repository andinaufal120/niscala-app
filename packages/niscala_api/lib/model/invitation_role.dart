//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// The role an invitation grants.
class InvitationRole {
  /// Instantiate a new enum with the provided [value].
  const InvitationRole._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const tenant = InvitationRole._(r'tenant');
  static const manager = InvitationRole._(r'manager');

  /// List of all possible values in this [enum][InvitationRole].
  static const values = <InvitationRole>[
    tenant,
    manager,
  ];

  static InvitationRole? fromJson(dynamic value) => InvitationRoleTypeTransformer().decode(value);

  static List<InvitationRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InvitationRole] to String,
/// and [decode] dynamic data back to [InvitationRole].
class InvitationRoleTypeTransformer {
  factory InvitationRoleTypeTransformer() => _instance ??= const InvitationRoleTypeTransformer._();

  const InvitationRoleTypeTransformer._();

  String encode(InvitationRole data) => data.value;

  /// Decodes a [dynamic value][data] to a InvitationRole.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InvitationRole? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'tenant': return InvitationRole.tenant;
        case r'manager': return InvitationRole.manager;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [InvitationRoleTypeTransformer] instance.
  static InvitationRoleTypeTransformer? _instance;
}

