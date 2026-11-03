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
import 'package:niscala/core/widgets/failure_dialog.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/dashboard/data/dashboard_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala/features/tenants/ui/tenant_widgets.dart';
import 'package:niscala_api/api.dart';

const _deleteMessage =
    'Masa sewa penyewa ini akan berakhir dan aksesnya ke akun dicabut. Kamar '
    'akan menjadi kosong. Riwayat pembayaran dan keluhan tetap disimpan.';

/// One tenant with the lease, the invitation and the other data kept about
/// them. A tenant who has not activated can get a new invitation link, and any
/// tenant can be edited or deleted.
class TenantDetailScreen extends ConsumerWidget {
  const TenantDetailScreen({
    super.key,
    required this.propertyId,
    required this.tenantId,
  });

  final String propertyId;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyDetailProvider(propertyId)).value;
    final tenant = ref.watch(tenantDetailProvider(tenantId));
    return Scaffold(
      appBar: DetailAppBar(title: 'Rincian Penyewa', subtitle: property?.name),
      body: tenant.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(tenantDetailProvider(tenantId)),
        ),
        data: (t) => _details(context, t),
      ),
    );
  }

  Widget _details(BuildContext context, Tenant t) {
    final theme = Theme.of(context);
    final lease = t.lease;
    final email = t.email;
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
                  child: Text(t.name, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: 4),
                Text('${t.phone} · ${email ?? 'email belum diisi'}'),
                formGap,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [TenantStatusBadge(status: t.accountStatus)],
                ),
              ],
            ),
          ),
          if (t.accountStatus == TenantAccountStatus.notActivated) ...[
            formGap,
            SectionCard(child: _invitation(context, t.invitation)),
          ],
          formGap,
          SectionCard(
            title: 'Kamar',
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () =>
                    context.go('/properti/$propertyId/kamar/${t.room.id}'),
                child: Text('Kamar ${t.room.number}'),
              ),
            ),
          ),
          formGap,
          SectionCard(
            title: 'Masa sewa',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pair(label: 'Mulai', value: _dateOrDash(lease.startDate)),
                _Pair(label: 'Berakhir', value: _dateOrDash(lease.endDate)),
                _Pair(
                  label: 'Tarif sewa',
                  value:
                      '${formatRupiah(lease.rent)} / '
                      '${billingCycleUnit(lease.billingCycle)}',
                ),
                _Pair(
                  label: 'Siklus penagihan',
                  value: billingCycleLabel(lease.billingCycle),
                ),
                _Pair(
                  label: 'Masa tenggang',
                  value: '${lease.gracePeriodDays} hari',
                ),
                _Pair(
                  label: 'Tagihan berikutnya',
                  value: _dateOrDash(lease.nextBillDate),
                ),
              ],
            ),
          ),
          formGap,
          SectionCard(
            title: 'Data lainnya',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kontak darurat', style: theme.textTheme.labelLarge),
                    if (t.emergencyContacts.isEmpty)
                      const Text('Belum diisi')
                    else
                      for (final contact in t.emergencyContacts) ...[
                        Text('${contact.name} · ${contact.relationship}'),
                        Text(contact.phone),
                      ],
                    const SizedBox(height: 8),
                  ],
                ),
                _Pair(
                  label: 'Pekerjaan / instansi',
                  value: t.occupation ?? '-',
                ),
              ],
            ),
          ),
          formGap,
          OutlinedButton(
            onPressed: () =>
                context.go('/properti/$propertyId/penyewa/$tenantId/ubah'),
            child: const Text('Ubah Data Penyewa'),
          ),
          const SizedBox(height: 8),
          _DeleteTenantButton(propertyId: propertyId, tenant: t),
        ],
      ),
    );
  }

  /// The invitation of a tenant who has not activated: when it was made or
  /// when it ended, the share action while the link is valid, and the action
  /// to make a new link.
  Widget _invitation(BuildContext context, TenantInvitation? invitation) {
    final url = invitation?.url;
    final shareable = invitation != null && !invitation.expired && url != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invitation != null)
          Text(
            invitation.expired
                ? 'Tautan undangan kedaluwarsa pada '
                      '${formatDate(invitation.expiresAt)} tanpa digunakan.'
                : 'Tautan undangan dibuat '
                      '${formatDate(invitation.createdAt)} '
                      'dan belum digunakan. Berlaku hingga '
                      '${formatDate(invitation.expiresAt)}.',
          ),
        if (shareable) ...[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () =>
                context.go('/properti/$propertyId/penyewa/$tenantId/undangan'),
            child: const Text('Bagikan tautan yang ada'),
          ),
        ],
        const SizedBox(height: 8),
        _RegenerateInvitationButton(propertyId: propertyId, tenantId: tenantId),
      ],
    );
  }
}

