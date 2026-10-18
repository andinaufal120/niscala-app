import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/core/api/device_info.dart';
import 'package:niscala_api/api.dart';

/// Invitation activation. Every method throws an `ApiFailure` when the call
/// fails.
abstract interface class InvitationRepository {
  /// Reports what the invitation [token] is for and whether it is still valid.
  Future<InvitationPreview> preview(String token);

  /// Creates the account with a local password and starts a session.
  Future<AuthSession> activateWithPassword({
    required String token,
    required String name,
    required String email,
    required String password,
    List<EmergencyContact>? emergencyContacts,
  });
}

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiInvitationRepository(
    invitations: InvitationsApi(client),
    device: () => ref.read(deviceInfoProvider.future),
  );
});

class ApiInvitationRepository implements InvitationRepository {
  ApiInvitationRepository({required this.invitations, required this.device});

  final InvitationsApi invitations;
  final Future<DeviceInfo> Function() device;

  @override
  Future<InvitationPreview> preview(String token) => _guard(() async {
    return (await invitations.previewInvitation(TokenInput(token: token)))!;
  });

  @override
  Future<AuthSession> activateWithPassword({
    required String token,
    required String name,
    required String email,
    required String password,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return _guard(() async {
      final input = InvitationPasswordActivationInput(
        device: await device(),
        token: token,
        name: name,
        email: email,
        password: password,
        emergencyContacts: emergencyContacts,
      );
      return (await invitations.activateInvitationWithPassword(input))!;
    });
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
