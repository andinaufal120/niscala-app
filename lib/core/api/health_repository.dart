import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/http_providers.dart';
import 'package:niscala_api/api.dart';

/// Asks the API whether it can serve requests. The call carries no
/// authentication, so a failing check never triggers a token refresh.
class HealthRepository {
  HealthRepository(this._api);

  final HealthApi _api;

  /// Completes when the API answers 200. Otherwise throws an `ApiFailure`.
  Future<void> check() async {
    try {
      await _api.getHealth();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final api = HealthApi(
    ApiClient(basePath: ref.watch(apiBaseUrlProvider))
      ..client = ref.watch(httpClientProvider),
  );
  return HealthRepository(api);
});
