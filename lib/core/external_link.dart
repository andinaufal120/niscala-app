import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// The published privacy policy page.
final privacyPolicyUri = Uri.parse('https://niscala.andinaufal.com/privacy/');

/// Opens web pages in the browser outside the app.
abstract interface class ExternalLinkOpener {
  /// Opens [uri] in an app outside Niscala. Returns whether it was opened.
  Future<bool> open(Uri uri);
}

/// [ExternalLinkOpener] backed by the url_launcher plugin.
class PluginExternalLinkOpener implements ExternalLinkOpener {
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

final externalLinkOpenerProvider = Provider<ExternalLinkOpener>(
  (ref) => PluginExternalLinkOpener(),
);
