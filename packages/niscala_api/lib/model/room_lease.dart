//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class RoomLease {
  /// Returns a new [RoomLease] instance.
  RoomLease({
    required this.endDate,
    required this.rent,
    required this.startDate,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
  });

  DateTime? endDate;

  /// In rupiah.
  int rent;

  DateTime? startDate;

  String tenantId;

  String tenantName;

  String tenantPhone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoomLease &&
    other.endDate == endDate &&
    other.rent == rent &&
    other.startDate == startDate &&
    other.tenantId == tenantId &&
    other.tenantName == tenantName &&
    other.tenantPhone == tenantPhone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (endDate == null ? 0 : endDate!.hashCode) +
    (rent.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (tenantId.hashCode) +
    (tenantName.hashCode) +
    (tenantPhone.hashCode);

  @override
  String toString() => 'RoomLease[endDate=$endDate, rent=$rent, startDate=$startDate, tenantId=$tenantId, tenantName=$tenantName, tenantPhone=$tenantPhone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!.toUtc());
    } else {
      json[r'endDate'] = null;
    }
      json[r'rent'] = this.rent;
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!.toUtc());
    } else {
      json[r'startDate'] = null;
    }
      json[r'tenantId'] = this.tenantId;
      json[r'tenantName'] = this.tenantName;
      json[r'tenantPhone'] = this.tenantPhone;
    return json;
  }

  /// Returns a new [RoomLease] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoomLease? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoomLease[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoomLease[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoomLease(
        endDate: mapDateTime(json, r'endDate', r''),
        rent: mapValueOfType<int>(json, r'rent')!,
        startDate: mapDateTime(json, r'startDate', r''),
        tenantId: mapValueOfType<String>(json, r'tenantId')!,
        tenantName: mapValueOfType<String>(json, r'tenantName')!,
        tenantPhone: mapValueOfType<String>(json, r'tenantPhone')!,
      );
    }
    return null;
  }

  static List<RoomLease> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoomLease>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoomLease.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoomLease> mapFromJson(dynamic json) {
    final map = <String, RoomLease>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoomLease.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoomLease-objects as value to a dart map
  static Map<String, List<RoomLease>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoomLease>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoomLease.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'endDate',
    'rent',
    'startDate',
    'tenantId',
    'tenantName',
    'tenantPhone',
  };
}

