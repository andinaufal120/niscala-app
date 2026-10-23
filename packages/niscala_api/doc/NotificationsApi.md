# niscala_api.api.NotificationsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getNotificationSettings**](NotificationsApi.md#getnotificationsettings) | **GET** /me/notification-settings | Get Notification Settings
[**listNotifications**](NotificationsApi.md#listnotifications) | **GET** /notifications | List Notifications
[**markAllNotificationsRead**](NotificationsApi.md#markallnotificationsread) | **POST** /notifications/read-all | Mark All Notifications Read
[**markNotificationRead**](NotificationsApi.md#marknotificationread) | **POST** /notifications/{notificationId}/read | Mark Notification Read
[**registerPushToken**](NotificationsApi.md#registerpushtoken) | **PUT** /me/push-token | Register Push Token
[**updateNotificationSettings**](NotificationsApi.md#updatenotificationsettings) | **PUT** /me/notification-settings | Update Notification Settings


# **getNotificationSettings**
> NotificationSettings getNotificationSettings()

Get Notification Settings

Return the caller's push settings, one entry per category of their role.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationsApi();

try {
    final result = api_instance.getNotificationSettings();
    print(result);
} catch (e) {
    print('Exception when calling NotificationsApi->getNotificationSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**NotificationSettings**](NotificationSettings.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listNotifications**
> NotificationList listNotifications()

List Notifications

List the caller's notifications, newest first, with the unread count.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationsApi();

try {
    final result = api_instance.listNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationsApi->listNotifications: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**NotificationList**](NotificationList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllNotificationsRead**
> markAllNotificationsRead()

Mark All Notifications Read

Mark all of the caller's notifications read.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationsApi();

try {
    api_instance.markAllNotificationsRead();
} catch (e) {
    print('Exception when calling NotificationsApi->markAllNotificationsRead: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markNotificationRead**
> Notification markNotificationRead(notificationId)

Mark Notification Read

Mark one of the caller's notifications read; already read stays read.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationsApi();
final notificationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.markNotificationRead(notificationId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationsApi->markNotificationRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **String**|  | 

### Return type

[**Notification**](Notification.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerPushToken**
> registerPushToken(pushTokenInput)

Register Push Token

Register the current session's device push token, replacing any earlier one.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationsApi();
final pushTokenInput = PushTokenInput(); // PushTokenInput | 

try {
    api_instance.registerPushToken(pushTokenInput);
} catch (e) {
    print('Exception when calling NotificationsApi->registerPushToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pushTokenInput** | [**PushTokenInput**](PushTokenInput.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateNotificationSettings**
> NotificationSettings updateNotificationSettings(notificationSettingsInput)

Update Notification Settings

Replace the caller's push settings.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationsApi();
final notificationSettingsInput = NotificationSettingsInput(); // NotificationSettingsInput | 

try {
    final result = api_instance.updateNotificationSettings(notificationSettingsInput);
    print(result);
} catch (e) {
    print('Exception when calling NotificationsApi->updateNotificationSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationSettingsInput** | [**NotificationSettingsInput**](NotificationSettingsInput.md)|  | 

### Return type

[**NotificationSettings**](NotificationSettings.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

