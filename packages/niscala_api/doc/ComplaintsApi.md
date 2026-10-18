# niscala_api.api.ComplaintsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**changeComplaintStatus**](ComplaintsApi.md#changecomplaintstatus) | **POST** /complaints/{complaintId}/status-changes | Change Complaint Status
[**classifyComplaint**](ComplaintsApi.md#classifycomplaint) | **PUT** /complaints/{complaintId}/classification | Classify Complaint
[**createComplaint**](ComplaintsApi.md#createcomplaint) | **POST** /complaints | Create Complaint
[**getComplaint**](ComplaintsApi.md#getcomplaint) | **GET** /complaints/{complaintId} | Get Complaint
[**getComplaintPhoto**](ComplaintsApi.md#getcomplaintphoto) | **GET** /complaints/{complaintId}/photo | Get Complaint Photo
[**listComplaintCategories**](ComplaintsApi.md#listcomplaintcategories) | **GET** /complaint-categories | List Complaint Categories
[**listComplaints**](ComplaintsApi.md#listcomplaints) | **GET** /complaints | List Complaints
[**uploadComplaintPhoto**](ComplaintsApi.md#uploadcomplaintphoto) | **PUT** /complaints/{complaintId}/photo | Upload Complaint Photo


# **changeComplaintStatus**
> Complaint changeComplaintStatus(complaintId, complaintStatusChangeInput)

Change Complaint Status

Move a complaint to its next status, optionally with a handling note.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();
final complaintId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final complaintStatusChangeInput = ComplaintStatusChangeInput(); // ComplaintStatusChangeInput | 

try {
    final result = api_instance.changeComplaintStatus(complaintId, complaintStatusChangeInput);
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->changeComplaintStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **complaintId** | **String**|  | 
 **complaintStatusChangeInput** | [**ComplaintStatusChangeInput**](ComplaintStatusChangeInput.md)|  | 

### Return type

[**Complaint**](Complaint.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **classifyComplaint**
> Complaint classifyComplaint(complaintId, complaintClassificationInput)

Classify Complaint

Set a complaint's category and urgency manually.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();
final complaintId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final complaintClassificationInput = ComplaintClassificationInput(); // ComplaintClassificationInput | 

try {
    final result = api_instance.classifyComplaint(complaintId, complaintClassificationInput);
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->classifyComplaint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **complaintId** | **String**|  | 
 **complaintClassificationInput** | [**ComplaintClassificationInput**](ComplaintClassificationInput.md)|  | 

### Return type

[**Complaint**](Complaint.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createComplaint**
> Complaint createComplaint(complaintInput)

Create Complaint

Submit a complaint as the calling tenant.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();
final complaintInput = ComplaintInput(); // ComplaintInput | 

try {
    final result = api_instance.createComplaint(complaintInput);
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->createComplaint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **complaintInput** | [**ComplaintInput**](ComplaintInput.md)|  | 

### Return type

[**Complaint**](Complaint.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getComplaint**
> Complaint getComplaint(complaintId)

Get Complaint

Return a complaint's detail with its status history.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();
final complaintId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getComplaint(complaintId);
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->getComplaint: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **complaintId** | **String**|  | 

### Return type

[**Complaint**](Complaint.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getComplaintPhoto**
> getComplaintPhoto(complaintId)

Get Complaint Photo

Return the complaint photo.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();
final complaintId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.getComplaintPhoto(complaintId);
} catch (e) {
    print('Exception when calling ComplaintsApi->getComplaintPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **complaintId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/jpeg, image/png

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listComplaintCategories**
> ComplaintCategoryList listComplaintCategories()

List Complaint Categories

Return the categories a complaint can be classified into.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();

try {
    final result = api_instance.listComplaintCategories();
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->listComplaintCategories: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ComplaintCategoryList**](ComplaintCategoryList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listComplaints**
> ComplaintList listComplaints()

List Complaints

List the caller's complaints: a tenant's own, or those on accessible properties.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();

try {
    final result = api_instance.listComplaints();
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->listComplaints: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ComplaintList**](ComplaintList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadComplaintPhoto**
> Complaint uploadComplaintPhoto(complaintId, file)

Upload Complaint Photo

Attach or replace the complaint photo.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ComplaintsApi();
final complaintId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.uploadComplaintPhoto(complaintId, file);
    print(result);
} catch (e) {
    print('Exception when calling ComplaintsApi->uploadComplaintPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **complaintId** | **String**|  | 
 **file** | **MultipartFile**|  | 

### Return type

[**Complaint**](Complaint.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

