//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Notification {
  /// Returns a new [Notification] instance.
  Notification({
    required this.actorName,
    required this.complaint,
    required this.createdAt,
    required this.id,
    required this.property,
    required this.read,
    required this.rentBill,
    required this.room,
    required this.tenant,
    required this.type,
  });

  String? actorName;

  NotificationComplaint? complaint;

  DateTime createdAt;

  String id;

  PropertyRef? property;

  bool read;

  NotificationRentBill? rentBill;

  RoomRef? room;

  TenantRef? tenant;

  NotificationType type;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Notification &&
    other.actorName == actorName &&
    other.complaint == complaint &&
    other.createdAt == createdAt &&
    other.id == id &&
    other.property == property &&
    other.read == read &&
    other.rentBill == rentBill &&
    other.room == room &&
    other.tenant == tenant &&
    other.type == type;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (actorName == null ? 0 : actorName!.hashCode) +
    (complaint == null ? 0 : complaint!.hashCode) +
    (createdAt.hashCode) +
    (id.hashCode) +
    (property == null ? 0 : property!.hashCode) +
    (read.hashCode) +
    (rentBill == null ? 0 : rentBill!.hashCode) +
    (room == null ? 0 : room!.hashCode) +
    (tenant == null ? 0 : tenant!.hashCode) +
    (type.hashCode);

  @override
  String toString() => 'Notification[actorName=$actorName, complaint=$complaint, createdAt=$createdAt, id=$id, property=$property, read=$read, rentBill=$rentBill, room=$room, tenant=$tenant, type=$type]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.actorName != null) {
      json[r'actorName'] = this.actorName;
    } else {
      json[r'actorName'] = null;
    }
    if (this.complaint != null) {
      json[r'complaint'] = this.complaint;
    } else {
      json[r'complaint'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'id'] = this.id;
    if (this.property != null) {
      json[r'property'] = this.property;
    } else {
      json[r'property'] = null;
    }
      json[r'read'] = this.read;
    if (this.rentBill != null) {
      json[r'rentBill'] = this.rentBill;
    } else {
      json[r'rentBill'] = null;
    }
    if (this.room != null) {
      json[r'room'] = this.room;
    } else {
      json[r'room'] = null;
    }
    if (this.tenant != null) {
      json[r'tenant'] = this.tenant;
    } else {
      json[r'tenant'] = null;
    }
      json[r'type'] = this.type;
    return json;
  }

  /// Returns a new [Notification] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Notification? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Notification[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Notification[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Notification(
        actorName: mapValueOfType<String>(json, r'actorName'),
        complaint: NotificationComplaint.fromJson(json[r'complaint']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        id: mapValueOfType<String>(json, r'id')!,
        property: PropertyRef.fromJson(json[r'property']),
        read: mapValueOfType<bool>(json, r'read')!,
        rentBill: NotificationRentBill.fromJson(json[r'rentBill']),
        room: RoomRef.fromJson(json[r'room']),
        tenant: TenantRef.fromJson(json[r'tenant']),
        type: NotificationType.fromJson(json[r'type'])!,
      );
    }
    return null;
  }

  static List<Notification> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Notification>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Notification.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Notification> mapFromJson(dynamic json) {
    final map = <String, Notification>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Notification.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Notification-objects as value to a dart map
  static Map<String, List<Notification>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Notification>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Notification.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'actorName',
    'complaint',
    'createdAt',
    'id',
    'property',
    'read',
    'rentBill',
    'room',
    'tenant',
    'type',
  };
}

