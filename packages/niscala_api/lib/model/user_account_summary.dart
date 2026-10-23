//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class UserAccountSummary {
  /// Returns a new [UserAccountSummary] instance.
  UserAccountSummary({
    required this.email,
    required this.id,
    required this.name,
    required this.role,
    required this.status,
  });

  String email;

  String id;

  String name;

  UserRole role;

  UserAccountStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserAccountSummary &&
    other.email == email &&
    other.id == id &&
    other.name == name &&
    other.role == role &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (id.hashCode) +
    (name.hashCode) +
    (role.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'UserAccountSummary[email=$email, id=$id, name=$name, role=$role, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'role'] = this.role;
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [UserAccountSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserAccountSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserAccountSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserAccountSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserAccountSummary(
        email: mapValueOfType<String>(json, r'email')!,
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        role: UserRole.fromJson(json[r'role'])!,
        status: UserAccountStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<UserAccountSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserAccountSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserAccountSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserAccountSummary> mapFromJson(dynamic json) {
    final map = <String, UserAccountSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserAccountSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserAccountSummary-objects as value to a dart map
  static Map<String, List<UserAccountSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserAccountSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserAccountSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'id',
    'name',
    'role',
    'status',
  };
}

