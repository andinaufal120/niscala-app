# niscala_api.model.UserAccount

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**activeLeaseCount** | **int** | Owner: across owned properties. Tenant: 0 or 1. Otherwise 0. | 
**email** | **String** | The email the account logs in with. | 
**id** | **String** |  | 
**lastLoginAt** | [**DateTime**](DateTime.md) |  | 
**loginMethods** | [**List<LoginMethod>**](LoginMethod.md) |  | [default to const []]
**name** | **String** |  | 
**pendingEmail** | **String** |  | 
**pendingEmailExpiresAt** | [**DateTime**](DateTime.md) |  | 
**properties** | [**List<AccountPropertyRef>**](AccountPropertyRef.md) | Owned (Owner) or assigned (Manager); empty for other roles. | [default to const []]
**registeredAt** | [**DateTime**](DateTime.md) |  | 
**role** | [**UserRole**](UserRole.md) |  | 
**status** | [**UserAccountStatus**](UserAccountStatus.md) |  | 
**tenancy** | [**AccountTenancy**](AccountTenancy.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


