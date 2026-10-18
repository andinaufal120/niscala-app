//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Subscription {
  /// Returns a new [Subscription] instance.
  Subscription({
    required this.autoRenew,
    required this.billingPeriod,
    required this.endDate,
    required this.openOrder,
    required this.planCode,
    required this.propertyCount,
    required this.scheduledDowngrade,
    required this.status,
  });

  /// False when the Owner cancelled renewal in Google Play; the plan stays active until endDate.
  bool autoRenew;

  SubscriptionPeriod? billingPeriod;

  DateTime? endDate;

  SubscriptionOrder? openOrder;

  PlanCode planCode;

  /// Properties the Owner has, view-only ones included.
  int propertyCount;

  ScheduledDowngrade? scheduledDowngrade;

  SubscriptionStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Subscription &&
    other.autoRenew == autoRenew &&
    other.billingPeriod == billingPeriod &&
    other.endDate == endDate &&
    other.openOrder == openOrder &&
    other.planCode == planCode &&
    other.propertyCount == propertyCount &&
    other.scheduledDowngrade == scheduledDowngrade &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (autoRenew.hashCode) +
    (billingPeriod == null ? 0 : billingPeriod!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (openOrder == null ? 0 : openOrder!.hashCode) +
    (planCode.hashCode) +
    (propertyCount.hashCode) +
    (scheduledDowngrade == null ? 0 : scheduledDowngrade!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'Subscription[autoRenew=$autoRenew, billingPeriod=$billingPeriod, endDate=$endDate, openOrder=$openOrder, planCode=$planCode, propertyCount=$propertyCount, scheduledDowngrade=$scheduledDowngrade, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'autoRenew'] = this.autoRenew;
    if (this.billingPeriod != null) {
      json[r'billingPeriod'] = this.billingPeriod;
    } else {
      json[r'billingPeriod'] = null;
    }
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!.toUtc());
    } else {
      json[r'endDate'] = null;
    }
    if (this.openOrder != null) {
      json[r'openOrder'] = this.openOrder;
    } else {
      json[r'openOrder'] = null;
    }
      json[r'planCode'] = this.planCode;
      json[r'propertyCount'] = this.propertyCount;
    if (this.scheduledDowngrade != null) {
      json[r'scheduledDowngrade'] = this.scheduledDowngrade;
    } else {
      json[r'scheduledDowngrade'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [Subscription] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Subscription? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Subscription[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Subscription[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Subscription(
        autoRenew: mapValueOfType<bool>(json, r'autoRenew')!,
        billingPeriod: SubscriptionPeriod.fromJson(json[r'billingPeriod']),
        endDate: mapDateTime(json, r'endDate', r''),
        openOrder: SubscriptionOrder.fromJson(json[r'openOrder']),
        planCode: PlanCode.fromJson(json[r'planCode'])!,
        propertyCount: mapValueOfType<int>(json, r'propertyCount')!,
        scheduledDowngrade: ScheduledDowngrade.fromJson(json[r'scheduledDowngrade']),
        status: SubscriptionStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<Subscription> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Subscription>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Subscription.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Subscription> mapFromJson(dynamic json) {
    final map = <String, Subscription>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Subscription.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Subscription-objects as value to a dart map
  static Map<String, List<Subscription>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Subscription>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Subscription.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'autoRenew',
    'billingPeriod',
    'endDate',
    'openOrder',
    'planCode',
    'propertyCount',
    'scheduledDowngrade',
    'status',
  };
}

