//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class AuthTokens {
  /// Returns a new [AuthTokens] instance.
  AuthTokens({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.tokenType,
  });

  String accessToken;

  /// Lifetime of the access token.
  ///
  /// Maximum value: 900
  int expiresIn;

  String refreshToken;

  AuthTokensTokenTypeEnum tokenType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthTokens &&
    other.accessToken == accessToken &&
    other.expiresIn == expiresIn &&
    other.refreshToken == refreshToken &&
    other.tokenType == tokenType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessToken.hashCode) +
    (expiresIn.hashCode) +
    (refreshToken.hashCode) +
    (tokenType.hashCode);

  @override
  String toString() => 'AuthTokens[accessToken=$accessToken, expiresIn=$expiresIn, refreshToken=$refreshToken, tokenType=$tokenType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accessToken'] = this.accessToken;
      json[r'expiresIn'] = this.expiresIn;
      json[r'refreshToken'] = this.refreshToken;
      json[r'tokenType'] = this.tokenType;
    return json;
  }

  /// Returns a new [AuthTokens] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthTokens? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuthTokens[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuthTokens[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthTokens(
        accessToken: mapValueOfType<String>(json, r'accessToken')!,
        expiresIn: mapValueOfType<int>(json, r'expiresIn')!,
        refreshToken: mapValueOfType<String>(json, r'refreshToken')!,
        tokenType: AuthTokensTokenTypeEnum.fromJson(json[r'tokenType'])!,
      );
    }
    return null;
  }

  static List<AuthTokens> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokens>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokens.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthTokens> mapFromJson(dynamic json) {
    final map = <String, AuthTokens>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthTokens.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthTokens-objects as value to a dart map
  static Map<String, List<AuthTokens>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthTokens>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthTokens.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accessToken',
    'expiresIn',
    'refreshToken',
    'tokenType',
  };
}


class AuthTokensTokenTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const AuthTokensTokenTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bearer = AuthTokensTokenTypeEnum._(r'bearer');

  /// List of all possible values in this [enum][AuthTokensTokenTypeEnum].
  static const values = <AuthTokensTokenTypeEnum>[
    bearer,
  ];

  static AuthTokensTokenTypeEnum? fromJson(dynamic value) => AuthTokensTokenTypeEnumTypeTransformer().decode(value);

  static List<AuthTokensTokenTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthTokensTokenTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthTokensTokenTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AuthTokensTokenTypeEnum] to String,
/// and [decode] dynamic data back to [AuthTokensTokenTypeEnum].
class AuthTokensTokenTypeEnumTypeTransformer {
  factory AuthTokensTokenTypeEnumTypeTransformer() => _instance ??= const AuthTokensTokenTypeEnumTypeTransformer._();

  const AuthTokensTokenTypeEnumTypeTransformer._();

  String encode(AuthTokensTokenTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AuthTokensTokenTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AuthTokensTokenTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'bearer': return AuthTokensTokenTypeEnum.bearer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AuthTokensTokenTypeEnumTypeTransformer] instance.
  static AuthTokensTokenTypeEnumTypeTransformer? _instance;
}


