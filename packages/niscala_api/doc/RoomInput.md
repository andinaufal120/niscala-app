# niscala_api.model.RoomInput

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**baseRate** | **int** | Per month, in rupiah. | 
**facilities** | **List<String>** | Free-form tags. On save each tag is trimmed, lowercased and has repeated spaces collapsed, and duplicates are dropped. At most 30 characters per tag and 15 tags per room. | [optional] [default to const []]
**lengthM** | **num** |  | [optional] 
**number** | **String** | Must be unique within the property. | 
**widthM** | **num** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


