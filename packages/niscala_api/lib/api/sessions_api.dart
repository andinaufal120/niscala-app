//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class SessionsApi {
  SessionsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// End My Other Sessions
  ///
  /// Sign out every device of the caller except the current one.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> endMyOtherSessionsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/me/sessions';

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

  /// End My Other Sessions
  ///
  /// Sign out every device of the caller except the current one.
  Future<void> endMyOtherSessions() async {
    final response = await endMyOtherSessionsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// End My Session
  ///
  /// Sign one of the caller's devices out.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] sessionId (required):
  Future<Response> endMySessionWithHttpInfo(String sessionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/me/sessions/{sessionId}'
      .replaceAll('{sessionId}', sessionId);

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

  /// End My Session
  ///
  /// Sign one of the caller's devices out.
  ///
  /// Parameters:
  ///
  /// * [String] sessionId (required):
  Future<void> endMySession(String sessionId,) async {
    final response = await endMySessionWithHttpInfo(sessionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// List My Sessions
  ///
  /// List the caller's signed-in devices.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMySessionsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/me/sessions';

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

  /// List My Sessions
  ///
  /// List the caller's signed-in devices.
  Future<SessionList?> listMySessions() async {
    final response = await listMySessionsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SessionList',) as SessionList;
    
    }
    return null;
  }
}
