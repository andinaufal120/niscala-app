import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Manager management. Every method throws an `ApiFailure` when the call fails.
abstract interface class ManagerRepository {
  /// The managers of the Owner, or only those assigned to [propertyId].
  Future<List<ManagerSummary>> list({String? propertyId});

  Future<Manager> get(String managerId);

  Future<Manager> create(ManagerInput input);

  Future<Manager> update(String managerId, ManagerInput input);

  Future<void> delete(String managerId);

  /// Gives a manager who is not active yet a new invitation link. The old link
  /// stops working.
  Future<ManagerInvitation> regenerateInvitation(String managerId);
}

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiManagerRepository(managers: ManagersApi(client));
});

/// The managers of one property. Invalidate it after a change. Failures are not
/// retried in the background: the screen shows them and the user retries.
final managerListProvider = FutureProvider.family<List<ManagerSummary>, String>(
  (ref, propertyId) =>
      ref.watch(managerRepositoryProvider).list(propertyId: propertyId),
  retry: (_, _) => null,
);

/// One manager. Invalidate it after a change. Failures are not retried in the
/// background, see [managerListProvider].
final managerDetailProvider = FutureProvider.family<Manager, String>(
  (ref, managerId) => ref.watch(managerRepositoryProvider).get(managerId),
  retry: (_, _) => null,
);

class ApiManagerRepository implements ManagerRepository {
  ApiManagerRepository({required this.managers});

  final ManagersApi managers;

  @override
  Future<List<ManagerSummary>> list({String? propertyId}) => _guard(() async {
    return (await managers.listManagers(propertyId: propertyId))!.items;
  });

  @override
  Future<Manager> get(String managerId) => _guard(() async {
    return (await managers.getManager(managerId))!;
  });

  @override
  Future<Manager> create(ManagerInput input) => _guard(() async {
    return (await managers.createManager(input))!;
  });

  @override
  Future<Manager> update(String managerId, ManagerInput input) =>
      _guard(() async {
        return (await managers.updateManager(managerId, input))!;
      });

  @override
  Future<void> delete(String managerId) =>
      _guard(() => managers.deleteManager(managerId));

  @override
  Future<ManagerInvitation> regenerateInvitation(String managerId) =>
      _guard(() async {
        return (await managers.regenerateManagerInvitation(managerId))!;
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
