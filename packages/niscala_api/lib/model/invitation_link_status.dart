//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Whether an invitation link can still be used.
class InvitationLinkStatus {
  /// Instantiate a new enum with the provided [value].
  const InvitationLinkStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const valid = InvitationLinkStatus._(r'valid');
  static const expired = InvitationLinkStatus._(r'expired');
  static const used = InvitationLinkStatus._(r'used');

  /// List of all possible values in this [enum][InvitationLinkStatus].
  static const values = <InvitationLinkStatus>[
    valid,
    expired,
    used,
  ];

  static InvitationLinkStatus? fromJson(dynamic value) => InvitationLinkStatusTypeTransformer().decode(value);

  static List<InvitationLinkStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationLinkStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationLinkStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InvitationLinkStatus] to String,
/// and [decode] dynamic data back to [InvitationLinkStatus].
class InvitationLinkStatusTypeTransformer {
  factory InvitationLinkStatusTypeTransformer() => _instance ??= const InvitationLinkStatusTypeTransformer._();

  const InvitationLinkStatusTypeTransformer._();

  String encode(InvitationLinkStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a InvitationLinkStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InvitationLinkStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'valid': return InvitationLinkStatus.valid;
        case r'expired': return InvitationLinkStatus.expired;
        case r'used': return InvitationLinkStatus.used;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [InvitationLinkStatusTypeTransformer] instance.
  static InvitationLinkStatusTypeTransformer? _instance;
}

