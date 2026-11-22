//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class RoomInput {
  /// Returns a new [RoomInput] instance.
  RoomInput({
    required this.baseRate,
    this.facilities = const [],
    this.lengthM,
    required this.number,
    this.widthM,
  });

  /// Per month, in rupiah.
  int baseRate;

  /// Free-form tags. On save each tag is trimmed, lowercased and has repeated spaces collapsed, and duplicates are dropped. At most 30 characters per tag and 15 tags per room.
  List<String> facilities;

  /// Maximum value: 20.0
  num? lengthM;

  /// Must be unique within the property.
  String number;

  /// Maximum value: 20.0
  num? widthM;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoomInput &&
    other.baseRate == baseRate &&
    _deepEquality.equals(other.facilities, facilities) &&
    other.lengthM == lengthM &&
    other.number == number &&
    other.widthM == widthM;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (baseRate.hashCode) +
    (facilities.hashCode) +
    (lengthM == null ? 0 : lengthM!.hashCode) +
    (number.hashCode) +
    (widthM == null ? 0 : widthM!.hashCode);

  @override
  String toString() => 'RoomInput[baseRate=$baseRate, facilities=$facilities, lengthM=$lengthM, number=$number, widthM=$widthM]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'baseRate'] = this.baseRate;
      json[r'facilities'] = this.facilities;
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

  /// Returns a new [RoomInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoomInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoomInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoomInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoomInput(
        baseRate: mapValueOfType<int>(json, r'baseRate')!,
        facilities: json[r'facilities'] is Iterable
            ? (json[r'facilities'] as Iterable).cast<String>().toList(growable: false)
            : const [],
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

  static List<RoomInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoomInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoomInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoomInput> mapFromJson(dynamic json) {
    final map = <String, RoomInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoomInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoomInput-objects as value to a dart map
  static Map<String, List<RoomInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoomInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoomInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'baseRate',
    'number',
  };
}

