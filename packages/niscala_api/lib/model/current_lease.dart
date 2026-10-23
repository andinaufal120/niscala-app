//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class CurrentLease {
  /// Returns a new [CurrentLease] instance.
  CurrentLease({
    required this.endDate,
    required this.room,
    required this.startDate,
  });

  DateTime? endDate;

  CurrentLeaseRoom room;

  DateTime? startDate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CurrentLease &&
    other.endDate == endDate &&
    other.room == room &&
    other.startDate == startDate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (endDate == null ? 0 : endDate!.hashCode) +
    (room.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode);

  @override
  String toString() => 'CurrentLease[endDate=$endDate, room=$room, startDate=$startDate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!.toUtc());
    } else {
      json[r'endDate'] = null;
    }
      json[r'room'] = this.room;
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!.toUtc());
    } else {
      json[r'startDate'] = null;
    }
    return json;
  }

  /// Returns a new [CurrentLease] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CurrentLease? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CurrentLease[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CurrentLease[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CurrentLease(
        endDate: mapDateTime(json, r'endDate', r''),
        room: CurrentLeaseRoom.fromJson(json[r'room'])!,
        startDate: mapDateTime(json, r'startDate', r''),
      );
    }
    return null;
  }

  static List<CurrentLease> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CurrentLease>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CurrentLease.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CurrentLease> mapFromJson(dynamic json) {
    final map = <String, CurrentLease>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CurrentLease.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CurrentLease-objects as value to a dart map
  static Map<String, List<CurrentLease>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CurrentLease>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CurrentLease.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'endDate',
    'room',
    'startDate',
  };
}

