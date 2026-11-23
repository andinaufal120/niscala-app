//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class EmergencyContact {
  /// Returns a new [EmergencyContact] instance.
  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  String name;

  /// Indonesian mobile number; returned as digits starting with 08.
  String phone;

  String relationship;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EmergencyContact &&
    other.name == name &&
    other.phone == phone &&
    other.relationship == relationship;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (phone.hashCode) +
    (relationship.hashCode);

  @override
  String toString() => 'EmergencyContact[name=$name, phone=$phone, relationship=$relationship]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'phone'] = this.phone;
      json[r'relationship'] = this.relationship;
    return json;
  }

  /// Returns a new [EmergencyContact] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EmergencyContact? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "EmergencyContact[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "EmergencyContact[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return EmergencyContact(
        name: mapValueOfType<String>(json, r'name')!,
        phone: mapValueOfType<String>(json, r'phone')!,
        relationship: mapValueOfType<String>(json, r'relationship')!,
      );
    }
    return null;
  }

  static List<EmergencyContact> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EmergencyContact>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmergencyContact.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EmergencyContact> mapFromJson(dynamic json) {
    final map = <String, EmergencyContact>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EmergencyContact.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EmergencyContact-objects as value to a dart map
  static Map<String, List<EmergencyContact>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EmergencyContact>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EmergencyContact.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'phone',
    'relationship',
  };
}

