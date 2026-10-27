import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala/features/managers/ui/manager_widgets.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

const _deleteMessage =
    'Akses Pengelola ke properti Anda akan dicabut. Akun Pengelola tidak ikut '
    'dihapus.';

/// One manager with the properties and the invitation. A manager who is not
/// active yet can also get a new invitation link.
class ManagerDetailScreen extends ConsumerStatefulWidget {
  const ManagerDetailScreen({
    super.key,
    required this.propertyId,
    required this.managerId,
  });

  final String propertyId;
  final String managerId;

  @override
  ConsumerState<ManagerDetailScreen> createState() =>
      _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends ConsumerState<ManagerDetailScreen> {
  var _deleting = false;

  Future<void> _askToDelete(Manager manager) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus ${manager.name}?',
      message: _deleteMessage,
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(managerRepositoryProvider).delete(manager.id);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _deleting = false);
      if (isStaleManagerFailure(failure)) {
        ref.invalidate(managerDetailProvider(manager.id));
      }
      await showManagerFailure(
        context,
        title: 'Pengelola belum bisa dihapus',
        message: errorMessageFor(failure),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(managerListProvider);
    leavePageTo(context, '/properti/${widget.propertyId}/pengelola');
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyDetailProvider(widget.propertyId)).value;
    final manager = ref.watch(managerDetailProvider(widget.managerId));
    return Scaffold(
      appBar: DetailAppBar(
        title: 'Rincian Pengelola',
        subtitle: property?.name,
      ),
      body: manager.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () =>
              ref.invalidate(managerDetailProvider(widget.managerId)),
        ),
        data: _details,
      ),
    );
  }

  Widget _details(Manager manager) {
    final theme = Theme.of(context);
    final nickname = manager.nickname;
    final active = manager.accountStatus == ManagerAccountStatus.active;
    final sharePath =
        '/properti/${widget.propertyId}/pengelola/${manager.id}/undangan';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    nickname ?? manager.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (nickname != null) Text(manager.name),
                formGap,
                ManagerStatusBadge(status: manager.accountStatus),
              ],
            ),
          ),
          formGap,
          SectionCard(
            title: 'Kontak',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pair(label: 'Nomor telepon', value: manager.phone),
                _Pair(label: 'Email', value: manager.email ?? 'Belum diisi'),
              ],
            ),
          ),
          formGap,
          SectionCard(
            title: 'Properti',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final property in manager.properties)
                  _Pair(label: property.name, value: property.address),
              ],
            ),
          ),
          if (!active) ...[
            formGap,
            SectionCard(
              title: 'Undangan',
              child: _invitation(manager, sharePath),
            ),
          ],
          formGap,
          OutlinedButton(
            onPressed: _deleting
                ? null
                : () => context.go(
                    '/properti/${widget.propertyId}/pengelola/${manager.id}/ubah',
                  ),
            child: const Text('Ubah'),
          ),
          const SizedBox(height: 8),
          DangerButton(
            label: 'Hapus',
            onPressed: _deleting ? null : () => _askToDelete(manager),
          ),
        ],
      ),
    );
  }

  Widget _invitation(Manager manager, String sharePath) {
    final invitation = manager.invitation;
    final link = shareableLinkOf(invitation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_invitationStatus(invitation)),
        formGap,
        if (link != null) ...[
          FilledButton(
            onPressed: () => context.go(sharePath),
            child: const Text('Bagikan tautan'),
          ),
          const SizedBox(height: 8),
        ],
        RegenerateInvitationButton(
          managerId: manager.id,
          onCreated: () => context.go(sharePath),
        ),
      ],
    );
  }
}

String _invitationStatus(ManagerInvitation? invitation) {
  if (invitation == null) return 'Tautan undangan belum tersedia.';
  final date = formatDate(invitation.expiresAt);
  return invitation.expired
      ? 'Undangan Kedaluwarsa pada $date.'
      : 'Undangan berlaku hingga $date.';
}

/// A label with its value below it. The value wraps, so long text never
/// overflows.
class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value),
        ],
      ),
    );
  }
}
