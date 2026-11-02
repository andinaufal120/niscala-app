import 'package:flutter/material.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';

const _reasonRequired = 'Alasan penolakan wajib diisi.';

/// Sends the rejection of the receipt with the trimmed [reason]. Completes
/// normally once the caller has handled the outcome, and throws an [ApiFailure]
/// for a failure the sheet shows to the user.
typedef ReceiptRejectionConfirm = Future<void> Function(String reason);

/// Asks for the reason of a rejected transfer receipt, which the tenant sees.
///
/// Pops once [onConfirm] completes. A blank reason is refused on the sheet. A
/// [ApiFailure] that names the reason field is shown on that field, any other
/// is shown above the field. The typed reason is kept in both cases.
class ReceiptRejectionSheet extends StatefulWidget {
  const ReceiptRejectionSheet({super.key, required this.onConfirm});

  final ReceiptRejectionConfirm onConfirm;

  @override
  State<ReceiptRejectionSheet> createState() => _ReceiptRejectionSheetState();
}

class _ReceiptRejectionSheetState extends State<ReceiptRejectionSheet> {
  final _reason = TextEditingController();
  var _saving = false;
  String? _banner;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonError = _reasonRequired);
      return;
    }
    setState(() {
      _saving = true;
      _banner = null;
      _reasonError = null;
    });
    try {
      await widget.onConfirm(reason);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      final message = errorMessageFor(failure);
      setState(() {
        _saving = false;
        if (failure.code == 'VALIDATION_FAILED' && failure.field == 'reason') {
          _reasonError = message;
        } else {
          _banner = message;
        }
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      'Tolak Pembayaran',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: NiscalaSpacing.s),
                  const Text(
                    'Penyewa bisa melihat alasan ini dan mengunggah ulang bukti '
                    'transfer.',
                  ),
                  formGap,
                  LabeledField(
                    label: 'Alasan penolakan',
                    required: true,
                    child: TextField(
                      controller: _reason,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(errorText: _reasonError),
                    ),
                  ),
                  if (_banner != null) ...[formGap, FormMessage(_banner!)],
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
                  label: 'Kirim Penolakan',
                  busy: _saving,
                  onPressed: _submit,
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
