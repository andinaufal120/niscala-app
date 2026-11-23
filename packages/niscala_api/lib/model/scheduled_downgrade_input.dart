//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ScheduledDowngradeInput {
  /// Returns a new [ScheduledDowngradeInput] instance.
  ScheduledDowngradeInput({
    this.keptPropertyIds = const [],
    this.keptRoomIds = const [],
    required this.planCode,
  });

  /// Exactly the target plan's property limit, or all properties if the Owner has fewer. No duplicates.
  List<String> keptPropertyIds;

  /// Only for free: exactly 15 rooms of the kept property, or all its rooms if it has fewer. Must be empty otherwise.
  List<String> keptRoomIds;

  /// free or basic; must be lower than the current plan.
  PlanCode planCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ScheduledDowngradeInput &&
    _deepEquality.equals(other.keptPropertyIds, keptPropertyIds) &&
    _deepEquality.equals(other.keptRoomIds, keptRoomIds) &&
    other.planCode == planCode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (keptPropertyIds.hashCode) +
    (keptRoomIds.hashCode) +
    (planCode.hashCode);

  @override
  String toString() => 'ScheduledDowngradeInput[keptPropertyIds=$keptPropertyIds, keptRoomIds=$keptRoomIds, planCode=$planCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'keptPropertyIds'] = this.keptPropertyIds;
      json[r'keptRoomIds'] = this.keptRoomIds;
      json[r'planCode'] = this.planCode;
    return json;
  }

  /// Returns a new [ScheduledDowngradeInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ScheduledDowngradeInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ScheduledDowngradeInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ScheduledDowngradeInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ScheduledDowngradeInput(
        keptPropertyIds: json[r'keptPropertyIds'] is Iterable
            ? (json[r'keptPropertyIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        keptRoomIds: json[r'keptRoomIds'] is Iterable
            ? (json[r'keptRoomIds'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        planCode: PlanCode.fromJson(json[r'planCode'])!,
      );
    }
    return null;
  }

  static List<ScheduledDowngradeInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ScheduledDowngradeInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ScheduledDowngradeInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ScheduledDowngradeInput> mapFromJson(dynamic json) {
    final map = <String, ScheduledDowngradeInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScheduledDowngradeInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ScheduledDowngradeInput-objects as value to a dart map
  static Map<String, List<ScheduledDowngradeInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ScheduledDowngradeInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ScheduledDowngradeInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'keptPropertyIds',
    'planCode',
  };
}

