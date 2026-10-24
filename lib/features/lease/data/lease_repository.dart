import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// The lease of the signed-in tenant. Every method throws an `ApiFailure` when
/// the call fails.
abstract interface class LeaseRepository {
  /// The caller's active lease, or null when the tenant has no lease.
  Future<CurrentLease?> myLease();
}

final leaseRepositoryProvider = Provider<LeaseRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiLeaseRepository(tenants: TenantsApi(client));
});

/// The tenant's own lease. Failures are not retried in the background: the
/// screen shows them and the user retries.
final myLeaseProvider = FutureProvider<CurrentLease?>(
  (ref) => ref.watch(leaseRepositoryProvider).myLease(),
  retry: (_, _) => null,
);

class ApiLeaseRepository implements LeaseRepository {
  ApiLeaseRepository({required this.tenants});

  final TenantsApi tenants;

  @override
  Future<CurrentLease?> myLease() => _guard(() async {
    return (await tenants.getMyLease())?.lease;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
