import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Maintenance complaints. Every method throws an `ApiFailure` when the call
/// fails.
abstract interface class ComplaintRepository {
  /// The complaints the caller can see: a tenant's own, or those on the
  /// properties the caller manages.
  Future<List<ComplaintSummary>> list();

  Future<Complaint> get(String complaintId);

  /// Saves a complaint as the calling tenant. The returned complaint may still
  /// be unclassified; the AI classification runs in the background.
  Future<Complaint> submit(String description);
}

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiComplaintRepository(complaints: ComplaintsApi(client));
});

/// The complaints of the caller. Invalidate it after a change. Failures are not
/// retried in the background: the screen shows them and the user retries.
final complaintListProvider = FutureProvider<List<ComplaintSummary>>(
  (ref) => ref.watch(complaintRepositoryProvider).list(),
  retry: (_, _) => null,
);

/// One complaint. Invalidate it to fetch the latest classification. Failures
/// are not retried in the background, see [complaintListProvider].
final complaintDetailProvider = FutureProvider.family<Complaint, String>(
  (ref, complaintId) => ref.watch(complaintRepositoryProvider).get(complaintId),
  retry: (_, _) => null,
);

class ApiComplaintRepository implements ComplaintRepository {
  ApiComplaintRepository({required this.complaints});

  final ComplaintsApi complaints;

  @override
  Future<List<ComplaintSummary>> list() => _guard(() async {
    return (await complaints.listComplaints())!.items;
  });

  @override
  Future<Complaint> get(String complaintId) => _guard(() async {
    return (await complaints.getComplaint(complaintId))!;
  });

  @override
  Future<Complaint> submit(String description) => _guard(() async {
    return (await complaints.createComplaint(
      ComplaintInput(description: description),
    ))!;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
