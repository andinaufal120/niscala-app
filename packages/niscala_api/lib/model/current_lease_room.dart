//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class CurrentLeaseRoom {
  /// Returns a new [CurrentLeaseRoom] instance.
  CurrentLeaseRoom({
    this.facilities = const [],
    required this.id,
    this.lengthM,
    required this.number,
    this.widthM,
  });

  List<String> facilities;

  String id;

  num? lengthM;

  String number;

  num? widthM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CurrentLeaseRoom &&
    _deepEquality.equals(other.facilities, facilities) &&
    other.id == id &&
    other.lengthM == lengthM &&
    other.number == number &&
    other.widthM == widthM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (facilities.hashCode) +
    (id.hashCode) +
    (lengthM == null ? 0 : lengthM!.hashCode) +
    (number.hashCode) +
    (widthM == null ? 0 : widthM!.hashCode);

  @override
  String toString() => 'CurrentLeaseRoom[facilities=$facilities, id=$id, lengthM=$lengthM, number=$number, widthM=$widthM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'facilities'] = this.facilities;
      json[r'id'] = this.id;
    if (this.lengthM != null) {
      json[r'lengthM'] = this.lengthM;
    } else {
      json[r'lengthM'] = null;
    }
      json[r'number'] = this.number;
    if (this.widthM != null) {
      json[r'widthM'] = this.widthM;
    } else {
      json[r'widthM'] = null;
    }
    return json;
  }

  /// Returns a new [CurrentLeaseRoom] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CurrentLeaseRoom? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CurrentLeaseRoom[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CurrentLeaseRoom[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CurrentLeaseRoom(
        facilities: json[r'facilities'] is Iterable
            ? (json[r'facilities'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        id: mapValueOfType<String>(json, r'id')!,
        lengthM: json[r'lengthM'] == null
            ? null
            : num.parse('${json[r'lengthM']}'),
        number: mapValueOfType<String>(json, r'number')!,
        widthM: json[r'widthM'] == null
            ? null
            : num.parse('${json[r'widthM']}'),
      );
    }
    return null;
  }

  static List<CurrentLeaseRoom> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CurrentLeaseRoom>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CurrentLeaseRoom.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CurrentLeaseRoom> mapFromJson(dynamic json) {
    final map = <String, CurrentLeaseRoom>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CurrentLeaseRoom.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CurrentLeaseRoom-objects as value to a dart map
  static Map<String, List<CurrentLeaseRoom>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CurrentLeaseRoom>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CurrentLeaseRoom.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'facilities',
    'id',
    'number',
  };
}