/// Makes a new invitation link for the tenant. The button is disabled while the
/// request is in flight.
///
/// On success the detail is reloaded and the share screen opens with the new
/// link. On failure the message is shown in a dialog and the old link stays.
class _RegenerateInvitationButton extends ConsumerStatefulWidget {
  const _RegenerateInvitationButton({
    required this.propertyId,
    required this.tenantId,
  });

  final String propertyId;
  final String tenantId;

  @override
  ConsumerState<_RegenerateInvitationButton> createState() =>
      _RegenerateInvitationButtonState();
}

class _RegenerateInvitationButtonState
    extends ConsumerState<_RegenerateInvitationButton> {
  var _busy = false;

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(tenantRepositoryProvider)
          .regenerateInvitation(widget.tenantId);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (failure.code == 'TENANT_NOT_FOUND') {
        ref.invalidate(tenantDetailProvider(widget.tenantId));
      }
      await showFailureDialog(
        context,
        title: 'Tautan belum bisa dibuat',
        message: errorMessageFor(failure),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(tenantDetailProvider(widget.tenantId));
    context.go(
      '/properti/${widget.propertyId}/penyewa/${widget.tenantId}/undangan',
    );
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: _busy ? null : _regenerate,
    child: const Text('Buat Ulang Tautan Undangan'),
  );
}

/// Deletes the tenant after confirmation. The button is disabled while the
/// request is in flight.
///
/// On success the lists and the dashboard that show the tenant are reloaded and
/// the tenant list of the property opens. On failure the message is shown in a
/// dialog; a tenant that no longer exists is reloaded.
class _DeleteTenantButton extends ConsumerStatefulWidget {
  const _DeleteTenantButton({required this.propertyId, required this.tenant});

  final String propertyId;
  final Tenant tenant;

  @override
  ConsumerState<_DeleteTenantButton> createState() =>
      _DeleteTenantButtonState();
}

class _DeleteTenantButtonState extends ConsumerState<_DeleteTenantButton> {
  var _busy = false;

  Future<void> _delete() async {
    final tenant = widget.tenant;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus ${tenant.name}?',
      message: _deleteMessage,
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(tenantRepositoryProvider).delete(tenant.id);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (failure.code == 'TENANT_NOT_FOUND') {
        ref.invalidate(tenantDetailProvider(tenant.id));
      }
      await showFailureDialog(
        context,
        title: 'Penyewa belum bisa dihapus',
        message: errorMessageFor(failure),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(tenantListProvider(widget.propertyId));
    ref.invalidate(roomListProvider(widget.propertyId));
    ref.invalidate(roomDetailProvider(tenant.room.id));
    ref.invalidate(occupancyDashboardProvider);
    leavePageTo(context, '/properti/${widget.propertyId}/penyewa');
  }

  @override
  Widget build(BuildContext context) =>
      DangerButton(label: 'Hapus Penyewa', onPressed: _busy ? null : _delete);
}

String _dateOrDash(DateTime? date) => date == null ? '-' : formatDate(date);

/// A label with its value below it. The value wraps, so long text never
/// overflows.
class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          Text(value),
        ],
      ),
    );
  }
}
