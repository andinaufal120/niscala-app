/// The invitation token in [input], or null when none remains. A pasted link
/// gives its last non-empty path segment, so the query and fragment are
/// ignored. Anything else is the token itself.
String? invitationTokenFromLink(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final segments = Uri.tryParse(text)?.pathSegments ?? const <String>[];
  final candidates = segments.isEmpty ? [text] : segments;
  final token = candidates.lastWhere(
    (segment) => segment.isNotEmpty,
    orElse: () => '',
  );
  return token.isEmpty ? null : token;
}
