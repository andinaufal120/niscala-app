//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class InvitationAcceptancePreview {
  /// Returns a new [InvitationAcceptancePreview] instance.
  InvitationAcceptancePreview({
    required this.accountEmail,
    required this.accountName,
    required this.accountRole,
    required this.activeLease,
    required this.blocker,
    required this.canAccept,
    required this.invitation,
  });

  String accountEmail;

  String accountName;

  UserRole accountRole;

  ActiveLeaseSummary? activeLease;

  InvitationBlocker? blocker;

  /// True only when the link is valid and there is no blocker.
  bool canAccept;

  InvitationPreview invitation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitationAcceptancePreview &&
    other.accountEmail == accountEmail &&
    other.accountName == accountName &&
    other.accountRole == accountRole &&
    other.activeLease == activeLease &&
    other.blocker == blocker &&
    other.canAccept == canAccept &&
    other.invitation == invitation;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accountEmail.hashCode) +
    (accountName.hashCode) +
    (accountRole.hashCode) +
    (activeLease == null ? 0 : activeLease!.hashCode) +
    (blocker == null ? 0 : blocker!.hashCode) +
    (canAccept.hashCode) +
    (invitation.hashCode);

  @override
  String toString() => 'InvitationAcceptancePreview[accountEmail=$accountEmail, accountName=$accountName, accountRole=$accountRole, activeLease=$activeLease, blocker=$blocker, canAccept=$canAccept, invitation=$invitation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accountEmail'] = this.accountEmail;
      json[r'accountName'] = this.accountName;
      json[r'accountRole'] = this.accountRole;
    if (this.activeLease != null) {
      json[r'activeLease'] = this.activeLease;
    } else {
      json[r'activeLease'] = null;
    }
    if (this.blocker != null) {
      json[r'blocker'] = this.blocker;
    } else {
      json[r'blocker'] = null;
    }
      json[r'canAccept'] = this.canAccept;
      json[r'invitation'] = this.invitation;
    return json;
  }

  /// Returns a new [InvitationAcceptancePreview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitationAcceptancePreview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvitationAcceptancePreview[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvitationAcceptancePreview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvitationAcceptancePreview(
        accountEmail: mapValueOfType<String>(json, r'accountEmail')!,
        accountName: mapValueOfType<String>(json, r'accountName')!,
        accountRole: UserRole.fromJson(json[r'accountRole'])!,
        activeLease: ActiveLeaseSummary.fromJson(json[r'activeLease']),
        blocker: InvitationBlocker.fromJson(json[r'blocker']),
        canAccept: mapValueOfType<bool>(json, r'canAccept')!,
        invitation: InvitationPreview.fromJson(json[r'invitation'])!,
      );
    }
    return null;
  }

  static List<InvitationAcceptancePreview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationAcceptancePreview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationAcceptancePreview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitationAcceptancePreview> mapFromJson(dynamic json) {
    final map = <String, InvitationAcceptancePreview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitationAcceptancePreview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitationAcceptancePreview-objects as value to a dart map
  static Map<String, List<InvitationAcceptancePreview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitationAcceptancePreview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitationAcceptancePreview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountEmail',
    'accountName',
    'accountRole',
    'activeLease',
    'blocker',
    'canAccept',
    'invitation',
  };
}

