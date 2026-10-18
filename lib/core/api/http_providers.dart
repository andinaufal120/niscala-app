import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Set with `--dart-define=API_BASE_URL=...`. The default reaches a backend
/// running on the host machine from the Android emulator.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

final apiBaseUrlProvider = Provider<String>((ref) => apiBaseUrl);

/// A client without authentication, for calls that must not refresh tokens.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
