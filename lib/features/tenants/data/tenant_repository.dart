import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Tenant management. Every method throws an `ApiFailure` when the call fails.
abstract interface class TenantRepository {
  Future<List<TenantSummary>> list(String propertyId);

  Future<Tenant> get(String tenantId);

  Future<Tenant> create(String propertyId, NewTenantInput input);
}

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiTenantRepository(tenants: TenantsApi(client));
});

/// The tenants of one property. Invalidate it after a change. Failures are not
/// retried in the background: the screen shows them and the user retries.
final tenantListProvider = FutureProvider.family<List<TenantSummary>, String>(
  (ref, propertyId) => ref.watch(tenantRepositoryProvider).list(propertyId),
  retry: (_, _) => null,
);

/// One tenant. Invalidate it after a change. Failures are not retried in the
/// background, see [tenantListProvider].
final tenantDetailProvider = FutureProvider.family<Tenant, String>(
  (ref, tenantId) => ref.watch(tenantRepositoryProvider).get(tenantId),
  retry: (_, _) => null,
);

class ApiTenantRepository implements TenantRepository {
  ApiTenantRepository({required this.tenants});

  final TenantsApi tenants;

  @override
  Future<List<TenantSummary>> list(String propertyId) => _guard(() async {
    return (await tenants.listTenants(propertyId))!.items;
  });

  @override
  Future<Tenant> get(String tenantId) => _guard(() async {
    return (await tenants.getTenant(tenantId))!;
  });

  @override
  Future<Tenant> create(String propertyId, NewTenantInput input) =>
      _guard(() async {
        return (await tenants.createTenant(propertyId, input))!;
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
