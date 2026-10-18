//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class InvitationsApi {
  InvitationsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Accept Invitation
  ///
  /// Accept an invitation with the caller's existing account.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<Response> acceptInvitationWithHttpInfo(TokenInput tokenInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/invitations/acceptances';

    // ignore: prefer_final_locals
    Object? postBody = tokenInput;

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

  /// Accept Invitation
  ///
  /// Accept an invitation with the caller's existing account.
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<void> acceptInvitation(TokenInput tokenInput,) async {
    final response = await acceptInvitationWithHttpInfo(tokenInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Activate Invitation With Google
  ///
  /// Consume an invitation link, create the account with Google and start a session.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InvitationGoogleActivationInput] invitationGoogleActivationInput (required):
  Future<Response> activateInvitationWithGoogleWithHttpInfo(InvitationGoogleActivationInput invitationGoogleActivationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/invitations/activations/google';

    // ignore: prefer_final_locals
    Object? postBody = invitationGoogleActivationInput;

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

  /// Activate Invitation With Google
  ///
  /// Consume an invitation link, create the account with Google and start a session.
  ///
  /// Parameters:
  ///
  /// * [InvitationGoogleActivationInput] invitationGoogleActivationInput (required):
  Future<AuthSession?> activateInvitationWithGoogle(InvitationGoogleActivationInput invitationGoogleActivationInput,) async {
    final response = await activateInvitationWithGoogleWithHttpInfo(invitationGoogleActivationInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthSession',) as AuthSession;
    
    }
    return null;
  }

  /// Activate Invitation With Password
  ///
  /// Consume an invitation link, create the account with a password and start a session.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InvitationPasswordActivationInput] invitationPasswordActivationInput (required):
  Future<Response> activateInvitationWithPasswordWithHttpInfo(InvitationPasswordActivationInput invitationPasswordActivationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/invitations/activations/password';

    // ignore: prefer_final_locals
    Object? postBody = invitationPasswordActivationInput;

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

  /// Activate Invitation With Password
  ///
  /// Consume an invitation link, create the account with a password and start a session.
  ///
  /// Parameters:
  ///
  /// * [InvitationPasswordActivationInput] invitationPasswordActivationInput (required):
  Future<AuthSession?> activateInvitationWithPassword(InvitationPasswordActivationInput invitationPasswordActivationInput,) async {
    final response = await activateInvitationWithPasswordWithHttpInfo(invitationPasswordActivationInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthSession',) as AuthSession;
    
    }
    return null;
  }

  /// Preview Invitation
  ///
  /// Report what an invitation link is for and whether it is still valid.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<Response> previewInvitationWithHttpInfo(TokenInput tokenInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/invitations/previews';

    // ignore: prefer_final_locals
    Object? postBody = tokenInput;

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

  /// Preview Invitation
  ///
  /// Report what an invitation link is for and whether it is still valid.
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<InvitationPreview?> previewInvitation(TokenInput tokenInput,) async {
    final response = await previewInvitationWithHttpInfo(tokenInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvitationPreview',) as InvitationPreview;
    
    }
    return null;
  }

  /// Preview Invitation Acceptance
  ///
  /// Check whether the caller's account can accept an invitation.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<Response> previewInvitationAcceptanceWithHttpInfo(TokenInput tokenInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/invitations/acceptance-previews';

    // ignore: prefer_final_locals
    Object? postBody = tokenInput;

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

  /// Preview Invitation Acceptance
  ///
  /// Check whether the caller's account can accept an invitation.
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<InvitationAcceptancePreview?> previewInvitationAcceptance(TokenInput tokenInput,) async {
    final response = await previewInvitationAcceptanceWithHttpInfo(tokenInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvitationAcceptancePreview',) as InvitationAcceptancePreview;
    
    }
    return null;
  }
}
