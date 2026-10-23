//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class SubscriptionsApi {
  SubscriptionsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Cancel Subscription Downgrade
  ///
  /// Cancel the scheduled downgrade.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> cancelSubscriptionDowngradeWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/subscription/scheduled-downgrade';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Cancel Subscription Downgrade
  ///
  /// Cancel the scheduled downgrade.
  Future<void> cancelSubscriptionDowngrade() async {
    final response = await cancelSubscriptionDowngradeWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create Subscription Order
  ///
  /// Start a purchase of a paid plan; the order expires if no purchase completes.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SubscriptionOrderInput] subscriptionOrderInput (required):
  Future<Response> createSubscriptionOrderWithHttpInfo(SubscriptionOrderInput subscriptionOrderInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/subscription/orders';

    // ignore: prefer_final_locals
    Object? postBody = subscriptionOrderInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Subscription Order
  ///
  /// Start a purchase of a paid plan; the order expires if no purchase completes.
  ///
  /// Parameters:
  ///
  /// * [SubscriptionOrderInput] subscriptionOrderInput (required):
  Future<SubscriptionOrder?> createSubscriptionOrder(SubscriptionOrderInput subscriptionOrderInput,) async {
    final response = await createSubscriptionOrderWithHttpInfo(subscriptionOrderInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionOrder',) as SubscriptionOrder;
    
    }
    return null;
  }

  /// Get Subscription
  ///
  /// Return the Owner's current subscription.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getSubscriptionWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/subscription';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get Subscription
  ///
  /// Return the Owner's current subscription.
  Future<Subscription?> getSubscription() async {
    final response = await getSubscriptionWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Subscription',) as Subscription;
    
    }
    return null;
  }

  /// Get Subscription Order
  ///
  /// Return an order with its status.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orderId (required):
  Future<Response> getSubscriptionOrderWithHttpInfo(String orderId,) async {
    // ignore: prefer_const_declarations
    final path = r'/subscription/orders/{orderId}'
      .replaceAll('{orderId}', orderId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get Subscription Order
  ///
  /// Return an order with its status.
  ///
  /// Parameters:
  ///
  /// * [String] orderId (required):
  Future<SubscriptionOrder?> getSubscriptionOrder(String orderId,) async {
    final response = await getSubscriptionOrderWithHttpInfo(orderId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionOrder',) as SubscriptionOrder;
    
    }
    return null;
  }

  /// List Subscription Plans
  ///
  /// List the available plans with limits, AI availability and prices.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listSubscriptionPlansWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/subscription-plans';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Subscription Plans
  ///
  /// List the available plans with limits, AI availability and prices.
  Future<SubscriptionPlanList?> listSubscriptionPlans() async {
    final response = await listSubscriptionPlansWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionPlanList',) as SubscriptionPlanList;
    
    }
    return null;
  }

  /// Schedule Subscription Downgrade
  ///
  /// Confirm a downgrade at the end of the paid period and the properties and rooms that stay editable.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ScheduledDowngradeInput] scheduledDowngradeInput (required):
  Future<Response> scheduleSubscriptionDowngradeWithHttpInfo(ScheduledDowngradeInput scheduledDowngradeInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/subscription/scheduled-downgrade';

    // ignore: prefer_final_locals
    Object? postBody = scheduledDowngradeInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Schedule Subscription Downgrade
  ///
  /// Confirm a downgrade at the end of the paid period and the properties and rooms that stay editable.
  ///
  /// Parameters:
  ///
  /// * [ScheduledDowngradeInput] scheduledDowngradeInput (required):
  Future<ScheduledDowngrade?> scheduleSubscriptionDowngrade(ScheduledDowngradeInput scheduledDowngradeInput,) async {
    final response = await scheduleSubscriptionDowngradeWithHttpInfo(scheduledDowngradeInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ScheduledDowngrade',) as ScheduledDowngrade;
    
    }
    return null;
  }

  /// Verify Subscription Purchase
  ///
  /// Verify the Google Play purchase token of an order and update the order and subscription.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] orderId (required):
  ///
  /// * [PurchaseVerificationInput] purchaseVerificationInput (required):
  Future<Response> verifySubscriptionPurchaseWithHttpInfo(String orderId, PurchaseVerificationInput purchaseVerificationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/subscription/orders/{orderId}/purchase-verification'
      .replaceAll('{orderId}', orderId);

    // ignore: prefer_final_locals
    Object? postBody = purchaseVerificationInput;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Verify Subscription Purchase
  ///
  /// Verify the Google Play purchase token of an order and update the order and subscription.
  ///
  /// Parameters:
  ///
  /// * [String] orderId (required):
  ///
  /// * [PurchaseVerificationInput] purchaseVerificationInput (required):
  Future<SubscriptionOrder?> verifySubscriptionPurchase(String orderId, PurchaseVerificationInput purchaseVerificationInput,) async {
    final response = await verifySubscriptionPurchaseWithHttpInfo(orderId, purchaseVerificationInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionOrder',) as SubscriptionOrder;
    
    }
    return null;
  }
}
