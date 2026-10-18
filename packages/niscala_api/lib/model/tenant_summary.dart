//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class TenantSummary {
  /// Returns a new [TenantSummary] instance.
  TenantSummary({
    required this.accountStatus,
    required this.billingCycle,
    required this.id,
    this.invitationExpiresAt,
    this.leaseEndDate,
    required this.name,
    required this.room,
  });

  TenantAccountStatus accountStatus;

  BillingCycle billingCycle;

  String id;

  DateTime? invitationExpiresAt;

  DateTime? leaseEndDate;

  String name;

  RoomRef room;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantSummary &&
    other.accountStatus == accountStatus &&
    other.billingCycle == billingCycle &&
    other.id == id &&
    other.invitationExpiresAt == invitationExpiresAt &&
    other.leaseEndDate == leaseEndDate &&
    other.name == name &&
    other.room == room;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accountStatus.hashCode) +
    (billingCycle.hashCode) +
    (id.hashCode) +
    (invitationExpiresAt == null ? 0 : invitationExpiresAt!.hashCode) +
    (leaseEndDate == null ? 0 : leaseEndDate!.hashCode) +
    (name.hashCode) +
    (room.hashCode);

  @override
  String toString() => 'TenantSummary[accountStatus=$accountStatus, billingCycle=$billingCycle, id=$id, invitationExpiresAt=$invitationExpiresAt, leaseEndDate=$leaseEndDate, name=$name, room=$room]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accountStatus'] = this.accountStatus;
      json[r'billingCycle'] = this.billingCycle;
      json[r'id'] = this.id;
    if (this.invitationExpiresAt != null) {
      json[r'invitationExpiresAt'] = this.invitationExpiresAt!.toUtc().toIso8601String();
    } else {
      json[r'invitationExpiresAt'] = null;
    }
    if (this.leaseEndDate != null) {
      json[r'leaseEndDate'] = _dateFormatter.format(this.leaseEndDate!.toUtc());
    } else {
      json[r'leaseEndDate'] = null;
    }
      json[r'name'] = this.name;
      json[r'room'] = this.room;
    return json;
  }

  /// Returns a new [TenantSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TenantSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TenantSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TenantSummary(
        accountStatus: TenantAccountStatus.fromJson(json[r'accountStatus'])!,
        billingCycle: BillingCycle.fromJson(json[r'billingCycle'])!,
        id: mapValueOfType<String>(json, r'id')!,
        invitationExpiresAt: mapDateTime(json, r'invitationExpiresAt', r''),
        leaseEndDate: mapDateTime(json, r'leaseEndDate', r''),
        name: mapValueOfType<String>(json, r'name')!,
        room: RoomRef.fromJson(json[r'room'])!,
      );
    }
    return null;
  }

  static List<TenantSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantSummary> mapFromJson(dynamic json) {
    final map = <String, TenantSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantSummary-objects as value to a dart map
  static Map<String, List<TenantSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountStatus',
    'billingCycle',
    'id',
    'name',
    'room',
  };
}

