# niscala_api.api.RoomsApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createRoom**](RoomsApi.md#createroom) | **POST** /properties/{propertyId}/rooms | Create Room
[**deleteRoom**](RoomsApi.md#deleteroom) | **DELETE** /rooms/{roomId} | Delete Room
[**getRoom**](RoomsApi.md#getroom) | **GET** /rooms/{roomId} | Get Room
[**listFacilitySuggestions**](RoomsApi.md#listfacilitysuggestions) | **GET** /properties/{propertyId}/facility-suggestions | List Facility Suggestions
[**listRooms**](RoomsApi.md#listrooms) | **GET** /properties/{propertyId}/rooms | List Rooms
[**updateRoom**](RoomsApi.md#updateroom) | **PUT** /rooms/{roomId} | Update Room


# **createRoom**
> Room createRoom(propertyId, roomInput)

Create Room

Add a room to a property.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RoomsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final roomInput = RoomInput(); // RoomInput | 

try {
    final result = api_instance.createRoom(propertyId, roomInput);
    print(result);
} catch (e) {
    print('Exception when calling RoomsApi->createRoom: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 
 **roomInput** | [**RoomInput**](RoomInput.md)|  | 

### Return type

[**Room**](Room.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteRoom**
> deleteRoom(roomId)

Delete Room

Delete a room.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RoomsApi();
final roomId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteRoom(roomId);
} catch (e) {
    print('Exception when calling RoomsApi->deleteRoom: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roomId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRoom**
> Room getRoom(roomId)

Get Room

Return a room's detail.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RoomsApi();
final roomId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getRoom(roomId);
    print(result);
} catch (e) {
    print('Exception when calling RoomsApi->getRoom: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roomId** | **String**|  | 

### Return type

[**Room**](Room.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFacilitySuggestions**
> FacilitySuggestionList listFacilitySuggestions(propertyId)

List Facility Suggestions

List the distinct facility tags already used on rooms of the property's Owner.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RoomsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listFacilitySuggestions(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling RoomsApi->listFacilitySuggestions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**FacilitySuggestionList**](FacilitySuggestionList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRooms**
> RoomList listRooms(propertyId)

List Rooms

List a property's rooms.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RoomsApi();
final propertyId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listRooms(propertyId);
    print(result);
} catch (e) {
    print('Exception when calling RoomsApi->listRooms: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **propertyId** | **String**|  | 

### Return type

[**RoomList**](RoomList.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateRoom**
> Room updateRoom(roomId, roomInput)

Update Room

Replace a room's fields.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RoomsApi();
final roomId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final roomInput = RoomInput(); // RoomInput | 

try {
    final result = api_instance.updateRoom(roomId, roomInput);
    print(result);
} catch (e) {
    print('Exception when calling RoomsApi->updateRoom: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roomId** | **String**|  | 
 **roomInput** | [**RoomInput**](RoomInput.md)|  | 

### Return type

[**Room**](Room.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

