//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class CurrentLeaseProperty {
  /// Returns a new [CurrentLeaseProperty] instance.
  CurrentLeaseProperty({
    required this.address,
    required this.id,
    required this.name,
  });

  String address;

  String id;

  String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CurrentLeaseProperty &&
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
  String toString() => 'CurrentLeaseProperty[address=$address, id=$id, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'address'] = this.address;
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [CurrentLeaseProperty] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CurrentLeaseProperty? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CurrentLeaseProperty[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CurrentLeaseProperty[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CurrentLeaseProperty(
        address: mapValueOfType<String>(json, r'address')!,
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<CurrentLeaseProperty> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CurrentLeaseProperty>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CurrentLeaseProperty.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CurrentLeaseProperty> mapFromJson(dynamic json) {
    final map = <String, CurrentLeaseProperty>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CurrentLeaseProperty.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CurrentLeaseProperty-objects as value to a dart map
  static Map<String, List<CurrentLeaseProperty>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CurrentLeaseProperty>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CurrentLeaseProperty.listFromJson(entry.value, growable: growable,);
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

