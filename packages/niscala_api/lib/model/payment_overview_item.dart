//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PaymentOverviewItem {
  /// Returns a new [PaymentOverviewItem] instance.
  PaymentOverviewItem({
    required this.bill,
    required this.room,
    required this.tenant,
  });

  RentBillSummary? bill;

  RoomRef room;

  TenantRef tenant;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentOverviewItem &&
    other.bill == bill &&
    other.room == room &&
    other.tenant == tenant;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bill == null ? 0 : bill!.hashCode) +
    (room.hashCode) +
    (tenant.hashCode);

  @override
  String toString() => 'PaymentOverviewItem[bill=$bill, room=$room, tenant=$tenant]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.bill != null) {
      json[r'bill'] = this.bill;
    } else {
      json[r'bill'] = null;
    }
      json[r'room'] = this.room;
      json[r'tenant'] = this.tenant;
    return json;
  }

  /// Returns a new [PaymentOverviewItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentOverviewItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaymentOverviewItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaymentOverviewItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaymentOverviewItem(
        bill: RentBillSummary.fromJson(json[r'bill']),
        room: RoomRef.fromJson(json[r'room'])!,
        tenant: TenantRef.fromJson(json[r'tenant'])!,
      );
    }
    return null;
  }

  static List<PaymentOverviewItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentOverviewItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentOverviewItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentOverviewItem> mapFromJson(dynamic json) {
    final map = <String, PaymentOverviewItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentOverviewItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentOverviewItem-objects as value to a dart map
  static Map<String, List<PaymentOverviewItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentOverviewItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentOverviewItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bill',
    'room',
    'tenant',
  };
}

