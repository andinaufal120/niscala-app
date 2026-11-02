import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_status_sheet.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

const _statusNotNextCode = 'COMPLAINT_STATUS_NOT_NEXT';
const _withheld = 'Klasifikasi AI memerlukan langganan aktif.';
const _aiDisclaimer =
    'Klasifikasi dibuat AI dan bisa keliru. Periksa kembali sebelum bertindak.';

/// What a complaint without a classification means for management.
String _stateExplanation(ComplaintClassificationState state) => switch (state) {
  ComplaintClassificationState.classifying =>
    'AI sedang mengklasifikasikan keluhan ini.',
  ComplaintClassificationState.awaitingClassification =>
    'Klasifikasi AI belum berhasil dibuat.',
  ComplaintClassificationState.notClassified =>
    'Keluhan ini belum diklasifikasi karena langganan Owner tidak aktif '
        'saat keluhan dikirim.',
  _ => throw ArgumentError.value(
    state,
    'state',
    'Unknown classification state',
  ),
};

/// The status a complaint moves to next, or null once it is done.
ComplaintStatus? _nextStatus(ComplaintStatus status) => switch (status) {
  ComplaintStatus.new_ => ComplaintStatus.inProgress,
  ComplaintStatus.inProgress => ComplaintStatus.done,
  _ => null,
};

/// One complaint on the caller's properties. Its one status action moves the
/// complaint to the next status after a confirmation.
class ManagementComplaintDetailScreen extends ConsumerStatefulWidget {
  const ManagementComplaintDetailScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  ConsumerState<ManagementComplaintDetailScreen> createState() =>
      _ManagementComplaintDetailScreenState();
}

class _ManagementComplaintDetailScreenState
    extends ConsumerState<ManagementComplaintDetailScreen> {
  /// Set when the status changed under the user, until the next change is saved.
  var _conflict = false;

  Future<void> _changeStatus(ComplaintStatus next) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ComplaintStatusSheet(
        next: next,
        onConfirm: (handlingNote) => _save(next, handlingNote),
      ),
    );
  }

  /// Stores the change and reloads what it affects. This runs to the end even
  /// when the sheet was dismissed while the request was in flight, so the
  /// outcome always reaches the screen.
  Future<void> _save(ComplaintStatus next, String? handlingNote) async {
    try {
      await ref
          .read(complaintRepositoryProvider)
          .changeStatus(widget.complaintId, next, handlingNote: handlingNote);
    } on ApiFailure catch (failure) {
      if (failure.code != _statusNotNextCode) rethrow;
      _settle(conflict: true);
      return;
    }
    _settle(conflict: false);
  }

  void _settle({required bool conflict}) {
    if (!mounted) return;
    ref.invalidate(complaintDetailProvider(widget.complaintId));
    if (!conflict) {
      // The list stays paused under this screen, so it fetches only when it is
      // read here.
      ref.invalidate(complaintListProvider);
      ref.read(complaintListProvider);
    }
    setState(() => _conflict = conflict);
  }

  @override
  Widget build(BuildContext context) {
    final complaint = ref.watch(complaintDetailProvider(widget.complaintId));
    final loaded = complaint.value;
    final next = loaded == null ? null : _nextStatus(loaded.status);
    return Scaffold(
      appBar: DetailAppBar(
        title: 'Rincian Keluhan',
        subtitle: loaded == null
            ? null
            : 'Kamar ${loaded.room.number} · ${loaded.tenantName}',
      ),
      body: complaint.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () =>
              ref.invalidate(complaintDetailProvider(widget.complaintId)),
        ),
        data: _details,
      ),
      bottomNavigationBar: next == null
          ? null
          : ActionFooter(
              primary: FilledButton(
                onPressed: () => _changeStatus(next),
                child: Text('Tandai ${complaintStatusStyles[next]!.label}'),
              ),
            ),
    );
  }

  Widget _details(Complaint c) {
    final theme = Theme.of(context);
    final classification = c.classification;
    final state = c.classificationState;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_conflict) ...[
            FormMessage(
              errorMessageFor(const ApiFailure(code: _statusNotNextCode)),
            ),
            formGap,
          ],
          SectionCard(
            title: 'Status',
            child: Semantics(
              container: true,
              liveRegion: true,
              child: ComplaintStatusSteps(status: c.status),
            ),
          ),
          formGap,
          if (c.classificationWithheld)
            const SectionCard(
              emphasis: true,
              title: 'Klasifikasi',
              child: Text(_withheld),
            )
          else if (classification != null)
            SectionCard(
              emphasis: true,
              title: 'Klasifikasi',
              child: _ClassificationDetails(classification: classification),
            )
          else if (state != null)
            SectionCard(
              emphasis: true,
              title: 'Klasifikasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ComplaintBadge.classification(state),
                  const SizedBox(height: 8),
                  Text(_stateExplanation(state)),
                  if (state == ComplaintClassificationState.classifying) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(
                        complaintDetailProvider(widget.complaintId),
                      ),
                      child: const Text('Segarkan'),
                    ),
                  ],
                ],
              ),
            ),
          formGap,
          SectionCard(
            title: 'Pesan penyewa',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  '${c.tenantName} · Kamar ${c.room.number} · '
                  'Dikirim ${formatDate(c.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          formGap,
          ComplaintStatusHistory(changes: c.statusChanges),
        ],
      ),
    );
  }
}

class _ClassificationDetails extends StatelessWidget {
  const _ClassificationDetails({required this.classification});

  final ComplaintClassification classification;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final suggestedAction = classification.suggestedAction;
    final classifiedBy = classification.classifiedByName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComplaintClassificationValues(classification: classification),
        if (suggestedAction != null) ...[
          const SizedBox(height: NiscalaSpacing.l),
          Text('Tindakan yang disarankan', style: labelStyle),
          const SizedBox(height: NiscalaSpacing.xs),
          Text(suggestedAction),
        ],
        if (classifiedBy == null) ...[
          const SizedBox(height: NiscalaSpacing.s),
          const AiDisclaimerNote(text: _aiDisclaimer),
        ] else ...[
          const SizedBox(height: NiscalaSpacing.s),
          Text('Diklasifikasi oleh $classifiedBy'),
        ],
      ],
    );
  }
}
