//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Property {
  /// Returns a new [Property] instance.
  Property({
    required this.address,
    required this.bankAccount,
    required this.editable,
    required this.id,
    this.managers = const [],
    required this.name,
    required this.occupiedRoomCount,
    required this.roomCount,
    required this.vacantRoomCount,
  });

  String address;

  BankAccount? bankAccount;

  /// False while the property is view-only.
  bool editable;

  String id;

  List<ManagerRef> managers;

  String name;

  int occupiedRoomCount;

  int roomCount;

  int vacantRoomCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Property &&
    other.address == address &&
    other.bankAccount == bankAccount &&
    other.editable == editable &&
    other.id == id &&
    _deepEquality.equals(other.managers, managers) &&
    other.name == name &&
    other.occupiedRoomCount == occupiedRoomCount &&
    other.roomCount == roomCount &&
    other.vacantRoomCount == vacantRoomCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (address.hashCode) +
    (bankAccount == null ? 0 : bankAccount!.hashCode) +
    (editable.hashCode) +
    (id.hashCode) +
    (managers.hashCode) +
    (name.hashCode) +
    (occupiedRoomCount.hashCode) +
    (roomCount.hashCode) +
    (vacantRoomCount.hashCode);

  @override
  String toString() => 'Property[address=$address, bankAccount=$bankAccount, editable=$editable, id=$id, managers=$managers, name=$name, occupiedRoomCount=$occupiedRoomCount, roomCount=$roomCount, vacantRoomCount=$vacantRoomCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'address'] = this.address;
    if (this.bankAccount != null) {
      json[r'bankAccount'] = this.bankAccount;
    } else {
      json[r'bankAccount'] = null;
    }
      json[r'editable'] = this.editable;
      json[r'id'] = this.id;
      json[r'managers'] = this.managers;
      json[r'name'] = this.name;
      json[r'occupiedRoomCount'] = this.occupiedRoomCount;
      json[r'roomCount'] = this.roomCount;
      json[r'vacantRoomCount'] = this.vacantRoomCount;
    return json;
  }

  /// Returns a new [Property] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Property? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Property[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Property[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Property(
        address: mapValueOfType<String>(json, r'address')!,
        bankAccount: BankAccount.fromJson(json[r'bankAccount']),
        editable: mapValueOfType<bool>(json, r'editable')!,
        id: mapValueOfType<String>(json, r'id')!,
        managers: ManagerRef.listFromJson(json[r'managers']),
        name: mapValueOfType<String>(json, r'name')!,
        occupiedRoomCount: mapValueOfType<int>(json, r'occupiedRoomCount')!,
        roomCount: mapValueOfType<int>(json, r'roomCount')!,
        vacantRoomCount: mapValueOfType<int>(json, r'vacantRoomCount')!,
      );
    }
    return null;
  }

  static List<Property> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Property>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Property.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Property> mapFromJson(dynamic json) {
    final map = <String, Property>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Property.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Property-objects as value to a dart map
  static Map<String, List<Property>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Property>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Property.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'address',
    'bankAccount',
    'editable',
    'id',
    'managers',
    'name',
    'occupiedRoomCount',
    'roomCount',
    'vacantRoomCount',
  };
}

