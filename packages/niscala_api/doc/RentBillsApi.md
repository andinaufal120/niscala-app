# niscala_api.api.RentBillsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**changePaymentStatus**](RentBillsApi.md#changepaymentstatus) | **POST** /rent-bills/{rentBillId}/status-changes | Change Payment Status
[**getPaymentOverview**](RentBillsApi.md#getpaymentoverview) | **GET** /properties/{propertyId}/payment-overview | Get Payment Overview
[**getPaymentPatterns**](RentBillsApi.md#getpaymentpatterns) | **GET** /properties/{propertyId}/payment-patterns | Get Payment Patterns
[**getReceipt**](RentBillsApi.md#getreceipt) | **GET** /rent-bills/{rentBillId}/receipt | Get Receipt
[**getRentBill**](RentBillsApi.md#getrentbill) | **GET** /rent-bills/{rentBillId} | Get Rent Bill
[**listRentBills**](RentBillsApi.md#listrentbills) | **GET** /rent-bills | List Rent Bills
[**recordCashPayment**](RentBillsApi.md#recordcashpayment) | **POST** /rent-bills/{rentBillId}/cash-payment | Record Cash Payment
[**rejectReceipt**](RentBillsApi.md#rejectreceipt) | **POST** /rent-bills/{rentBillId}/rejection | Reject Receipt
[**uploadReceipt**](RentBillsApi.md#uploadreceipt) | **PUT** /rent-bills/{rentBillId}/receipt | Upload Receipt
[**verifyReceipt**](RentBillsApi.md#verifyreceipt) | **POST** /rent-bills/{rentBillId}/verification | Verify Receipt


# **changePaymentStatus**
> RentBill changePaymentStatus(rentBillId, paymentStatusChangeInput)

Change Payment Status

Manually set a bill's payment status, with a reason.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final paymentStatusChangeInput = PaymentStatusChangeInput(); // PaymentStatusChangeInput | 

try {
    final result = api_instance.changePaymentStatus(rentBillId, paymentStatusChangeInput);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->changePaymentStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 
 **paymentStatusChangeInput** | [**PaymentStatusChangeInput**](PaymentStatusChangeInput.md)|  | 

### Return type

[**RentBill**](RentBill.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPaymentOverview**
> PaymentOverview getPaymentOverview(propertyId, date)

Get Payment Overview

Show each tenant's bill covering a date, defaulting to today.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final date = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getPaymentOverview(propertyId, date);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->getPaymentOverview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **date** | **DateTime**|  | [optional] 

### Return type

[**PaymentOverview**](PaymentOverview.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPaymentPatterns**
> PaymentPatternList getPaymentPatterns(propertyId)

Get Payment Patterns

Show each tenant's payment pattern over their most recent bills.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPaymentPatterns(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->getPaymentPatterns: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**PaymentPatternList**](PaymentPatternList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getReceipt**
> getReceipt(rentBillId)

Get Receipt

Return the receipt image of a rent bill.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.getReceipt(rentBillId);
} catch (e) {
    print('Exception when calling RentBillsApi->getReceipt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/jpeg, image/png

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRentBill**
> RentBill getRentBill(rentBillId)

Get Rent Bill

Return a rent bill's detail.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getRentBill(rentBillId);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->getRentBill: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 

### Return type

[**RentBill**](RentBill.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRentBills**
> RentBillList listRentBills(tenantId, paymentStatus)

List Rent Bills

List the caller's rent bills: a tenant's own, or those on accessible properties.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final tenantId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final paymentStatus = ; // PaymentStatus | 

try {
    final result = api_instance.listRentBills(tenantId, paymentStatus);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->listRentBills: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tenantId** | **String**|  | [optional] 
 **paymentStatus** | [**PaymentStatus**](.md)|  | [optional] 

### Return type

[**RentBillList**](RentBillList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recordCashPayment**
> RentBill recordCashPayment(rentBillId, cashPaymentInput)

Record Cash Payment

Record a cash payment and mark the bill as paid.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final cashPaymentInput = CashPaymentInput(); // CashPaymentInput | 

try {
    final result = api_instance.recordCashPayment(rentBillId, cashPaymentInput);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->recordCashPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 
 **cashPaymentInput** | [**CashPaymentInput**](CashPaymentInput.md)|  | 

### Return type

[**RentBill**](RentBill.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectReceipt**
> RentBill rejectReceipt(rentBillId, receiptRejectionInput)

Reject Receipt

Reject a transfer receipt with a reason.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final receiptRejectionInput = ReceiptRejectionInput(); // ReceiptRejectionInput | 

try {
    final result = api_instance.rejectReceipt(rentBillId, receiptRejectionInput);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->rejectReceipt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 
 **receiptRejectionInput** | [**ReceiptRejectionInput**](ReceiptRejectionInput.md)|  | 

### Return type

[**RentBill**](RentBill.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadReceipt**
> RentBill uploadReceipt(rentBillId, file)

Upload Receipt

Attach a transfer receipt image and mark the bill as awaiting verification.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.uploadReceipt(rentBillId, file);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->uploadReceipt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 
 **file** | **MultipartFile**|  | 

### Return type

[**RentBill**](RentBill.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifyReceipt**
> RentBill verifyReceipt(rentBillId)

Verify Receipt

Accept a transfer receipt and mark the bill as paid.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RentBillsApi();
final rentBillId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.verifyReceipt(rentBillId);
    print(result);
} catch (e) {
    print('Exception when calling RentBillsApi->verifyReceipt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rentBillId** | **String**|  | 

### Return type

[**RentBill**](RentBill.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

