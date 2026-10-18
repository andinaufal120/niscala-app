//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PaymentPattern {
  /// Returns a new [PaymentPattern] instance.
  PaymentPattern({
    required this.arrears,
    required this.atRisk,
    required this.averageDaysLate,
    required this.countedBillCount,
    required this.onTimeCount,
    required this.room,
    this.summary,
    required this.summaryWithheld,
    required this.tenant,
  });

  /// In rupiah.
  ///
  /// Minimum value: 0
  int arrears;

  bool atRisk;

  /// Minimum value: 0
  int averageDaysLate;

  /// Minimum value: 0
  /// Maximum value: 6
  int countedBillCount;

  /// Minimum value: 0
  int onTimeCount;

  RoomRef room;

  String? summary;

  /// True when a summary exists but is withheld for lack of a subscription.
  bool summaryWithheld;

  TenantRef tenant;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentPattern &&
    other.arrears == arrears &&
    other.atRisk == atRisk &&
    other.averageDaysLate == averageDaysLate &&
    other.countedBillCount == countedBillCount &&
    other.onTimeCount == onTimeCount &&
    other.room == room &&
    other.summary == summary &&
    other.summaryWithheld == summaryWithheld &&
    other.tenant == tenant;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (arrears.hashCode) +
    (atRisk.hashCode) +
    (averageDaysLate.hashCode) +
    (countedBillCount.hashCode) +
    (onTimeCount.hashCode) +
    (room.hashCode) +
    (summary == null ? 0 : summary!.hashCode) +
    (summaryWithheld.hashCode) +
    (tenant.hashCode);

  @override
  String toString() => 'PaymentPattern[arrears=$arrears, atRisk=$atRisk, averageDaysLate=$averageDaysLate, countedBillCount=$countedBillCount, onTimeCount=$onTimeCount, room=$room, summary=$summary, summaryWithheld=$summaryWithheld, tenant=$tenant]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'arrears'] = this.arrears;
      json[r'atRisk'] = this.atRisk;
      json[r'averageDaysLate'] = this.averageDaysLate;
      json[r'countedBillCount'] = this.countedBillCount;
      json[r'onTimeCount'] = this.onTimeCount;
      json[r'room'] = this.room;
    if (this.summary != null) {
      json[r'summary'] = this.summary;
    } else {
      json[r'summary'] = null;
    }
      json[r'summaryWithheld'] = this.summaryWithheld;
      json[r'tenant'] = this.tenant;
    return json;
  }

  /// Returns a new [PaymentPattern] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentPattern? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaymentPattern[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaymentPattern[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaymentPattern(
        arrears: mapValueOfType<int>(json, r'arrears')!,
        atRisk: mapValueOfType<bool>(json, r'atRisk')!,
        averageDaysLate: mapValueOfType<int>(json, r'averageDaysLate')!,
        countedBillCount: mapValueOfType<int>(json, r'countedBillCount')!,
        onTimeCount: mapValueOfType<int>(json, r'onTimeCount')!,
        room: RoomRef.fromJson(json[r'room'])!,
        summary: mapValueOfType<String>(json, r'summary'),
        summaryWithheld: mapValueOfType<bool>(json, r'summaryWithheld')!,
        tenant: TenantRef.fromJson(json[r'tenant'])!,
      );
    }
    return null;
  }

  static List<PaymentPattern> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentPattern>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentPattern.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentPattern> mapFromJson(dynamic json) {
    final map = <String, PaymentPattern>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentPattern.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentPattern-objects as value to a dart map
  static Map<String, List<PaymentPattern>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentPattern>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentPattern.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'arrears',
    'atRisk',
    'averageDaysLate',
    'countedBillCount',
    'onTimeCount',
    'room',
    'summaryWithheld',
    'tenant',
  };
}

