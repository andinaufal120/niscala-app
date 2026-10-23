//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PasswordResetInput {
  /// Returns a new [PasswordResetInput] instance.
  PasswordResetInput({
    required this.newPassword,
    required this.token,
  });

  /// 8 to 128 characters; not trimmed.
  String newPassword;

  String token;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PasswordResetInput &&
    other.newPassword == newPassword &&
    other.token == token;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (newPassword.hashCode) +
    (token.hashCode);

  @override
  String toString() => 'PasswordResetInput[newPassword=$newPassword, token=$token]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'newPassword'] = this.newPassword;
      json[r'token'] = this.token;
    return json;
  }

  /// Returns a new [PasswordResetInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PasswordResetInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PasswordResetInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PasswordResetInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PasswordResetInput(
        newPassword: mapValueOfType<String>(json, r'newPassword')!,
        token: mapValueOfType<String>(json, r'token')!,
      );
    }
    return null;
  }

  static List<PasswordResetInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PasswordResetInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PasswordResetInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PasswordResetInput> mapFromJson(dynamic json) {
    final map = <String, PasswordResetInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PasswordResetInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PasswordResetInput-objects as value to a dart map
  static Map<String, List<PasswordResetInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PasswordResetInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PasswordResetInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'newPassword',
    'token',
  };
}

