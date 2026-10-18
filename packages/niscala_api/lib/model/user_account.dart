//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class UserAccount {
  /// Returns a new [UserAccount] instance.
  UserAccount({
    required this.activeLeaseCount,
    required this.email,
    required this.id,
    required this.lastLoginAt,
    this.loginMethods = const [],
    required this.name,
    required this.pendingEmail,
    required this.pendingEmailExpiresAt,
    this.properties = const [],
    required this.registeredAt,
    required this.role,
    required this.status,
    required this.tenancy,
  });

  /// Owner: across owned properties. Tenant: 0 or 1. Otherwise 0.
  ///
  /// Minimum value: 0
  int activeLeaseCount;

  /// The email the account logs in with.
  String email;

  String id;

  DateTime? lastLoginAt;

  List<LoginMethod> loginMethods;

  String name;

  String? pendingEmail;

  DateTime? pendingEmailExpiresAt;

  /// Owned (Owner) or assigned (Manager); empty for other roles.
  List<AccountPropertyRef> properties;

  DateTime registeredAt;

  UserRole role;

  UserAccountStatus status;

  AccountTenancy? tenancy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserAccount &&
    other.activeLeaseCount == activeLeaseCount &&
    other.email == email &&
    other.id == id &&
    other.lastLoginAt == lastLoginAt &&
    _deepEquality.equals(other.loginMethods, loginMethods) &&
    other.name == name &&
    other.pendingEmail == pendingEmail &&
    other.pendingEmailExpiresAt == pendingEmailExpiresAt &&
    _deepEquality.equals(other.properties, properties) &&
    other.registeredAt == registeredAt &&
    other.role == role &&
    other.status == status &&
    other.tenancy == tenancy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (activeLeaseCount.hashCode) +
    (email.hashCode) +
    (id.hashCode) +
    (lastLoginAt == null ? 0 : lastLoginAt!.hashCode) +
    (loginMethods.hashCode) +
    (name.hashCode) +
    (pendingEmail == null ? 0 : pendingEmail!.hashCode) +
    (pendingEmailExpiresAt == null ? 0 : pendingEmailExpiresAt!.hashCode) +
    (properties.hashCode) +
    (registeredAt.hashCode) +
    (role.hashCode) +
    (status.hashCode) +
    (tenancy == null ? 0 : tenancy!.hashCode);

  @override
  String toString() => 'UserAccount[activeLeaseCount=$activeLeaseCount, email=$email, id=$id, lastLoginAt=$lastLoginAt, loginMethods=$loginMethods, name=$name, pendingEmail=$pendingEmail, pendingEmailExpiresAt=$pendingEmailExpiresAt, properties=$properties, registeredAt=$registeredAt, role=$role, status=$status, tenancy=$tenancy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'activeLeaseCount'] = this.activeLeaseCount;
      json[r'email'] = this.email;
      json[r'id'] = this.id;
    if (this.lastLoginAt != null) {
      json[r'lastLoginAt'] = this.lastLoginAt!.toUtc().toIso8601String();
    } else {
      json[r'lastLoginAt'] = null;
    }
      json[r'loginMethods'] = this.loginMethods;
      json[r'name'] = this.name;
    if (this.pendingEmail != null) {
      json[r'pendingEmail'] = this.pendingEmail;
    } else {
      json[r'pendingEmail'] = null;
    }
    if (this.pendingEmailExpiresAt != null) {
      json[r'pendingEmailExpiresAt'] = this.pendingEmailExpiresAt!.toUtc().toIso8601String();
    } else {
      json[r'pendingEmailExpiresAt'] = null;
    }
      json[r'properties'] = this.properties;
      json[r'registeredAt'] = this.registeredAt.toUtc().toIso8601String();
      json[r'role'] = this.role;
      json[r'status'] = this.status;
    if (this.tenancy != null) {
      json[r'tenancy'] = this.tenancy;
    } else {
      json[r'tenancy'] = null;
    }
    return json;
  }

  /// Returns a new [UserAccount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserAccount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserAccount[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserAccount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserAccount(
        activeLeaseCount: mapValueOfType<int>(json, r'activeLeaseCount')!,
        email: mapValueOfType<String>(json, r'email')!,
        id: mapValueOfType<String>(json, r'id')!,
        lastLoginAt: mapDateTime(json, r'lastLoginAt', r''),
        loginMethods: LoginMethod.listFromJson(json[r'loginMethods']),
        name: mapValueOfType<String>(json, r'name')!,
        pendingEmail: mapValueOfType<String>(json, r'pendingEmail'),
        pendingEmailExpiresAt: mapDateTime(json, r'pendingEmailExpiresAt', r''),
        properties: AccountPropertyRef.listFromJson(json[r'properties']),
        registeredAt: mapDateTime(json, r'registeredAt', r'')!,
        role: UserRole.fromJson(json[r'role'])!,
        status: UserAccountStatus.fromJson(json[r'status'])!,
        tenancy: AccountTenancy.fromJson(json[r'tenancy']),
      );
    }
    return null;
  }

  static List<UserAccount> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserAccount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserAccount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserAccount> mapFromJson(dynamic json) {
    final map = <String, UserAccount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserAccount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserAccount-objects as value to a dart map
  static Map<String, List<UserAccount>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserAccount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserAccount.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'activeLeaseCount',
    'email',
    'id',
    'lastLoginAt',
    'loginMethods',
    'name',
    'pendingEmail',
    'pendingEmailExpiresAt',
    'properties',
    'registeredAt',
    'role',
    'status',
    'tenancy',
  };
}

