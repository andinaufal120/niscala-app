# niscala_api.api.AuthApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**confirmEmail**](AuthApi.md#confirmemail) | **POST** /auth/email-verification/confirmation | Confirm Email
[**confirmEmailChange**](AuthApi.md#confirmemailchange) | **POST** /auth/email-changes | Confirm Email Change
[**login**](AuthApi.md#login) | **POST** /auth/login | Login
[**loginWithGoogle**](AuthApi.md#loginwithgoogle) | **POST** /auth/login/google | Login With Google
[**logout**](AuthApi.md#logout) | **POST** /auth/logout | Logout
[**previewPasswordReset**](AuthApi.md#previewpasswordreset) | **POST** /auth/password-reset-previews | Preview Password Reset
[**refreshTokens**](AuthApi.md#refreshtokens) | **POST** /auth/refresh | Refresh Tokens
[**registerOwner**](AuthApi.md#registerowner) | **POST** /auth/register | Register Owner
[**registerOwnerWithGoogle**](AuthApi.md#registerownerwithgoogle) | **POST** /auth/register/google | Register Owner With Google
[**requestPasswordReset**](AuthApi.md#requestpasswordreset) | **POST** /auth/password-reset-requests | Request Password Reset
[**resetPassword**](AuthApi.md#resetpassword) | **POST** /auth/password-resets | Reset Password
[**sendEmailVerification**](AuthApi.md#sendemailverification) | **POST** /auth/email-verification | Send Email Verification


# **confirmEmail**
> Account confirmEmail(emailConfirmationInput)

Confirm Email

Confirm the caller's email with the code that was sent.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();
final emailConfirmationInput = EmailConfirmationInput(); // EmailConfirmationInput | 

try {
    final result = api_instance.confirmEmail(emailConfirmationInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->confirmEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **emailConfirmationInput** | [**EmailConfirmationInput**](EmailConfirmationInput.md)|  | 

### Return type

[**Account**](Account.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **confirmEmailChange**
> confirmEmailChange(tokenInput)

Confirm Email Change

Make the email of an emailed change link the account's login email.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final tokenInput = TokenInput(); // TokenInput | 

try {
    api_instance.confirmEmailChange(tokenInput);
} catch (e) {
    print('Exception when calling AuthApi->confirmEmailChange: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenInput** | [**TokenInput**](TokenInput.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login**
> AuthSession login(loginInput)

Login

Log in with email and password and start a session.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final loginInput = LoginInput(); // LoginInput | 

try {
    final result = api_instance.login(loginInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginInput** | [**LoginInput**](LoginInput.md)|  | 

### Return type

[**AuthSession**](AuthSession.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginWithGoogle**
> AuthSession loginWithGoogle(googleAuthInput)

Login With Google

Log in with Google and start a session.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final googleAuthInput = GoogleAuthInput(); // GoogleAuthInput | 

try {
    final result = api_instance.loginWithGoogle(googleAuthInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->loginWithGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **googleAuthInput** | [**GoogleAuthInput**](GoogleAuthInput.md)|  | 

### Return type

[**AuthSession**](AuthSession.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> logout()

Logout

End the current session.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();

try {
    api_instance.logout();
} catch (e) {
    print('Exception when calling AuthApi->logout: $e\n');
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

# **previewPasswordReset**
> PasswordResetPreview previewPasswordReset(tokenInput)

Preview Password Reset

Check a password-reset link and return the account email.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final tokenInput = TokenInput(); // TokenInput | 

try {
    final result = api_instance.previewPasswordReset(tokenInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->previewPasswordReset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenInput** | [**TokenInput**](TokenInput.md)|  | 

### Return type

[**PasswordResetPreview**](PasswordResetPreview.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshTokens**
> AuthTokens refreshTokens(refreshInput)

Refresh Tokens

Exchange a refresh token for a new token pair; the old one stops working.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final refreshInput = RefreshInput(); // RefreshInput | 

try {
    final result = api_instance.refreshTokens(refreshInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->refreshTokens: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshInput** | [**RefreshInput**](RefreshInput.md)|  | 

### Return type

[**AuthTokens**](AuthTokens.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerOwner**
> AuthSession registerOwner(registerOwnerInput)

Register Owner

Sign up an Owner with a password and start a session.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final registerOwnerInput = RegisterOwnerInput(); // RegisterOwnerInput | 

try {
    final result = api_instance.registerOwner(registerOwnerInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->registerOwner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerOwnerInput** | [**RegisterOwnerInput**](RegisterOwnerInput.md)|  | 

### Return type

[**AuthSession**](AuthSession.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerOwnerWithGoogle**
> AuthSession registerOwnerWithGoogle(googleAuthInput)

Register Owner With Google

Sign up an Owner with Google and start a session.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final googleAuthInput = GoogleAuthInput(); // GoogleAuthInput | 

try {
    final result = api_instance.registerOwnerWithGoogle(googleAuthInput);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->registerOwnerWithGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **googleAuthInput** | [**GoogleAuthInput**](GoogleAuthInput.md)|  | 

### Return type

[**AuthSession**](AuthSession.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestPasswordReset**
> requestPasswordReset(passwordResetRequestInput)

Request Password Reset

Email a password-reset link; answers the same whether or not the email is registered.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final passwordResetRequestInput = PasswordResetRequestInput(); // PasswordResetRequestInput | 

try {
    api_instance.requestPasswordReset(passwordResetRequestInput);
} catch (e) {
    print('Exception when calling AuthApi->requestPasswordReset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordResetRequestInput** | [**PasswordResetRequestInput**](PasswordResetRequestInput.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetPassword**
> resetPassword(passwordResetInput)

Reset Password

Set a new password with a reset link and end every session of the account.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = AuthApi();
final passwordResetInput = PasswordResetInput(); // PasswordResetInput | 

try {
    api_instance.resetPassword(passwordResetInput);
} catch (e) {
    print('Exception when calling AuthApi->resetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordResetInput** | [**PasswordResetInput**](PasswordResetInput.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendEmailVerification**
> EmailVerificationSent sendEmailVerification()

Send Email Verification

Email a new 6-digit verification code to the caller's account.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();

try {
    final result = api_instance.sendEmailVerification();
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->sendEmailVerification: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**EmailVerificationSent**](EmailVerificationSent.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

