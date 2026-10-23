# niscala_api.model.PropertyOccupancy

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**name** | **String** |  | 
**occupancyPercentage** | **int** | Occupied rooms as a whole-number percentage of all rooms, halves rounded up; 0 when there are no rooms. | 
**occupiedRoomCount** | **int** |  | 
**roomCount** | **int** |  | 
**rooms** | [**List<OccupancyRoom>**](OccupancyRoom.md) |  | [default to const []]
**vacantRoomCount** | **int** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


