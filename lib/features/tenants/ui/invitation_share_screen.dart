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
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/tenants/data/invitation_sharing.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala_api/api.dart';

/// The invitation link of one tenant, to copy, share or show as a QR code.
/// [isNew] marks a tenant that was just added, which shows a heading to say so.
class InvitationShareScreen extends ConsumerStatefulWidget {
  const InvitationShareScreen({
    super.key,
    required this.propertyId,
    required this.tenantId,
    required this.isNew,
  });

  final String propertyId;
  final String tenantId;
  final bool isNew;

  @override
  ConsumerState<InvitationShareScreen> createState() =>
      _InvitationShareScreenState();
}

class _InvitationShareScreenState extends ConsumerState<InvitationShareScreen> {
  var _copied = false;

  void _goToList() =>
      leavePageTo(context, '/properti/${widget.propertyId}/penyewa');

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  Future<void> _share(Tenant tenant, String url) => ref.read(
    invitationSharerProvider,
  )(invitationShareText(tenantName: tenant.name, url: url));

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyDetailProvider(widget.propertyId)).value;
    final tenant = ref.watch(tenantDetailProvider(widget.tenantId));
    return Scaffold(
      appBar: DetailAppBar(
        title: 'Undangan Penyewa',
        subtitle: property?.name,
        actions: [
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close),
            onPressed: _goToList,
          ),
        ],
      ),
      body: tenant.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(tenantDetailProvider(widget.tenantId)),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(Tenant tenant) {
    final theme = Theme.of(context);
    final invitation = tenant.invitation;
    final url = invitation?.url;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              widget.isNew ? 'Penyewa ditambahkan' : 'Tautan undangan',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan tautan ini kepada ${tenant.name} (${tenant.phone}). Ia akan '
            'melengkapi email dan kata sandi, atau masuk dengan Google, saat '
            'membuka tautan.',
          ),
          formGap,
          if (invitation == null || url == null)
            Text(
              'Tautan undangan belum tersedia.',
              style: theme.textTheme.bodyLarge,
            )
          else ...[
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
                        child: Text('Salin'),
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
              onPressed: () => _share(tenant, url),
              child: const Text('Bagikan via WhatsApp'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go(
                '/properti/${widget.propertyId}/penyewa/${widget.tenantId}'
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
