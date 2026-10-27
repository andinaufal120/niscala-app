import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala_api/api.dart';

/// The API code of a status change that another user already made.
const statusNotNextCode = 'COMPLAINT_STATUS_NOT_NEXT';

/// How a [ComplaintStatusSheet] ended, when the caller must act on it. Cancelling
/// pops without a value.
enum ComplaintStatusChangeOutcome { saved, conflict }

/// Asks the caller to confirm moving a complaint to [next] and collects the
/// optional handling note, which the tenant sees.
///
/// Pops with [ComplaintStatusChangeOutcome.saved] once the change is stored, or
/// with `conflict` when the complaint already moved on. Any other failure stays
/// on the sheet with its message, and the typed note is kept.
class ComplaintStatusSheet extends ConsumerStatefulWidget {
  const ComplaintStatusSheet({
    super.key,
    required this.complaintId,
    required this.next,
  });

  final String complaintId;
  final ComplaintStatus next;

  @override
  ConsumerState<ComplaintStatusSheet> createState() =>
      _ComplaintStatusSheetState();
}

class _ComplaintStatusSheetState extends ConsumerState<ComplaintStatusSheet> {
  final _note = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final note = _note.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(complaintRepositoryProvider)
          .changeStatus(
            widget.complaintId,
            widget.next,
            handlingNote: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      Navigator.of(context).pop(ComplaintStatusChangeOutcome.saved);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == statusNotNextCode) {
        Navigator.of(context).pop(ComplaintStatusChangeOutcome.conflict);
        return;
      }
      setState(() {
        _saving = false;
        _error = errorMessageFor(failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = complaintStatusStyles[widget.next]!.label;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The text scrolls, so the buttons stay in view at large text sizes.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                NiscalaSpacing.gutter,
                NiscalaSpacing.gutter,
                NiscalaSpacing.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Tandai keluhan sebagai $label?',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: NiscalaSpacing.s),
                  const Text(
                    'Status tidak bisa dikembalikan, dan penyewa akan diberi tahu.',
                  ),
                  formGap,
                  LabeledField(
                    label: 'Catatan penanganan',
                    required: false,
                    helper: 'Terlihat oleh penyewa',
                    child: TextField(
                      controller: _note,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  if (_error != null) ...[formGap, FormMessage(_error!)],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BusyButton(
                  label: 'Ya, $label',
                  busy: _saving,
                  onPressed: _confirm,
                ),
                const SizedBox(height: NiscalaSpacing.s),
                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
