# niscala_api.api.UserAccountsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteUserAccount**](UserAccountsApi.md#deleteuseraccount) | **DELETE** /user-accounts/{userAccountId} | Delete User Account
[**getUserAccount**](UserAccountsApi.md#getuseraccount) | **GET** /user-accounts/{userAccountId} | Get User Account
[**listUserAccounts**](UserAccountsApi.md#listuseraccounts) | **GET** /user-accounts | List User Accounts
[**updateUserAccount**](UserAccountsApi.md#updateuseraccount) | **PUT** /user-accounts/{userAccountId} | Update User Account


# **deleteUserAccount**
> deleteUserAccount(userAccountId)

Delete User Account

Soft-delete an account and end its sessions.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserAccountsApi();
final userAccountId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteUserAccount(userAccountId);
} catch (e) {
    print('Exception when calling UserAccountsApi->deleteUserAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userAccountId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserAccount**
> UserAccount getUserAccount(userAccountId)

Get User Account

Return one user account with its login details and links.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserAccountsApi();
final userAccountId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getUserAccount(userAccountId);
    print(result);
} catch (e) {
    print('Exception when calling UserAccountsApi->getUserAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userAccountId** | **String**|  | 

### Return type

[**UserAccount**](UserAccount.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUserAccounts**
> UserAccountList listUserAccounts(email, role, includeDeleted)

List User Accounts

List user accounts of every role; deleted ones only on request.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserAccountsApi();
final email = email_example; // String | Case-insensitive match on any part of the current email.
final role = ; // UserRole | 
final includeDeleted = true; // bool | Include deleted accounts.

try {
    final result = api_instance.listUserAccounts(email, role, includeDeleted);
    print(result);
} catch (e) {
    print('Exception when calling UserAccountsApi->listUserAccounts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **email** | **String**| Case-insensitive match on any part of the current email. | [optional] 
 **role** | [**UserRole**](.md)|  | [optional] 
 **includeDeleted** | **bool**| Include deleted accounts. | [optional] [default to false]

### Return type

[**UserAccountList**](UserAccountList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUserAccount**
> UserAccount updateUserAccount(userAccountId, userAccountInput)

Update User Account

Change name, email and status; a new email stays pending until verified.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserAccountsApi();
final userAccountId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final userAccountInput = UserAccountInput(); // UserAccountInput | 

try {
    final result = api_instance.updateUserAccount(userAccountId, userAccountInput);
    print(result);
} catch (e) {
    print('Exception when calling UserAccountsApi->updateUserAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userAccountId** | **String**|  | 
 **userAccountInput** | [**UserAccountInput**](UserAccountInput.md)|  | 

### Return type

[**UserAccount**](UserAccount.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

