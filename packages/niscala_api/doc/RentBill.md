# niscala_api.model.RentBill

## Load the model package
```dart
import 'package:niscala_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**amount** | **int** | In rupiah. | 
**bankAccount** | [**BankAccount**](BankAccount.md) |  | [optional] 
**canUploadReceipt** | **bool** | True when the bill is unpaid or rejected and its property has a bank account. Describes the bill, not the caller's role. | 
**daysOverdue** | **int** | Days past the due date while unpaid or rejected, else 0. | 
**dueDate** | [**DateTime**](DateTime.md) |  | 
**id** | **String** |  | 
**isCurrent** | **bool** | True when the billing period contains today in Asia/Jakarta. | 
**payment** | [**Payment**](Payment.md) |  | 
**periodEnd** | [**DateTime**](DateTime.md) |  | 
**periodStart** | [**DateTime**](DateTime.md) |  | 
**property** | [**PropertyRef**](PropertyRef.md) |  | 
**room** | [**RoomRef**](RoomRef.md) |  | 
**statusChanges** | [**List<PaymentStatusChange>**](PaymentStatusChange.md) | Oldest first. | [default to const []]
**tenant** | [**TenantRef**](TenantRef.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


