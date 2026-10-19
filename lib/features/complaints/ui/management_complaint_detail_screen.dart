import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

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

/// One complaint on the caller's properties. The screen is read-only.
class ManagementComplaintDetailScreen extends ConsumerWidget {
  const ManagementComplaintDetailScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaint = ref.watch(complaintDetailProvider(complaintId));
    return Scaffold(
      appBar: AppBar(title: const Text('Rincian Keluhan')),
      body: complaint.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(complaintDetailProvider(complaintId)),
        ),
        data: (c) => _details(context, ref, c),
      ),
    );
  }

  Widget _details(BuildContext context, WidgetRef ref, Complaint c) {
    final theme = Theme.of(context);
    final classification = c.classification;
    final state = c.classificationState;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [ComplaintBadge.status(c.status)],
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
                      onPressed: () =>
                          ref.invalidate(complaintDetailProvider(complaintId)),
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
                Text(c.tenantName, style: theme.textTheme.titleMedium),
                Text('Kamar ${c.room.number}'),
                Text('Dikirim ${formatDate(c.createdAt.toLocal())}'),
                const SizedBox(height: 8),
                Text(c.description, style: theme.textTheme.bodyLarge),
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
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    final suggestedAction = classification.suggestedAction;
    final classifiedBy = classification.classifiedByName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: labelStyle),
        Text(classification.category),
        const SizedBox(height: 8),
        Text('Urgensi', style: labelStyle),
        ComplaintBadge.urgency(classification.urgency),
        if (suggestedAction != null) ...[
          const SizedBox(height: 8),
          Text('Tindakan yang disarankan', style: labelStyle),
          Text(suggestedAction),
        ],
        const SizedBox(height: 8),
        if (classifiedBy == null)
          const Text(_aiDisclaimer)
        else
          Text('Diklasifikasi oleh $classifiedBy'),
      ],
    );
  }
}
