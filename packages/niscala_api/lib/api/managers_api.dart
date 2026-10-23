//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class ManagersApi {
  ManagersApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Manager
  ///
  /// Add a manager to properties of the Owner and return them with an invitation.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ManagerInput] managerInput (required):
  Future<Response> createManagerWithHttpInfo(ManagerInput managerInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/managers';

    // ignore: prefer_final_locals
    Object? postBody = managerInput;

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

  /// Create Manager
  ///
  /// Add a manager to properties of the Owner and return them with an invitation.
  ///
  /// Parameters:
  ///
  /// * [ManagerInput] managerInput (required):
  Future<Manager?> createManager(ManagerInput managerInput,) async {
    final response = await createManagerWithHttpInfo(managerInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Manager',) as Manager;
    
    }
    return null;
  }

  /// Delete Manager
  ///
  /// Revoke the manager's assignments to the Owner's properties; history is kept.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  Future<Response> deleteManagerWithHttpInfo(String managerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/managers/{managerId}'
      .replaceAll('{managerId}', managerId);

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

  /// Delete Manager
  ///
  /// Revoke the manager's assignments to the Owner's properties; history is kept.
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  Future<void> deleteManager(String managerId,) async {
    final response = await deleteManagerWithHttpInfo(managerId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get Manager
  ///
  /// Return a manager's detail, with the invitation while not activated.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  Future<Response> getManagerWithHttpInfo(String managerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/managers/{managerId}'
      .replaceAll('{managerId}', managerId);

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

  /// Get Manager
  ///
  /// Return a manager's detail, with the invitation while not activated.
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  Future<Manager?> getManager(String managerId,) async {
    final response = await getManagerWithHttpInfo(managerId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Manager',) as Manager;
    
    }
    return null;
  }

  /// List Managers
  ///
  /// List the Owner's managers, optionally only those assigned to one property.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId:
  Future<Response> listManagersWithHttpInfo({ String? propertyId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/managers';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (propertyId != null) {
      queryParams.addAll(_queryParams('', 'propertyId', propertyId));
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

  /// List Managers
  ///
  /// List the Owner's managers, optionally only those assigned to one property.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId:
  Future<ManagerList?> listManagers({ String? propertyId, }) async {
    final response = await listManagersWithHttpInfo( propertyId: propertyId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ManagerList',) as ManagerList;
    
    }
    return null;
  }

  /// Regenerate Manager Invitation
  ///
  /// Create a new invitation link for a manager, invalidating the old one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  Future<Response> regenerateManagerInvitationWithHttpInfo(String managerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/managers/{managerId}/invitation'
      .replaceAll('{managerId}', managerId);

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

  /// Regenerate Manager Invitation
  ///
  /// Create a new invitation link for a manager, invalidating the old one.
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  Future<ManagerInvitation?> regenerateManagerInvitation(String managerId,) async {
    final response = await regenerateManagerInvitationWithHttpInfo(managerId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ManagerInvitation',) as ManagerInvitation;
    
    }
    return null;
  }

  /// Update Manager
  ///
  /// Replace a manager's fields; access to removed properties is revoked.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  ///
  /// * [ManagerInput] managerInput (required):
  Future<Response> updateManagerWithHttpInfo(String managerId, ManagerInput managerInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/managers/{managerId}'
      .replaceAll('{managerId}', managerId);

    // ignore: prefer_final_locals
    Object? postBody = managerInput;

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

  /// Update Manager
  ///
  /// Replace a manager's fields; access to removed properties is revoked.
  ///
  /// Parameters:
  ///
  /// * [String] managerId (required):
  ///
  /// * [ManagerInput] managerInput (required):
  Future<Manager?> updateManager(String managerId, ManagerInput managerInput,) async {
    final response = await updateManagerWithHttpInfo(managerId, managerInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Manager',) as Manager;
    
    }
    return null;
  }
}
