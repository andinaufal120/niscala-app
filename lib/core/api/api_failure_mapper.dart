import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala_api/api.dart';

/// Turns an exception thrown by the generated client into an [ApiFailure].
///
/// The generated client reports transport errors as an [ApiException] that
/// carries the original exception in `innerException`.
ApiFailure toApiFailure(Object error) {
  if (error is ApiFailure) return error;
  if (error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return const ApiFailure.network();
  }
  if (error is ApiException) {
    if (error.innerException != null) return const ApiFailure.network();
    return _fromBody(error.code, error.message);
  }
  return const ApiFailure(code: 'UNKNOWN');
}

ApiFailure _fromBody(int statusCode, String? body) {
  try {
    final json = jsonDecode(body ?? '');
    if (json is Map && json['code'] is String) {
      final field = json['field'];
      return ApiFailure(
        code: json['code'] as String,
        field: field is String ? field : null,
        statusCode: statusCode,
      );
    }
  } on FormatException {
    // Falls through to the generic failure below.
  }
  return ApiFailure(
    code: statusCode >= 500 ? 'INTERNAL_ERROR' : 'UNKNOWN',
    statusCode: statusCode,
  );
}
