//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class AccountTenancy {
  /// Returns a new [AccountTenancy] instance.
  AccountTenancy({
    required this.leaseEndDate,
    required this.propertyName,
    required this.roomNumber,
  });

  DateTime? leaseEndDate;

  String propertyName;

  String roomNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AccountTenancy &&
    other.leaseEndDate == leaseEndDate &&
    other.propertyName == propertyName &&
    other.roomNumber == roomNumber;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leaseEndDate == null ? 0 : leaseEndDate!.hashCode) +
    (propertyName.hashCode) +
    (roomNumber.hashCode);

  @override
  String toString() => 'AccountTenancy[leaseEndDate=$leaseEndDate, propertyName=$propertyName, roomNumber=$roomNumber]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.leaseEndDate != null) {
      json[r'leaseEndDate'] = _dateFormatter.format(this.leaseEndDate!.toUtc());
    } else {
      json[r'leaseEndDate'] = null;
    }
      json[r'propertyName'] = this.propertyName;
      json[r'roomNumber'] = this.roomNumber;
    return json;
  }

  /// Returns a new [AccountTenancy] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AccountTenancy? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AccountTenancy[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AccountTenancy[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AccountTenancy(
        leaseEndDate: mapDateTime(json, r'leaseEndDate', r''),
        propertyName: mapValueOfType<String>(json, r'propertyName')!,
        roomNumber: mapValueOfType<String>(json, r'roomNumber')!,
      );
    }
    return null;
  }

  static List<AccountTenancy> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccountTenancy>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccountTenancy.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AccountTenancy> mapFromJson(dynamic json) {
    final map = <String, AccountTenancy>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AccountTenancy.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AccountTenancy-objects as value to a dart map
  static Map<String, List<AccountTenancy>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AccountTenancy>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AccountTenancy.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'leaseEndDate',
    'propertyName',
    'roomNumber',
  };
}

