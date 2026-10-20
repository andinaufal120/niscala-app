import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/filter_chip_row.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala/features/tenants/ui/tenant_widgets.dart';
import 'package:niscala_api/api.dart';

const _empty =
    'Belum ada penyewa. Daftarkan penyewa ke kamar kosong, lalu bagikan '
    'tautan undangan agar ia bisa mengaktifkan akun.';
const _emptyFilter = 'Tidak ada penyewa dengan status ini.';

/// A null status shows every tenant.
const _filters = <(String, TenantAccountStatus?)>[
  ('Semua', null),
  ('Aktif', TenantAccountStatus.active),
  ('Belum Diaktifkan', TenantAccountStatus.notActivated),
];

/// The tenants of one property. Filtering by status happens on the loaded list,
/// so it never sends a request.
class TenantListScreen extends ConsumerStatefulWidget {
  const TenantListScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends ConsumerState<TenantListScreen> {
  /// Null shows every tenant.
  TenantAccountStatus? _filter;

  void _openAdd() =>
      context.go('/properti/${widget.propertyId}/penyewa/tambah');

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyDetailProvider(widget.propertyId)).value;
    final name = property?.name;
    // A property that failed to load keeps the add action; the server still
    // enforces the view-only rule.
    final canAdd = property?.editable ?? true;
    final tenants = ref.watch(tenantListProvider(widget.propertyId));
    return tenants.when(
      skipLoadingOnReload: true,
      loading: () => _page(
        name,
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
      ),
      error: (error, _) => _page(
        name,
        ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(tenantListProvider(widget.propertyId)),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _page(
            name,
            EmptyState(
              message: _empty,
              actionLabel: canAdd ? 'Tambah Penyewa' : null,
              onAction: canAdd ? _openAdd : null,
            ),
          );
        }
        final shown = _filter == null
            ? items
            : items.where((tenant) => tenant.accountStatus == _filter).toList();
        return _page(
          name,
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (canAdd) ...[
                FilledButton.icon(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
                formGap,
              ],
              FilterChipRow(
                chips: [
                  for (final (label, status) in _filters)
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == status,
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                ],
              ),
              formGap,
              if (shown.isEmpty)
                Text(_emptyFilter, style: Theme.of(context).textTheme.bodyLarge)
              else
                for (final tenant in shown) ...[
                  _TenantRow(propertyId: widget.propertyId, tenant: tenant),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

Scaffold _page(String? propertyName, Widget body) => Scaffold(
  appBar: DetailAppBar(title: 'Penyewa', subtitle: propertyName),
  body: body,
);

class _TenantRow extends StatelessWidget {
  const _TenantRow({required this.propertyId, required this.tenant});

  final String propertyId;
  final TenantSummary tenant;

  /// The billing cycle, followed by the end of the lease once the tenant is
  /// active, or by the end of the invitation before that.
  String get _detailLine {
    final cycle = billingCycleLabel(tenant.billingCycle);
    if (tenant.accountStatus == TenantAccountStatus.active) {
      final end = tenant.leaseEndDate;
      return end == null ? cycle : '$cycle · s.d. ${formatDate(end)}';
    }
    final expires = tenant.invitationExpiresAt;
    return expires == null
        ? cycle
        : '$cycle · tautan undangan s.d. ${formatDate(expires)}';
  }

  @override
  Widget build(BuildContext context) {
    final number = tenant.room.number;
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.go('/properti/$propertyId/penyewa/${tenant.id}'),
          leading: Semantics(
            label: 'Kamar $number',
            excludeSemantics: true,
            child: Text(number, style: Theme.of(context).textTheme.titleMedium),
          ),
          title: Text(
            tenant.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_detailLine),
              const SizedBox(height: 4),
              TenantStatusBadge(status: tenant.accountStatus),
            ],
          ),
        ),
      ),
    );
  }
}
