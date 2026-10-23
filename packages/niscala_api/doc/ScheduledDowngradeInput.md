# niscala_api.model.ScheduledDowngradeInput

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**keptPropertyIds** | **List<String>** | Exactly the target plan's property limit, or all properties if the Owner has fewer. No duplicates. | [default to const []]
**keptRoomIds** | **List<String>** | Only for free: exactly 15 rooms of the kept property, or all its rooms if it has fewer. Must be empty otherwise. | [optional] [default to const []]
**planCode** | [**PlanCode**](PlanCode.md) | free or basic; must be lower than the current plan. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


