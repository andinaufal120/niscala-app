//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ManagerProperty {
  /// Returns a new [ManagerProperty] instance.
  ManagerProperty({
    required this.address,
    required this.id,
    required this.name,
  });

  String address;

  String id;

  String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ManagerProperty &&
    other.address == address &&
    other.id == id &&
    other.name == name;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (address.hashCode) +
    (id.hashCode) +
    (name.hashCode);

  @override
  String toString() => 'ManagerProperty[address=$address, id=$id, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'address'] = this.address;
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [ManagerProperty] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ManagerProperty? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ManagerProperty[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ManagerProperty[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ManagerProperty(
        address: mapValueOfType<String>(json, r'address')!,
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<ManagerProperty> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ManagerProperty>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ManagerProperty.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ManagerProperty> mapFromJson(dynamic json) {
    final map = <String, ManagerProperty>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ManagerProperty.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ManagerProperty-objects as value to a dart map
  static Map<String, List<ManagerProperty>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ManagerProperty>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ManagerProperty.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'address',
    'id',
    'name',
  };
}

