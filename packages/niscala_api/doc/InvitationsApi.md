# niscala_api.api.InvitationsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptInvitation**](InvitationsApi.md#acceptinvitation) | **POST** /invitations/acceptances | Accept Invitation
[**activateInvitationWithGoogle**](InvitationsApi.md#activateinvitationwithgoogle) | **POST** /invitations/activations/google | Activate Invitation With Google
[**activateInvitationWithPassword**](InvitationsApi.md#activateinvitationwithpassword) | **POST** /invitations/activations/password | Activate Invitation With Password
[**previewInvitation**](InvitationsApi.md#previewinvitation) | **POST** /invitations/previews | Preview Invitation
[**previewInvitationAcceptance**](InvitationsApi.md#previewinvitationacceptance) | **POST** /invitations/acceptance-previews | Preview Invitation Acceptance


# **acceptInvitation**
> acceptInvitation(tokenInput)

Accept Invitation

Accept an invitation with the caller's existing account.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = InvitationsApi();
final tokenInput = TokenInput(); // TokenInput | 

try {
    api_instance.acceptInvitation(tokenInput);
} catch (e) {
    print('Exception when calling InvitationsApi->acceptInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenInput** | [**TokenInput**](TokenInput.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **activateInvitationWithGoogle**
> AuthSession activateInvitationWithGoogle(invitationGoogleActivationInput)

Activate Invitation With Google

Consume an invitation link, create the account with Google and start a session.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = InvitationsApi();
final invitationGoogleActivationInput = InvitationGoogleActivationInput(); // InvitationGoogleActivationInput | 

try {
    final result = api_instance.activateInvitationWithGoogle(invitationGoogleActivationInput);
    print(result);
} catch (e) {
    print('Exception when calling InvitationsApi->activateInvitationWithGoogle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **invitationGoogleActivationInput** | [**InvitationGoogleActivationInput**](InvitationGoogleActivationInput.md)|  | 

### Return type

[**AuthSession**](AuthSession.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **activateInvitationWithPassword**
> AuthSession activateInvitationWithPassword(invitationPasswordActivationInput)

Activate Invitation With Password

Consume an invitation link, create the account with a password and start a session.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = InvitationsApi();
final invitationPasswordActivationInput = InvitationPasswordActivationInput(); // InvitationPasswordActivationInput | 

try {
    final result = api_instance.activateInvitationWithPassword(invitationPasswordActivationInput);
    print(result);
} catch (e) {
    print('Exception when calling InvitationsApi->activateInvitationWithPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **invitationPasswordActivationInput** | [**InvitationPasswordActivationInput**](InvitationPasswordActivationInput.md)|  | 

### Return type

[**AuthSession**](AuthSession.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **previewInvitation**
> InvitationPreview previewInvitation(tokenInput)

Preview Invitation

Report what an invitation link is for and whether it is still valid.

### Example
```dart
import 'package:niscala_api/api.dart';

final api_instance = InvitationsApi();
final tokenInput = TokenInput(); // TokenInput | 

try {
    final result = api_instance.previewInvitation(tokenInput);
    print(result);
} catch (e) {
    print('Exception when calling InvitationsApi->previewInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenInput** | [**TokenInput**](TokenInput.md)|  | 

### Return type

[**InvitationPreview**](InvitationPreview.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **previewInvitationAcceptance**
> InvitationAcceptancePreview previewInvitationAcceptance(tokenInput)

Preview Invitation Acceptance

Check whether the caller's account can accept an invitation.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = InvitationsApi();
final tokenInput = TokenInput(); // TokenInput | 

try {
    final result = api_instance.previewInvitationAcceptance(tokenInput);
    print(result);
} catch (e) {
    print('Exception when calling InvitationsApi->previewInvitationAcceptance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tokenInput** | [**TokenInput**](TokenInput.md)|  | 

### Return type

[**InvitationAcceptancePreview**](InvitationAcceptancePreview.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

