import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// The account and the signed-in devices of the caller. Every method throws an
/// `ApiFailure` when the call fails.
abstract interface class AccountRepository {
  Future<Account> me();

  /// The caller's devices, in the order the API returns them.
  Future<List<Session>> sessions();

  /// Signs one device of the caller out. Fails with `SESSION_IS_CURRENT` for
  /// the device that makes the call.
  Future<void> endSession(String id);

  /// Signs out every device of the caller except the current one.
  Future<void> endOtherSessions();

  /// Replaces the caller's password after the API checks [currentPassword].
  /// Returns whether the caller has other devices signed in.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiAccountRepository(
    account: AccountApi(client),
    sessions: SessionsApi(client),
  );
});

/// The caller's account. Failures are not retried in the background: the
/// screen shows them and the user retries.
final meProvider = FutureProvider<Account>(
  (ref) => ref.watch(accountRepositoryProvider).me(),
  retry: (_, _) => null,
);

/// The caller's devices. Invalidate it after ending a device. Failures are not
/// retried in the background, see [meProvider].
final sessionsProvider = FutureProvider<List<Session>>(
  (ref) => ref.watch(accountRepositoryProvider).sessions(),
  retry: (_, _) => null,
);

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository({
    required AccountApi account,
    required SessionsApi sessions,
  }) : accountApi = account,
       sessionsApi = sessions;

  final AccountApi accountApi;
  final SessionsApi sessionsApi;

  @override
  Future<Account> me() => _guard(() async {
    return (await accountApi.getMyAccount())!;
  });

  @override
  Future<List<Session>> sessions() => _guard(() async {
    return (await sessionsApi.listMySessions())!.items;
  });

  @override
  Future<void> endSession(String id) =>
      _guard(() => sessionsApi.endMySession(id));

  @override
  Future<void> endOtherSessions() => _guard(sessionsApi.endMyOtherSessions);

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final result = await accountApi.changeMyPassword(
      PasswordChangeInput(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    return result!.hasOtherSessions;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
