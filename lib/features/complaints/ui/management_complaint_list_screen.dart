import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

const _empty = 'Belum ada keluhan dari penyewa.';
const _emptyFilter = 'Tidak ada keluhan dengan status ini.';
const _withheld = 'Klasifikasi AI memerlukan langganan aktif.';

/// A null status shows every complaint.
const _filters = <(String, ComplaintStatus?)>[
  ('Semua', null),
  ('Baru', ComplaintStatus.new_),
  ('Diproses', ComplaintStatus.inProgress),
  ('Selesai', ComplaintStatus.done),
];

/// The complaints on the caller's properties, in the order the API returns
/// them. Filtering happens on the loaded list, so it never sends a request.
class ManagementComplaintListScreen extends ConsumerStatefulWidget {
  const ManagementComplaintListScreen({super.key});

  @override
  ConsumerState<ManagementComplaintListScreen> createState() =>
      _ManagementComplaintListScreenState();
}

class _ManagementComplaintListScreenState
    extends ConsumerState<ManagementComplaintListScreen> {
  /// Null shows every complaint.
  ComplaintStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final complaints = ref.watch(complaintListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Keluhan')),
      body: complaints.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(complaintListProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const EmptyState(message: _empty);
          final shown = [
            for (final complaint in items)
              if (_filter == null || complaint.status == _filter) complaint,
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
                for (final complaint in shown) ...[
                  _ComplaintRow(complaint: complaint),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

/// One complaint: its message, the room and tenant, the property and the
/// date, and its status and classification.
class _ComplaintRow extends StatelessWidget {
  const _ComplaintRow({required this.complaint});

  final ComplaintSummary complaint;

  @override
  Widget build(BuildContext context) {
    final classification = complaint.classification;
    final state = complaint.classificationState;
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.go('/keluhan/${complaint.id}'),
          title: Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kamar ${complaint.room.number} · ${complaint.tenantName}'),
              Text(
                '${complaint.property.name} · '
                '${formatDate(complaint.createdAt.toLocal())}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ComplaintBadge.status(complaint.status),
                  if (complaint.classificationWithheld)
                    const Text(_withheld)
                  else if (classification != null) ...[
                    Chip(label: Text(classification.category)),
                    ComplaintBadge.urgency(classification.urgency),
                  ] else if (state != null)
                    ComplaintBadge.classification(state),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
