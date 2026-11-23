//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PurchaseVerificationInput {
  /// Returns a new [PurchaseVerificationInput] instance.
  PurchaseVerificationInput({
    required this.purchaseToken,
  });

  /// The token Google Play Billing returned for the purchase.
  String purchaseToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PurchaseVerificationInput &&
    other.purchaseToken == purchaseToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (purchaseToken.hashCode);

  @override
  String toString() => 'PurchaseVerificationInput[purchaseToken=$purchaseToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'purchaseToken'] = this.purchaseToken;
    return json;
  }

  /// Returns a new [PurchaseVerificationInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PurchaseVerificationInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PurchaseVerificationInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PurchaseVerificationInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PurchaseVerificationInput(
        purchaseToken: mapValueOfType<String>(json, r'purchaseToken')!,
      );
    }
    return null;
  }

  static List<PurchaseVerificationInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PurchaseVerificationInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PurchaseVerificationInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PurchaseVerificationInput> mapFromJson(dynamic json) {
    final map = <String, PurchaseVerificationInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PurchaseVerificationInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PurchaseVerificationInput-objects as value to a dart map
  static Map<String, List<PurchaseVerificationInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PurchaseVerificationInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PurchaseVerificationInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'purchaseToken',
  };
}

