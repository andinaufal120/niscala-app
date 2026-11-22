//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// What an account may do.
class UserRole {
  /// Instantiate a new enum with the provided [value].
  const UserRole._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const tenant = UserRole._(r'tenant');
  static const owner = UserRole._(r'owner');
  static const manager = UserRole._(r'manager');
  static const admin = UserRole._(r'admin');

  /// List of all possible values in this [enum][UserRole].
  static const values = <UserRole>[
    tenant,
    owner,
    manager,
    admin,
  ];

  static UserRole? fromJson(dynamic value) => UserRoleTypeTransformer().decode(value);

  static List<UserRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserRole] to String,
/// and [decode] dynamic data back to [UserRole].
class UserRoleTypeTransformer {
  factory UserRoleTypeTransformer() => _instance ??= const UserRoleTypeTransformer._();

  const UserRoleTypeTransformer._();

  String encode(UserRole data) => data.value;

  /// Decodes a [dynamic value][data] to a UserRole.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserRole? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'tenant': return UserRole.tenant;
        case r'owner': return UserRole.owner;
        case r'manager': return UserRole.manager;
        case r'admin': return UserRole.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserRoleTypeTransformer] instance.
  static UserRoleTypeTransformer? _instance;
}

