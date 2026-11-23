//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class BankAccount {
  /// Returns a new [BankAccount] instance.
  BankAccount({
    required this.accountHolderName,
    required this.accountNumber,
    required this.bankName,
  });

  String accountHolderName;

  String accountNumber;

  String bankName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BankAccount &&
    other.accountHolderName == accountHolderName &&
    other.accountNumber == accountNumber &&
    other.bankName == bankName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accountHolderName.hashCode) +
    (accountNumber.hashCode) +
    (bankName.hashCode);

  @override
  String toString() => 'BankAccount[accountHolderName=$accountHolderName, accountNumber=$accountNumber, bankName=$bankName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accountHolderName'] = this.accountHolderName;
      json[r'accountNumber'] = this.accountNumber;
      json[r'bankName'] = this.bankName;
    return json;
  }

  /// Returns a new [BankAccount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BankAccount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "BankAccount[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "BankAccount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BankAccount(
        accountHolderName: mapValueOfType<String>(json, r'accountHolderName')!,
        accountNumber: mapValueOfType<String>(json, r'accountNumber')!,
        bankName: mapValueOfType<String>(json, r'bankName')!,
      );
    }
    return null;
  }

  static List<BankAccount> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankAccount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankAccount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BankAccount> mapFromJson(dynamic json) {
    final map = <String, BankAccount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BankAccount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BankAccount-objects as value to a dart map
  static Map<String, List<BankAccount>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BankAccount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BankAccount.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountHolderName',
    'accountNumber',
    'bankName',
  };
}

