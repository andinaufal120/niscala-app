//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class EmailVerificationSent {
  /// Returns a new [EmailVerificationSent] instance.
  EmailVerificationSent({
    required this.resendAvailableAt,
  });

  DateTime resendAvailableAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EmailVerificationSent &&
    other.resendAvailableAt == resendAvailableAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (resendAvailableAt.hashCode);

  @override
  String toString() => 'EmailVerificationSent[resendAvailableAt=$resendAvailableAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'resendAvailableAt'] = this.resendAvailableAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [EmailVerificationSent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EmailVerificationSent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "EmailVerificationSent[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "EmailVerificationSent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return EmailVerificationSent(
        resendAvailableAt: mapDateTime(json, r'resendAvailableAt', r'')!,
      );
    }
    return null;
  }

  static List<EmailVerificationSent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EmailVerificationSent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailVerificationSent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EmailVerificationSent> mapFromJson(dynamic json) {
    final map = <String, EmailVerificationSent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EmailVerificationSent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EmailVerificationSent-objects as value to a dart map
  static Map<String, List<EmailVerificationSent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EmailVerificationSent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EmailVerificationSent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'resendAvailableAt',
  };
}

