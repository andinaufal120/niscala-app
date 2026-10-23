//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Statuses an Admin can set; deleted is reached only by deleting the account.
class EditableAccountStatus {
  /// Instantiate a new enum with the provided [value].
  const EditableAccountStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const active = EditableAccountStatus._(r'active');
  static const inactive = EditableAccountStatus._(r'inactive');

  /// List of all possible values in this [enum][EditableAccountStatus].
  static const values = <EditableAccountStatus>[
    active,
    inactive,
  ];

  static EditableAccountStatus? fromJson(dynamic value) => EditableAccountStatusTypeTransformer().decode(value);

  static List<EditableAccountStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EditableAccountStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EditableAccountStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [EditableAccountStatus] to String,
/// and [decode] dynamic data back to [EditableAccountStatus].
class EditableAccountStatusTypeTransformer {
  factory EditableAccountStatusTypeTransformer() => _instance ??= const EditableAccountStatusTypeTransformer._();

  const EditableAccountStatusTypeTransformer._();

  String encode(EditableAccountStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a EditableAccountStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  EditableAccountStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'active': return EditableAccountStatus.active;
        case r'inactive': return EditableAccountStatus.inactive;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [EditableAccountStatusTypeTransformer] instance.
  static EditableAccountStatusTypeTransformer? _instance;
}

