//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class NotificationsApi {
  NotificationsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Notification Settings
  ///
  /// Return the caller's push settings, one entry per category of their role.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getNotificationSettingsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/me/notification-settings';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get Notification Settings
  ///
  /// Return the caller's push settings, one entry per category of their role.
  Future<NotificationSettings?> getNotificationSettings() async {
    final response = await getNotificationSettingsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotificationSettings',) as NotificationSettings;
    
    }
    return null;
  }

  /// List Notifications
  ///
  /// List the caller's notifications, newest first, with the unread count.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listNotificationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/notifications';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Notifications
  ///
  /// List the caller's notifications, newest first, with the unread count.
  Future<NotificationList?> listNotifications() async {
    final response = await listNotificationsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotificationList',) as NotificationList;
    
    }
    return null;
  }

  /// Mark All Notifications Read
  ///
  /// Mark all of the caller's notifications read.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> markAllNotificationsReadWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/notifications/read-all';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Mark All Notifications Read
  ///
  /// Mark all of the caller's notifications read.
  Future<void> markAllNotificationsRead() async {
    final response = await markAllNotificationsReadWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Mark Notification Read
  ///
  /// Mark one of the caller's notifications read; already read stays read.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] notificationId (required):
  Future<Response> markNotificationReadWithHttpInfo(String notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/notifications/{notificationId}/read'
      .replaceAll('{notificationId}', notificationId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Mark Notification Read
  ///
  /// Mark one of the caller's notifications read; already read stays read.
  ///
  /// Parameters:
  ///
  /// * [String] notificationId (required):
  Future<Notification?> markNotificationRead(String notificationId,) async {
    final response = await markNotificationReadWithHttpInfo(notificationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Notification',) as Notification;
    
    }
    return null;
  }

  /// Register Push Token
  ///
  /// Register the current session's device push token, replacing any earlier one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PushTokenInput] pushTokenInput (required):
  Future<Response> registerPushTokenWithHttpInfo(PushTokenInput pushTokenInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/push-token';

    // ignore: prefer_final_locals
    Object? postBody = pushTokenInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Register Push Token
  ///
  /// Register the current session's device push token, replacing any earlier one.
  ///
  /// Parameters:
  ///
  /// * [PushTokenInput] pushTokenInput (required):
  Future<void> registerPushToken(PushTokenInput pushTokenInput,) async {
    final response = await registerPushTokenWithHttpInfo(pushTokenInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Update Notification Settings
  ///
  /// Replace the caller's push settings.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotificationSettingsInput] notificationSettingsInput (required):
  Future<Response> updateNotificationSettingsWithHttpInfo(NotificationSettingsInput notificationSettingsInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/notification-settings';

    // ignore: prefer_final_locals
    Object? postBody = notificationSettingsInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update Notification Settings
  ///
  /// Replace the caller's push settings.
  ///
  /// Parameters:
  ///
  /// * [NotificationSettingsInput] notificationSettingsInput (required):
  Future<NotificationSettings?> updateNotificationSettings(NotificationSettingsInput notificationSettingsInput,) async {
    final response = await updateNotificationSettingsWithHttpInfo(notificationSettingsInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotificationSettings',) as NotificationSettings;
    
    }
    return null;
  }
}
