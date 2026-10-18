//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class TenantInvitation {
  /// Returns a new [TenantInvitation] instance.
  TenantInvitation({
    required this.createdAt,
    required this.expired,
    required this.expiresAt,
    this.url,
  });

  DateTime createdAt;

  bool expired;

  DateTime expiresAt;

  String? url;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TenantInvitation &&
    other.createdAt == createdAt &&
    other.expired == expired &&
    other.expiresAt == expiresAt &&
    other.url == url;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (createdAt.hashCode) +
    (expired.hashCode) +
    (expiresAt.hashCode) +
    (url == null ? 0 : url!.hashCode);

  @override
  String toString() => 'TenantInvitation[createdAt=$createdAt, expired=$expired, expiresAt=$expiresAt, url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
      json[r'expired'] = this.expired;
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    return json;
  }

  /// Returns a new [TenantInvitation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TenantInvitation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TenantInvitation[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TenantInvitation[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TenantInvitation(
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        expired: mapValueOfType<bool>(json, r'expired')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
        url: mapValueOfType<String>(json, r'url'),
      );
    }
    return null;
  }

  static List<TenantInvitation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TenantInvitation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TenantInvitation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TenantInvitation> mapFromJson(dynamic json) {
    final map = <String, TenantInvitation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TenantInvitation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TenantInvitation-objects as value to a dart map
  static Map<String, List<TenantInvitation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TenantInvitation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TenantInvitation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'createdAt',
    'expired',
    'expiresAt',
  };
}

