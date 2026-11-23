//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class RentBillsApi {
  RentBillsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Change Payment Status
  ///
  /// Manually set a bill's payment status, with a reason.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [PaymentStatusChangeInput] paymentStatusChangeInput (required):
  Future<Response> changePaymentStatusWithHttpInfo(String rentBillId, PaymentStatusChangeInput paymentStatusChangeInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}/status-changes'
      .replaceAll('{rentBillId}', rentBillId);

    // ignore: prefer_final_locals
    Object? postBody = paymentStatusChangeInput;

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

  /// Change Payment Status
  ///
  /// Manually set a bill's payment status, with a reason.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [PaymentStatusChangeInput] paymentStatusChangeInput (required):
  Future<RentBill?> changePaymentStatus(String rentBillId, PaymentStatusChangeInput paymentStatusChangeInput,) async {
    final response = await changePaymentStatusWithHttpInfo(rentBillId, paymentStatusChangeInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBill',) as RentBill;
    
    }
    return null;
  }

  /// Get Payment Overview
  ///
  /// Show each tenant's bill covering a date, defaulting to today.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [DateTime] date:
  Future<Response> getPaymentOverviewWithHttpInfo(String propertyId, { DateTime? date, }) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/payment-overview'
      .replaceAll('{propertyId}', propertyId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (date != null) {
      queryParams.addAll(_queryParams('', 'date', date));
    }

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

  /// Get Payment Overview
  ///
  /// Show each tenant's bill covering a date, defaulting to today.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [DateTime] date:
  Future<PaymentOverview?> getPaymentOverview(String propertyId, { DateTime? date, }) async {
    final response = await getPaymentOverviewWithHttpInfo(propertyId,  date: date, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentOverview',) as PaymentOverview;
    
    }
    return null;
  }

  /// Get Payment Patterns
  ///
  /// Show each tenant's payment pattern over their most recent bills.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> getPaymentPatternsWithHttpInfo(String propertyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/payment-patterns'
      .replaceAll('{propertyId}', propertyId);

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

  /// Get Payment Patterns
  ///
  /// Show each tenant's payment pattern over their most recent bills.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<PaymentPatternList?> getPaymentPatterns(String propertyId,) async {
    final response = await getPaymentPatternsWithHttpInfo(propertyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaymentPatternList',) as PaymentPatternList;
    
    }
    return null;
  }

  /// Get Receipt
  ///
  /// Return the receipt image of a rent bill.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  Future<Response> getReceiptWithHttpInfo(String rentBillId,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}/receipt'
      .replaceAll('{rentBillId}', rentBillId);

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

  /// Get Receipt
  ///
  /// Return the receipt image of a rent bill.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  Future<void> getReceipt(String rentBillId,) async {
    final response = await getReceiptWithHttpInfo(rentBillId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get Rent Bill
  ///
  /// Return a rent bill's detail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  Future<Response> getRentBillWithHttpInfo(String rentBillId,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}'
      .replaceAll('{rentBillId}', rentBillId);

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

  /// Get Rent Bill
  ///
  /// Return a rent bill's detail.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  Future<RentBill?> getRentBill(String rentBillId,) async {
    final response = await getRentBillWithHttpInfo(rentBillId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBill',) as RentBill;
    
    }
    return null;
  }

  /// List Rent Bills
  ///
  /// List the caller's rent bills: a tenant's own, or those on accessible properties.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] tenantId:
  ///
  /// * [String] propertyId:
  ///
  /// * [List<PaymentStatus>] paymentStatus:
  Future<Response> listRentBillsWithHttpInfo({ String? tenantId, String? propertyId, List<PaymentStatus>? paymentStatus, }) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (tenantId != null) {
      queryParams.addAll(_queryParams('', 'tenantId', tenantId));
    }
    if (propertyId != null) {
      queryParams.addAll(_queryParams('', 'propertyId', propertyId));
    }
    if (paymentStatus != null) {
      queryParams.addAll(_queryParams('multi', 'paymentStatus', paymentStatus));
    }

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

  /// List Rent Bills
  ///
  /// List the caller's rent bills: a tenant's own, or those on accessible properties.
  ///
  /// Parameters:
  ///
  /// * [String] tenantId:
  ///
  /// * [String] propertyId:
  ///
  /// * [List<PaymentStatus>] paymentStatus:
  Future<RentBillList?> listRentBills({ String? tenantId, String? propertyId, List<PaymentStatus>? paymentStatus, }) async {
    final response = await listRentBillsWithHttpInfo( tenantId: tenantId, propertyId: propertyId, paymentStatus: paymentStatus, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBillList',) as RentBillList;
    
    }
    return null;
  }

  /// Record Cash Payment
  ///
  /// Record a cash payment and mark the bill as paid.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [CashPaymentInput] cashPaymentInput (required):
  Future<Response> recordCashPaymentWithHttpInfo(String rentBillId, CashPaymentInput cashPaymentInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}/cash-payment'
      .replaceAll('{rentBillId}', rentBillId);

    // ignore: prefer_final_locals
    Object? postBody = cashPaymentInput;

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

  /// Record Cash Payment
  ///
  /// Record a cash payment and mark the bill as paid.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [CashPaymentInput] cashPaymentInput (required):
  Future<RentBill?> recordCashPayment(String rentBillId, CashPaymentInput cashPaymentInput,) async {
    final response = await recordCashPaymentWithHttpInfo(rentBillId, cashPaymentInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBill',) as RentBill;
    
    }
    return null;
  }

  /// Reject Receipt
  ///
  /// Reject a transfer receipt with a reason.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [ReceiptRejectionInput] receiptRejectionInput (required):
  Future<Response> rejectReceiptWithHttpInfo(String rentBillId, ReceiptRejectionInput receiptRejectionInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}/rejection'
      .replaceAll('{rentBillId}', rentBillId);

    // ignore: prefer_final_locals
    Object? postBody = receiptRejectionInput;

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

  /// Reject Receipt
  ///
  /// Reject a transfer receipt with a reason.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [ReceiptRejectionInput] receiptRejectionInput (required):
  Future<RentBill?> rejectReceipt(String rentBillId, ReceiptRejectionInput receiptRejectionInput,) async {
    final response = await rejectReceiptWithHttpInfo(rentBillId, receiptRejectionInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBill',) as RentBill;
    
    }
    return null;
  }

  /// Upload Receipt
  ///
  /// Attach a transfer receipt image and mark the bill as awaiting verification.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [MultipartFile] file (required):
  Future<Response> uploadReceiptWithHttpInfo(String rentBillId, MultipartFile file,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}/receipt'
      .replaceAll('{rentBillId}', rentBillId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('PUT', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
    }
    if (hasFields) {
      postBody = mp;
    }

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

  /// Upload Receipt
  ///
  /// Attach a transfer receipt image and mark the bill as awaiting verification.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  ///
  /// * [MultipartFile] file (required):
  Future<RentBill?> uploadReceipt(String rentBillId, MultipartFile file,) async {
    final response = await uploadReceiptWithHttpInfo(rentBillId, file,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBill',) as RentBill;
    
    }
    return null;
  }

  /// Verify Receipt
  ///
  /// Accept a transfer receipt and mark the bill as paid.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  Future<Response> verifyReceiptWithHttpInfo(String rentBillId,) async {
    // ignore: prefer_const_declarations
    final path = r'/rent-bills/{rentBillId}/verification'
      .replaceAll('{rentBillId}', rentBillId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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

  /// Verify Receipt
  ///
  /// Accept a transfer receipt and mark the bill as paid.
  ///
  /// Parameters:
  ///
  /// * [String] rentBillId (required):
  Future<RentBill?> verifyReceipt(String rentBillId,) async {
    final response = await verifyReceiptWithHttpInfo(rentBillId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RentBill',) as RentBill;
    
    }
    return null;
  }
}
