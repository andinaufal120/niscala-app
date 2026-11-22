//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class InvitationPasswordActivationInput {
  /// Returns a new [InvitationPasswordActivationInput] instance.
  InvitationPasswordActivationInput({
    required this.device,
    this.email,
    this.emergencyContacts = const [],
    required this.name,
    required this.password,
    required this.token,
  });

  DeviceInfo device;

  String? email;

  List<EmergencyContact>? emergencyContacts;

  String name;

  /// 8 to 128 characters; not trimmed.
  String password;

  String token;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitationPasswordActivationInput &&
    other.device == device &&
    other.email == email &&
    _deepEquality.equals(other.emergencyContacts, emergencyContacts) &&
    other.name == name &&
    other.password == password &&
    other.token == token;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (device.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (emergencyContacts == null ? 0 : emergencyContacts!.hashCode) +
    (name.hashCode) +
    (password.hashCode) +
    (token.hashCode);

  @override
  String toString() => 'InvitationPasswordActivationInput[device=$device, email=$email, emergencyContacts=$emergencyContacts, name=$name, password=$password, token=$token]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'device'] = this.device;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.emergencyContacts != null) {
      json[r'emergencyContacts'] = this.emergencyContacts;
    } else {
      json[r'emergencyContacts'] = null;
    }
      json[r'name'] = this.name;
      json[r'password'] = this.password;
      json[r'token'] = this.token;
    return json;
  }

  /// Returns a new [InvitationPasswordActivationInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitationPasswordActivationInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvitationPasswordActivationInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvitationPasswordActivationInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvitationPasswordActivationInput(
        device: DeviceInfo.fromJson(json[r'device'])!,
        email: mapValueOfType<String>(json, r'email'),
        emergencyContacts: EmergencyContact.listFromJson(json[r'emergencyContacts']),
        name: mapValueOfType<String>(json, r'name')!,
        password: mapValueOfType<String>(json, r'password')!,
        token: mapValueOfType<String>(json, r'token')!,
      );
    }
    return null;
  }

  static List<InvitationPasswordActivationInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationPasswordActivationInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationPasswordActivationInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitationPasswordActivationInput> mapFromJson(dynamic json) {
    final map = <String, InvitationPasswordActivationInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitationPasswordActivationInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitationPasswordActivationInput-objects as value to a dart map
  static Map<String, List<InvitationPasswordActivationInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitationPasswordActivationInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitationPasswordActivationInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'device',
    'name',
    'password',
    'token',
  };
}

