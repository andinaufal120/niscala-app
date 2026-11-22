//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ScheduledDowngrade {
  /// Returns a new [ScheduledDowngrade] instance.
  ScheduledDowngrade({
    required this.effectiveDate,
    this.keptPropertyIds = const [],
    this.keptRoomIds = const [],
    required this.planCode,
  });

  /// The day after the paid period ends.
  DateTime effectiveDate;

  List<String> keptPropertyIds;

  /// Rooms of the single kept property; empty unless planCode is free.
  List<String> keptRoomIds;

  /// The plan that applies from effectiveDate.
  PlanCode planCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ScheduledDowngrade &&
    other.effectiveDate == effectiveDate &&
    _deepEquality.equals(other.keptPropertyIds, keptPropertyIds) &&
    _deepEquality.equals(other.keptRoomIds, keptRoomIds) &&
    other.planCode == planCode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (effectiveDate.hashCode) +
    (keptPropertyIds.hashCode) +
    (keptRoomIds.hashCode) +
    (planCode.hashCode);

  @override
  String toString() => 'ScheduledDowngrade[effectiveDate=$effectiveDate, keptPropertyIds=$keptPropertyIds, keptRoomIds=$keptRoomIds, planCode=$planCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'effectiveDate'] = _dateFormatter.format(this.effectiveDate.toUtc());
      json[r'keptPropertyIds'] = this.keptPropertyIds;
      json[r'keptRoomIds'] = this.keptRoomIds;
      json[r'planCode'] = this.planCode;
    return json;
  }

  /// Returns a new [ScheduledDowngrade] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ScheduledDowngrade? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ScheduledDowngrade[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ScheduledDowngrade[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ScheduledDowngrade(
        effectiveDate: mapDateTime(json, r'effectiveDate', r'')!,
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

  static List<ScheduledDowngrade> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ScheduledDowngrade>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ScheduledDowngrade.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ScheduledDowngrade> mapFromJson(dynamic json) {
    final map = <String, ScheduledDowngrade>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScheduledDowngrade.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ScheduledDowngrade-objects as value to a dart map
  static Map<String, List<ScheduledDowngrade>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ScheduledDowngrade>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ScheduledDowngrade.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'effectiveDate',
    'keptPropertyIds',
    'keptRoomIds',
    'planCode',
  };
}

