//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class AuthSession {
  /// Returns a new [AuthSession] instance.
  AuthSession({
    required this.accessToken,
    required this.account,
    required this.expiresIn,
    required this.refreshToken,
    required this.tokenType,
  });

  String accessToken;

  Account account;

  /// Lifetime of the access token.
  ///
  /// Maximum value: 900
  int expiresIn;

  String refreshToken;

  AuthSessionTokenTypeEnum tokenType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthSession &&
    other.accessToken == accessToken &&
    other.account == account &&
    other.expiresIn == expiresIn &&
    other.refreshToken == refreshToken &&
    other.tokenType == tokenType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessToken.hashCode) +
    (account.hashCode) +
    (expiresIn.hashCode) +
    (refreshToken.hashCode) +
    (tokenType.hashCode);

  @override
  String toString() => 'AuthSession[accessToken=$accessToken, account=$account, expiresIn=$expiresIn, refreshToken=$refreshToken, tokenType=$tokenType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accessToken'] = this.accessToken;
      json[r'account'] = this.account;
      json[r'expiresIn'] = this.expiresIn;
      json[r'refreshToken'] = this.refreshToken;
      json[r'tokenType'] = this.tokenType;
    return json;
  }

  /// Returns a new [AuthSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuthSession[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuthSession[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthSession(
        accessToken: mapValueOfType<String>(json, r'accessToken')!,
        account: Account.fromJson(json[r'account'])!,
        expiresIn: mapValueOfType<int>(json, r'expiresIn')!,
        refreshToken: mapValueOfType<String>(json, r'refreshToken')!,
        tokenType: AuthSessionTokenTypeEnum.fromJson(json[r'tokenType'])!,
      );
    }
    return null;
  }

  static List<AuthSession> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthSession> mapFromJson(dynamic json) {
    final map = <String, AuthSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthSession-objects as value to a dart map
  static Map<String, List<AuthSession>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthSession.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accessToken',
    'account',
    'expiresIn',
    'refreshToken',
    'tokenType',
  };
}


class AuthSessionTokenTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const AuthSessionTokenTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bearer = AuthSessionTokenTypeEnum._(r'bearer');

  /// List of all possible values in this [enum][AuthSessionTokenTypeEnum].
  static const values = <AuthSessionTokenTypeEnum>[
    bearer,
  ];

  static AuthSessionTokenTypeEnum? fromJson(dynamic value) => AuthSessionTokenTypeEnumTypeTransformer().decode(value);

  static List<AuthSessionTokenTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthSessionTokenTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthSessionTokenTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthSessionTokenTypeEnum] to String,
/// and [decode] dynamic data back to [AuthSessionTokenTypeEnum].
class AuthSessionTokenTypeEnumTypeTransformer {
  factory AuthSessionTokenTypeEnumTypeTransformer() => _instance ??= const AuthSessionTokenTypeEnumTypeTransformer._();

  const AuthSessionTokenTypeEnumTypeTransformer._();

  String encode(AuthSessionTokenTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AuthSessionTokenTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthSessionTokenTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'bearer': return AuthSessionTokenTypeEnum.bearer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AuthSessionTokenTypeEnumTypeTransformer] instance.
  static AuthSessionTokenTypeEnumTypeTransformer? _instance;
}


