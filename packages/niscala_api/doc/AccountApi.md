# niscala_api.api.AccountApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addLocalPassword**](AccountApi.md#addlocalpassword) | **POST** /me/local-password | Add Local Password
[**changeMyPassword**](AccountApi.md#changemypassword) | **POST** /me/password-changes | Change My Password
[**getMyAccount**](AccountApi.md#getmyaccount) | **GET** /me | Get My Account
[**linkGoogle**](AccountApi.md#linkgoogle) | **POST** /me/google-link | Link Google
[**reauthenticateWithGoogle**](AccountApi.md#reauthenticatewithgoogle) | **POST** /me/reauthentication/google | Reauthenticate With Google
[**reauthenticateWithPassword**](AccountApi.md#reauthenticatewithpassword) | **POST** /me/reauthentication/password | Reauthenticate With Password


# **addLocalPassword**
> Account addLocalPassword(addLocalPasswordInput)

Add Local Password

Add a password to a Google account, proven with a fresh Google ID token.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AccountApi();
final addLocalPasswordInput = AddLocalPasswordInput(); // AddLocalPasswordInput | 

try {
    final result = api_instance.addLocalPassword(addLocalPasswordInput);
    print(result);
} catch (e) {
    print('Exception when calling AccountApi->addLocalPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **addLocalPasswordInput** | [**AddLocalPasswordInput**](AddLocalPasswordInput.md)|  | 

### Return type

[**Account**](Account.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **changeMyPassword**
> PasswordChangeResult changeMyPassword(passwordChangeInput)

Change My Password

Replace the caller's password after checking the current one.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AccountApi();
final passwordChangeInput = PasswordChangeInput(); // PasswordChangeInput | 

try {
    final result = api_instance.changeMyPassword(passwordChangeInput);
    print(result);
} catch (e) {
    print('Exception when calling AccountApi->changeMyPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordChangeInput** | [**PasswordChangeInput**](PasswordChangeInput.md)|  | 

### Return type

[**PasswordChangeResult**](PasswordChangeResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyAccount**
> Account getMyAccount()

Get My Account

Return the caller's account and sign-in methods.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AccountApi();

try {
    final result = api_instance.getMyAccount();
    print(result);
} catch (e) {
    print('Exception when calling AccountApi->getMyAccount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Account**](Account.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **linkGoogle**
> Account linkGoogle(linkGoogleInput)

Link Google

Link a Google account to an account that has a password.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AccountApi();
final linkGoogleInput = LinkGoogleInput(); // LinkGoogleInput | 

try {
    final result = api_instance.linkGoogle(linkGoogleInput);
    print(result);
} catch (e) {
    print('Exception when calling AccountApi->linkGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **linkGoogleInput** | [**LinkGoogleInput**](LinkGoogleInput.md)|  | 

### Return type

[**Account**](Account.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reauthenticateWithGoogle**
> Reauthentication reauthenticateWithGoogle(reauthenticationGoogleInput)

Reauthenticate With Google

Confirm the caller's identity with a Google ID token.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AccountApi();
final reauthenticationGoogleInput = ReauthenticationGoogleInput(); // ReauthenticationGoogleInput | 

try {
    final result = api_instance.reauthenticateWithGoogle(reauthenticationGoogleInput);
    print(result);
} catch (e) {
    print('Exception when calling AccountApi->reauthenticateWithGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reauthenticationGoogleInput** | [**ReauthenticationGoogleInput**](ReauthenticationGoogleInput.md)|  | 

### Return type

[**Reauthentication**](Reauthentication.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reauthenticateWithPassword**
> Reauthentication reauthenticateWithPassword(reauthenticationPasswordInput)

Reauthenticate With Password

Confirm the caller's identity with their password.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AccountApi();
final reauthenticationPasswordInput = ReauthenticationPasswordInput(); // ReauthenticationPasswordInput | 

try {
    final result = api_instance.reauthenticateWithPassword(reauthenticationPasswordInput);
    print(result);
} catch (e) {
    print('Exception when calling AccountApi->reauthenticateWithPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reauthenticationPasswordInput** | [**ReauthenticationPasswordInput**](ReauthenticationPasswordInput.md)|  | 

### Return type

[**Reauthentication**](Reauthentication.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

