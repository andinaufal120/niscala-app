import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';
import 'package:niscala/features/auth/invitation_link.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala/features/auth/ui/invitation_link_field.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

const _accepted =
    'Undangan diterima. Properti baru sudah tersedia di menu Properti.';

/// Adds a Manager invitation to the account that is signed in. The pasted link
/// is checked first; the second step shows the invitation, the account that
/// will accept it and the buttons to accept or to paste another link.
class AcceptInvitationScreen extends ConsumerStatefulWidget {
  const AcceptInvitationScreen({super.key});

  @override
  ConsumerState<AcceptInvitationScreen> createState() =>
      _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState
    extends ConsumerState<AcceptInvitationScreen> {
  final _link = TextEditingController();
  var _busy = false;
  String? _linkError;
  String? _banner;
  ({String token, InvitationAcceptancePreview preview})? _checked;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _checkLink() async {
    if (_busy) return;
    final token = invitationTokenFromLink(_link.text);
    if (token == null) {
      setState(() => _linkError = invitationLinkRequiredMessage);
      return;
    }
    setState(() {
      _linkError = null;
      _banner = null;
      _busy = true;
    });
    try {
      final preview = await ref
          .read(invitationRepositoryProvider)
          .previewAcceptance(token);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (preview.canAccept) {
          _checked = (token: token, preview: preview);
        } else {
          _banner = _blockedMessage(preview);
        }
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessageFor(failure);
      });
    }
  }

  /// The message for a checked link that cannot be accepted.
  String _blockedMessage(InvitationAcceptancePreview preview) {
    final status = preview.invitation.status;
    if (status == InvitationLinkStatus.expired) return invitationExpiredMessage;
    if (status == InvitationLinkStatus.used) return invitationUsedMessage;
    final blocker = preview.blocker;
    if (blocker == InvitationBlocker.roleMismatch) {
      return errorMessageFor(
        const ApiFailure(code: 'INVITATION_ROLE_MISMATCH'),
      );
    }
    if (blocker == InvitationBlocker.activeLease) {
      return errorMessageFor(const ApiFailure(code: 'TENANT_HAS_ACTIVE_LEASE'));
    }
    return genericErrorMessage;
  }

  Future<void> _accept() async {
    final checked = _checked;
    if (_busy || checked == null) return;
    setState(() {
      _busy = true;
      _banner = null;
    });
    try {
      await ref.read(invitationRepositoryProvider).accept(checked.token);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    ref.invalidate(meProvider);
    ref.invalidate(propertyListProvider);
    context.go(accountTabPath(ref.read(currentRoleProvider)), extra: _accepted);
  }

  void _changeLink() => setState(() {
    _checked = null;
    _banner = null;
  });

  @override
  Widget build(BuildContext context) {
    final checked = _checked;
    return checked == null ? _linkStep() : _invitationStep(checked.preview);
  }

  Widget _linkStep() {
    return AuthPage(
      appBar: const DetailAppBar(title: 'Terima Undangan'),
      children: [
        if (_banner != null) ...[FormMessage(_banner!), formGap],
        InvitationLinkField(controller: _link, error: _linkError),
        formGap,
        BusyButton(label: 'Lanjut', busy: _busy, onPressed: _checkLink),
      ],
    );
  }

  Widget _invitationStep(InvitationAcceptancePreview preview) {
    final theme = Theme.of(context);
    final invitation = preview.invitation;
    return AuthPage(
      appBar: const DetailAppBar(title: 'Terima Undangan'),
      footer: ActionFooter(
        primary: BusyButton(
          label: 'Terima undangan',
          busy: _busy,
          onPressed: _accept,
        ),
        secondary: OutlinedButton(
          onPressed: _busy ? null : _changeLink,
          child: const Text('Ganti tautan'),
        ),
      ),
      children: [
        if (_banner != null) ...[FormMessage(_banner!), formGap],
        Semantics(
          header: true,
          child: Text(
            'Dari ${invitation.inviterName}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Berlaku sampai ${formatDate(invitation.expiresAt)}',
          style: theme.textTheme.bodyMedium,
        ),
        formGap,
        Semantics(
          header: true,
          child: Text(
            'Properti yang diundang',
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        for (final property in invitation.properties) ...[
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.name, style: theme.textTheme.titleSmall),
                Text(property.address, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        formGap,
        SectionCard(
          title: 'Diterima dengan akun',
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preview.accountName, style: theme.textTheme.titleSmall),
                Text(preview.accountEmail, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
