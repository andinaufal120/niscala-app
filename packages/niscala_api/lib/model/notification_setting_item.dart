//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class NotificationSettingItem {
  /// Returns a new [NotificationSettingItem] instance.
  NotificationSettingItem({
    required this.category,
    required this.pushEnabled,
    required this.urgencyScope,
  });

  NotificationCategory category;

  bool pushEnabled;

  NotificationUrgencyScope? urgencyScope;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationSettingItem &&
    other.category == category &&
    other.pushEnabled == pushEnabled &&
    other.urgencyScope == urgencyScope;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (category.hashCode) +
    (pushEnabled.hashCode) +
    (urgencyScope == null ? 0 : urgencyScope!.hashCode);

  @override
  String toString() => 'NotificationSettingItem[category=$category, pushEnabled=$pushEnabled, urgencyScope=$urgencyScope]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'category'] = this.category;
      json[r'pushEnabled'] = this.pushEnabled;
    if (this.urgencyScope != null) {
      json[r'urgencyScope'] = this.urgencyScope;
    } else {
      json[r'urgencyScope'] = null;
    }
    return json;
  }

  /// Returns a new [NotificationSettingItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationSettingItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationSettingItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationSettingItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationSettingItem(
        category: NotificationCategory.fromJson(json[r'category'])!,
        pushEnabled: mapValueOfType<bool>(json, r'pushEnabled')!,
        urgencyScope: NotificationUrgencyScope.fromJson(json[r'urgencyScope']),
      );
    }
    return null;
  }

  static List<NotificationSettingItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationSettingItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationSettingItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationSettingItem> mapFromJson(dynamic json) {
    final map = <String, NotificationSettingItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationSettingItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationSettingItem-objects as value to a dart map
  static Map<String, List<NotificationSettingItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationSettingItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationSettingItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
    'pushEnabled',
    'urgencyScope',
  };
}

