//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class InvitationGoogleActivationInput {
  /// Returns a new [InvitationGoogleActivationInput] instance.
  InvitationGoogleActivationInput({
    required this.device,
    this.emergencyContacts = const [],
    required this.idToken,
    required this.name,
    required this.token,
  });

  DeviceInfo device;

  List<EmergencyContact>? emergencyContacts;

  String idToken;

  String name;

  String token;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitationGoogleActivationInput &&
    other.device == device &&
    _deepEquality.equals(other.emergencyContacts, emergencyContacts) &&
    other.idToken == idToken &&
    other.name == name &&
    other.token == token;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (device.hashCode) +
    (emergencyContacts == null ? 0 : emergencyContacts!.hashCode) +
    (idToken.hashCode) +
    (name.hashCode) +
    (token.hashCode);

  @override
  String toString() => 'InvitationGoogleActivationInput[device=$device, emergencyContacts=$emergencyContacts, idToken=$idToken, name=$name, token=$token]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'device'] = this.device;
    if (this.emergencyContacts != null) {
      json[r'emergencyContacts'] = this.emergencyContacts;
    } else {
      json[r'emergencyContacts'] = null;
    }
      json[r'idToken'] = this.idToken;
      json[r'name'] = this.name;
      json[r'token'] = this.token;
    return json;
  }

  /// Returns a new [InvitationGoogleActivationInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitationGoogleActivationInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvitationGoogleActivationInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvitationGoogleActivationInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvitationGoogleActivationInput(
        device: DeviceInfo.fromJson(json[r'device'])!,
        emergencyContacts: EmergencyContact.listFromJson(json[r'emergencyContacts']),
        idToken: mapValueOfType<String>(json, r'idToken')!,
        name: mapValueOfType<String>(json, r'name')!,
        token: mapValueOfType<String>(json, r'token')!,
      );
    }
    return null;
  }

  static List<InvitationGoogleActivationInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationGoogleActivationInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationGoogleActivationInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitationGoogleActivationInput> mapFromJson(dynamic json) {
    final map = <String, InvitationGoogleActivationInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitationGoogleActivationInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitationGoogleActivationInput-objects as value to a dart map
  static Map<String, List<InvitationGoogleActivationInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitationGoogleActivationInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitationGoogleActivationInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'device',
    'idToken',
    'name',
    'token',
  };
}

