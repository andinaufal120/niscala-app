# niscala_api.model.Room

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**baseRate** | **int** | Per month, in rupiah. | 
**editable** | **bool** | False while the room is view-only. | 
**facilities** | **List<String>** |  | [default to const []]
**id** | **String** |  | 
**lease** | [**RoomLease**](RoomLease.md) |  | [optional] 
**lengthM** | **num** |  | [optional] 
**number** | **String** |  | 
**occupancy** | [**Occupancy**](Occupancy.md) |  | 
**propertyId** | **String** |  | 
**version** | **int** | Rises by one with every edit. Send it back in the If-Match header, as a quoted number such as \"3\", to refuse an edit made on stale data. | 
**widthM** | **num** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


