//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PropertyOccupancy {
  /// Returns a new [PropertyOccupancy] instance.
  PropertyOccupancy({
    required this.id,
    required this.name,
    required this.occupancyPercentage,
    required this.occupiedRoomCount,
    required this.roomCount,
    this.rooms = const [],
    required this.vacantRoomCount,
  });

  String id;

  String name;

  /// Occupied rooms as a whole-number percentage of all rooms, halves rounded up; 0 when there are no rooms.
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  int occupancyPercentage;

  /// Minimum value: 0
  int occupiedRoomCount;

  /// Minimum value: 0
  int roomCount;

  List<OccupancyRoom> rooms;

  /// Minimum value: 0
  int vacantRoomCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyOccupancy &&
    other.id == id &&
    other.name == name &&
    other.occupancyPercentage == occupancyPercentage &&
    other.occupiedRoomCount == occupiedRoomCount &&
    other.roomCount == roomCount &&
    _deepEquality.equals(other.rooms, rooms) &&
    other.vacantRoomCount == vacantRoomCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (occupancyPercentage.hashCode) +
    (occupiedRoomCount.hashCode) +
    (roomCount.hashCode) +
    (rooms.hashCode) +
    (vacantRoomCount.hashCode);

  @override
  String toString() => 'PropertyOccupancy[id=$id, name=$name, occupancyPercentage=$occupancyPercentage, occupiedRoomCount=$occupiedRoomCount, roomCount=$roomCount, rooms=$rooms, vacantRoomCount=$vacantRoomCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'occupancyPercentage'] = this.occupancyPercentage;
      json[r'occupiedRoomCount'] = this.occupiedRoomCount;
      json[r'roomCount'] = this.roomCount;
      json[r'rooms'] = this.rooms;
      json[r'vacantRoomCount'] = this.vacantRoomCount;
    return json;
  }

  /// Returns a new [PropertyOccupancy] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyOccupancy? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PropertyOccupancy[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PropertyOccupancy[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PropertyOccupancy(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        occupancyPercentage: mapValueOfType<int>(json, r'occupancyPercentage')!,
        occupiedRoomCount: mapValueOfType<int>(json, r'occupiedRoomCount')!,
        roomCount: mapValueOfType<int>(json, r'roomCount')!,
        rooms: OccupancyRoom.listFromJson(json[r'rooms']),
        vacantRoomCount: mapValueOfType<int>(json, r'vacantRoomCount')!,
      );
    }
    return null;
  }

  static List<PropertyOccupancy> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyOccupancy>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyOccupancy.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyOccupancy> mapFromJson(dynamic json) {
    final map = <String, PropertyOccupancy>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyOccupancy.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyOccupancy-objects as value to a dart map
  static Map<String, List<PropertyOccupancy>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyOccupancy>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyOccupancy.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'occupancyPercentage',
    'occupiedRoomCount',
    'roomCount',
    'rooms',
    'vacantRoomCount',
  };
}

