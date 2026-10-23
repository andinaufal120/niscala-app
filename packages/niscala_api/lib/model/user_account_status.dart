//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Status of an account as shown to an Admin.
class UserAccountStatus {
  /// Instantiate a new enum with the provided [value].
  const UserAccountStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const active = UserAccountStatus._(r'active');
  static const inactive = UserAccountStatus._(r'inactive');
  static const deleted = UserAccountStatus._(r'deleted');

  /// List of all possible values in this [enum][UserAccountStatus].
  static const values = <UserAccountStatus>[
    active,
    inactive,
    deleted,
  ];

  static UserAccountStatus? fromJson(dynamic value) => UserAccountStatusTypeTransformer().decode(value);

  static List<UserAccountStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserAccountStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserAccountStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserAccountStatus] to String,
/// and [decode] dynamic data back to [UserAccountStatus].
class UserAccountStatusTypeTransformer {
  factory UserAccountStatusTypeTransformer() => _instance ??= const UserAccountStatusTypeTransformer._();

  const UserAccountStatusTypeTransformer._();

  String encode(UserAccountStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a UserAccountStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserAccountStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'active': return UserAccountStatus.active;
        case r'inactive': return UserAccountStatus.inactive;
        case r'deleted': return UserAccountStatus.deleted;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserAccountStatusTypeTransformer] instance.
  static UserAccountStatusTypeTransformer? _instance;
}

