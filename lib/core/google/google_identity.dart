import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:niscala/core/api/api_failure.dart';

/// The Google OAuth client ID of the backend, given with `--dart-define`. Empty
/// when the app was built without it.
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Lets the user pick a Google account and returns its ID token.
abstract interface class GoogleIdentity {
  /// Returns the ID token of the chosen account, or null when the user cancels
  /// the chooser. Throws an `ApiFailure` when Google sign-in is not configured
  /// or Google returns no token; any other error comes from the Google plugin.
  Future<String?> idToken();
}

final googleIdentityProvider = Provider<GoogleIdentity>(
  (ref) => const GoogleSignInIdentity(),
);

/// The [GoogleIdentity] backed by the `google_sign_in` plugin.
class GoogleSignInIdentity implements GoogleIdentity {
  const GoogleSignInIdentity();

  static Future<void>? _initialization;

  @override
  Future<String?> idToken() async {
    if (_serverClientId.isEmpty) {
      throw const ApiFailure(code: 'GOOGLE_SIGN_IN_UNAVAILABLE');
    }
    final google = GoogleSignIn.instance;
    await (_initialization ??= google.initialize(
      serverClientId: _serverClientId,
    ));
    // Signing out first makes the chooser appear even when an account was
    // used before, so the user can pick another one.
    await google.signOut();
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const ApiFailure(code: 'GOOGLE_TOKEN_INVALID');
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
