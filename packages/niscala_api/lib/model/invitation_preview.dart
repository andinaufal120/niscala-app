//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class InvitationPreview {
  /// Returns a new [InvitationPreview] instance.
  InvitationPreview({
    required this.emergencyContactsRequired,
    required this.expiresAt,
    required this.inviterName,
    required this.name,
    this.properties = const [],
    required this.role,
    required this.roomNumber,
    required this.status,
  });

  /// True when a Tenant's emergency contacts are still missing.
  bool emergencyContactsRequired;

  DateTime expiresAt;

  String inviterName;

  /// Pre-filled by management.
  String name;

  /// One for a Tenant, one or more for a Manager.
  List<InvitationProperty> properties;

  InvitationRole role;

  String? roomNumber;

  InvitationLinkStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitationPreview &&
    other.emergencyContactsRequired == emergencyContactsRequired &&
    other.expiresAt == expiresAt &&
    other.inviterName == inviterName &&
    other.name == name &&
    _deepEquality.equals(other.properties, properties) &&
    other.role == role &&
    other.roomNumber == roomNumber &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (emergencyContactsRequired.hashCode) +
    (expiresAt.hashCode) +
    (inviterName.hashCode) +
    (name.hashCode) +
    (properties.hashCode) +
    (role.hashCode) +
    (roomNumber == null ? 0 : roomNumber!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'InvitationPreview[emergencyContactsRequired=$emergencyContactsRequired, expiresAt=$expiresAt, inviterName=$inviterName, name=$name, properties=$properties, role=$role, roomNumber=$roomNumber, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'emergencyContactsRequired'] = this.emergencyContactsRequired;
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
      json[r'inviterName'] = this.inviterName;
      json[r'name'] = this.name;
      json[r'properties'] = this.properties;
      json[r'role'] = this.role;
    if (this.roomNumber != null) {
      json[r'roomNumber'] = this.roomNumber;
    } else {
      json[r'roomNumber'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [InvitationPreview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitationPreview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvitationPreview[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvitationPreview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvitationPreview(
        emergencyContactsRequired: mapValueOfType<bool>(json, r'emergencyContactsRequired')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
        inviterName: mapValueOfType<String>(json, r'inviterName')!,
        name: mapValueOfType<String>(json, r'name')!,
        properties: InvitationProperty.listFromJson(json[r'properties']),
        role: InvitationRole.fromJson(json[r'role'])!,
        roomNumber: mapValueOfType<String>(json, r'roomNumber'),
        status: InvitationLinkStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<InvitationPreview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationPreview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationPreview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitationPreview> mapFromJson(dynamic json) {
    final map = <String, InvitationPreview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitationPreview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitationPreview-objects as value to a dart map
  static Map<String, List<InvitationPreview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitationPreview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitationPreview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'emergencyContactsRequired',
    'expiresAt',
    'inviterName',
    'name',
    'properties',
    'role',
    'roomNumber',
    'status',
  };
}

