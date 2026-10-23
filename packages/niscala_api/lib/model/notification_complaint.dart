//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class NotificationComplaint {
  /// Returns a new [NotificationComplaint] instance.
  NotificationComplaint({
    required this.category,
    required this.complaintId,
    required this.description,
    required this.handlingNote,
    required this.status,
    required this.urgency,
  });

  String? category;

  String complaintId;

  String description;

  String? handlingNote;

  ComplaintStatus status;

  ComplaintUrgency? urgency;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationComplaint &&
    other.category == category &&
    other.complaintId == complaintId &&
    other.description == description &&
    other.handlingNote == handlingNote &&
    other.status == status &&
    other.urgency == urgency;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (category == null ? 0 : category!.hashCode) +
    (complaintId.hashCode) +
    (description.hashCode) +
    (handlingNote == null ? 0 : handlingNote!.hashCode) +
    (status.hashCode) +
    (urgency == null ? 0 : urgency!.hashCode);

  @override
  String toString() => 'NotificationComplaint[category=$category, complaintId=$complaintId, description=$description, handlingNote=$handlingNote, status=$status, urgency=$urgency]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
      json[r'complaintId'] = this.complaintId;
      json[r'description'] = this.description;
    if (this.handlingNote != null) {
      json[r'handlingNote'] = this.handlingNote;
    } else {
      json[r'handlingNote'] = null;
    }
      json[r'status'] = this.status;
    if (this.urgency != null) {
      json[r'urgency'] = this.urgency;
    } else {
      json[r'urgency'] = null;
    }
    return json;
  }

  /// Returns a new [NotificationComplaint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationComplaint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationComplaint[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationComplaint[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationComplaint(
        category: mapValueOfType<String>(json, r'category'),
        complaintId: mapValueOfType<String>(json, r'complaintId')!,
        description: mapValueOfType<String>(json, r'description')!,
        handlingNote: mapValueOfType<String>(json, r'handlingNote'),
        status: ComplaintStatus.fromJson(json[r'status'])!,
        urgency: ComplaintUrgency.fromJson(json[r'urgency']),
      );
    }
    return null;
  }

  static List<NotificationComplaint> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationComplaint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationComplaint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationComplaint> mapFromJson(dynamic json) {
    final map = <String, NotificationComplaint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationComplaint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationComplaint-objects as value to a dart map
  static Map<String, List<NotificationComplaint>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationComplaint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationComplaint.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
    'complaintId',
    'description',
    'handlingNote',
    'status',
    'urgency',
  };
}

