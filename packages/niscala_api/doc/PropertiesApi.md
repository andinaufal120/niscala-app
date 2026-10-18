# niscala_api.api.PropertiesApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createProperty**](PropertiesApi.md#createproperty) | **POST** /properties | Create Property
[**deleteProperty**](PropertiesApi.md#deleteproperty) | **DELETE** /properties/{propertyId} | Delete Property
[**getProperty**](PropertiesApi.md#getproperty) | **GET** /properties/{propertyId} | Get Property
[**listProperties**](PropertiesApi.md#listproperties) | **GET** /properties | List Properties
[**updateProperty**](PropertiesApi.md#updateproperty) | **PUT** /properties/{propertyId} | Update Property


# **createProperty**
> Property createProperty(propertyInput)

Create Property

Add a property to the Owner's account.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PropertiesApi();
final propertyInput = PropertyInput(); // PropertyInput | 

try {
    final result = api_instance.createProperty(propertyInput);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->createProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyInput** | [**PropertyInput**](PropertyInput.md)|  | 

### Return type

[**Property**](Property.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteProperty**
> deleteProperty(propertyId)

Delete Property

Delete a property together with its rooms and manager assignments.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteProperty(propertyId);
} catch (e) {
    print('Exception when calling PropertiesApi->deleteProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProperty**
> Property getProperty(propertyId)

Get Property

Return a property's detail.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getProperty(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->getProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**Property**](Property.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listProperties**
> PropertyList listProperties()

List Properties

List the properties the caller may access.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PropertiesApi();

try {
    final result = api_instance.listProperties();
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->listProperties: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PropertyList**](PropertyList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProperty**
> Property updateProperty(propertyId, propertyInput)

Update Property

Replace a property's name, address and bank account.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PropertiesApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final propertyInput = PropertyInput(); // PropertyInput | 

try {
    final result = api_instance.updateProperty(propertyId, propertyInput);
    print(result);
} catch (e) {
    print('Exception when calling PropertiesApi->updateProperty: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **propertyInput** | [**PropertyInput**](PropertyInput.md)|  | 

### Return type

[**Property**](Property.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

