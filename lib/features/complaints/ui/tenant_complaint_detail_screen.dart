import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

const _submittedMessage = 'Keluhan terkirim.';
const _aiDisclaimer = 'Klasifikasi dibuat AI dan bisa keliru.';

/// What a complaint without a classification means for the tenant.
String _stateExplanation(ComplaintClassificationState state) => switch (state) {
  ComplaintClassificationState.classifying =>
    'AI sedang mengklasifikasikan keluhan Anda.',
  ComplaintClassificationState.awaitingClassification =>
    'Klasifikasi belum berhasil dibuat. Keluhan Anda tetap tersimpan dan '
        'akan ditangani pengelola.',
  ComplaintClassificationState.notClassified =>
    'Keluhan ini belum diklasifikasi. Keluhan Anda tetap tersimpan dan '
        'akan ditangani pengelola.',
  _ => throw ArgumentError.value(
    state,
    'state',
    'Unknown classification state',
  ),
};

/// One of the tenant's complaints. [submitted] is set when the screen opens
/// right after the complaint was saved.
class TenantComplaintDetailScreen extends ConsumerWidget {
  const TenantComplaintDetailScreen({
    super.key,
    required this.complaintId,
    this.submitted = false,
  });

  final String complaintId;
  final bool submitted;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (submitted) ...[
            FormMessage(_submittedMessage, isError: false),
            formGap,
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [ComplaintBadge.status(c.status)],
          ),
          const SizedBox(height: 8),
          Text('Dikirim ${formatDate(c.createdAt.toLocal())}'),
          formGap,
          Text(c.description, style: theme.textTheme.bodyLarge),
          formGap,
          if (classification != null)
            _ClassificationDetails(classification: classification)
          else if (state != null) ...[
            const ComplaintSectionHeader('Klasifikasi'),
            const SizedBox(height: 8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ComplaintSectionHeader('Klasifikasi'),
        const SizedBox(height: 8),
        Text('Kategori', style: labelStyle),
        Text(classification.category),
        const SizedBox(height: 8),
        Text('Urgensi', style: labelStyle),
        ComplaintBadge.urgency(classification.urgency),
        const SizedBox(height: 8),
        const Text(_aiDisclaimer),
      ],
    );
  }
}
