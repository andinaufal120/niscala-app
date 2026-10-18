//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class OccupancySummary {
  /// Returns a new [OccupancySummary] instance.
  OccupancySummary({
    required this.occupancyPercentage,
    required this.occupiedRoomCount,
    required this.propertyCount,
    required this.roomCount,
    required this.vacantRoomCount,
  });

  /// Occupied rooms as a whole-number percentage of all rooms, halves rounded up; 0 when there are no rooms.
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  int occupancyPercentage;

  /// Minimum value: 0
  int occupiedRoomCount;

  /// Minimum value: 0
  int propertyCount;

  /// Minimum value: 0
  int roomCount;

  /// Minimum value: 0
  int vacantRoomCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OccupancySummary &&
    other.occupancyPercentage == occupancyPercentage &&
    other.occupiedRoomCount == occupiedRoomCount &&
    other.propertyCount == propertyCount &&
    other.roomCount == roomCount &&
    other.vacantRoomCount == vacantRoomCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (occupancyPercentage.hashCode) +
    (occupiedRoomCount.hashCode) +
    (propertyCount.hashCode) +
    (roomCount.hashCode) +
    (vacantRoomCount.hashCode);

  @override
  String toString() => 'OccupancySummary[occupancyPercentage=$occupancyPercentage, occupiedRoomCount=$occupiedRoomCount, propertyCount=$propertyCount, roomCount=$roomCount, vacantRoomCount=$vacantRoomCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'occupancyPercentage'] = this.occupancyPercentage;
      json[r'occupiedRoomCount'] = this.occupiedRoomCount;
      json[r'propertyCount'] = this.propertyCount;
      json[r'roomCount'] = this.roomCount;
      json[r'vacantRoomCount'] = this.vacantRoomCount;
    return json;
  }

  /// Returns a new [OccupancySummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OccupancySummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "OccupancySummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "OccupancySummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OccupancySummary(
        occupancyPercentage: mapValueOfType<int>(json, r'occupancyPercentage')!,
        occupiedRoomCount: mapValueOfType<int>(json, r'occupiedRoomCount')!,
        propertyCount: mapValueOfType<int>(json, r'propertyCount')!,
        roomCount: mapValueOfType<int>(json, r'roomCount')!,
        vacantRoomCount: mapValueOfType<int>(json, r'vacantRoomCount')!,
      );
    }
    return null;
  }

  static List<OccupancySummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OccupancySummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OccupancySummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OccupancySummary> mapFromJson(dynamic json) {
    final map = <String, OccupancySummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OccupancySummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OccupancySummary-objects as value to a dart map
  static Map<String, List<OccupancySummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OccupancySummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OccupancySummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'occupancyPercentage',
    'occupiedRoomCount',
    'propertyCount',
    'roomCount',
    'vacantRoomCount',
  };
}

