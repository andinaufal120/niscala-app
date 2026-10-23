import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/auth_http_client.dart';
import 'package:niscala/core/api/http_providers.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  final client = AuthHttpClient(
    inner: ref.watch(httpClientProvider),
    tokens: ref.watch(sessionControllerProvider.notifier),
  );
  ref.onDispose(client.close);
  return client;
});

/// The generated client that sends the signed-in user's bearer token.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(basePath: ref.watch(apiBaseUrlProvider))
    ..client = ref.watch(authHttpClientProvider);
});
