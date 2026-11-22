# niscala_api.model.TenantSummary

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accountStatus** | [**TenantAccountStatus**](TenantAccountStatus.md) |  | 
**billingCycle** | [**BillingCycle**](BillingCycle.md) |  | 
**id** | **String** |  | 
**invitationExpiresAt** | [**DateTime**](DateTime.md) |  | [optional] 
**leaseEndDate** | [**DateTime**](DateTime.md) |  | [optional] 
**name** | **String** |  | 
**room** | [**RoomRef**](RoomRef.md) |  | 
**version** | **int** | Rises by one with every edit. Send it back in the If-Match header, as a quoted number such as \"3\", to refuse an edit made on stale data. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


