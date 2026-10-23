import 'dart:convert';

import 'package:http/http.dart' as http;

/// What [AuthHttpClient] needs from the session.
abstract interface class TokenSource {
  String? get accessToken;

  /// Gets a new access token. Returns false when the session cannot continue.
  Future<bool> refresh();

  /// Ends the session after a refresh failed.
  void expire();
}

/// Adds the bearer token to every request. When the API answers
/// `ACCESS_TOKEN_INVALID`, it refreshes the tokens once and re-sends the
/// request. Concurrent requests share a single refresh.
class AuthHttpClient extends http.BaseClient {
  AuthHttpClient({required this._inner, required this._tokens});

  final http.Client _inner;
  final TokenSource _tokens;
  Future<bool>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final first = await _inner.send(_copy(request, body));
    if (first.statusCode != 401) return first;

    final firstBody = await first.stream.toBytes();
    if (!_isAccessTokenInvalid(firstBody) || !await _refreshOnce()) {
      return _replay(first, firstBody);
    }
    return _inner.send(_copy(request, body));
  }

  @override
  void close() => _inner.close();

  http.Request _copy(http.BaseRequest request, List<int> body) {
    final copy = http.Request(request.method, request.url)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll(request.headers)
      ..bodyBytes = body;
    final token = _tokens.accessToken;
    if (token != null) copy.headers['Authorization'] = 'Bearer $token';
    return copy;
  }

  Future<bool> _refreshOnce() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final refreshed = await _tokens.refresh();
    if (!refreshed) _tokens.expire();
    return refreshed;
  }

  bool _isAccessTokenInvalid(List<int> body) {
    try {
      final json = jsonDecode(utf8.decode(body));
      return json is Map && json['code'] == 'ACCESS_TOKEN_INVALID';
    } on FormatException {
      return false;
    }
  }

  http.StreamedResponse _replay(
    http.StreamedResponse response,
    List<int> body,
  ) {
    return http.StreamedResponse(
      http.ByteStream.fromBytes(body),
      response.statusCode,
      contentLength: body.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
