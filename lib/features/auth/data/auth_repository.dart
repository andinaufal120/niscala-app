import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/core/api/device_info.dart';
import 'package:niscala_api/api.dart';

/// Sign-up, login and email verification. Every method throws an
/// `ApiFailure` when the call fails.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  /// Logs in with the Google account of [idToken] and starts a session.
  Future<AuthSession> loginWithGoogle(String idToken);

  Future<AuthSession> registerOwner({
    required String name,
    required String email,
    required String password,
  });

  /// Signs up an Owner with the Google account of [idToken]. A null or blank
  /// [name] is sent as no name.
  Future<AuthSession> registerOwnerWithGoogle(String idToken, {String? name});

  Future<Account> getMyAccount();

  /// Emails a new verification code and returns when another may be requested.
  Future<DateTime> sendEmailVerification();

  Future<Account> confirmEmail(String code);

  /// Emails a password-reset link. Completes the same way for every email.
  Future<void> requestPasswordReset(String email);

  /// Checks a password-reset token and returns the email of its account.
  Future<String> previewPasswordReset(String token);

  /// Sets a new password with a reset token. The password is sent untrimmed.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Makes the new email of an emailed change link the login email of its
  /// account. Signs nobody in.
  Future<void> confirmEmailChange(String token);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiAuthRepository(
    auth: AuthApi(client),
    account: AccountApi(client),
    device: () => ref.read(deviceInfoProvider.future),
  );
});

/// The signed-in account. Failures are not retried in the background: the
/// screen shows them and the user retries.
final myAccountProvider = FutureProvider<Account>(
  (ref) => ref.watch(authRepositoryProvider).getMyAccount(),
  retry: (_, _) => null,
);

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this.auth,
    required this.account,
    required this.device,
  });

  final AuthApi auth;
  final AccountApi account;
  final Future<DeviceInfo> Function() device;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _guard(() async {
      final input = LoginInput(
        device: await device(),
        email: email,
        password: password,
      );
      return (await auth.login(input))!;
    });
  }

  @override
  Future<AuthSession> loginWithGoogle(String idToken) {
    return _guard(() async {
      final input = GoogleAuthInput(device: await device(), idToken: idToken);
      return (await auth.loginWithGoogle(input))!;
    });
  }

  @override
  Future<AuthSession> registerOwner({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final input = RegisterOwnerInput(
        device: await device(),
        email: email,
        name: name,
        password: password,
      );
      return (await auth.registerOwner(input))!;
    });
  }

  @override
  Future<AuthSession> registerOwnerWithGoogle(String idToken, {String? name}) {
    return _guard(() async {
      final input = GoogleAuthInput(
        device: await device(),
        idToken: idToken,
        name: _nonBlank(name),
      );
      return (await auth.registerOwnerWithGoogle(input))!;
    });
  }

  @override
  Future<Account> getMyAccount() => _guard(() async {
    return (await account.getMyAccount())!;
  });

  @override
  Future<DateTime> sendEmailVerification() => _guard(() async {
    return (await auth.sendEmailVerification())!.resendAvailableAt;
  });

  @override
  Future<Account> confirmEmail(String code) => _guard(() async {
    return (await auth.confirmEmail(EmailConfirmationInput(code: code)))!;
  });

  @override
  Future<void> requestPasswordReset(String email) => _guard(() async {
    await auth.requestPasswordReset(PasswordResetRequestInput(email: email));
  });

  @override
  Future<String> previewPasswordReset(String token) => _guard(() async {
    return (await auth.previewPasswordReset(TokenInput(token: token)))!.email;
  });

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => _guard(() async {
    await auth.resetPassword(
      PasswordResetInput(token: token, newPassword: newPassword),
    );
  });

  @override
  Future<void> confirmEmailChange(String token) => _guard(() async {
    await auth.confirmEmailChange(TokenInput(token: token));
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}

/// The trimmed [value], or null when it is missing or blank.
String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
