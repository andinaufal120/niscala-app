//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ComplaintStatusChangeInput {
  /// Returns a new [ComplaintStatusChangeInput] instance.
  ComplaintStatusChangeInput({
    this.handlingNote,
    required this.status,
  });

  String? handlingNote;

  /// Must be the next status.
  ComplaintStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComplaintStatusChangeInput &&
    other.handlingNote == handlingNote &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (handlingNote == null ? 0 : handlingNote!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'ComplaintStatusChangeInput[handlingNote=$handlingNote, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.handlingNote != null) {
      json[r'handlingNote'] = this.handlingNote;
    } else {
      json[r'handlingNote'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [ComplaintStatusChangeInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComplaintStatusChangeInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ComplaintStatusChangeInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ComplaintStatusChangeInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ComplaintStatusChangeInput(
        handlingNote: mapValueOfType<String>(json, r'handlingNote'),
        status: ComplaintStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<ComplaintStatusChangeInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintStatusChangeInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintStatusChangeInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComplaintStatusChangeInput> mapFromJson(dynamic json) {
    final map = <String, ComplaintStatusChangeInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComplaintStatusChangeInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComplaintStatusChangeInput-objects as value to a dart map
  static Map<String, List<ComplaintStatusChangeInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComplaintStatusChangeInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComplaintStatusChangeInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
  };
}

