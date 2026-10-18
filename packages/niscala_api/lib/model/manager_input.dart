//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ManagerInput {
  /// Returns a new [ManagerInput] instance.
  ManagerInput({
    required this.name,
    required this.phone,
    this.propertyIds = const [],
  });

  String name;

  /// Indonesian mobile number; returned as digits starting with 08.
  String phone;

  /// Properties of the Owner the Manager may access; at least one, no duplicates.
  List<String> propertyIds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ManagerInput &&
    other.name == name &&
    other.phone == phone &&
    _deepEquality.equals(other.propertyIds, propertyIds);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (phone.hashCode) +
    (propertyIds.hashCode);

  @override
  String toString() => 'ManagerInput[name=$name, phone=$phone, propertyIds=$propertyIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'phone'] = this.phone;
      json[r'propertyIds'] = this.propertyIds;
    return json;
  }

  /// Returns a new [ManagerInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ManagerInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ManagerInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ManagerInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ManagerInput(
        name: mapValueOfType<String>(json, r'name')!,
        phone: mapValueOfType<String>(json, r'phone')!,
        propertyIds: json[r'propertyIds'] is Iterable
            ? (json[r'propertyIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<ManagerInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ManagerInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ManagerInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ManagerInput> mapFromJson(dynamic json) {
    final map = <String, ManagerInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ManagerInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ManagerInput-objects as value to a dart map
  static Map<String, List<ManagerInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ManagerInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ManagerInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'phone',
    'propertyIds',
  };
}

