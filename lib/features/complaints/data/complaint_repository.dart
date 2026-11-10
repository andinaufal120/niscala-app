import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/core/api/image_transfer.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala_api/api.dart';

/// Maintenance complaints. Every method throws an `ApiFailure` when the call
/// fails.
abstract interface class ComplaintRepository {
  /// The complaints the caller can see: a tenant's own, or those on the
  /// properties the caller manages.
  Future<List<ComplaintSummary>> list();

  Future<Complaint> get(String complaintId);

  /// Moves a complaint to [status], which must be its next status. A blank
  /// [handlingNote] is sent as none; otherwise it is sent trimmed.
  Future<Complaint> changeStatus(
    String complaintId,
    ComplaintStatus status, {
    String? handlingNote,
  });

  /// Saves a complaint as the calling tenant about the room [roomId] of one of
  /// the tenant's leases. The returned complaint may still be unclassified; the
  /// AI classification runs in the background.
  Future<Complaint> submit(String description, String roomId);

  /// The categories a complaint can be classified into, in the order given.
  Future<List<String>> categories();

  /// Sets the category and urgency of a complaint by hand. The returned
  /// complaint keeps the AI result that this classification replaced.
  Future<Complaint> classify(
    String complaintId, {
    required String category,
    required ComplaintUrgency urgency,
  });

  /// Attaches [image] to the complaint, replacing its photo. Only a complaint
  /// that is still new can change its photo.
  Future<Complaint> uploadPhoto(String complaintId, PickedImage image);

  /// The photo of the complaint, as received.
  Future<Uint8List> photo(String complaintId);
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

/// The categories for manual classification. Fetched once; invalidate it to
/// fetch again. Failures are not retried in the background, see
/// [complaintListProvider].
final complaintCategoriesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(complaintRepositoryProvider).categories(),
  retry: (_, _) => null,
);

/// The photo of one complaint. Invalidate it after the photo changes. Failures
/// are not retried in the background, see [complaintListProvider].
final complaintPhotoBytesProvider = FutureProvider.family<Uint8List, String>(
  (ref, complaintId) =>
      ref.watch(complaintRepositoryProvider).photo(complaintId),
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
  Future<Complaint> changeStatus(
    String complaintId,
    ComplaintStatus status, {
    String? handlingNote,
  }) => _guard(() async {
    final note = handlingNote?.trim();
    return (await complaints.changeComplaintStatus(
      complaintId,
      ComplaintStatusChangeInput(
        status: status,
        handlingNote: note == null || note.isEmpty ? null : note,
      ),
    ))!;
  });

  @override
  Future<Complaint> submit(String description, String roomId) =>
      _guard(() async {
        return (await complaints.createComplaint(
          ComplaintInput(description: description, roomId: roomId),
        ))!;
      });

  @override
  Future<List<String>> categories() => _guard(() async {
    return (await complaints.listComplaintCategories())!.items;
  });

  @override
  Future<Complaint> classify(
    String complaintId, {
    required String category,
    required ComplaintUrgency urgency,
  }) => _guard(() async {
    return (await complaints.classifyComplaint(
      complaintId,
      ComplaintClassificationInput(category: category, urgency: urgency),
    ))!;
  });

  @override
  Future<Complaint> uploadPhoto(String complaintId, PickedImage image) =>
      _guard(() async {
        return (await complaints.uploadComplaintPhoto(
          complaintId,
          imageUploadPart(image),
        ))!;
      });

  @override
  Future<Uint8List> photo(String complaintId) => _guard(() async {
    return imageBytesOf(
      await complaints.getComplaintPhotoWithHttpInfo(complaintId),
    );
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
