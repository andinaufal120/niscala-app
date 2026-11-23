# niscala_api.model.UserAccount

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**activeLeaseCount** | **int** | Owner: across owned properties. Tenant: across their records. Otherwise 0. | 
**email** | **String** | The email the account logs in with. | 
**id** | **String** |  | 
**lastLoginAt** | [**DateTime**](DateTime.md) |  | [optional] 
**loginMethods** | [**List<LoginMethod>**](LoginMethod.md) |  | [default to const []]
**name** | **String** |  | 
**pendingEmail** | **String** |  | [optional] 
**pendingEmailExpiresAt** | [**DateTime**](DateTime.md) |  | [optional] 
**properties** | [**List<AccountPropertyRef>**](AccountPropertyRef.md) | Owned (Owner) or assigned (Manager); empty for other roles. | [default to const []]
**registeredAt** | [**DateTime**](DateTime.md) |  | 
**role** | [**UserRole**](UserRole.md) |  | 
**status** | [**UserAccountStatus**](UserAccountStatus.md) |  | 
**tenancies** | [**List<AccountTenancy>**](AccountTenancy.md) | A Tenant's active leases; empty for other roles. | [default to const []]
**version** | **int** | Rises by one with every edit. Send it back in the If-Match header, as a quoted number such as \"3\", to refuse an edit made on stale data. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


