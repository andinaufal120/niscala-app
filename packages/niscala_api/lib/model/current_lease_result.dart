//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class CurrentLeaseResult {
  /// Returns a new [CurrentLeaseResult] instance.
  CurrentLeaseResult({
    required this.lease,
  });

  CurrentLease? lease;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CurrentLeaseResult &&
    other.lease == lease;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lease == null ? 0 : lease!.hashCode);

  @override
  String toString() => 'CurrentLeaseResult[lease=$lease]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.lease != null) {
      json[r'lease'] = this.lease;
    } else {
      json[r'lease'] = null;
    }
    return json;
  }

  /// Returns a new [CurrentLeaseResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CurrentLeaseResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CurrentLeaseResult[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CurrentLeaseResult[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CurrentLeaseResult(
        lease: CurrentLease.fromJson(json[r'lease']),
      );
    }
    return null;
  }

  static List<CurrentLeaseResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CurrentLeaseResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CurrentLeaseResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CurrentLeaseResult> mapFromJson(dynamic json) {
    final map = <String, CurrentLeaseResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CurrentLeaseResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CurrentLeaseResult-objects as value to a dart map
  static Map<String, List<CurrentLeaseResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CurrentLeaseResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CurrentLeaseResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lease',
  };
}

