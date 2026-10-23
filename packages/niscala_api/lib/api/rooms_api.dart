//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class RoomsApi {
  RoomsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Room
  ///
  /// Add a room to a property.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [RoomInput] roomInput (required):
  Future<Response> createRoomWithHttpInfo(String propertyId, RoomInput roomInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/rooms'
      .replaceAll('{propertyId}', propertyId);

    // ignore: prefer_final_locals
    Object? postBody = roomInput;

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

  /// Create Room
  ///
  /// Add a room to a property.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  ///
  /// * [RoomInput] roomInput (required):
  Future<Room?> createRoom(String propertyId, RoomInput roomInput,) async {
    final response = await createRoomWithHttpInfo(propertyId, roomInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Room',) as Room;
    
    }
    return null;
  }

  /// Delete Room
  ///
  /// Delete a room.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] roomId (required):
  Future<Response> deleteRoomWithHttpInfo(String roomId,) async {
    // ignore: prefer_const_declarations
    final path = r'/rooms/{roomId}'
      .replaceAll('{roomId}', roomId);

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

  /// Delete Room
  ///
  /// Delete a room.
  ///
  /// Parameters:
  ///
  /// * [String] roomId (required):
  Future<void> deleteRoom(String roomId,) async {
    final response = await deleteRoomWithHttpInfo(roomId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get Room
  ///
  /// Return a room's detail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] roomId (required):
  Future<Response> getRoomWithHttpInfo(String roomId,) async {
    // ignore: prefer_const_declarations
    final path = r'/rooms/{roomId}'
      .replaceAll('{roomId}', roomId);

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

  /// Get Room
  ///
  /// Return a room's detail.
  ///
  /// Parameters:
  ///
  /// * [String] roomId (required):
  Future<Room?> getRoom(String roomId,) async {
    final response = await getRoomWithHttpInfo(roomId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Room',) as Room;
    
    }
    return null;
  }

  /// List Facility Suggestions
  ///
  /// List the distinct facility tags already used on rooms of the property's Owner.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> listFacilitySuggestionsWithHttpInfo(String propertyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/facility-suggestions'
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

  /// List Facility Suggestions
  ///
  /// List the distinct facility tags already used on rooms of the property's Owner.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<FacilitySuggestionList?> listFacilitySuggestions(String propertyId,) async {
    final response = await listFacilitySuggestionsWithHttpInfo(propertyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'FacilitySuggestionList',) as FacilitySuggestionList;
    
    }
    return null;
  }

  /// List Rooms
  ///
  /// List a property's rooms.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<Response> listRoomsWithHttpInfo(String propertyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/properties/{propertyId}/rooms'
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

  /// List Rooms
  ///
  /// List a property's rooms.
  ///
  /// Parameters:
  ///
  /// * [String] propertyId (required):
  Future<RoomList?> listRooms(String propertyId,) async {
    final response = await listRoomsWithHttpInfo(propertyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RoomList',) as RoomList;
    
    }
    return null;
  }

  /// Update Room
  ///
  /// Replace a room's fields.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] roomId (required):
  ///
  /// * [RoomInput] roomInput (required):
  Future<Response> updateRoomWithHttpInfo(String roomId, RoomInput roomInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/rooms/{roomId}'
      .replaceAll('{roomId}', roomId);

    // ignore: prefer_final_locals
    Object? postBody = roomInput;

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

  /// Update Room
  ///
  /// Replace a room's fields.
  ///
  /// Parameters:
  ///
  /// * [String] roomId (required):
  ///
  /// * [RoomInput] roomInput (required):
  Future<Room?> updateRoom(String roomId, RoomInput roomInput,) async {
    final response = await updateRoomWithHttpInfo(roomId, roomInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Room',) as Room;
    
    }
    return null;
  }
}
