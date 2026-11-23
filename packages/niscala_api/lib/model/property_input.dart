//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PropertyInput {
  /// Returns a new [PropertyInput] instance.
  PropertyInput({
    required this.address,
    this.bankAccount,
    required this.name,
  });

  String address;

  BankAccount? bankAccount;

  /// Must be unique within the Owner's account.
  String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PropertyInput &&
    other.address == address &&
    other.bankAccount == bankAccount &&
    other.name == name;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (address.hashCode) +
    (bankAccount == null ? 0 : bankAccount!.hashCode) +
    (name.hashCode);

  @override
  String toString() => 'PropertyInput[address=$address, bankAccount=$bankAccount, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'address'] = this.address;
    if (this.bankAccount != null) {
      json[r'bankAccount'] = this.bankAccount;
    } else {
      json[r'bankAccount'] = null;
    }
      json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [PropertyInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PropertyInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PropertyInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PropertyInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PropertyInput(
        address: mapValueOfType<String>(json, r'address')!,
        bankAccount: BankAccount.fromJson(json[r'bankAccount']),
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<PropertyInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PropertyInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PropertyInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PropertyInput> mapFromJson(dynamic json) {
    final map = <String, PropertyInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PropertyInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PropertyInput-objects as value to a dart map
  static Map<String, List<PropertyInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PropertyInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PropertyInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'address',
    'name',
  };
}

