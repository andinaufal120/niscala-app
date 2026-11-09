import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';

/// The photo of one complaint, full screen. The image is labelled with the
/// photo and the day the complaint was sent.
class ComplaintPhotoScreen extends ConsumerWidget {
  const ComplaintPhotoScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaint = ref.watch(complaintDetailProvider(complaintId));
    final photo = ref.watch(complaintPhotoBytesProvider(complaintId));
    void reload() {
      ref.invalidate(complaintDetailProvider(complaintId));
      ref.invalidate(complaintPhotoBytesProvider(complaintId));
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Foto Keluhan'),
      body: switch ((complaint, photo)) {
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
          ErrorView(message: errorMessageFor(error), onRetry: reload),
        (AsyncData(value: final c), AsyncData(value: final bytes)) => Padding(
          padding: const EdgeInsets.all(NiscalaSpacing.gutter),
          child: Center(
            child: Image.memory(
              bytes,
              semanticLabel:
                  'Foto keluhan, ${formatDate(c.createdAt.toLocal())}',
              errorBuilder: (_, _, _) =>
                  ErrorView(message: unreadablePhotoMessage, onRetry: reload),
            ),
          ),
        ),
        _ => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
      },
    );
  }
}
