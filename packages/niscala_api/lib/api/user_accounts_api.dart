//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class UserAccountsApi {
  UserAccountsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Delete User Account
  ///
  /// Soft-delete an account and end its sessions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userAccountId (required):
  Future<Response> deleteUserAccountWithHttpInfo(String userAccountId,) async {
    // ignore: prefer_const_declarations
    final path = r'/user-accounts/{userAccountId}'
      .replaceAll('{userAccountId}', userAccountId);

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

  /// Delete User Account
  ///
  /// Soft-delete an account and end its sessions.
  ///
  /// Parameters:
  ///
  /// * [String] userAccountId (required):
  Future<void> deleteUserAccount(String userAccountId,) async {
    final response = await deleteUserAccountWithHttpInfo(userAccountId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get User Account
  ///
  /// Return one user account with its login details and links.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userAccountId (required):
  Future<Response> getUserAccountWithHttpInfo(String userAccountId,) async {
    // ignore: prefer_const_declarations
    final path = r'/user-accounts/{userAccountId}'
      .replaceAll('{userAccountId}', userAccountId);

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

  /// Get User Account
  ///
  /// Return one user account with its login details and links.
  ///
  /// Parameters:
  ///
  /// * [String] userAccountId (required):
  Future<UserAccount?> getUserAccount(String userAccountId,) async {
    final response = await getUserAccountWithHttpInfo(userAccountId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UserAccount',) as UserAccount;
    
    }
    return null;
  }

  /// List User Accounts
  ///
  /// List user accounts of every role; deleted ones only on request.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] email:
  ///   Case-insensitive match on any part of the current email.
  ///
  /// * [UserRole] role:
  ///
  /// * [bool] includeDeleted:
  ///   Include deleted accounts.
  Future<Response> listUserAccountsWithHttpInfo({ String? email, UserRole? role, bool? includeDeleted, }) async {
    // ignore: prefer_const_declarations
    final path = r'/user-accounts';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (email != null) {
      queryParams.addAll(_queryParams('', 'email', email));
    }
    if (role != null) {
      queryParams.addAll(_queryParams('', 'role', role));
    }
    if (includeDeleted != null) {
      queryParams.addAll(_queryParams('', 'includeDeleted', includeDeleted));
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

  /// List User Accounts
  ///
  /// List user accounts of every role; deleted ones only on request.
  ///
  /// Parameters:
  ///
  /// * [String] email:
  ///   Case-insensitive match on any part of the current email.
  ///
  /// * [UserRole] role:
  ///
  /// * [bool] includeDeleted:
  ///   Include deleted accounts.
  Future<UserAccountList?> listUserAccounts({ String? email, UserRole? role, bool? includeDeleted, }) async {
    final response = await listUserAccountsWithHttpInfo( email: email, role: role, includeDeleted: includeDeleted, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UserAccountList',) as UserAccountList;
    
    }
    return null;
  }

  /// Update User Account
  ///
  /// Change name, email and status; a new email stays pending until verified.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userAccountId (required):
  ///
  /// * [UserAccountInput] userAccountInput (required):
  Future<Response> updateUserAccountWithHttpInfo(String userAccountId, UserAccountInput userAccountInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/user-accounts/{userAccountId}'
      .replaceAll('{userAccountId}', userAccountId);

    // ignore: prefer_final_locals
    Object? postBody = userAccountInput;

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

  /// Update User Account
  ///
  /// Change name, email and status; a new email stays pending until verified.
  ///
  /// Parameters:
  ///
  /// * [String] userAccountId (required):
  ///
  /// * [UserAccountInput] userAccountInput (required):
  Future<UserAccount?> updateUserAccount(String userAccountId, UserAccountInput userAccountInput,) async {
    final response = await updateUserAccountWithHttpInfo(userAccountId, userAccountInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UserAccount',) as UserAccount;
    
    }
    return null;
  }
}
