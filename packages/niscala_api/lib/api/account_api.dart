//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class AccountApi {
  AccountApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add Local Password
  ///
  /// Add a password to a Google account, proven with a fresh Google ID token.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AddLocalPasswordInput] addLocalPasswordInput (required):
  Future<Response> addLocalPasswordWithHttpInfo(AddLocalPasswordInput addLocalPasswordInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/local-password';

    // ignore: prefer_final_locals
    Object? postBody = addLocalPasswordInput;

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

  /// Add Local Password
  ///
  /// Add a password to a Google account, proven with a fresh Google ID token.
  ///
  /// Parameters:
  ///
  /// * [AddLocalPasswordInput] addLocalPasswordInput (required):
  Future<Account?> addLocalPassword(AddLocalPasswordInput addLocalPasswordInput,) async {
    final response = await addLocalPasswordWithHttpInfo(addLocalPasswordInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Account',) as Account;
    
    }
    return null;
  }

  /// Change My Password
  ///
  /// Replace the caller's password after checking the current one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PasswordChangeInput] passwordChangeInput (required):
  Future<Response> changeMyPasswordWithHttpInfo(PasswordChangeInput passwordChangeInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/password-changes';

    // ignore: prefer_final_locals
    Object? postBody = passwordChangeInput;

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

  /// Change My Password
  ///
  /// Replace the caller's password after checking the current one.
  ///
  /// Parameters:
  ///
  /// * [PasswordChangeInput] passwordChangeInput (required):
  Future<PasswordChangeResult?> changeMyPassword(PasswordChangeInput passwordChangeInput,) async {
    final response = await changeMyPasswordWithHttpInfo(passwordChangeInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PasswordChangeResult',) as PasswordChangeResult;
    
    }
    return null;
  }

  /// Get My Account
  ///
  /// Return the caller's account and sign-in methods.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMyAccountWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/me';

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

  /// Get My Account
  ///
  /// Return the caller's account and sign-in methods.
  Future<Account?> getMyAccount() async {
    final response = await getMyAccountWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Account',) as Account;
    
    }
    return null;
  }

  /// Link Google
  ///
  /// Link a Google account to an account that has a password.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LinkGoogleInput] linkGoogleInput (required):
  Future<Response> linkGoogleWithHttpInfo(LinkGoogleInput linkGoogleInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/google-link';

    // ignore: prefer_final_locals
    Object? postBody = linkGoogleInput;

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

  /// Link Google
  ///
  /// Link a Google account to an account that has a password.
  ///
  /// Parameters:
  ///
  /// * [LinkGoogleInput] linkGoogleInput (required):
  Future<Account?> linkGoogle(LinkGoogleInput linkGoogleInput,) async {
    final response = await linkGoogleWithHttpInfo(linkGoogleInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Account',) as Account;
    
    }
    return null;
  }

  /// Reauthenticate With Google
  ///
  /// Confirm the caller's identity with a Google ID token.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ReauthenticationGoogleInput] reauthenticationGoogleInput (required):
  Future<Response> reauthenticateWithGoogleWithHttpInfo(ReauthenticationGoogleInput reauthenticationGoogleInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/reauthentication/google';

    // ignore: prefer_final_locals
    Object? postBody = reauthenticationGoogleInput;

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

  /// Reauthenticate With Google
  ///
  /// Confirm the caller's identity with a Google ID token.
  ///
  /// Parameters:
  ///
  /// * [ReauthenticationGoogleInput] reauthenticationGoogleInput (required):
  Future<Reauthentication?> reauthenticateWithGoogle(ReauthenticationGoogleInput reauthenticationGoogleInput,) async {
    final response = await reauthenticateWithGoogleWithHttpInfo(reauthenticationGoogleInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Reauthentication',) as Reauthentication;
    
    }
    return null;
  }

  /// Reauthenticate With Password
  ///
  /// Confirm the caller's identity with their password.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ReauthenticationPasswordInput] reauthenticationPasswordInput (required):
  Future<Response> reauthenticateWithPasswordWithHttpInfo(ReauthenticationPasswordInput reauthenticationPasswordInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/reauthentication/password';

    // ignore: prefer_final_locals
    Object? postBody = reauthenticationPasswordInput;

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

  /// Reauthenticate With Password
  ///
  /// Confirm the caller's identity with their password.
  ///
  /// Parameters:
  ///
  /// * [ReauthenticationPasswordInput] reauthenticationPasswordInput (required):
  Future<Reauthentication?> reauthenticateWithPassword(ReauthenticationPasswordInput reauthenticationPasswordInput,) async {
    final response = await reauthenticateWithPasswordWithHttpInfo(reauthenticationPasswordInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Reauthentication',) as Reauthentication;
    
    }
    return null;
  }
}
