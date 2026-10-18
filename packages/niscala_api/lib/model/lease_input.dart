//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class LeaseInput {
  /// Returns a new [LeaseInput] instance.
  LeaseInput({
    this.billingCycle = BillingCycle.monthly,
    this.endDate,
    this.gracePeriodDays = 0,
    this.rent,
    this.startDate,
  });

  BillingCycle billingCycle;

  DateTime? endDate;

  /// Minimum value: 0
  int gracePeriodDays;

  int? rent;

  DateTime? startDate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseInput &&
    other.billingCycle == billingCycle &&
    other.endDate == endDate &&
    other.gracePeriodDays == gracePeriodDays &&
    other.rent == rent &&
    other.startDate == startDate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billingCycle.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (gracePeriodDays.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode);

  @override
  String toString() => 'LeaseInput[billingCycle=$billingCycle, endDate=$endDate, gracePeriodDays=$gracePeriodDays, rent=$rent, startDate=$startDate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'billingCycle'] = this.billingCycle;
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!.toUtc());
    } else {
      json[r'endDate'] = null;
    }
      json[r'gracePeriodDays'] = this.gracePeriodDays;
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!.toUtc());
    } else {
      json[r'startDate'] = null;
    }
    return json;
  }

  /// Returns a new [LeaseInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseInput(
        billingCycle: BillingCycle.fromJson(json[r'billingCycle']) ?? BillingCycle.monthly,
        endDate: mapDateTime(json, r'endDate', r''),
        gracePeriodDays: mapValueOfType<int>(json, r'gracePeriodDays') ?? 0,
        rent: mapValueOfType<int>(json, r'rent'),
        startDate: mapDateTime(json, r'startDate', r''),
      );
    }
    return null;
  }

  static List<LeaseInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseInput> mapFromJson(dynamic json) {
    final map = <String, LeaseInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseInput-objects as value to a dart map
  static Map<String, List<LeaseInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

