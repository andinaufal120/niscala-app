//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class AiComplaintClassification {
  /// Returns a new [AiComplaintClassification] instance.
  AiComplaintClassification({
    required this.category,
    required this.suggestedAction,
    required this.urgency,
  });

  String category;

  String suggestedAction;

  ComplaintUrgency urgency;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AiComplaintClassification &&
    other.category == category &&
    other.suggestedAction == suggestedAction &&
    other.urgency == urgency;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (category.hashCode) +
    (suggestedAction.hashCode) +
    (urgency.hashCode);

  @override
  String toString() => 'AiComplaintClassification[category=$category, suggestedAction=$suggestedAction, urgency=$urgency]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'category'] = this.category;
      json[r'suggestedAction'] = this.suggestedAction;
      json[r'urgency'] = this.urgency;
    return json;
  }

  /// Returns a new [AiComplaintClassification] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AiComplaintClassification? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AiComplaintClassification[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AiComplaintClassification[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AiComplaintClassification(
        category: mapValueOfType<String>(json, r'category')!,
        suggestedAction: mapValueOfType<String>(json, r'suggestedAction')!,
        urgency: ComplaintUrgency.fromJson(json[r'urgency'])!,
      );
    }
    return null;
  }

  static List<AiComplaintClassification> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AiComplaintClassification>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AiComplaintClassification.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AiComplaintClassification> mapFromJson(dynamic json) {
    final map = <String, AiComplaintClassification>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AiComplaintClassification.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AiComplaintClassification-objects as value to a dart map
  static Map<String, List<AiComplaintClassification>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AiComplaintClassification>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AiComplaintClassification.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
    'suggestedAction',
    'urgency',
  };
}

