# niscala_api.model.RentBillSummary

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**amount** | **int** | In rupiah. | 
**daysOverdue** | **int** | Days past the due date while unpaid or rejected, else 0. | 
**dueDate** | [**DateTime**](DateTime.md) |  | 
**id** | **String** |  | 
**payment** | [**Payment**](Payment.md) |  | 
**periodEnd** | [**DateTime**](DateTime.md) |  | 
**periodStart** | [**DateTime**](DateTime.md) |  | 
**room** | [**RoomRef**](RoomRef.md) |  | 
**tenant** | [**TenantRef**](TenantRef.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


