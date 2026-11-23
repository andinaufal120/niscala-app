//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class NotificationSettings {
  /// Returns a new [NotificationSettings] instance.
  NotificationSettings({
    this.items = const [],
  });

  /// One entry per category of the caller's role.
  List<NotificationSettingItem> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationSettings &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode);

  @override
  String toString() => 'NotificationSettings[items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
    return json;
  }

  /// Returns a new [NotificationSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationSettings[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationSettings[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationSettings(
        items: NotificationSettingItem.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<NotificationSettings> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationSettings> mapFromJson(dynamic json) {
    final map = <String, NotificationSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationSettings-objects as value to a dart map
  static Map<String, List<NotificationSettings>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationSettings.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
  };
}

