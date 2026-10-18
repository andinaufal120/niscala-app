//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class PaymentStatusChangeInput {
  /// Returns a new [PaymentStatusChangeInput] instance.
  PaymentStatusChangeInput({
    this.method,
    required this.reason,
    this.receivedOn,
    required this.status,
  });

  PaymentMethod? method;

  /// Not blank after trimming.
  String reason;

  DateTime? receivedOn;

  PaymentStatusChangeInputStatusEnum status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentStatusChangeInput &&
    other.method == method &&
    other.reason == reason &&
    other.receivedOn == receivedOn &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (method == null ? 0 : method!.hashCode) +
    (reason.hashCode) +
    (receivedOn == null ? 0 : receivedOn!.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'PaymentStatusChangeInput[method=$method, reason=$reason, receivedOn=$receivedOn, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.method != null) {
      json[r'method'] = this.method;
    } else {
      json[r'method'] = null;
    }
      json[r'reason'] = this.reason;
    if (this.receivedOn != null) {
      json[r'receivedOn'] = _dateFormatter.format(this.receivedOn!.toUtc());
    } else {
      json[r'receivedOn'] = null;
    }
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [PaymentStatusChangeInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentStatusChangeInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaymentStatusChangeInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaymentStatusChangeInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaymentStatusChangeInput(
        method: PaymentMethod.fromJson(json[r'method']),
        reason: mapValueOfType<String>(json, r'reason')!,
        receivedOn: mapDateTime(json, r'receivedOn', r''),
        status: PaymentStatusChangeInputStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<PaymentStatusChangeInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentStatusChangeInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentStatusChangeInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentStatusChangeInput> mapFromJson(dynamic json) {
    final map = <String, PaymentStatusChangeInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentStatusChangeInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentStatusChangeInput-objects as value to a dart map
  static Map<String, List<PaymentStatusChangeInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentStatusChangeInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentStatusChangeInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reason',
    'status',
  };
}


class PaymentStatusChangeInputStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const PaymentStatusChangeInputStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unpaid = PaymentStatusChangeInputStatusEnum._(r'unpaid');
  static const paid = PaymentStatusChangeInputStatusEnum._(r'paid');
  static const rejected = PaymentStatusChangeInputStatusEnum._(r'rejected');

  /// List of all possible values in this [enum][PaymentStatusChangeInputStatusEnum].
  static const values = <PaymentStatusChangeInputStatusEnum>[
    unpaid,
    paid,
    rejected,
  ];

  static PaymentStatusChangeInputStatusEnum? fromJson(dynamic value) => PaymentStatusChangeInputStatusEnumTypeTransformer().decode(value);

  static List<PaymentStatusChangeInputStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentStatusChangeInputStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentStatusChangeInputStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentStatusChangeInputStatusEnum] to String,
/// and [decode] dynamic data back to [PaymentStatusChangeInputStatusEnum].
class PaymentStatusChangeInputStatusEnumTypeTransformer {
  factory PaymentStatusChangeInputStatusEnumTypeTransformer() => _instance ??= const PaymentStatusChangeInputStatusEnumTypeTransformer._();

  const PaymentStatusChangeInputStatusEnumTypeTransformer._();

  String encode(PaymentStatusChangeInputStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PaymentStatusChangeInputStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentStatusChangeInputStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unpaid': return PaymentStatusChangeInputStatusEnum.unpaid;
        case r'paid': return PaymentStatusChangeInputStatusEnum.paid;
        case r'rejected': return PaymentStatusChangeInputStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PaymentStatusChangeInputStatusEnumTypeTransformer] instance.
  static PaymentStatusChangeInputStatusEnumTypeTransformer? _instance;
}


