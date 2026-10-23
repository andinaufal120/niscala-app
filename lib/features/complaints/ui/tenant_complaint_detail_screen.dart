import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
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
      appBar: const DetailAppBar(title: 'Rincian Keluhan'),
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
          if (submitted) ...[
            FormMessage(_submittedMessage, isError: false),
            formGap,
          ],
          SectionCard(
            title: 'Status',
            child: ComplaintStatusSteps(status: c.status),
          ),
          formGap,
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  'Dikirim ${formatDate(c.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          formGap,
          if (classification != null)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComplaintClassificationValues(classification: classification),
        if (classification.classifiedByName == null) ...[
          const SizedBox(height: NiscalaSpacing.s),
          const AiDisclaimerNote(text: _aiDisclaimer),
        ],
      ],
    );
  }
}
