//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class NotificationRentBill {
  /// Returns a new [NotificationRentBill] instance.
  NotificationRentBill({
    required this.amount,
    required this.daysOverdue,
    required this.dueDate,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.periodEnd,
    required this.periodStart,
    required this.reason,
    required this.rentBillId,
  });

  /// In rupiah.
  int amount;

  /// Days past the due date; 0 unless billOverdue.
  ///
  /// Minimum value: 0
  int daysOverdue;

  DateTime dueDate;

  PaymentMethod? paymentMethod;

  /// The status the notification announces, or the bill had at that time.
  PaymentStatus paymentStatus;

  DateTime periodEnd;

  DateTime periodStart;

  String? reason;

  String rentBillId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationRentBill &&
    other.amount == amount &&
    other.daysOverdue == daysOverdue &&
    other.dueDate == dueDate &&
    other.paymentMethod == paymentMethod &&
    other.paymentStatus == paymentStatus &&
    other.periodEnd == periodEnd &&
    other.periodStart == periodStart &&
    other.reason == reason &&
    other.rentBillId == rentBillId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amount.hashCode) +
    (daysOverdue.hashCode) +
    (dueDate.hashCode) +
    (paymentMethod == null ? 0 : paymentMethod!.hashCode) +
    (paymentStatus.hashCode) +
    (periodEnd.hashCode) +
    (periodStart.hashCode) +
    (reason == null ? 0 : reason!.hashCode) +
    (rentBillId.hashCode);

  @override
  String toString() => 'NotificationRentBill[amount=$amount, daysOverdue=$daysOverdue, dueDate=$dueDate, paymentMethod=$paymentMethod, paymentStatus=$paymentStatus, periodEnd=$periodEnd, periodStart=$periodStart, reason=$reason, rentBillId=$rentBillId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'amount'] = this.amount;
      json[r'daysOverdue'] = this.daysOverdue;
      json[r'dueDate'] = _dateFormatter.format(this.dueDate.toUtc());
    if (this.paymentMethod != null) {
      json[r'paymentMethod'] = this.paymentMethod;
    } else {
      json[r'paymentMethod'] = null;
    }
      json[r'paymentStatus'] = this.paymentStatus;
      json[r'periodEnd'] = _dateFormatter.format(this.periodEnd.toUtc());
      json[r'periodStart'] = _dateFormatter.format(this.periodStart.toUtc());
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
      json[r'rentBillId'] = this.rentBillId;
    return json;
  }

  /// Returns a new [NotificationRentBill] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationRentBill? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationRentBill[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationRentBill[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationRentBill(
        amount: mapValueOfType<int>(json, r'amount')!,
        daysOverdue: mapValueOfType<int>(json, r'daysOverdue')!,
        dueDate: mapDateTime(json, r'dueDate', r'')!,
        paymentMethod: PaymentMethod.fromJson(json[r'paymentMethod']),
        paymentStatus: PaymentStatus.fromJson(json[r'paymentStatus'])!,
        periodEnd: mapDateTime(json, r'periodEnd', r'')!,
        periodStart: mapDateTime(json, r'periodStart', r'')!,
        reason: mapValueOfType<String>(json, r'reason'),
        rentBillId: mapValueOfType<String>(json, r'rentBillId')!,
      );
    }
    return null;
  }

  static List<NotificationRentBill> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationRentBill>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationRentBill.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationRentBill> mapFromJson(dynamic json) {
    final map = <String, NotificationRentBill>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationRentBill.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationRentBill-objects as value to a dart map
  static Map<String, List<NotificationRentBill>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationRentBill>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationRentBill.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'daysOverdue',
    'dueDate',
    'paymentMethod',
    'paymentStatus',
    'periodEnd',
    'periodStart',
    'reason',
    'rentBillId',
  };
}

