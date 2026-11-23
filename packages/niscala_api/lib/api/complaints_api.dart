//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;


class ComplaintsApi {
  ComplaintsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Change Complaint Status
  ///
  /// Move a complaint to its next status, optionally with a handling note.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  ///
  /// * [ComplaintStatusChangeInput] complaintStatusChangeInput (required):
  Future<Response> changeComplaintStatusWithHttpInfo(String complaintId, ComplaintStatusChangeInput complaintStatusChangeInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/complaints/{complaintId}/status-changes'
      .replaceAll('{complaintId}', complaintId);

    // ignore: prefer_final_locals
    Object? postBody = complaintStatusChangeInput;

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

  /// Change Complaint Status
  ///
  /// Move a complaint to its next status, optionally with a handling note.
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  ///
  /// * [ComplaintStatusChangeInput] complaintStatusChangeInput (required):
  Future<Complaint?> changeComplaintStatus(String complaintId, ComplaintStatusChangeInput complaintStatusChangeInput,) async {
    final response = await changeComplaintStatusWithHttpInfo(complaintId, complaintStatusChangeInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Complaint',) as Complaint;
    
    }
    return null;
  }

  /// Classify Complaint
  ///
  /// Set a complaint's category and urgency manually.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  ///
  /// * [ComplaintClassificationInput] complaintClassificationInput (required):
  Future<Response> classifyComplaintWithHttpInfo(String complaintId, ComplaintClassificationInput complaintClassificationInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/complaints/{complaintId}/classification'
      .replaceAll('{complaintId}', complaintId);

    // ignore: prefer_final_locals
    Object? postBody = complaintClassificationInput;

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

  /// Classify Complaint
  ///
  /// Set a complaint's category and urgency manually.
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  ///
  /// * [ComplaintClassificationInput] complaintClassificationInput (required):
  Future<Complaint?> classifyComplaint(String complaintId, ComplaintClassificationInput complaintClassificationInput,) async {
    final response = await classifyComplaintWithHttpInfo(complaintId, complaintClassificationInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Complaint',) as Complaint;
    
    }
    return null;
  }

  /// Create Complaint
  ///
  /// Submit a complaint as the calling tenant.  The complaint is saved before it is classified in the background.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ComplaintInput] complaintInput (required):
  Future<Response> createComplaintWithHttpInfo(ComplaintInput complaintInput,) async {
    // ignore: prefer_const_declarations
    final path = r'/complaints';

    // ignore: prefer_final_locals
    Object? postBody = complaintInput;

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

  /// Create Complaint
  ///
  /// Submit a complaint as the calling tenant.  The complaint is saved before it is classified in the background.
  ///
  /// Parameters:
  ///
  /// * [ComplaintInput] complaintInput (required):
  Future<Complaint?> createComplaint(ComplaintInput complaintInput,) async {
    final response = await createComplaintWithHttpInfo(complaintInput,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Complaint',) as Complaint;
    
    }
    return null;
  }

  /// Get Complaint
  ///
  /// Return a complaint's detail with its status history.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  Future<Response> getComplaintWithHttpInfo(String complaintId,) async {
    // ignore: prefer_const_declarations
    final path = r'/complaints/{complaintId}'
      .replaceAll('{complaintId}', complaintId);

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

  /// Get Complaint
  ///
  /// Return a complaint's detail with its status history.
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  Future<Complaint?> getComplaint(String complaintId,) async {
    final response = await getComplaintWithHttpInfo(complaintId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Complaint',) as Complaint;
    
    }
    return null;
  }

  /// Get Complaint Photo
  ///
  /// Return the complaint photo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  Future<Response> getComplaintPhotoWithHttpInfo(String complaintId,) async {
    // ignore: prefer_const_declarations
    final path = r'/complaints/{complaintId}/photo'
      .replaceAll('{complaintId}', complaintId);

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

  /// Get Complaint Photo
  ///
  /// Return the complaint photo.
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  Future<void> getComplaintPhoto(String complaintId,) async {
    final response = await getComplaintPhotoWithHttpInfo(complaintId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// List Complaint Categories
  ///
  /// Return the categories a complaint can be classified into.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listComplaintCategoriesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/complaint-categories';

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

  /// List Complaint Categories
  ///
  /// Return the categories a complaint can be classified into.
  Future<ComplaintCategoryList?> listComplaintCategories() async {
    final response = await listComplaintCategoriesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ComplaintCategoryList',) as ComplaintCategoryList;
    
    }
    return null;
  }

  /// List Complaints
  ///
  /// List the caller's complaints: a tenant's own, or those on accessible properties.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listComplaintsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/complaints';

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

  /// List Complaints
  ///
  /// List the caller's complaints: a tenant's own, or those on accessible properties.
  Future<ComplaintList?> listComplaints() async {
    final response = await listComplaintsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ComplaintList',) as ComplaintList;
    
    }
    return null;
  }

  /// Upload Complaint Photo
  ///
  /// Attach or replace the complaint photo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  ///
  /// * [MultipartFile] file (required):
  Future<Response> uploadComplaintPhotoWithHttpInfo(String complaintId, MultipartFile file,) async {
    // ignore: prefer_const_declarations
    final path = r'/complaints/{complaintId}/photo'
      .replaceAll('{complaintId}', complaintId);

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

  /// Upload Complaint Photo
  ///
  /// Attach or replace the complaint photo.
  ///
  /// Parameters:
  ///
  /// * [String] complaintId (required):
  ///
  /// * [MultipartFile] file (required):
  Future<Complaint?> uploadComplaintPhoto(String complaintId, MultipartFile file,) async {
    final response = await uploadComplaintPhotoWithHttpInfo(complaintId, file,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Complaint',) as Complaint;
    
    }
    return null;
  }
}
