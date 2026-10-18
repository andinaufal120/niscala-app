//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PropertySummary {
  /// Returns a new [PropertySummary] instance.
  PropertySummary({
    required this.address,
    required this.editable,
    required this.id,
    this.managers = const [],
    required this.name,
    required this.occupiedRoomCount,
    required this.roomCount,
  });

  String address;

  /// False while the property is view-only.
  bool editable;

  String id;

  List<ManagerRef> managers;

  String name;

  int occupiedRoomCount;

  int roomCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertySummary &&
    other.address == address &&
    other.editable == editable &&
    other.id == id &&
    _deepEquality.equals(other.managers, managers) &&
    other.name == name &&
    other.occupiedRoomCount == occupiedRoomCount &&
    other.roomCount == roomCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (address.hashCode) +
    (editable.hashCode) +
    (id.hashCode) +
    (managers.hashCode) +
    (name.hashCode) +
    (occupiedRoomCount.hashCode) +
    (roomCount.hashCode);

  @override
  String toString() => 'PropertySummary[address=$address, editable=$editable, id=$id, managers=$managers, name=$name, occupiedRoomCount=$occupiedRoomCount, roomCount=$roomCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'address'] = this.address;
      json[r'editable'] = this.editable;
      json[r'id'] = this.id;
      json[r'managers'] = this.managers;
      json[r'name'] = this.name;
      json[r'occupiedRoomCount'] = this.occupiedRoomCount;
      json[r'roomCount'] = this.roomCount;
    return json;
  }

  /// Returns a new [PropertySummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertySummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PropertySummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PropertySummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PropertySummary(
        address: mapValueOfType<String>(json, r'address')!,
        editable: mapValueOfType<bool>(json, r'editable')!,
        id: mapValueOfType<String>(json, r'id')!,
        managers: ManagerRef.listFromJson(json[r'managers']),
        name: mapValueOfType<String>(json, r'name')!,
        occupiedRoomCount: mapValueOfType<int>(json, r'occupiedRoomCount')!,
        roomCount: mapValueOfType<int>(json, r'roomCount')!,
      );
    }
    return null;
  }

  static List<PropertySummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertySummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertySummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertySummary> mapFromJson(dynamic json) {
    final map = <String, PropertySummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertySummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertySummary-objects as value to a dart map
  static Map<String, List<PropertySummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertySummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertySummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'address',
    'editable',
    'id',
    'managers',
    'name',
    'occupiedRoomCount',
    'roomCount',
  };
}

