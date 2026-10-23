//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class RentBill {
  /// Returns a new [RentBill] instance.
  RentBill({
    required this.amount,
    required this.bankAccount,
    required this.daysOverdue,
    required this.dueDate,
    required this.id,
    required this.payment,
    required this.periodEnd,
    required this.periodStart,
    required this.property,
    required this.room,
    this.statusChanges = const [],
    required this.tenant,
  });

  /// In rupiah.
  int amount;

  BankAccount? bankAccount;

  /// Days past the due date while unpaid or rejected, else 0.
  ///
  /// Minimum value: 0
  int daysOverdue;

  DateTime dueDate;

  String id;

  Payment payment;

  DateTime periodEnd;

  DateTime periodStart;

  PropertyRef property;

  RoomRef room;

  /// Oldest first.
  List<PaymentStatusChange> statusChanges;

  TenantRef tenant;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentBill &&
    other.amount == amount &&
    other.bankAccount == bankAccount &&
    other.daysOverdue == daysOverdue &&
    other.dueDate == dueDate &&
    other.id == id &&
    other.payment == payment &&
    other.periodEnd == periodEnd &&
    other.periodStart == periodStart &&
    other.property == property &&
    other.room == room &&
    _deepEquality.equals(other.statusChanges, statusChanges) &&
    other.tenant == tenant;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amount.hashCode) +
    (bankAccount == null ? 0 : bankAccount!.hashCode) +
    (daysOverdue.hashCode) +
    (dueDate.hashCode) +
    (id.hashCode) +
    (payment.hashCode) +
    (periodEnd.hashCode) +
    (periodStart.hashCode) +
    (property.hashCode) +
    (room.hashCode) +
    (statusChanges.hashCode) +
    (tenant.hashCode);

  @override
  String toString() => 'RentBill[amount=$amount, bankAccount=$bankAccount, daysOverdue=$daysOverdue, dueDate=$dueDate, id=$id, payment=$payment, periodEnd=$periodEnd, periodStart=$periodStart, property=$property, room=$room, statusChanges=$statusChanges, tenant=$tenant]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'amount'] = this.amount;
    if (this.bankAccount != null) {
      json[r'bankAccount'] = this.bankAccount;
    } else {
      json[r'bankAccount'] = null;
    }
      json[r'daysOverdue'] = this.daysOverdue;
      json[r'dueDate'] = _dateFormatter.format(this.dueDate.toUtc());
      json[r'id'] = this.id;
      json[r'payment'] = this.payment;
      json[r'periodEnd'] = _dateFormatter.format(this.periodEnd.toUtc());
      json[r'periodStart'] = _dateFormatter.format(this.periodStart.toUtc());
      json[r'property'] = this.property;
      json[r'room'] = this.room;
      json[r'statusChanges'] = this.statusChanges;
      json[r'tenant'] = this.tenant;
    return json;
  }

  /// Returns a new [RentBill] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentBill? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RentBill[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RentBill[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RentBill(
        amount: mapValueOfType<int>(json, r'amount')!,
        bankAccount: BankAccount.fromJson(json[r'bankAccount']),
        daysOverdue: mapValueOfType<int>(json, r'daysOverdue')!,
        dueDate: mapDateTime(json, r'dueDate', r'')!,
        id: mapValueOfType<String>(json, r'id')!,
        payment: Payment.fromJson(json[r'payment'])!,
        periodEnd: mapDateTime(json, r'periodEnd', r'')!,
        periodStart: mapDateTime(json, r'periodStart', r'')!,
        property: PropertyRef.fromJson(json[r'property'])!,
        room: RoomRef.fromJson(json[r'room'])!,
        statusChanges: PaymentStatusChange.listFromJson(json[r'statusChanges']),
        tenant: TenantRef.fromJson(json[r'tenant'])!,
      );
    }
    return null;
  }

  static List<RentBill> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentBill>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentBill.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentBill> mapFromJson(dynamic json) {
    final map = <String, RentBill>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentBill.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentBill-objects as value to a dart map
  static Map<String, List<RentBill>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentBill>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentBill.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'bankAccount',
    'daysOverdue',
    'dueDate',
    'id',
    'payment',
    'periodEnd',
    'periodStart',
    'property',
    'room',
    'statusChanges',
    'tenant',
  };
}

