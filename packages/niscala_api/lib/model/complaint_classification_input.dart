//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ComplaintClassificationInput {
  /// Returns a new [ComplaintClassificationInput] instance.
  ComplaintClassificationInput({
    required this.category,
    required this.urgency,
  });

  /// One of the categories from /complaint-categories.
  String category;

  ComplaintUrgency urgency;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComplaintClassificationInput &&
    other.category == category &&
    other.urgency == urgency;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (category.hashCode) +
    (urgency.hashCode);

  @override
  String toString() => 'ComplaintClassificationInput[category=$category, urgency=$urgency]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'category'] = this.category;
      json[r'urgency'] = this.urgency;
    return json;
  }

  /// Returns a new [ComplaintClassificationInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComplaintClassificationInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ComplaintClassificationInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ComplaintClassificationInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ComplaintClassificationInput(
        category: mapValueOfType<String>(json, r'category')!,
        urgency: ComplaintUrgency.fromJson(json[r'urgency'])!,
      );
    }
    return null;
  }

  static List<ComplaintClassificationInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintClassificationInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintClassificationInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComplaintClassificationInput> mapFromJson(dynamic json) {
    final map = <String, ComplaintClassificationInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComplaintClassificationInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComplaintClassificationInput-objects as value to a dart map
  static Map<String, List<ComplaintClassificationInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComplaintClassificationInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComplaintClassificationInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
    'urgency',
  };
}

