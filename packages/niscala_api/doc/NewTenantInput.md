# niscala_api.model.NewTenantInput

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**emergencyContacts** | [**List<EmergencyContact>**](EmergencyContact.md) | 2 to 4 contacts. May be empty only while the Tenant's account is not activated; the Tenant then completes them during activation. Exactly 1 is rejected. | [optional] [default to const []]
**lease** | [**LeaseInput**](LeaseInput.md) |  | [optional] 
**name** | **String** |  | 
**occupation** | **String** |  | [optional] 
**phone** | **String** | Indonesian mobile number; returned as digits starting with 08. | 
**roomId** | **String** | A vacant room of the property. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


