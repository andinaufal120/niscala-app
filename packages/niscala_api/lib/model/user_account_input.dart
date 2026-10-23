//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class UserAccountInput {
  /// Returns a new [UserAccountInput] instance.
  UserAccountInput({
    required this.email,
    required this.name,
    required this.status,
  });

  /// Compared case-insensitively. A value different from the current email starts a pending change; the current email cancels a pending one.
  String email;

  String name;

  EditableAccountStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserAccountInput &&
    other.email == email &&
    other.name == name &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (name.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'UserAccountInput[email=$email, name=$name, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'name'] = this.name;
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [UserAccountInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserAccountInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserAccountInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserAccountInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserAccountInput(
        email: mapValueOfType<String>(json, r'email')!,
        name: mapValueOfType<String>(json, r'name')!,
        status: EditableAccountStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<UserAccountInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserAccountInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserAccountInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserAccountInput> mapFromJson(dynamic json) {
    final map = <String, UserAccountInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserAccountInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserAccountInput-objects as value to a dart map
  static Map<String, List<UserAccountInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserAccountInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserAccountInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'name',
    'status',
  };
}

