import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/filter_chip_row.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

const _empty =
    'Belum ada keluhan. Ketuk Ajukan Keluhan jika ada masalah di kamar Anda.';
const _emptyFilter = 'Tidak ada keluhan dengan status ini.';

/// The complaint filters. Active means *Baru* and *Diproses*.
enum _Filter { active, done }

const _filters = <(String, _Filter)>[
  ('Aktif', _Filter.active),
  ('Selesai', _Filter.done),
];

bool _matches(_Filter filter, ComplaintSummary complaint) => switch (filter) {
  _Filter.active => complaint.status != ComplaintStatus.done,
  _Filter.done => complaint.status == ComplaintStatus.done,
};

/// The tenant's own complaints. Filtering happens on the loaded list, so it
/// never sends a request.
class TenantComplaintListScreen extends ConsumerStatefulWidget {
  const TenantComplaintListScreen({super.key});

  @override
  ConsumerState<TenantComplaintListScreen> createState() =>
      _TenantComplaintListScreenState();
}

class _TenantComplaintListScreenState
    extends ConsumerState<TenantComplaintListScreen> {
  var _filter = _Filter.active;

  void _openForm() => context.go('/penyewa/keluhan/baru');

  @override
  Widget build(BuildContext context) {
    final complaints = ref.watch(complaintListProvider);
    // The Ajukan action keeps its place in every state, so the header does not
    // change size. It is shown only when there are complaints.
    final ajukan = FilledButton(
      onPressed: _openForm,
      child: const Text('Ajukan'),
    );
    return complaints.when(
      skipLoadingOnReload: true,
      loading: () => _listPage(
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        action: ajukan,
        actionVisible: false,
      ),
      error: (error, _) => _listPage(
        ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(complaintListProvider),
        ),
        action: ajukan,
        actionVisible: false,
      ),
      data: (items) {
        if (items.isEmpty) {
          return _listPage(
            EmptyState(
              message: _empty,
              actionLabel: 'Ajukan Keluhan',
              onAction: _openForm,
            ),
            action: ajukan,
            actionVisible: false,
          );
        }
        final shown = [
          for (final complaint in items)
            if (_matches(_filter, complaint)) complaint,
        ];
        return _listPage(
          ListView(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            children: [
              FilterChipRow(
                chips: [
                  for (final (label, filter) in _filters)
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
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
          ),
          action: ajukan,
        );
      },
    );
  }
}

/// The tab page: the header on top, the state below it. The header has no
/// app bar, as a tab root does.
Scaffold _listPage(Widget body, {Widget? action, bool actionVisible = true}) =>
    Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Keluhan Saya',
            action: action,
            actionVisible: actionVisible,
          ),
          Expanded(child: body),
        ],
      ),
    );

/// One complaint: its description, status, and either its classification or
/// the state that explains why it has none.
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
          onTap: () => context.go('/penyewa/keluhan/${complaint.id}'),
          title: Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ComplaintBadge.status(complaint.status),
              if (classification != null) ...[
                Text(classification.category),
                ComplaintBadge.urgency(classification.urgency),
              ] else if (state != null)
                ComplaintBadge.classification(state),
            ],
          ),
        ),
      ),
    );
  }
}
