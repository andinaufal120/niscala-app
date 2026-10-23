//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Lease {
  /// Returns a new [Lease] instance.
  Lease({
    required this.billingCycle,
    this.endDate,
    required this.gracePeriodDays,
    this.nextBillDate,
    required this.rent,
    this.startDate,
  });

  BillingCycle billingCycle;

  DateTime? endDate;

  int gracePeriodDays;

  DateTime? nextBillDate;

  /// Per billing cycle, in rupiah.
  int rent;

  DateTime? startDate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Lease &&
    other.billingCycle == billingCycle &&
    other.endDate == endDate &&
    other.gracePeriodDays == gracePeriodDays &&
    other.nextBillDate == nextBillDate &&
    other.rent == rent &&
    other.startDate == startDate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billingCycle.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (gracePeriodDays.hashCode) +
    (nextBillDate == null ? 0 : nextBillDate!.hashCode) +
    (rent.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode);

  @override
  String toString() => 'Lease[billingCycle=$billingCycle, endDate=$endDate, gracePeriodDays=$gracePeriodDays, nextBillDate=$nextBillDate, rent=$rent, startDate=$startDate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'billingCycle'] = this.billingCycle;
    if (this.endDate != null) {
      json[r'endDate'] = _dateFormatter.format(this.endDate!.toUtc());
    } else {
      json[r'endDate'] = null;
    }
      json[r'gracePeriodDays'] = this.gracePeriodDays;
    if (this.nextBillDate != null) {
      json[r'nextBillDate'] = _dateFormatter.format(this.nextBillDate!.toUtc());
    } else {
      json[r'nextBillDate'] = null;
    }
      json[r'rent'] = this.rent;
    if (this.startDate != null) {
      json[r'startDate'] = _dateFormatter.format(this.startDate!.toUtc());
    } else {
      json[r'startDate'] = null;
    }
    return json;
  }

  /// Returns a new [Lease] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Lease? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Lease[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Lease[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Lease(
        billingCycle: BillingCycle.fromJson(json[r'billingCycle'])!,
        endDate: mapDateTime(json, r'endDate', r''),
        gracePeriodDays: mapValueOfType<int>(json, r'gracePeriodDays')!,
        nextBillDate: mapDateTime(json, r'nextBillDate', r''),
        rent: mapValueOfType<int>(json, r'rent')!,
        startDate: mapDateTime(json, r'startDate', r''),
      );
    }
    return null;
  }

  static List<Lease> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Lease>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Lease.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Lease> mapFromJson(dynamic json) {
    final map = <String, Lease>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Lease.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Lease-objects as value to a dart map
  static Map<String, List<Lease>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Lease>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Lease.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'billingCycle',
    'gracePeriodDays',
    'rent',
  };
}

