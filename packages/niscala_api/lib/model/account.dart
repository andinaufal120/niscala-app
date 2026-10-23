//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Account {
  /// Returns a new [Account] instance.
  Account({
    required this.email,
    required this.emailVerified,
    required this.googleEmail,
    required this.hasPassword,
    required this.id,
    required this.name,
    required this.role,
  });

  String email;

  bool emailVerified;

  String? googleEmail;

  bool hasPassword;

  String id;

  String name;

  UserRole role;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Account &&
    other.email == email &&
    other.emailVerified == emailVerified &&
    other.googleEmail == googleEmail &&
    other.hasPassword == hasPassword &&
    other.id == id &&
    other.name == name &&
    other.role == role;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email.hashCode) +
    (emailVerified.hashCode) +
    (googleEmail == null ? 0 : googleEmail!.hashCode) +
    (hasPassword.hashCode) +
    (id.hashCode) +
    (name.hashCode) +
    (role.hashCode);

  @override
  String toString() => 'Account[email=$email, emailVerified=$emailVerified, googleEmail=$googleEmail, hasPassword=$hasPassword, id=$id, name=$name, role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email'] = this.email;
      json[r'emailVerified'] = this.emailVerified;
    if (this.googleEmail != null) {
      json[r'googleEmail'] = this.googleEmail;
    } else {
      json[r'googleEmail'] = null;
    }
      json[r'hasPassword'] = this.hasPassword;
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'role'] = this.role;
    return json;
  }

  /// Returns a new [Account] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Account? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Account[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Account[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Account(
        email: mapValueOfType<String>(json, r'email')!,
        emailVerified: mapValueOfType<bool>(json, r'emailVerified')!,
        googleEmail: mapValueOfType<String>(json, r'googleEmail'),
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        role: UserRole.fromJson(json[r'role'])!,
      );
    }
    return null;
  }

  static List<Account> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Account>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Account.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Account> mapFromJson(dynamic json) {
    final map = <String, Account>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Account.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Account-objects as value to a dart map
  static Map<String, List<Account>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Account>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Account.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'emailVerified',
    'googleEmail',
    'hasPassword',
    'id',
    'name',
    'role',
  };
}

