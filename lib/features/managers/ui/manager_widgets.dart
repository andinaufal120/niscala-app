import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala_api/api.dart';

/// The account status of a manager as a text badge. It uses the tenant status
/// colours, so one status looks the same on every screen.
class ManagerStatusBadge extends StatelessWidget {
  const ManagerStatusBadge({super.key, required this.status});

  final ManagerAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = NiscalaTokens.of(context);
    return status == ManagerAccountStatus.active
        ? StatusBadge(label: 'Aktif', colors: tokens.tenantActive)
        : StatusBadge(
            label: 'Belum Diaktifkan',
            colors: tokens.tenantNotActivated,
          );
  }
}

/// The link of [invitation] to share, or null when there is none or it has
/// expired.
String? shareableLinkOf(ManagerInvitation? invitation) =>
    invitation == null || invitation.expired ? null : invitation.url;

/// Whether [failure] means the manager was deleted or became active while the
/// screen showed it, so the screen must reload it.
bool isStaleManagerFailure(ApiFailure failure) =>
    failure.code == 'MANAGER_NOT_FOUND' ||
    failure.code == 'MANAGER_ALREADY_ACTIVE';

/// Shows why a manager action failed. The dialog stays until the user closes it.
Future<void> showManagerFailure(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Mengerti'),
      ),
    ],
  ),
);

/// Makes a new invitation link for a manager who is not active yet. The button
/// is disabled while the request is in flight.
///
/// On success the manager is reloaded and [onCreated] runs. On failure the
/// message is shown in a dialog, and a manager that changed under the screen
/// is reloaded so the screen shows its current state.
class RegenerateInvitationButton extends ConsumerStatefulWidget {
  const RegenerateInvitationButton({
    super.key,
    required this.managerId,
    this.onCreated,
  });

  final String managerId;
  final VoidCallback? onCreated;

  @override
  ConsumerState<RegenerateInvitationButton> createState() =>
      _RegenerateInvitationButtonState();
}

class _RegenerateInvitationButtonState
    extends ConsumerState<RegenerateInvitationButton> {
  var _busy = false;

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(managerRepositoryProvider)
          .regenerateInvitation(widget.managerId);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (isStaleManagerFailure(failure)) {
        ref.invalidate(managerDetailProvider(widget.managerId));
      }
      await showManagerFailure(
        context,
        title: 'Tautan belum bisa dibuat',
        message: errorMessageFor(failure),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(managerDetailProvider(widget.managerId));
    widget.onCreated?.call();
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: _busy ? null : _regenerate,
    child: const Text('Buat Ulang Tautan Undangan'),
  );
}
