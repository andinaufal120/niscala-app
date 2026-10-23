# niscala_api.model.InvitationPreview

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**emergencyContactsRequired** | **bool** | True when a Tenant's emergency contacts are still missing. | 
**expiresAt** | [**DateTime**](DateTime.md) |  | 
**inviterName** | **String** |  | 
**name** | **String** | Pre-filled by management. | 
**properties** | [**List<InvitationProperty>**](InvitationProperty.md) | One for a Tenant, one or more for a Manager. | [default to const []]
**role** | [**InvitationRole**](InvitationRole.md) |  | 
**roomNumber** | **String** |  | 
**status** | [**InvitationLinkStatus**](InvitationLinkStatus.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


