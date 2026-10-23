//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ComplaintList {
  /// Returns a new [ComplaintList] instance.
  ComplaintList({
    this.items = const [],
  });

  List<ComplaintSummary> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComplaintList &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode);

  @override
  String toString() => 'ComplaintList[items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
    return json;
  }

  /// Returns a new [ComplaintList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComplaintList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ComplaintList[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ComplaintList[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ComplaintList(
        items: ComplaintSummary.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<ComplaintList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComplaintList> mapFromJson(dynamic json) {
    final map = <String, ComplaintList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComplaintList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComplaintList-objects as value to a dart map
  static Map<String, List<ComplaintList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComplaintList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComplaintList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
  };
}

