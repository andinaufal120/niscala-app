import 'package:flutter/material.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

const _title = 'Ubah Status Pembayaran';
const _statusGroupLabel = 'Status baru (wajib)';
const _methodGroupLabel = 'Metode pembayaran (wajib)';
const _statusRequired = 'Pilih status baru.';
const _methodRequired = 'Pilih metode pembayaran.';
const _reasonRequired = 'Alasan perubahan wajib diisi.';

/// The label of the reason field, as the API's field error names it.
const _reasonFieldLabel = {'reason': 'Alasan perubahan'};

/// The statuses that can be set by hand. Awaiting verification is set by
/// uploading a receipt, so it is never offered.
const _settable = [
  PaymentStatus.unpaid,
  PaymentStatus.paid,
  PaymentStatus.rejected,
];

/// Sends the status change with the trimmed reason. Completes normally once
/// the caller has handled the outcome, and throws an [ApiFailure] for a failure
/// the sheet shows to the user.
typedef PaymentStatusChangeConfirm = Future<void> Function({
  required PaymentStatus status,
  required String reason,
  PaymentMethod? method,
  DateTime? receivedOn,
});

/// Changes the payment status of a bill by hand, with a required reason. The
/// status [current] is not offered. Choosing Lunas asks for the method and the
/// day received, which starts at today.
///
/// Pops once [onConfirm] completes. A refused input is shown on its field or
/// next to its group of choices. A failure of the API is shown on the field
/// it names, next to the group of its field, or above the buttons. The typed
/// values are kept in every case.
class PaymentStatusChangeSheet extends StatefulWidget {
  const PaymentStatusChangeSheet({
    super.key,
    required this.current,
    required this.onConfirm,
  });

  final PaymentStatus current;
  final PaymentStatusChangeConfirm onConfirm;

  @override
  State<PaymentStatusChangeSheet> createState() =>
      _PaymentStatusChangeSheetState();
}

class _PaymentStatusChangeSheetState extends State<PaymentStatusChangeSheet> {
  final _reason = TextEditingController();
  final _receivedOnText = TextEditingController();

  /// The day the money was received. Starts at today and is never later.
  var _receivedOn = _today();
  PaymentStatus? _status;
  PaymentMethod? _method;

  /// Set while the change is sent, so that a second tap sends nothing.
  var _saving = false;
  String? _banner;
  String? _statusError;
  String? _methodError;
  String? _reasonError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _receivedOnText.text = formatDate(_receivedOn);
  }

  @override
  void dispose() {
    _reason.dispose();
    _receivedOnText.dispose();
    super.dispose();
  }

  void _chooseStatus(PaymentStatus? status) => setState(() {
    _status = status;
    _statusError = null;
    _methodError = null;
  });

  void _chooseMethod(PaymentMethod? method) => setState(() {
    _method = method;
    _methodError = null;
  });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: DateTime(2000),
      lastDate: _today(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _receivedOn = picked;
      _receivedOnText.text = formatDate(picked);
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final status = _status;
    final method = _method;
    final reason = _reason.text.trim();
    final paid = status == PaymentStatus.paid;
    if (status == null || reason.isEmpty || (paid && method == null)) {
      setState(() {
        _statusError = status == null ? _statusRequired : null;
        _reasonError = reason.isEmpty ? _reasonRequired : null;
        _methodError = paid && method == null ? _methodRequired : null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _banner = null;
      _statusError = null;
      _methodError = null;
      _reasonError = null;
      _dateError = null;
    });
    try {
      await widget.onConfirm(
        status: status,
        reason: reason,
        method: paid ? method : null,
        receivedOn: paid ? _receivedOn : null,
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _failed(failure);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Shows the failure on the field it names, or above the buttons when it
  /// names none.
  void _failed(ApiFailure failure) {
    final message = errorMessageFor(failure, labels: _reasonFieldLabel);
    final field = failure.field;
    setState(() {
      _saving = false;
      if (field == 'reason') {
        _reasonError = message;
      } else if (field == 'receivedOn') {
        _dateError = message;
      } else if (field == 'status') {
        _statusError = message;
      } else if (field == 'method') {
        _methodError = message;
      } else {
        _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = _status == PaymentStatus.paid;
    final statuses = [
      for (final status in _settable)
        if (status != widget.current) status,
    ];
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
                    child: Text(_title, style: theme.textTheme.titleLarge),
                  ),
                  formGap,
                  Text(_statusGroupLabel, style: theme.textTheme.titleSmall),
                  RadioGroup<PaymentStatus>(
                    groupValue: _status,
                    onChanged: _chooseStatus,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final status in statuses)
                          RadioListTile<PaymentStatus>(
                            value: status,
                            title: Text(paymentStatusStyles[status]!.label),
                          ),
                      ],
                    ),
                  ),
                  if (_statusError != null)
                    _Note(_statusError!, color: theme.colorScheme.error),
                  formGap,
                  LabeledField(
                    label: 'Alasan perubahan',
                    required: true,
                    child: TextField(
                      controller: _reason,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(errorText: _reasonError),
                    ),
                  ),
                  if (paid) ...[
                    formGap,
                    Text(_methodGroupLabel, style: theme.textTheme.titleSmall),
                    RadioGroup<PaymentMethod>(
                      groupValue: _method,
                      onChanged: _chooseMethod,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final method in PaymentMethod.values)
                            RadioListTile<PaymentMethod>(
                              value: method,
                              title: Text(paymentMethodLabels[method]!),
                            ),
                        ],
                      ),
                    ),
                    if (_methodError != null)
                      _Note(_methodError!, color: theme.colorScheme.error),
                    formGap,
                    LabeledField(
                      label: 'Tanggal diterima',
                      required: true,
                      child: TextField(
                        controller: _receivedOnText,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(errorText: _dateError),
                      ),
                    ),
                  ],
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
                  label: 'Simpan Perubahan',
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

/// A message next to a group of choices, in the error colour.
class _Note extends StatelessWidget {
  const _Note(this.message, {required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: NiscalaSpacing.xs),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
