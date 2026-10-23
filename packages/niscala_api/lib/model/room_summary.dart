//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class RoomSummary {
  /// Returns a new [RoomSummary] instance.
  RoomSummary({
    required this.baseRate,
    required this.editable,
    this.facilities = const [],
    required this.id,
    required this.lease,
    required this.lengthM,
    required this.number,
    required this.occupancy,
    required this.widthM,
  });

  /// Per month, in rupiah.
  int baseRate;

  /// False while the room is view-only.
  bool editable;

  List<String> facilities;

  String id;

  RoomLeaseSummary? lease;

  num? lengthM;

  String number;

  Occupancy occupancy;

  num? widthM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoomSummary &&
    other.baseRate == baseRate &&
    other.editable == editable &&
    _deepEquality.equals(other.facilities, facilities) &&
    other.id == id &&
    other.lease == lease &&
    other.lengthM == lengthM &&
    other.number == number &&
    other.occupancy == occupancy &&
    other.widthM == widthM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (baseRate.hashCode) +
    (editable.hashCode) +
    (facilities.hashCode) +
    (id.hashCode) +
    (lease == null ? 0 : lease!.hashCode) +
    (lengthM == null ? 0 : lengthM!.hashCode) +
    (number.hashCode) +
    (occupancy.hashCode) +
    (widthM == null ? 0 : widthM!.hashCode);

  @override
  String toString() => 'RoomSummary[baseRate=$baseRate, editable=$editable, facilities=$facilities, id=$id, lease=$lease, lengthM=$lengthM, number=$number, occupancy=$occupancy, widthM=$widthM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'baseRate'] = this.baseRate;
      json[r'editable'] = this.editable;
      json[r'facilities'] = this.facilities;
      json[r'id'] = this.id;
    if (this.lease != null) {
      json[r'lease'] = this.lease;
    } else {
      json[r'lease'] = null;
    }
    if (this.lengthM != null) {
      json[r'lengthM'] = this.lengthM;
    } else {
      json[r'lengthM'] = null;
    }
      json[r'number'] = this.number;
      json[r'occupancy'] = this.occupancy;
    if (this.widthM != null) {
      json[r'widthM'] = this.widthM;
    } else {
      json[r'widthM'] = null;
    }
    return json;
  }

  /// Returns a new [RoomSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoomSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoomSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoomSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoomSummary(
        baseRate: mapValueOfType<int>(json, r'baseRate')!,
        editable: mapValueOfType<bool>(json, r'editable')!,
        facilities: json[r'facilities'] is Iterable
            ? (json[r'facilities'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        id: mapValueOfType<String>(json, r'id')!,
        lease: RoomLeaseSummary.fromJson(json[r'lease']),
        lengthM: json[r'lengthM'] == null
            ? null
            : num.parse('${json[r'lengthM']}'),
        number: mapValueOfType<String>(json, r'number')!,
        occupancy: Occupancy.fromJson(json[r'occupancy'])!,
        widthM: json[r'widthM'] == null
            ? null
            : num.parse('${json[r'widthM']}'),
      );
    }
    return null;
  }

  static List<RoomSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoomSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoomSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoomSummary> mapFromJson(dynamic json) {
    final map = <String, RoomSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoomSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoomSummary-objects as value to a dart map
  static Map<String, List<RoomSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoomSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoomSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'baseRate',
    'editable',
    'facilities',
    'id',
    'lease',
    'lengthM',
    'number',
    'occupancy',
    'widthM',
  };
}

