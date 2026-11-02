//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Confirm Email
  ///
  /// Confirm the caller's email with the code that was sent.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [EmailConfirmationInput] emailConfirmationInput (required):
  Future<Response> confirmEmailWithHttpInfo(EmailConfirmationInput emailConfirmationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/email-verification/confirmation';

    // ignore: prefer_final_locals
    Object? postBody = emailConfirmationInput;

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

  /// Confirm Email
  ///
  /// Confirm the caller's email with the code that was sent.
  ///
  /// Parameters:
  ///
  /// * [EmailConfirmationInput] emailConfirmationInput (required):
  Future<Account?> confirmEmail(EmailConfirmationInput emailConfirmationInput,) async {
    final response = await confirmEmailWithHttpInfo(emailConfirmationInput,);
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

  /// Confirm Email Change
  ///
  /// Make the email of an emailed change link the account's login email.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<Response> confirmEmailChangeWithHttpInfo(TokenInput tokenInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/email-changes';

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

  /// Confirm Email Change
  ///
  /// Make the email of an emailed change link the account's login email.
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<void> confirmEmailChange(TokenInput tokenInput,) async {
    final response = await confirmEmailChangeWithHttpInfo(tokenInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Login
  ///
  /// Log in with email and password and start a session.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LoginInput] loginInput (required):
  Future<Response> loginWithHttpInfo(LoginInput loginInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = loginInput;

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

  /// Login
  ///
  /// Log in with email and password and start a session.
  ///
  /// Parameters:
  ///
  /// * [LoginInput] loginInput (required):
  Future<AuthSession?> login(LoginInput loginInput,) async {
    final response = await loginWithHttpInfo(loginInput,);
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

  /// Login With Google
  ///
  /// Log in with Google and start a session.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [GoogleAuthInput] googleAuthInput (required):
  Future<Response> loginWithGoogleWithHttpInfo(GoogleAuthInput googleAuthInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/login/google';

    // ignore: prefer_final_locals
    Object? postBody = googleAuthInput;

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

  /// Login With Google
  ///
  /// Log in with Google and start a session.
  ///
  /// Parameters:
  ///
  /// * [GoogleAuthInput] googleAuthInput (required):
  Future<AuthSession?> loginWithGoogle(GoogleAuthInput googleAuthInput,) async {
    final response = await loginWithGoogleWithHttpInfo(googleAuthInput,);
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

  /// Logout
  ///
  /// End the current session.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> logoutWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/auth/logout';

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

  /// Logout
  ///
  /// End the current session.
  Future<void> logout() async {
    final response = await logoutWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Preview Password Reset
  ///
  /// Check a password-reset link and return the account email.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<Response> previewPasswordResetWithHttpInfo(TokenInput tokenInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/password-reset-previews';

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

  /// Preview Password Reset
  ///
  /// Check a password-reset link and return the account email.
  ///
  /// Parameters:
  ///
  /// * [TokenInput] tokenInput (required):
  Future<PasswordResetPreview?> previewPasswordReset(TokenInput tokenInput,) async {
    final response = await previewPasswordResetWithHttpInfo(tokenInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PasswordResetPreview',) as PasswordResetPreview;
    
    }
    return null;
  }

  /// Refresh Tokens
  ///
  /// Exchange a refresh token for a new token pair; the old one stops working.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RefreshInput] refreshInput (required):
  Future<Response> refreshTokensWithHttpInfo(RefreshInput refreshInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/refresh';

    // ignore: prefer_final_locals
    Object? postBody = refreshInput;

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

  /// Refresh Tokens
  ///
  /// Exchange a refresh token for a new token pair; the old one stops working.
  ///
  /// Parameters:
  ///
  /// * [RefreshInput] refreshInput (required):
  Future<AuthTokens?> refreshTokens(RefreshInput refreshInput,) async {
    final response = await refreshTokensWithHttpInfo(refreshInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthTokens',) as AuthTokens;
    
    }
    return null;
  }

  /// Register Owner
  ///
  /// Sign up an Owner with a password and start a session.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RegisterOwnerInput] registerOwnerInput (required):
  Future<Response> registerOwnerWithHttpInfo(RegisterOwnerInput registerOwnerInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/register';

    // ignore: prefer_final_locals
    Object? postBody = registerOwnerInput;

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

  /// Register Owner
  ///
  /// Sign up an Owner with a password and start a session.
  ///
  /// Parameters:
  ///
  /// * [RegisterOwnerInput] registerOwnerInput (required):
  Future<AuthSession?> registerOwner(RegisterOwnerInput registerOwnerInput,) async {
    final response = await registerOwnerWithHttpInfo(registerOwnerInput,);
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

  /// Register Owner With Google
  ///
  /// Sign up an Owner with Google and start a session.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [GoogleAuthInput] googleAuthInput (required):
  Future<Response> registerOwnerWithGoogleWithHttpInfo(GoogleAuthInput googleAuthInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/register/google';

    // ignore: prefer_final_locals
    Object? postBody = googleAuthInput;

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

  /// Register Owner With Google
  ///
  /// Sign up an Owner with Google and start a session.
  ///
  /// Parameters:
  ///
  /// * [GoogleAuthInput] googleAuthInput (required):
  Future<AuthSession?> registerOwnerWithGoogle(GoogleAuthInput googleAuthInput,) async {
    final response = await registerOwnerWithGoogleWithHttpInfo(googleAuthInput,);
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

  /// Request Password Reset
  ///
  /// Email a password-reset link; answers the same whether or not the email is registered.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PasswordResetRequestInput] passwordResetRequestInput (required):
  Future<Response> requestPasswordResetWithHttpInfo(PasswordResetRequestInput passwordResetRequestInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/password-reset-requests';

    // ignore: prefer_final_locals
    Object? postBody = passwordResetRequestInput;

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

  /// Request Password Reset
  ///
  /// Email a password-reset link; answers the same whether or not the email is registered.
  ///
  /// Parameters:
  ///
  /// * [PasswordResetRequestInput] passwordResetRequestInput (required):
  Future<void> requestPasswordReset(PasswordResetRequestInput passwordResetRequestInput,) async {
    final response = await requestPasswordResetWithHttpInfo(passwordResetRequestInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Reset Password
  ///
  /// Set a new password with a reset link and end every session of the account.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PasswordResetInput] passwordResetInput (required):
  Future<Response> resetPasswordWithHttpInfo(PasswordResetInput passwordResetInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/auth/password-resets';

    // ignore: prefer_final_locals
    Object? postBody = passwordResetInput;

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

  /// Reset Password
  ///
  /// Set a new password with a reset link and end every session of the account.
  ///
  /// Parameters:
  ///
  /// * [PasswordResetInput] passwordResetInput (required):
  Future<void> resetPassword(PasswordResetInput passwordResetInput,) async {
    final response = await resetPasswordWithHttpInfo(passwordResetInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Send Email Verification
  ///
  /// Email a new 6-digit verification code to the caller's account.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> sendEmailVerificationWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/auth/email-verification';

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

  /// Send Email Verification
  ///
  /// Email a new 6-digit verification code to the caller's account.
  Future<EmailVerificationSent?> sendEmailVerification() async {
    final response = await sendEmailVerificationWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'EmailVerificationSent',) as EmailVerificationSent;
    
    }
    return null;
  }
}
