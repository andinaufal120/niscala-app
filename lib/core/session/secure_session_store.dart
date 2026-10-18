import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:niscala/core/session/session_store.dart';
import 'package:niscala_api/api.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _roleKey = 'role';
const _emailVerifiedKey = 'email_verified';

/// Keeps the session in the platform's encrypted storage.
class SecureSessionStore implements SessionStore {
  const SecureSessionStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final role = UserRole.fromJson(await _storage.read(key: _roleKey));
      final emailVerified = await _storage.read(key: _emailVerifiedKey);
      if (accessToken == null ||
          refreshToken == null ||
          role == null ||
          (emailVerified != 'true' && emailVerified != 'false')) {
        return null;
      }
      return StoredSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
        emailVerified: emailVerified == 'true',
      );
    } on Exception {
      // Unreadable storage is treated as no session.
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: _roleKey, value: session.role.value);
    await _storage.write(
      key: _emailVerifiedKey,
      value: session.emailVerified.toString(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _emailVerifiedKey);
  }
}
