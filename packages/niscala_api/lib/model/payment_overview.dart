//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PaymentOverview {
  /// Returns a new [PaymentOverview] instance.
  PaymentOverview({
    required this.date,
    this.items = const [],
  });

  DateTime date;

  List<PaymentOverviewItem> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentOverview &&
    other.date == date &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (date.hashCode) +
    (items.hashCode);

  @override
  String toString() => 'PaymentOverview[date=$date, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'date'] = _dateFormatter.format(this.date.toUtc());
      json[r'items'] = this.items;
    return json;
  }

  /// Returns a new [PaymentOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaymentOverview[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaymentOverview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaymentOverview(
        date: mapDateTime(json, r'date', r'')!,
        items: PaymentOverviewItem.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<PaymentOverview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentOverview> mapFromJson(dynamic json) {
    final map = <String, PaymentOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentOverview-objects as value to a dart map
  static Map<String, List<PaymentOverview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentOverview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'date',
    'items',
  };
}

