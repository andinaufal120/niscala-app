//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Manager {
  /// Returns a new [Manager] instance.
  Manager({
    required this.accountStatus,
    required this.email,
    required this.id,
    required this.invitation,
    required this.name,
    required this.phone,
    this.properties = const [],
  });

  ManagerAccountStatus accountStatus;

  String? email;

  String id;

  ManagerInvitation? invitation;

  String name;

  /// Indonesian mobile number; returned as digits starting with 08.
  String phone;

  List<ManagerProperty> properties;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Manager &&
    other.accountStatus == accountStatus &&
    other.email == email &&
    other.id == id &&
    other.invitation == invitation &&
    other.name == name &&
    other.phone == phone &&
    _deepEquality.equals(other.properties, properties);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accountStatus.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (id.hashCode) +
    (invitation == null ? 0 : invitation!.hashCode) +
    (name.hashCode) +
    (phone.hashCode) +
    (properties.hashCode);

  @override
  String toString() => 'Manager[accountStatus=$accountStatus, email=$email, id=$id, invitation=$invitation, name=$name, phone=$phone, properties=$properties]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accountStatus'] = this.accountStatus;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'id'] = this.id;
    if (this.invitation != null) {
      json[r'invitation'] = this.invitation;
    } else {
      json[r'invitation'] = null;
    }
      json[r'name'] = this.name;
      json[r'phone'] = this.phone;
      json[r'properties'] = this.properties;
    return json;
  }

  /// Returns a new [Manager] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Manager? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Manager[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Manager[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Manager(
        accountStatus: ManagerAccountStatus.fromJson(json[r'accountStatus'])!,
        email: mapValueOfType<String>(json, r'email'),
        id: mapValueOfType<String>(json, r'id')!,
        invitation: ManagerInvitation.fromJson(json[r'invitation']),
        name: mapValueOfType<String>(json, r'name')!,
        phone: mapValueOfType<String>(json, r'phone')!,
        properties: ManagerProperty.listFromJson(json[r'properties']),
      );
    }
    return null;
  }

  static List<Manager> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Manager>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Manager.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Manager> mapFromJson(dynamic json) {
    final map = <String, Manager>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Manager.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Manager-objects as value to a dart map
  static Map<String, List<Manager>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Manager>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Manager.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountStatus',
    'email',
    'id',
    'invitation',
    'name',
    'phone',
    'properties',
  };
}

