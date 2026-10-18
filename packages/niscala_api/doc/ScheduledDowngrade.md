# niscala_api.model.ScheduledDowngrade

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**effectiveDate** | [**DateTime**](DateTime.md) | The day after the paid period ends. | 
**keptPropertyIds** | **List<String>** |  | [default to const []]
**keptRoomIds** | **List<String>** | Rooms of the single kept property; empty unless planCode is free. | [default to const []]
**planCode** | [**PlanCode**](PlanCode.md) | The plan that applies from effectiveDate. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


