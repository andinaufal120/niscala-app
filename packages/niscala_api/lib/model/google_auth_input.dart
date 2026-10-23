//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class GoogleAuthInput {
  /// Returns a new [GoogleAuthInput] instance.
  GoogleAuthInput({
    required this.device,
    required this.idToken,
  });

  DeviceInfo device;

  String idToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GoogleAuthInput &&
    other.device == device &&
    other.idToken == idToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (device.hashCode) +
    (idToken.hashCode);

  @override
  String toString() => 'GoogleAuthInput[device=$device, idToken=$idToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'device'] = this.device;
      json[r'idToken'] = this.idToken;
    return json;
  }

  /// Returns a new [GoogleAuthInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GoogleAuthInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GoogleAuthInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GoogleAuthInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GoogleAuthInput(
        device: DeviceInfo.fromJson(json[r'device'])!,
        idToken: mapValueOfType<String>(json, r'idToken')!,
      );
    }
    return null;
  }

  static List<GoogleAuthInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GoogleAuthInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GoogleAuthInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GoogleAuthInput> mapFromJson(dynamic json) {
    final map = <String, GoogleAuthInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GoogleAuthInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GoogleAuthInput-objects as value to a dart map
  static Map<String, List<GoogleAuthInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GoogleAuthInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GoogleAuthInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'device',
    'idToken',
  };
}

