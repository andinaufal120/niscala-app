import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// The filters of the user account list. Each field is sent as its query
/// parameter, and a null field is left out of the request.
typedef UserAccountQuery = ({
  String? email,
  UserRole? role,
  bool includeDeleted,
});

/// User accounts for an Admin. Every method throws an `ApiFailure` when the
/// call fails.
abstract interface class UserAccountRepository {
  /// The accounts that match the filters. Deleted accounts are left out unless
  /// [includeDeleted] is set.
  Future<List<UserAccountSummary>> list({
    String? email,
    UserRole? role,
    bool includeDeleted = false,
  });

  Future<UserAccount> get(String userAccountId);

  /// Saves the name, email and status of the account and returns it. A new
  /// email stays pending until its link is confirmed.
  Future<UserAccount> update(String userAccountId, UserAccountInput input);
}

final userAccountRepositoryProvider = Provider<UserAccountRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiUserAccountRepository(userAccounts: UserAccountsApi(client));
});

/// The accounts for one query. It is released when the screen stops watching
/// it, so a query that is shown again asks the API again. Failures are not
/// retried in the background: the screen shows them and the user retries.
final userAccountListProvider = FutureProvider.autoDispose
    .family<List<UserAccountSummary>, UserAccountQuery>(
      (ref, query) => ref
          .watch(userAccountRepositoryProvider)
          .list(
            email: query.email,
            role: query.role,
            includeDeleted: query.includeDeleted,
          ),
      retry: (_, _) => null,
    );

/// One account. Failures are not retried in the background, see
/// [userAccountListProvider].
final userAccountDetailProvider = FutureProvider.family<UserAccount, String>(
  (ref, userAccountId) =>
      ref.watch(userAccountRepositoryProvider).get(userAccountId),
  retry: (_, _) => null,
);

class ApiUserAccountRepository implements UserAccountRepository {
  ApiUserAccountRepository({required this.userAccounts});

  final UserAccountsApi userAccounts;

  @override
  Future<List<UserAccountSummary>> list({
    String? email,
    UserRole? role,
    bool includeDeleted = false,
  }) => _guard(() async {
    final result = await userAccounts.listUserAccounts(
      email: email,
      role: role,
      includeDeleted: includeDeleted,
    );
    return result!.items;
  });

  @override
  Future<UserAccount> get(String userAccountId) => _guard(() async {
    return (await userAccounts.getUserAccount(userAccountId))!;
  });

  @override
  Future<UserAccount> update(String userAccountId, UserAccountInput input) =>
      _guard(() async {
        return (await userAccounts.updateUserAccount(userAccountId, input))!;
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
