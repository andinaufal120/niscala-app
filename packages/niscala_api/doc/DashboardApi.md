# niscala_api.api.DashboardApi

## Load the API package
```dart
import 'package:niscala_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getOccupancyDashboard**](DashboardApi.md#getoccupancydashboard) | **GET** /occupancy-dashboard | Get Occupancy Dashboard


# **getOccupancyDashboard**
> OccupancyDashboard getOccupancyDashboard()

Get Occupancy Dashboard

Show occupancy figures for each accessible property and a summary across them.

### Example
```dart
import 'package:niscala_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearerAuth
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DashboardApi();

try {
    final result = api_instance.getOccupancyDashboard();
    print(result);
} catch (e) {
    print('Exception when calling DashboardApi->getOccupancyDashboard: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**OccupancyDashboard**](OccupancyDashboard.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

