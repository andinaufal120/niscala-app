# niscala_api.model.Subscription

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**autoRenew** | **bool** | False when the Owner cancelled renewal in Google Play; the plan stays active until endDate. | 
**billingPeriod** | [**SubscriptionPeriod**](SubscriptionPeriod.md) |  | [optional] 
**endDate** | [**DateTime**](DateTime.md) |  | [optional] 
**openOrder** | [**SubscriptionOrder**](SubscriptionOrder.md) |  | [optional] 
**planCode** | [**PlanCode**](PlanCode.md) |  | 
**propertyCount** | **int** | Properties the Owner has, view-only ones included. | 
**scheduledDowngrade** | [**ScheduledDowngrade**](ScheduledDowngrade.md) |  | [optional] 
**status** | [**SubscriptionStatus**](SubscriptionStatus.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


