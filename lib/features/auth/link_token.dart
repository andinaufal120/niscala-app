/// The token in a pasted password-reset or email-change link. A link gives its
/// `token` query parameter; the path and the fragment are ignored. Text with no
/// `?` and no `/` is a bare token and is returned trimmed.
///
/// Returns null when the text holds no token. Never throws, also for a
/// malformed percent escape.
String? tokenFromQueryLink(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('?') && !text.contains('/')) return text;
  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  final token = _queryToken(uri);
  return token == null || token.isEmpty ? null : token;
}

String? _queryToken(Uri uri) {
  try {
    return uri.queryParameters['token'];
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}
