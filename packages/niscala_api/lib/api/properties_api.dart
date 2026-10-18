//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class PropertiesApi {
  PropertiesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Property
  ///
  /// Add a property to the Owner's account.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PropertyInput] propertyInput (required):
  Future<Response> createPropertyWithHttpInfo(PropertyInput propertyInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties';

    // ignore: prefer_final_locals
    Object? postBody = propertyInput;

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

  /// Create Property
  ///
  /// Add a property to the Owner's account.
  ///
  /// Parameters:
  ///
  /// * [PropertyInput] propertyInput (required):
  Future<Property?> createProperty(PropertyInput propertyInput,) async {
    final response = await createPropertyWithHttpInfo(propertyInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Property',) as Property;
    
    }
    return null;
  }

  /// Delete Property
  ///
  /// Delete a property together with its rooms and manager assignments.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> deletePropertyWithHttpInfo(String propertyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}'
      .replaceAll('{propertyId}', propertyId);

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

  /// Delete Property
  ///
  /// Delete a property together with its rooms and manager assignments.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<void> deleteProperty(String propertyId,) async {
    final response = await deletePropertyWithHttpInfo(propertyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get Property
  ///
  /// Return a property's detail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> getPropertyWithHttpInfo(String propertyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}'
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

  /// Get Property
  ///
  /// Return a property's detail.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Property?> getProperty(String propertyId,) async {
    final response = await getPropertyWithHttpInfo(propertyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Property',) as Property;
    
    }
    return null;
  }

  /// List Properties
  ///
  /// List the properties the caller may access.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPropertiesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/properties';

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

  /// List Properties
  ///
  /// List the properties the caller may access.
  Future<PropertyList?> listProperties() async {
    final response = await listPropertiesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PropertyList',) as PropertyList;
    
    }
    return null;
  }

  /// Update Property
  ///
  /// Replace a property's name, address and bank account.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [PropertyInput] propertyInput (required):
  Future<Response> updatePropertyWithHttpInfo(String propertyId, PropertyInput propertyInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}'
      .replaceAll('{propertyId}', propertyId);

    // ignore: prefer_final_locals
    Object? postBody = propertyInput;

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

  /// Update Property
  ///
  /// Replace a property's name, address and bank account.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [PropertyInput] propertyInput (required):
  Future<Property?> updateProperty(String propertyId, PropertyInput propertyInput,) async {
    final response = await updatePropertyWithHttpInfo(propertyId, propertyInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Property',) as Property;
    
    }
    return null;
  }
}
