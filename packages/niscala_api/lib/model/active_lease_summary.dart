//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ActiveLeaseSummary {
  /// Returns a new [ActiveLeaseSummary] instance.
  ActiveLeaseSummary({
    this.endDate,
    required this.propertyName,
    required this.roomNumber,
  });

  DateTime? endDate;

  String propertyName;

  String roomNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ActiveLeaseSummary &&
    other.endDate == endDate &&
    other.propertyName == propertyName &&
    other.roomNumber == roomNumber;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (endDate == null ? 0 : endDate!.hashCode) +
    (propertyName.hashCode) +
    (roomNumber.hashCode);

  @override
  String toString() => 'ActiveLeaseSummary[endDate=$endDate, propertyName=$propertyName, roomNumber=$roomNumber]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!.toUtc());
    } else {
      json[r'endDate'] = null;
    }
      json[r'propertyName'] = this.propertyName;
      json[r'roomNumber'] = this.roomNumber;
    return json;
  }

  /// Returns a new [ActiveLeaseSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ActiveLeaseSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ActiveLeaseSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ActiveLeaseSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ActiveLeaseSummary(
        endDate: mapDateTime(json, r'endDate', r''),
        propertyName: mapValueOfType<String>(json, r'propertyName')!,
        roomNumber: mapValueOfType<String>(json, r'roomNumber')!,
      );
    }
    return null;
  }

  static List<ActiveLeaseSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ActiveLeaseSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ActiveLeaseSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ActiveLeaseSummary> mapFromJson(dynamic json) {
    final map = <String, ActiveLeaseSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ActiveLeaseSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ActiveLeaseSummary-objects as value to a dart map
  static Map<String, List<ActiveLeaseSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ActiveLeaseSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ActiveLeaseSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'propertyName',
    'roomNumber',
  };
}

