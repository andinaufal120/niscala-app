//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// How a session was started.
class LoginMethod {
  /// Instantiate a new enum with the provided [value].
  const LoginMethod._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const google = LoginMethod._(r'google');
  static const password = LoginMethod._(r'password');

  /// List of all possible values in this [enum][LoginMethod].
  static const values = <LoginMethod>[
    google,
    password,
  ];

  static LoginMethod? fromJson(dynamic value) => LoginMethodTypeTransformer().decode(value);

  static List<LoginMethod> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoginMethod>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoginMethod.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LoginMethod] to String,
/// and [decode] dynamic data back to [LoginMethod].
class LoginMethodTypeTransformer {
  factory LoginMethodTypeTransformer() => _instance ??= const LoginMethodTypeTransformer._();

  const LoginMethodTypeTransformer._();

  String encode(LoginMethod data) => data.value;

  /// Decodes a [dynamic value][data] to a LoginMethod.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LoginMethod? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'google': return LoginMethod.google;
        case r'password': return LoginMethod.password;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LoginMethodTypeTransformer] instance.
  static LoginMethodTypeTransformer? _instance;
}

