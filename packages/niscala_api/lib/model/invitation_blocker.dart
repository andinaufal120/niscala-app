//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

/// Why an existing account cannot accept an invitation.
class InvitationBlocker {
  /// Instantiate a new enum with the provided [value].
  const InvitationBlocker._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const roleMismatch = InvitationBlocker._(r'roleMismatch');
  static const activeLease = InvitationBlocker._(r'activeLease');

  /// List of all possible values in this [enum][InvitationBlocker].
  static const values = <InvitationBlocker>[
    roleMismatch,
    activeLease,
  ];

  static InvitationBlocker? fromJson(dynamic value) => InvitationBlockerTypeTransformer().decode(value);

  static List<InvitationBlocker> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationBlocker>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationBlocker.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InvitationBlocker] to String,
/// and [decode] dynamic data back to [InvitationBlocker].
class InvitationBlockerTypeTransformer {
  factory InvitationBlockerTypeTransformer() => _instance ??= const InvitationBlockerTypeTransformer._();

  const InvitationBlockerTypeTransformer._();

  String encode(InvitationBlocker data) => data.value;

  /// Decodes a [dynamic value][data] to a InvitationBlocker.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InvitationBlocker? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'roleMismatch': return InvitationBlocker.roleMismatch;
        case r'activeLease': return InvitationBlocker.activeLease;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [InvitationBlockerTypeTransformer] instance.
  static InvitationBlockerTypeTransformer? _instance;
}

