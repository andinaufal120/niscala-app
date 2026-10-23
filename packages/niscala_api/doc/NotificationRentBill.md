# niscala_api.model.NotificationRentBill

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**amount** | **int** | In rupiah. | 
**daysOverdue** | **int** | Days past the due date; 0 unless billOverdue. | 
**dueDate** | [**DateTime**](DateTime.md) |  | 
**paymentMethod** | [**PaymentMethod**](PaymentMethod.md) |  | 
**paymentStatus** | [**PaymentStatus**](PaymentStatus.md) | The status the notification announces, or the bill had at that time. | 
**periodEnd** | [**DateTime**](DateTime.md) |  | 
**periodStart** | [**DateTime**](DateTime.md) |  | 
**reason** | **String** |  | 
**rentBillId** | **String** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


