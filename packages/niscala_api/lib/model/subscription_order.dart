//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class SubscriptionOrder {
  /// Returns a new [SubscriptionOrder] instance.
  SubscriptionOrder({
    required this.billingPeriod,
    required this.createdAt,
    required this.googlePlayBasePlanId,
    required this.googlePlayProductId,
    required this.id,
    required this.obfuscatedAccountId,
    required this.planCode,
    required this.status,
  });

  SubscriptionPeriod billingPeriod;

  DateTime createdAt;

  String googlePlayBasePlanId;

  String googlePlayProductId;

  String id;

  /// Opaque id the app passes to Google Play Billing when it starts the purchase, so the purchase can be tied to this Owner.
  String obfuscatedAccountId;

  PaidPlanCode planCode;

  OrderStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubscriptionOrder &&
    other.billingPeriod == billingPeriod &&
    other.createdAt == createdAt &&
    other.googlePlayBasePlanId == googlePlayBasePlanId &&
    other.googlePlayProductId == googlePlayProductId &&
    other.id == id &&
    other.obfuscatedAccountId == obfuscatedAccountId &&
    other.planCode == planCode &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billingPeriod.hashCode) +
    (createdAt.hashCode) +
    (googlePlayBasePlanId.hashCode) +
    (googlePlayProductId.hashCode) +
    (id.hashCode) +
    (obfuscatedAccountId.hashCode) +
    (planCode.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'SubscriptionOrder[billingPeriod=$billingPeriod, createdAt=$createdAt, googlePlayBasePlanId=$googlePlayBasePlanId, googlePlayProductId=$googlePlayProductId, id=$id, obfuscatedAccountId=$obfuscatedAccountId, planCode=$planCode, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'billingPeriod'] = this.billingPeriod;
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'googlePlayBasePlanId'] = this.googlePlayBasePlanId;
      json[r'googlePlayProductId'] = this.googlePlayProductId;
      json[r'id'] = this.id;
      json[r'obfuscatedAccountId'] = this.obfuscatedAccountId;
      json[r'planCode'] = this.planCode;
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [SubscriptionOrder] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubscriptionOrder? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubscriptionOrder[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubscriptionOrder[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubscriptionOrder(
        billingPeriod: SubscriptionPeriod.fromJson(json[r'billingPeriod'])!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        googlePlayBasePlanId: mapValueOfType<String>(json, r'googlePlayBasePlanId')!,
        googlePlayProductId: mapValueOfType<String>(json, r'googlePlayProductId')!,
        id: mapValueOfType<String>(json, r'id')!,
        obfuscatedAccountId: mapValueOfType<String>(json, r'obfuscatedAccountId')!,
        planCode: PaidPlanCode.fromJson(json[r'planCode'])!,
        status: OrderStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<SubscriptionOrder> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionOrder>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionOrder.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubscriptionOrder> mapFromJson(dynamic json) {
    final map = <String, SubscriptionOrder>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubscriptionOrder.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubscriptionOrder-objects as value to a dart map
  static Map<String, List<SubscriptionOrder>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubscriptionOrder>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubscriptionOrder.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'billingPeriod',
    'createdAt',
    'googlePlayBasePlanId',
    'googlePlayProductId',
    'id',
    'obfuscatedAccountId',
    'planCode',
    'status',
  };
}

