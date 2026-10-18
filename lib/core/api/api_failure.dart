/// A failed call to the API, reduced to what the UI needs.
///
/// [code] is the API's error code, or `NETWORK_ERROR` when no response was
/// received. [field] names the request field a validation error belongs to.
class ApiFailure implements Exception {
  const ApiFailure({required this.code, this.field, this.statusCode});

  const ApiFailure.network()
    : code = 'NETWORK_ERROR',
      field = null,
      statusCode = null;

  final String code;
  final String? field;
  final int? statusCode;

  @override
  String toString() => 'ApiFailure($code, field: $field, status: $statusCode)';
}
