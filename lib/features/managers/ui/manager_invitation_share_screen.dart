import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala/features/managers/ui/manager_widgets.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala_api/api.dart';

/// The invitation link of one manager, to copy, share or show as a QR code.
/// [isNew] marks a manager who was just added, which shows a heading to say so.
class ManagerInvitationShareScreen extends ConsumerStatefulWidget {
  const ManagerInvitationShareScreen({
    super.key,
    required this.propertyId,
    required this.managerId,
    required this.isNew,
  });

  final String propertyId;
  final String managerId;
  final bool isNew;

  @override
  ConsumerState<ManagerInvitationShareScreen> createState() =>
      _ManagerInvitationShareScreenState();
}

class _ManagerInvitationShareScreenState
    extends ConsumerState<ManagerInvitationShareScreen> {
  var _copied = false;

  void _goToList() =>
      leavePageTo(context, '/properti/${widget.propertyId}/pengelola');

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyDetailProvider(widget.propertyId)).value;
    final manager = ref.watch(managerDetailProvider(widget.managerId));
    return Scaffold(
      appBar: DetailAppBar(
        title: 'Undangan Pengelola',
        subtitle: property?.name,
        actions: [
          DetailBarAction.icon(
            icon: Icons.close,
            tooltip: 'Tutup',
            onPressed: _goToList,
          ),
        ],
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
        data: _body,
      ),
    );
  }

  Widget _body(Manager manager) {
    final theme = Theme.of(context);
    final invitation = manager.invitation;
    final url = shareableLinkOf(invitation);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              widget.isNew ? 'Pengelola ditambahkan' : 'Tautan undangan',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan tautan ini kepada ${manager.name} (${manager.phone}). '
            'Pengelola akan mengisi email dan kata sandi, atau masuk dengan '
            'Google, saat membuka tautan.',
          ),
          formGap,
          if (invitation == null || url == null) ...[
            Text(
              'Tautan undangan belum tersedia.',
              style: theme.textTheme.bodyLarge,
            ),
            if (manager.accountStatus == ManagerAccountStatus.notActivated) ...[
              formGap,
              RegenerateInvitationButton(managerId: manager.id),
            ],
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tautan undangan', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SelectableText(url),
                    const SizedBox(height: 8),
                    Text(
                      'Berlaku hingga ${formatDate(invitation.expiresAt)} · '
                      'sekali pakai',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _copy(url),
                      child: Semantics(
                        label: 'Salin tautan undangan',
                        excludeSemantics: true,
                        child: const Text('Salin'),
                      ),
                    ),
                    if (_copied) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: const Text('Tautan disalin.'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            formGap,
            FilledButton(
              onPressed: () => ref.read(invitationSharerProvider)(
                invitationShareText(tenantName: manager.name, url: url),
              ),
              child: const Text('Bagikan via WhatsApp'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go(
                '/properti/${widget.propertyId}/pengelola/${widget.managerId}'
                '/undangan/qr',
              ),
              child: const Text('Tampilkan kode QR'),
            ),
          ],
          formGap,
          OutlinedButton(onPressed: _goToList, child: const Text('Selesai')),
        ],
      ),
    );
  }
}
