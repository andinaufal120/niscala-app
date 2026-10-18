# niscala_api.api.ManagersApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createManager**](ManagersApi.md#createmanager) | **POST** /managers | Create Manager
[**deleteManager**](ManagersApi.md#deletemanager) | **DELETE** /managers/{managerId} | Delete Manager
[**getManager**](ManagersApi.md#getmanager) | **GET** /managers/{managerId} | Get Manager
[**listManagers**](ManagersApi.md#listmanagers) | **GET** /managers | List Managers
[**regenerateManagerInvitation**](ManagersApi.md#regeneratemanagerinvitation) | **POST** /managers/{managerId}/invitation | Regenerate Manager Invitation
[**updateManager**](ManagersApi.md#updatemanager) | **PUT** /managers/{managerId} | Update Manager


# **createManager**
> Manager createManager(managerInput)

Create Manager

Add a manager to properties of the Owner and return them with an invitation.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ManagersApi();
final managerInput = ManagerInput(); // ManagerInput | 

try {
    final result = api_instance.createManager(managerInput);
    print(result);
} catch (e) {
    print('Exception when calling ManagersApi->createManager: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **managerInput** | [**ManagerInput**](ManagerInput.md)|  | 

### Return type

[**Manager**](Manager.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteManager**
> deleteManager(managerId)

Delete Manager

Revoke the manager's assignments to the Owner's properties; history is kept.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ManagersApi();
final managerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteManager(managerId);
} catch (e) {
    print('Exception when calling ManagersApi->deleteManager: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **managerId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getManager**
> Manager getManager(managerId)

Get Manager

Return a manager's detail, with the invitation while not activated.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ManagersApi();
final managerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getManager(managerId);
    print(result);
} catch (e) {
    print('Exception when calling ManagersApi->getManager: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **managerId** | **String**|  | 

### Return type

[**Manager**](Manager.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listManagers**
> ManagerList listManagers(propertyId)

List Managers

List the Owner's managers, optionally only those assigned to one property.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ManagersApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listManagers(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling ManagersApi->listManagers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | [optional] 

### Return type

[**ManagerList**](ManagerList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **regenerateManagerInvitation**
> ManagerInvitation regenerateManagerInvitation(managerId)

Regenerate Manager Invitation

Create a new invitation link for a manager, invalidating the old one.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ManagersApi();
final managerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.regenerateManagerInvitation(managerId);
    print(result);
} catch (e) {
    print('Exception when calling ManagersApi->regenerateManagerInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **managerId** | **String**|  | 

### Return type

[**ManagerInvitation**](ManagerInvitation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateManager**
> Manager updateManager(managerId, managerInput)

Update Manager

Replace a manager's fields; access to removed properties is revoked.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ManagersApi();
final managerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final managerInput = ManagerInput(); // ManagerInput | 

try {
    final result = api_instance.updateManager(managerId, managerInput);
    print(result);
} catch (e) {
    print('Exception when calling ManagersApi->updateManager: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **managerId** | **String**|  | 
 **managerInput** | [**ManagerInput**](ManagerInput.md)|  | 

### Return type

[**Manager**](Manager.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

