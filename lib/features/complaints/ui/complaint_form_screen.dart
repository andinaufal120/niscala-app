import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';

const _helper = 'Ceritakan masalahnya, minimal 10 karakter.';
const _required = 'Deskripsi keluhan wajib diisi.';
const _tooShort = 'Tulis minimal 10 karakter.';
const _minLength = 10;

/// Submits a complaint. On success the detail screen opens at once, while the
/// AI classification may still be running.
class ComplaintFormScreen extends ConsumerStatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  ConsumerState<ComplaintFormScreen> createState() =>
      _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends ConsumerState<ComplaintFormScreen> {
  final _description = TextEditingController();

  var _busy = false;
  String? _descriptionError;

  /// Failures that are not about the description. The banner stays until the
  /// next submit, and the text the user wrote is kept.
  String? _banner;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final text = _description.text.trim();
    final error = text.isEmpty
        ? _required
        : text.length < _minLength
        ? _tooShort
        : null;
    setState(() {
      _descriptionError = error;
      _banner = null;
      _busy = error == null;
    });
    if (error != null) return;
    await _send(text);
  }

  Future<void> _send(String description) async {
    try {
      final complaint = await ref
          .read(complaintRepositoryProvider)
          .submit(description);
      if (!mounted) return;
      ref.invalidate(complaintListProvider);
      context.go('/penyewa/keluhan/${complaint.id}?terkirim=1');
    } on ApiFailure catch (failure) {
      if (mounted) _showFailure(failure);
    }
  }

  void _showFailure(ApiFailure failure) {
    final message = errorMessage(failure.code);
    setState(() {
      _busy = false;
      if (failure.field == 'description') {
        _descriptionError = message;
      } else {
        _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Keluhan')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NiscalaSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_banner != null) ...[FormMessage(_banner!), formGap],
                  LabeledField(
                    label: 'Deskripsi keluhan',
                    required: true,
                    helper: _helper,
                    child: TextField(
                      controller: _description,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 4,
                      maxLines: null,
                      decoration: InputDecoration(errorText: _descriptionError),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ActionFooter(
            primary: BusyButton(
              label: 'Kirim Keluhan',
              busy: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
