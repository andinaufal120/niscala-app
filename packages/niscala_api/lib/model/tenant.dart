//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Tenant {
  /// Returns a new [Tenant] instance.
  Tenant({
    required this.accountStatus,
    required this.email,
    this.emergencyContacts = const [],
    required this.id,
    required this.invitation,
    required this.lease,
    required this.name,
    required this.occupation,
    required this.phone,
    required this.room,
  });

  TenantAccountStatus accountStatus;

  String? email;

  List<EmergencyContact> emergencyContacts;

  String id;

  TenantInvitation? invitation;

  Lease lease;

  String name;

  String? occupation;

  /// Indonesian mobile number; returned as digits starting with 08.
  String phone;

  RoomRef room;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Tenant &&
    other.accountStatus == accountStatus &&
    other.email == email &&
    _deepEquality.equals(other.emergencyContacts, emergencyContacts) &&
    other.id == id &&
    other.invitation == invitation &&
    other.lease == lease &&
    other.name == name &&
    other.occupation == occupation &&
    other.phone == phone &&
    other.room == room;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accountStatus.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (emergencyContacts.hashCode) +
    (id.hashCode) +
    (invitation == null ? 0 : invitation!.hashCode) +
    (lease.hashCode) +
    (name.hashCode) +
    (occupation == null ? 0 : occupation!.hashCode) +
    (phone.hashCode) +
    (room.hashCode);

  @override
  String toString() => 'Tenant[accountStatus=$accountStatus, email=$email, emergencyContacts=$emergencyContacts, id=$id, invitation=$invitation, lease=$lease, name=$name, occupation=$occupation, phone=$phone, room=$room]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accountStatus'] = this.accountStatus;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'emergencyContacts'] = this.emergencyContacts;
      json[r'id'] = this.id;
    if (this.invitation != null) {
      json[r'invitation'] = this.invitation;
    } else {
      json[r'invitation'] = null;
    }
      json[r'lease'] = this.lease;
      json[r'name'] = this.name;
    if (this.occupation != null) {
      json[r'occupation'] = this.occupation;
    } else {
      json[r'occupation'] = null;
    }
      json[r'phone'] = this.phone;
      json[r'room'] = this.room;
    return json;
  }

  /// Returns a new [Tenant] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Tenant? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Tenant[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Tenant[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Tenant(
        accountStatus: TenantAccountStatus.fromJson(json[r'accountStatus'])!,
        email: mapValueOfType<String>(json, r'email'),
        emergencyContacts: EmergencyContact.listFromJson(json[r'emergencyContacts']),
        id: mapValueOfType<String>(json, r'id')!,
        invitation: TenantInvitation.fromJson(json[r'invitation']),
        lease: Lease.fromJson(json[r'lease'])!,
        name: mapValueOfType<String>(json, r'name')!,
        occupation: mapValueOfType<String>(json, r'occupation'),
        phone: mapValueOfType<String>(json, r'phone')!,
        room: RoomRef.fromJson(json[r'room'])!,
      );
    }
    return null;
  }

  static List<Tenant> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Tenant>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Tenant.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Tenant> mapFromJson(dynamic json) {
    final map = <String, Tenant>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Tenant.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Tenant-objects as value to a dart map
  static Map<String, List<Tenant>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Tenant>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Tenant.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountStatus',
    'email',
    'emergencyContacts',
    'id',
    'invitation',
    'lease',
    'name',
    'occupation',
    'phone',
    'room',
  };
}

