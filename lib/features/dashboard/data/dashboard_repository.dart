import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// The occupancy dashboard of the signed-in management user. Every method
/// throws an `ApiFailure` when the call fails.
abstract interface class DashboardRepository {
  /// The occupancy of each property the caller can see, with a summary across
  /// them. The figures are the ones the API returns.
  Future<OccupancyDashboard> occupancyDashboard();
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiDashboardRepository(dashboard: DashboardApi(client));
});

/// The occupancy dashboard. Failures are not retried in the background: the
/// screen shows them and the user retries.
final occupancyDashboardProvider = FutureProvider<OccupancyDashboard>(
  (ref) => ref.watch(dashboardRepositoryProvider).occupancyDashboard(),
  retry: (_, _) => null,
);

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({required this.dashboard});

  final DashboardApi dashboard;

  @override
  Future<OccupancyDashboard> occupancyDashboard() => _guard(() async {
    final result = await dashboard.getOccupancyDashboard();
    // The API answers every successful call with a body, so an empty answer
    // is a server fault and is reported as one.
    if (result == null) throw const ApiFailure(code: 'INTERNAL_ERROR');
    return result;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
