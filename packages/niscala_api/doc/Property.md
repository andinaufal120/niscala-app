# niscala_api.model.Property

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**address** | **String** |  | 
**bankAccount** | [**BankAccount**](BankAccount.md) |  | [optional] 
**editable** | **bool** | False while the property is view-only. | 
**id** | **String** |  | 
**managers** | [**List<ManagerRef>**](ManagerRef.md) |  | [default to const []]
**name** | **String** |  | 
**occupiedRoomCount** | **int** |  | 
**roomCount** | **int** |  | 
**vacantRoomCount** | **int** |  | 
**version** | **int** | Rises by one with every edit. Send it back in the If-Match header, as a quoted number such as \"3\", to refuse an edit made on stale data. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


