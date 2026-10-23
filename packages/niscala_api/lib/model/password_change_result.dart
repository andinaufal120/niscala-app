//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PasswordChangeResult {
  /// Returns a new [PasswordChangeResult] instance.
  PasswordChangeResult({
    required this.hasOtherSessions,
  });

  /// True when sessions other than the current one are still signed in.
  bool hasOtherSessions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PasswordChangeResult &&
    other.hasOtherSessions == hasOtherSessions;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hasOtherSessions.hashCode);

  @override
  String toString() => 'PasswordChangeResult[hasOtherSessions=$hasOtherSessions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'hasOtherSessions'] = this.hasOtherSessions;
    return json;
  }

  /// Returns a new [PasswordChangeResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PasswordChangeResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PasswordChangeResult[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PasswordChangeResult[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PasswordChangeResult(
        hasOtherSessions: mapValueOfType<bool>(json, r'hasOtherSessions')!,
      );
    }
    return null;
  }

  static List<PasswordChangeResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PasswordChangeResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PasswordChangeResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PasswordChangeResult> mapFromJson(dynamic json) {
    final map = <String, PasswordChangeResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PasswordChangeResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PasswordChangeResult-objects as value to a dart map
  static Map<String, List<PasswordChangeResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PasswordChangeResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PasswordChangeResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hasOtherSessions',
  };
}

