import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala/features/tenants/ui/tenant_widgets.dart';
import 'package:niscala_api/api.dart';

/// One tenant with the lease, the invitation and the other data kept about
/// them. The tenant is read-only here.
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
      appBar: AppBar(
        title: TenantTitle(
          title: 'Rincian Penyewa',
          propertyName: property?.name,
        ),
      ),
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
    final invitation = t.invitation;
    final email = t.email;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          if (t.accountStatus == TenantAccountStatus.notActivated &&
              invitation != null) ...[
            formGap,
            if (invitation.expired)
              Text(
                'Tautan undangan kedaluwarsa pada '
                '${formatDate(invitation.expiresAt)} tanpa digunakan.',
              )
            else ...[
              Text(
                'Tautan undangan dibuat ${formatDate(invitation.createdAt)} '
                'dan belum digunakan. Berlaku hingga '
                '${formatDate(invitation.expiresAt)}.',
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => context.go(
                  '/properti/$propertyId/penyewa/$tenantId/undangan',
                ),
                child: const Text('Bagikan tautan yang ada'),
              ),
            ],
          ],
          formGap,
          _Section(
            title: 'Kamar',
            children: [
              TextButton(
                onPressed: () =>
                    context.go('/properti/$propertyId/kamar/${t.room.id}'),
                child: Text('Kamar ${t.room.number}'),
              ),
            ],
          ),
          formGap,
          _Section(
            title: 'Masa sewa',
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
          formGap,
          _Section(
            title: 'Data lainnya',
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
              _Pair(label: 'Pekerjaan / instansi', value: t.occupation ?? '-'),
            ],
          ),
        ],
      ),
    );
  }
}

String _dateOrDash(DateTime? date) => date == null ? '-' : formatDate(date);

/// A titled block of the detail screen. The title is a header for assistive
/// technology.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}

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
