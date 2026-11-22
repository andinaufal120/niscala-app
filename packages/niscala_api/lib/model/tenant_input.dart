//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class TenantInput {
  /// Returns a new [TenantInput] instance.
  TenantInput({
    this.emergencyContacts = const [],
    this.lease,
    required this.name,
    this.occupation,
    required this.phone,
  });

  /// 2 to 4 contacts. May be empty only while the Tenant's account is not activated; the Tenant then completes them during activation. Exactly 1 is rejected.
  List<EmergencyContact> emergencyContacts;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  LeaseInput? lease;

  String name;

  String? occupation;

  /// Indonesian mobile number; returned as digits starting with 08.
  String phone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantInput &&
    _deepEquality.equals(other.emergencyContacts, emergencyContacts) &&
    other.lease == lease &&
    other.name == name &&
    other.occupation == occupation &&
    other.phone == phone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (emergencyContacts.hashCode) +
    (lease == null ? 0 : lease!.hashCode) +
    (name.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (phone.hashCode);

  @override
  String toString() => 'TenantInput[emergencyContacts=$emergencyContacts, lease=$lease, name=$name, occupation=$occupation, phone=$phone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'emergencyContacts'] = this.emergencyContacts;
    if (this.lease != null) {
      json[r'lease'] = this.lease;
    } else {
      json[r'lease'] = null;
    }
      json[r'name'] = this.name;
    if (this.occupation != null) {
      json[r'occupation'] = this.occupation;
    } else {
      json[r'occupation'] = null;
    }
      json[r'phone'] = this.phone;
    return json;
  }

  /// Returns a new [TenantInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TenantInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TenantInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TenantInput(
        emergencyContacts: EmergencyContact.listFromJson(json[r'emergencyContacts']),
        lease: LeaseInput.fromJson(json[r'lease']),
        name: mapValueOfType<String>(json, r'name')!,
        occupation: mapValueOfType<String>(json, r'occupation'),
        phone: mapValueOfType<String>(json, r'phone')!,
      );
    }
    return null;
  }

  static List<TenantInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantInput> mapFromJson(dynamic json) {
    final map = <String, TenantInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantInput-objects as value to a dart map
  static Map<String, List<TenantInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'phone',
  };
}

