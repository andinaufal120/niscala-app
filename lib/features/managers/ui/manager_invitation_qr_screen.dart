import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala/features/managers/ui/manager_widgets.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala_api/api.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The invitation link of one manager as a QR code, for the manager to scan
/// with a phone camera. The link is also shown as text, so the code is never
/// the only way to get it.
class ManagerInvitationQrScreen extends ConsumerWidget {
  const ManagerInvitationQrScreen({
    super.key,
    required this.propertyId,
    required this.managerId,
  });

  final String propertyId;
  final String managerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(managerDetailProvider(managerId));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Kode QR undangan'),
      body: manager.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(managerDetailProvider(managerId)),
        ),
        data: (m) => _body(context, ref, m),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Manager m) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final invitation = m.invitation;
    final url = shareableLinkOf(invitation);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (invitation == null || url == null) ...[
            Text(
              'Tautan undangan belum tersedia.',
              style: theme.textTheme.bodyLarge,
            ),
            if (m.accountStatus == ManagerAccountStatus.notActivated) ...[
              formGap,
              RegenerateInvitationButton(managerId: m.id),
            ],
          ] else ...[
            Text(
              'Minta ${firstNameOf(m.name)} memindai kode ini dengan kamera '
              'ponselnya.',
            ),
            formGap,
            Center(
              child: QrImageView(
                data: url,
                size: 240,
                semanticsLabel: 'Kode QR tautan undangan',
                backgroundColor: scheme.surface,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: scheme.onSurface,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: scheme.onSurface,
                ),
              ),
            ),
            formGap,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(url),
                    const SizedBox(height: 8),
                    Text(
                      'Berlaku hingga ${formatDate(invitation.expiresAt)} · '
                      'sekali pakai',
                    ),
                  ],
                ),
              ),
            ),
            formGap,
            FilledButton(
              onPressed: () => ref.read(invitationSharerProvider)(
                invitationShareText(tenantName: m.name, url: url),
              ),
              child: const Text('Bagikan via WhatsApp'),
            ),
          ],
          formGap,
          OutlinedButton(
            onPressed: () =>
                leavePageTo(context, '/properti/$propertyId/pengelola'),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
