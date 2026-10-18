# niscala_api.api.SubscriptionsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancelSubscriptionDowngrade**](SubscriptionsApi.md#cancelsubscriptiondowngrade) | **DELETE** /subscription/scheduled-downgrade | Cancel Subscription Downgrade
[**createSubscriptionOrder**](SubscriptionsApi.md#createsubscriptionorder) | **POST** /subscription/orders | Create Subscription Order
[**getSubscription**](SubscriptionsApi.md#getsubscription) | **GET** /subscription | Get Subscription
[**getSubscriptionOrder**](SubscriptionsApi.md#getsubscriptionorder) | **GET** /subscription/orders/{orderId} | Get Subscription Order
[**listSubscriptionPlans**](SubscriptionsApi.md#listsubscriptionplans) | **GET** /subscription-plans | List Subscription Plans
[**scheduleSubscriptionDowngrade**](SubscriptionsApi.md#schedulesubscriptiondowngrade) | **PUT** /subscription/scheduled-downgrade | Schedule Subscription Downgrade
[**verifySubscriptionPurchase**](SubscriptionsApi.md#verifysubscriptionpurchase) | **POST** /subscription/orders/{orderId}/purchase-verification | Verify Subscription Purchase


# **cancelSubscriptionDowngrade**
> cancelSubscriptionDowngrade()

Cancel Subscription Downgrade

Cancel the scheduled downgrade.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();

try {
    api_instance.cancelSubscriptionDowngrade();
} catch (e) {
    print('Exception when calling SubscriptionsApi->cancelSubscriptionDowngrade: $e\n');
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

# **createSubscriptionOrder**
> SubscriptionOrder createSubscriptionOrder(subscriptionOrderInput)

Create Subscription Order

Start a purchase of a paid plan; the order expires if no purchase completes.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();
final subscriptionOrderInput = SubscriptionOrderInput(); // SubscriptionOrderInput | 

try {
    final result = api_instance.createSubscriptionOrder(subscriptionOrderInput);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionsApi->createSubscriptionOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subscriptionOrderInput** | [**SubscriptionOrderInput**](SubscriptionOrderInput.md)|  | 

### Return type

[**SubscriptionOrder**](SubscriptionOrder.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSubscription**
> Subscription getSubscription()

Get Subscription

Return the Owner's current subscription.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();

try {
    final result = api_instance.getSubscription();
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionsApi->getSubscription: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Subscription**](Subscription.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSubscriptionOrder**
> SubscriptionOrder getSubscriptionOrder(orderId)

Get Subscription Order

Return an order with its status.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();
final orderId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getSubscriptionOrder(orderId);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionsApi->getSubscriptionOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 

### Return type

[**SubscriptionOrder**](SubscriptionOrder.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSubscriptionPlans**
> SubscriptionPlanList listSubscriptionPlans()

List Subscription Plans

List the available plans with limits, AI availability and prices.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();

try {
    final result = api_instance.listSubscriptionPlans();
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionsApi->listSubscriptionPlans: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SubscriptionPlanList**](SubscriptionPlanList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **scheduleSubscriptionDowngrade**
> ScheduledDowngrade scheduleSubscriptionDowngrade(scheduledDowngradeInput)

Schedule Subscription Downgrade

Confirm a downgrade at the end of the paid period and the properties and rooms that stay editable.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();
final scheduledDowngradeInput = ScheduledDowngradeInput(); // ScheduledDowngradeInput | 

try {
    final result = api_instance.scheduleSubscriptionDowngrade(scheduledDowngradeInput);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionsApi->scheduleSubscriptionDowngrade: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scheduledDowngradeInput** | [**ScheduledDowngradeInput**](ScheduledDowngradeInput.md)|  | 

### Return type

[**ScheduledDowngrade**](ScheduledDowngrade.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifySubscriptionPurchase**
> SubscriptionOrder verifySubscriptionPurchase(orderId, purchaseVerificationInput)

Verify Subscription Purchase

Verify the Google Play purchase token of an order and update the order and subscription.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubscriptionsApi();
final orderId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final purchaseVerificationInput = PurchaseVerificationInput(); // PurchaseVerificationInput | 

try {
    final result = api_instance.verifySubscriptionPurchase(orderId, purchaseVerificationInput);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionsApi->verifySubscriptionPurchase: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderId** | **String**|  | 
 **purchaseVerificationInput** | [**PurchaseVerificationInput**](PurchaseVerificationInput.md)|  | 

### Return type

[**SubscriptionOrder**](SubscriptionOrder.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

