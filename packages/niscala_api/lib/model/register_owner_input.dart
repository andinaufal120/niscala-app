//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class RegisterOwnerInput {
  /// Returns a new [RegisterOwnerInput] instance.
  RegisterOwnerInput({
    required this.device,
    required this.email,
    required this.name,
    required this.password,
  });

  DeviceInfo device;

  String email;

  String name;

  /// 8 to 128 characters; not trimmed.
  String password;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterOwnerInput &&
    other.device == device &&
    other.email == email &&
    other.name == name &&
    other.password == password;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (device.hashCode) +
    (email.hashCode) +
    (name.hashCode) +
    (password.hashCode);

  @override
  String toString() => 'RegisterOwnerInput[device=$device, email=$email, name=$name, password=$password]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'device'] = this.device;
      json[r'email'] = this.email;
      json[r'name'] = this.name;
      json[r'password'] = this.password;
    return json;
  }

  /// Returns a new [RegisterOwnerInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterOwnerInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RegisterOwnerInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RegisterOwnerInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RegisterOwnerInput(
        device: DeviceInfo.fromJson(json[r'device'])!,
        email: mapValueOfType<String>(json, r'email')!,
        name: mapValueOfType<String>(json, r'name')!,
        password: mapValueOfType<String>(json, r'password')!,
      );
    }
    return null;
  }

  static List<RegisterOwnerInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterOwnerInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterOwnerInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterOwnerInput> mapFromJson(dynamic json) {
    final map = <String, RegisterOwnerInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterOwnerInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterOwnerInput-objects as value to a dart map
  static Map<String, List<RegisterOwnerInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterOwnerInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterOwnerInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'device',
    'email',
    'name',
    'password',
  };
}

