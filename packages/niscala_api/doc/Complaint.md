# niscala_api.model.Complaint

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**classification** | [**ComplaintClassification**](ComplaintClassification.md) |  | 
**classificationState** | [**ComplaintClassificationState**](ComplaintClassificationState.md) |  | 
**classificationWithheld** | **bool** | True when an AI result exists but is withheld. | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**description** | **String** |  | 
**hasPhoto** | **bool** |  | 
**id** | **String** |  | 
**property** | [**PropertyRef**](PropertyRef.md) |  | 
**room** | [**RoomRef**](RoomRef.md) |  | 
**status** | [**ComplaintStatus**](ComplaintStatus.md) |  | 
**statusChanges** | [**List<ComplaintStatusChange>**](ComplaintStatusChange.md) |  | [default to const []]
**tenantName** | **String** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


