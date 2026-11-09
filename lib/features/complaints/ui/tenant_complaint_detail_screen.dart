import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_photo_choice.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

const _submittedMessage = 'Keluhan terkirim.';
const _photoNotUploadedMessage =
    'Keluhan terkirim, tetapi foto belum terunggah. Coba lagi lewat Tambah foto.';
const _aiDisclaimer = 'Klasifikasi dibuat AI dan bisa keliru.';
const _photoNotNewCode = 'COMPLAINT_NOT_NEW';

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
/// right after the complaint was saved, and [photoNotUploaded] when the photo
/// sent with it did not upload. While the complaint is new, the photo can be
/// added or replaced here.
class TenantComplaintDetailScreen extends ConsumerStatefulWidget {
  const TenantComplaintDetailScreen({
    super.key,
    required this.complaintId,
    this.submitted = false,
    this.photoNotUploaded = false,
  });

  final String complaintId;
  final bool submitted;
  final bool photoNotUploaded;

  @override
  ConsumerState<TenantComplaintDetailScreen> createState() =>
      _TenantComplaintDetailScreenState();
}

class _TenantComplaintDetailScreenState
    extends ConsumerState<TenantComplaintDetailScreen> {
  /// Set while a photo is being uploaded.
  var _uploading = false;

  /// The message for a photo that was rejected, could not be chosen or did not
  /// upload.
  String? _photoError;

  /// Uploads the photo the tenant chooses, then reloads the complaint.
  Future<void> _changePhoto() async {
    final choice = await choosePhoto(context, ref);
    if (choice == null || !mounted) return;
    final photo = choice.photo;
    if (photo == null) {
      setState(() => _photoError = choice.error);
      return;
    }
    setState(() {
      _uploading = true;
      _photoError = null;
    });
    try {
      await ref
          .read(complaintRepositoryProvider)
          .uploadPhoto(widget.complaintId, photo);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == _photoNotNewCode) {
        ref.invalidate(complaintDetailProvider(widget.complaintId));
      }
      setState(() {
        _uploading = false;
        _photoError = errorMessageFor(failure, labels: photoFormLabels);
      });
      return;
    }
    if (!mounted) return;
    ref.invalidate(complaintDetailProvider(widget.complaintId));
    ref.invalidate(complaintPhotoBytesProvider(widget.complaintId));
    ref.invalidate(complaintListProvider);
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final complaint = ref.watch(complaintDetailProvider(widget.complaintId));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Rincian Keluhan'),
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
          if (widget.submitted) ...[
            FormMessage(
              widget.photoNotUploaded
                  ? _photoNotUploadedMessage
                  : _submittedMessage,
              isError: widget.photoNotUploaded,
            ),
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
          if (c.hasPhoto ||
              c.status == ComplaintStatus.new_ ||
              _photoError != null) ...[
            _photoCard(c),
            formGap,
          ],
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
          ComplaintStatusHistory(changes: c.statusChanges),
        ],
      ),
    );
  }

  /// The photo of the complaint, which opens full screen, and while the
  /// complaint is new the action that adds or replaces it.
  Widget _photoCard(Complaint c) {
    return SectionCard(
      title: 'Foto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.hasPhoto)
            ComplaintPhotoTile(
              sentAt: c.createdAt,
              onOpen: () => context.go('/penyewa/keluhan/${c.id}/foto'),
            ),
          if (_photoError != null) ...[
            const SizedBox(height: NiscalaSpacing.s),
            FieldMessage(_photoError!),
          ],
          if (c.status == ComplaintStatus.new_) ...[
            const SizedBox(height: NiscalaSpacing.s),
            if (_uploading)
              const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Mengunggah foto',
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _changePhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(c.hasPhoto ? 'Ganti foto' : 'Tambah foto'),
              ),
          ],
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
