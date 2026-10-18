import 'package:niscala_api/api.dart';

/// What is kept on the device between app launches.
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.emailVerified,
  });

  final String accessToken;
  final String refreshToken;
  final UserRole role;
  final bool emailVerified;

  StoredSession copyWith({
    String? accessToken,
    String? refreshToken,
    bool? emailVerified,
  }) => StoredSession(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    role: role,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}

abstract interface class SessionStore {
  /// The stored session, or null when there is none or it is unreadable.
  Future<StoredSession?> read();

  Future<void> write(StoredSession session);

  Future<void> clear();
}
