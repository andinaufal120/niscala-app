import 'package:flutter/material.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala_api/api.dart';

/// Saves the status change with the trimmed handling note, or null when the
/// note is empty. Completes normally once the caller has handled the outcome,
/// and throws an [ApiFailure] for a failure the sheet shows to the user.
typedef ComplaintStatusConfirm = Future<void> Function(String? handlingNote);

/// Asks the caller to confirm moving a complaint to [next] and collects the
/// optional handling note, which the tenant sees.
///
/// Pops once [onConfirm] completes. Any [ApiFailure] it throws stays on the
/// sheet with its message, and the typed note is kept. The sheet holds no
/// request of its own, so the caller's work goes on if the sheet is dismissed
/// while it is in flight.
class ComplaintStatusSheet extends StatefulWidget {
  const ComplaintStatusSheet({
    super.key,
    required this.next,
    required this.onConfirm,
  });

  final ComplaintStatus next;
  final ComplaintStatusConfirm onConfirm;

  @override
  State<ComplaintStatusSheet> createState() => _ComplaintStatusSheetState();
}

class _ComplaintStatusSheetState extends State<ComplaintStatusSheet> {
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
      await widget.onConfirm(note.isEmpty ? null : note);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
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
