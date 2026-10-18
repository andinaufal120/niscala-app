import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala_api/api.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The invitation link of one tenant as a QR code, for the tenant to scan with
/// a phone camera. The link is also shown as text, so the code is never the
/// only way to get it.
class InvitationQrScreen extends ConsumerWidget {
  const InvitationQrScreen({
    super.key,
    required this.propertyId,
    required this.tenantId,
  });

  final String propertyId;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(tenantDetailProvider(tenantId));
    return Scaffold(
      appBar: AppBar(title: const Text('Kode QR undangan')),
      body: tenant.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(tenantDetailProvider(tenantId)),
        ),
        data: (t) => _body(context, ref, t),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Tenant t) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final invitation = t.invitation;
    final url = invitation?.url;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(t.name, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          if (invitation == null || url == null)
            Text(
              'Tautan undangan belum tersedia.',
              style: theme.textTheme.bodyLarge,
            )
          else ...[
            Text(
              'Minta ${firstNameOf(t.name)} memindai kode ini dengan kamera '
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
                invitationShareText(tenantName: t.name, url: url),
              ),
              child: const Text('Bagikan via WhatsApp'),
            ),
          ],
          formGap,
          OutlinedButton(
            onPressed: () =>
                context.go('/properti/$propertyId/penyewa/$tenantId/undangan'),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
