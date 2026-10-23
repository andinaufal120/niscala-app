import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/core/api/device_info.dart';
import 'package:niscala_api/api.dart';

/// Sign-up, login and email verification. Every method throws an
/// `ApiFailure` when the call fails.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> registerOwner({
    required String name,
    required String email,
    required String password,
  });

  Future<Account> getMyAccount();

  /// Emails a new verification code and returns when another may be requested.
  Future<DateTime> sendEmailVerification();

  Future<Account> confirmEmail(String code);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiAuthRepository(
    auth: AuthApi(client),
    account: AccountApi(client),
    device: () => ref.read(deviceInfoProvider.future),
  );
});

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

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
