# niscala_api.model.Tenant

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accountStatus** | [**TenantAccountStatus**](TenantAccountStatus.md) |  | 
**email** | **String** |  | [optional] 
**emergencyContacts** | [**List<EmergencyContact>**](EmergencyContact.md) |  | [default to const []]
**id** | **String** |  | 
**invitation** | [**TenantInvitation**](TenantInvitation.md) |  | [optional] 
**lease** | [**Lease**](Lease.md) |  | 
**name** | **String** |  | 
**occupation** | **String** |  | [optional] 
**phone** | **String** | Indonesian mobile number; returned as digits starting with 08. | 
**room** | [**RoomRef**](RoomRef.md) |  | 
**version** | **int** | Rises by one with every edit. Send it back in the If-Match header, as a quoted number such as \"3\", to refuse an edit made on stale data. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


