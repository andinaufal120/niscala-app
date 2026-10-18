//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class RentBillSummary {
  /// Returns a new [RentBillSummary] instance.
  RentBillSummary({
    required this.amount,
    required this.daysOverdue,
    required this.dueDate,
    required this.id,
    required this.payment,
    required this.periodEnd,
    required this.periodStart,
    required this.room,
    required this.tenant,
  });

  /// In rupiah.
  int amount;

  /// Days past the due date while unpaid or rejected, else 0.
  ///
  /// Minimum value: 0
  int daysOverdue;

  DateTime dueDate;

  String id;

  Payment payment;

  DateTime periodEnd;

  DateTime periodStart;

  RoomRef room;

  TenantRef tenant;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentBillSummary &&
    other.amount == amount &&
    other.daysOverdue == daysOverdue &&
    other.dueDate == dueDate &&
    other.id == id &&
    other.payment == payment &&
    other.periodEnd == periodEnd &&
    other.periodStart == periodStart &&
    other.room == room &&
    other.tenant == tenant;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amount.hashCode) +
    (daysOverdue.hashCode) +
    (dueDate.hashCode) +
    (id.hashCode) +
    (payment.hashCode) +
    (periodEnd.hashCode) +
    (periodStart.hashCode) +
    (room.hashCode) +
    (tenant.hashCode);

  @override
  String toString() => 'RentBillSummary[amount=$amount, daysOverdue=$daysOverdue, dueDate=$dueDate, id=$id, payment=$payment, periodEnd=$periodEnd, periodStart=$periodStart, room=$room, tenant=$tenant]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'amount'] = this.amount;
      json[r'daysOverdue'] = this.daysOverdue;
      json[r'dueDate'] = _dateFormatter.format(this.dueDate.toUtc());
      json[r'id'] = this.id;
      json[r'payment'] = this.payment;
      json[r'periodEnd'] = _dateFormatter.format(this.periodEnd.toUtc());
      json[r'periodStart'] = _dateFormatter.format(this.periodStart.toUtc());
      json[r'room'] = this.room;
      json[r'tenant'] = this.tenant;
    return json;
  }

  /// Returns a new [RentBillSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentBillSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RentBillSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RentBillSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RentBillSummary(
        amount: mapValueOfType<int>(json, r'amount')!,
        daysOverdue: mapValueOfType<int>(json, r'daysOverdue')!,
        dueDate: mapDateTime(json, r'dueDate', r'')!,
        id: mapValueOfType<String>(json, r'id')!,
        payment: Payment.fromJson(json[r'payment'])!,
        periodEnd: mapDateTime(json, r'periodEnd', r'')!,
        periodStart: mapDateTime(json, r'periodStart', r'')!,
        room: RoomRef.fromJson(json[r'room'])!,
        tenant: TenantRef.fromJson(json[r'tenant'])!,
      );
    }
    return null;
  }

  static List<RentBillSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentBillSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentBillSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentBillSummary> mapFromJson(dynamic json) {
    final map = <String, RentBillSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentBillSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentBillSummary-objects as value to a dart map
  static Map<String, List<RentBillSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentBillSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentBillSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'daysOverdue',
    'dueDate',
    'id',
    'payment',
    'periodEnd',
    'periodStart',
    'room',
    'tenant',
  };
}

