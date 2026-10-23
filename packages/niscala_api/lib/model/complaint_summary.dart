//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ComplaintSummary {
  /// Returns a new [ComplaintSummary] instance.
  ComplaintSummary({
    required this.classification,
    required this.classificationState,
    required this.classificationWithheld,
    required this.createdAt,
    required this.description,
    required this.hasPhoto,
    required this.id,
    required this.property,
    required this.room,
    required this.status,
    required this.tenantName,
  });

  ComplaintClassification? classification;

  ComplaintClassificationState? classificationState;

  /// True when an AI result exists but is withheld.
  bool classificationWithheld;

  DateTime createdAt;

  String description;

  bool hasPhoto;

  String id;

  PropertyRef property;

  RoomRef room;

  ComplaintStatus status;

  String tenantName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ComplaintSummary &&
    other.classification == classification &&
    other.classificationState == classificationState &&
    other.classificationWithheld == classificationWithheld &&
    other.createdAt == createdAt &&
    other.description == description &&
    other.hasPhoto == hasPhoto &&
    other.id == id &&
    other.property == property &&
    other.room == room &&
    other.status == status &&
    other.tenantName == tenantName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (classification == null ? 0 : classification!.hashCode) +
    (classificationState == null ? 0 : classificationState!.hashCode) +
    (classificationWithheld.hashCode) +
    (createdAt.hashCode) +
    (description.hashCode) +
    (hasPhoto.hashCode) +
    (id.hashCode) +
    (property.hashCode) +
    (room.hashCode) +
    (status.hashCode) +
    (tenantName.hashCode);

  @override
  String toString() => 'ComplaintSummary[classification=$classification, classificationState=$classificationState, classificationWithheld=$classificationWithheld, createdAt=$createdAt, description=$description, hasPhoto=$hasPhoto, id=$id, property=$property, room=$room, status=$status, tenantName=$tenantName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.classification != null) {
      json[r'classification'] = this.classification;
    } else {
      json[r'classification'] = null;
    }
    if (this.classificationState != null) {
      json[r'classificationState'] = this.classificationState;
    } else {
      json[r'classificationState'] = null;
    }
      json[r'classificationWithheld'] = this.classificationWithheld;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'description'] = this.description;
      json[r'hasPhoto'] = this.hasPhoto;
      json[r'id'] = this.id;
      json[r'property'] = this.property;
      json[r'room'] = this.room;
      json[r'status'] = this.status;
      json[r'tenantName'] = this.tenantName;
    return json;
  }

  /// Returns a new [ComplaintSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ComplaintSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ComplaintSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ComplaintSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ComplaintSummary(
        classification: ComplaintClassification.fromJson(json[r'classification']),
        classificationState: ComplaintClassificationState.fromJson(json[r'classificationState']),
        classificationWithheld: mapValueOfType<bool>(json, r'classificationWithheld')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        description: mapValueOfType<String>(json, r'description')!,
        hasPhoto: mapValueOfType<bool>(json, r'hasPhoto')!,
        id: mapValueOfType<String>(json, r'id')!,
        property: PropertyRef.fromJson(json[r'property'])!,
        room: RoomRef.fromJson(json[r'room'])!,
        status: ComplaintStatus.fromJson(json[r'status'])!,
        tenantName: mapValueOfType<String>(json, r'tenantName')!,
      );
    }
    return null;
  }

  static List<ComplaintSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ComplaintSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ComplaintSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ComplaintSummary> mapFromJson(dynamic json) {
    final map = <String, ComplaintSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ComplaintSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ComplaintSummary-objects as value to a dart map
  static Map<String, List<ComplaintSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ComplaintSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ComplaintSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'classification',
    'classificationState',
    'classificationWithheld',
    'createdAt',
    'description',
    'hasPhoto',
    'id',
    'property',
    'room',
    'status',
    'tenantName',
  };
}

