//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class TenantsApi {
  TenantsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Tenant
  ///
  /// Add a tenant to a vacant room of a property and create their invitation.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [NewTenantInput] newTenantInput (required):
  Future<Response> createTenantWithHttpInfo(String propertyId, NewTenantInput newTenantInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/tenants'
      .replaceAll('{propertyId}', propertyId);

    // ignore: prefer_final_locals
    Object? postBody = newTenantInput;

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

  /// Create Tenant
  ///
  /// Add a tenant to a vacant room of a property and create their invitation.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [NewTenantInput] newTenantInput (required):
  Future<Tenant?> createTenant(String propertyId, NewTenantInput newTenantInput,) async {
    final response = await createTenantWithHttpInfo(propertyId, newTenantInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Tenant',) as Tenant;
    
    }
    return null;
  }

  /// Delete Tenant
  ///
  /// End a tenant's lease, revoke their access and free the room; history is kept.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  Future<Response> deleteTenantWithHttpInfo(String tenantId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tenants/{tenantId}'
      .replaceAll('{tenantId}', tenantId);

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

  /// Delete Tenant
  ///
  /// End a tenant's lease, revoke their access and free the room; history is kept.
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  Future<void> deleteTenant(String tenantId,) async {
    final response = await deleteTenantWithHttpInfo(tenantId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get My Lease
  ///
  /// Return the calling tenant's active lease, or null when it has ended.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMyLeaseWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/me/lease';

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

  /// Get My Lease
  ///
  /// Return the calling tenant's active lease, or null when it has ended.
  Future<CurrentLeaseResult?> getMyLease() async {
    final response = await getMyLeaseWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CurrentLeaseResult',) as CurrentLeaseResult;
    
    }
    return null;
  }

  /// Get Tenant
  ///
  /// Return a tenant's detail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  Future<Response> getTenantWithHttpInfo(String tenantId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tenants/{tenantId}'
      .replaceAll('{tenantId}', tenantId);

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

  /// Get Tenant
  ///
  /// Return a tenant's detail.
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  Future<Tenant?> getTenant(String tenantId,) async {
    final response = await getTenantWithHttpInfo(tenantId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Tenant',) as Tenant;
    
    }
    return null;
  }

  /// List Tenants
  ///
  /// List a property's tenants.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> listTenantsWithHttpInfo(String propertyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/tenants'
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

  /// List Tenants
  ///
  /// List a property's tenants.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<TenantList?> listTenants(String propertyId,) async {
    final response = await listTenantsWithHttpInfo(propertyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TenantList',) as TenantList;
    
    }
    return null;
  }

  /// Regenerate Tenant Invitation
  ///
  /// Create a new invitation link for a tenant, invalidating the old one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  Future<Response> regenerateTenantInvitationWithHttpInfo(String tenantId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tenants/{tenantId}/invitation'
      .replaceAll('{tenantId}', tenantId);

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

  /// Regenerate Tenant Invitation
  ///
  /// Create a new invitation link for a tenant, invalidating the old one.
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  Future<TenantInvitation?> regenerateTenantInvitation(String tenantId,) async {
    final response = await regenerateTenantInvitationWithHttpInfo(tenantId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TenantInvitation',) as TenantInvitation;
    
    }
    return null;
  }

  /// Update Tenant
  ///
  /// Replace a tenant's fields. The room cannot be changed.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  ///
  /// * [TenantInput] tenantInput (required):
  Future<Response> updateTenantWithHttpInfo(String tenantId, TenantInput tenantInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/tenants/{tenantId}'
      .replaceAll('{tenantId}', tenantId);

    // ignore: prefer_final_locals
    Object? postBody = tenantInput;

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

  /// Update Tenant
  ///
  /// Replace a tenant's fields. The room cannot be changed.
  ///
  /// Parameters:
  ///
  /// * [String] tenantId (required):
  ///
  /// * [TenantInput] tenantInput (required):
  Future<Tenant?> updateTenant(String tenantId, TenantInput tenantInput,) async {
    final response = await updateTenantWithHttpInfo(tenantId, tenantInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Tenant',) as Tenant;
    
    }
    return null;
  }
}
