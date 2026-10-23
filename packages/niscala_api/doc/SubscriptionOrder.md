# niscala_api.model.SubscriptionOrder

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**billingPeriod** | [**SubscriptionPeriod**](SubscriptionPeriod.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**googlePlayBasePlanId** | **String** |  | 
**googlePlayProductId** | **String** |  | 
**id** | **String** |  | 
**obfuscatedAccountId** | **String** | Opaque id the app passes to Google Play Billing when it starts the purchase, so the purchase can be tied to this Owner. | 
**planCode** | [**PaidPlanCode**](PaidPlanCode.md) |  | 
**status** | [**OrderStatus**](OrderStatus.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


