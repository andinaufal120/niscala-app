import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
import 'package:niscala/features/rooms/ui/room_widgets.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala_api/api.dart';

/// Shown to a tenant who has no active lease.
const noActiveLeaseMessage =
    'Anda belum memiliki masa sewa aktif. Hubungi pengelola kost.';

/// The rooms and leases of the signed-in tenant: one card per lease, in the
/// order the API returns them. The loading, empty and error states replace the
/// cards.
class LeaseCard extends ConsumerWidget {
  const LeaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leases = ref.watch(myLeasesProvider);
    return leases.when(
      // Retrying after an error shows the spinner, not the old error.
      skipLoadingOnRefresh: false,
      loading: () => _leaseSection(
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
      ),
      error: (error, _) => _leaseSection(
        ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(myLeasesProvider),
        ),
      ),
      data: (items) => items.isEmpty
          ? _leaseSection(const EmptyState(message: noActiveLeaseMessage))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, lease) in items.indexed) ...[
                  if (index > 0) const SizedBox(height: NiscalaSpacing.l),
                  _leaseSection(_LeaseDetails(lease: lease)),
                ],
              ],
            ),
    );
  }
}

SectionCard _leaseSection(Widget child) =>
    SectionCard(title: 'Kamar & masa sewa', child: child);

/// The facts of one active lease, each on its own line.
class _LeaseDetails extends StatelessWidget {
  const _LeaseDetails({required this.lease});

  final CurrentLease lease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startDate = lease.startDate;
    final endDate = lease.endDate;
    final room = lease.room;
    final lengthM = room.lengthM;
    final widthM = room.widthM;
    final facilities = room.facilities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(lease.property.name, style: theme.textTheme.titleMedium),
        Text(lease.property.address),
        const SizedBox(height: NiscalaSpacing.s),
        Text('Kamar ${room.number}'),
        Text(
          '${startDate == null ? 'Belum ditentukan' : formatDate(startDate)}'
          ' - '
          '${endDate == null ? 'Tanpa batas' : formatDate(endDate)}',
        ),
        Text(
          '${formatRupiah(lease.rent)} / '
          '${billingCycleUnit(lease.billingCycle)}',
        ),
        if (lengthM != null && widthM != null)
          Text(formatDimensions(lengthM, widthM)),
        if (facilities.isNotEmpty) Text('Fasilitas: ${facilities.join(', ')}'),
      ],
    );
  }
}
