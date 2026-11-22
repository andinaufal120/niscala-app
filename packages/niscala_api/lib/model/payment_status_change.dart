//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PaymentStatusChange {
  /// Returns a new [PaymentStatusChange] instance.
  PaymentStatusChange({
    this.actorName,
    required this.changedAt,
    required this.manual,
    this.method,
    this.reason,
    required this.status,
  });

  String? actorName;

  DateTime changedAt;

  bool manual;

  PaymentMethod? method;

  String? reason;

  PaymentStatus status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentStatusChange &&
    other.actorName == actorName &&
    other.changedAt == changedAt &&
    other.manual == manual &&
    other.method == method &&
    other.reason == reason &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (actorName == null ? 0 : actorName!.hashCode) +
    (changedAt.hashCode) +
    (manual.hashCode) +
    (method == null ? 0 : method!.hashCode) +
    (reason == null ? 0 : reason!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'PaymentStatusChange[actorName=$actorName, changedAt=$changedAt, manual=$manual, method=$method, reason=$reason, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.actorName != null) {
      json[r'actorName'] = this.actorName;
    } else {
      json[r'actorName'] = null;
    }
      json[r'changedAt'] = this.changedAt.toUtc().toIso8601String();
      json[r'manual'] = this.manual;
    if (this.method != null) {
      json[r'method'] = this.method;
    } else {
      json[r'method'] = null;
    }
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [PaymentStatusChange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentStatusChange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaymentStatusChange[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaymentStatusChange[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaymentStatusChange(
        actorName: mapValueOfType<String>(json, r'actorName'),
        changedAt: mapDateTime(json, r'changedAt', r'')!,
        manual: mapValueOfType<bool>(json, r'manual')!,
        method: PaymentMethod.fromJson(json[r'method']),
        reason: mapValueOfType<String>(json, r'reason'),
        status: PaymentStatus.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<PaymentStatusChange> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentStatusChange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentStatusChange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentStatusChange> mapFromJson(dynamic json) {
    final map = <String, PaymentStatusChange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentStatusChange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentStatusChange-objects as value to a dart map
  static Map<String, List<PaymentStatusChange>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentStatusChange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentStatusChange.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'changedAt',
    'manual',
    'status',
  };
}

