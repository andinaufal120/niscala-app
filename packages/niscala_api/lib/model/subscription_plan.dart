//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class SubscriptionPlan {
  /// Returns a new [SubscriptionPlan] instance.
  SubscriptionPlan({
    required this.aiEnabled,
    required this.code,
    required this.maxProperties,
    required this.maxRoomsPerProperty,
    this.prices = const [],
  });

  bool aiEnabled;

  PlanCode code;

  int? maxProperties;

  int? maxRoomsPerProperty;

  /// Empty for the free plan.
  List<SubscriptionPlanPrice> prices;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubscriptionPlan &&
    other.aiEnabled == aiEnabled &&
    other.code == code &&
    other.maxProperties == maxProperties &&
    other.maxRoomsPerProperty == maxRoomsPerProperty &&
    _deepEquality.equals(other.prices, prices);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (aiEnabled.hashCode) +
    (code.hashCode) +
    (maxProperties == null ? 0 : maxProperties!.hashCode) +
    (maxRoomsPerProperty == null ? 0 : maxRoomsPerProperty!.hashCode) +
    (prices.hashCode);

  @override
  String toString() => 'SubscriptionPlan[aiEnabled=$aiEnabled, code=$code, maxProperties=$maxProperties, maxRoomsPerProperty=$maxRoomsPerProperty, prices=$prices]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'aiEnabled'] = this.aiEnabled;
      json[r'code'] = this.code;
    if (this.maxProperties != null) {
      json[r'maxProperties'] = this.maxProperties;
    } else {
      json[r'maxProperties'] = null;
    }
    if (this.maxRoomsPerProperty != null) {
      json[r'maxRoomsPerProperty'] = this.maxRoomsPerProperty;
    } else {
      json[r'maxRoomsPerProperty'] = null;
    }
      json[r'prices'] = this.prices;
    return json;
  }

  /// Returns a new [SubscriptionPlan] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubscriptionPlan? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubscriptionPlan[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubscriptionPlan[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubscriptionPlan(
        aiEnabled: mapValueOfType<bool>(json, r'aiEnabled')!,
        code: PlanCode.fromJson(json[r'code'])!,
        maxProperties: mapValueOfType<int>(json, r'maxProperties'),
        maxRoomsPerProperty: mapValueOfType<int>(json, r'maxRoomsPerProperty'),
        prices: SubscriptionPlanPrice.listFromJson(json[r'prices']),
      );
    }
    return null;
  }

  static List<SubscriptionPlan> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionPlan>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionPlan.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubscriptionPlan> mapFromJson(dynamic json) {
    final map = <String, SubscriptionPlan>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubscriptionPlan.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubscriptionPlan-objects as value to a dart map
  static Map<String, List<SubscriptionPlan>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubscriptionPlan>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubscriptionPlan.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'aiEnabled',
    'code',
    'maxProperties',
    'maxRoomsPerProperty',
    'prices',
  };
}

