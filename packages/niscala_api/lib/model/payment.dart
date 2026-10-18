//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class Payment {
  /// Returns a new [Payment] instance.
  Payment({
    required this.hasReceipt,
    this.method,
    this.paidOn,
    this.rejectionReason,
    required this.status,
  });

  bool hasReceipt;

  PaymentMethod? method;

  DateTime? paidOn;

  String? rejectionReason;

  PaymentStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Payment &&
    other.hasReceipt == hasReceipt &&
    other.method == method &&
    other.paidOn == paidOn &&
    other.rejectionReason == rejectionReason &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hasReceipt.hashCode) +
    (method == null ? 0 : method!.hashCode) +
    (paidOn == null ? 0 : paidOn!.hashCode) +
    (rejectionReason == null ? 0 : rejectionReason!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'Payment[hasReceipt=$hasReceipt, method=$method, paidOn=$paidOn, rejectionReason=$rejectionReason, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'hasReceipt'] = this.hasReceipt;
    if (this.method != null) {
      json[r'method'] = this.method;
    } else {
      json[r'method'] = null;
    }
    if (this.paidOn != null) {
      json[r'paidOn'] = _dateFormatter.format(this.paidOn!.toUtc());
    } else {
      json[r'paidOn'] = null;
    }
    if (this.rejectionReason != null) {
      json[r'rejectionReason'] = this.rejectionReason;
    } else {
      json[r'rejectionReason'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [Payment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Payment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Payment[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Payment[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Payment(
        hasReceipt: mapValueOfType<bool>(json, r'hasReceipt')!,
        method: PaymentMethod.fromJson(json[r'method']),
        paidOn: mapDateTime(json, r'paidOn', r''),
        rejectionReason: mapValueOfType<String>(json, r'rejectionReason'),
        status: PaymentStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<Payment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Payment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Payment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Payment> mapFromJson(dynamic json) {
    final map = <String, Payment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Payment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Payment-objects as value to a dart map
  static Map<String, List<Payment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Payment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Payment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hasReceipt',
    'status',
  };
}

