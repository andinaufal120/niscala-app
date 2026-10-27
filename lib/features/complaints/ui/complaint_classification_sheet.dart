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

const _correctionNote = 'Koreksi Anda disimpan bersama hasil asli AI.';

/// Saves the category and urgency set by hand. Completes normally once the
/// caller has handled the outcome, and throws an [ApiFailure] for a failure the
/// sheet shows to the user.
typedef ComplaintClassificationConfirm = Future<void> Function(
  String category,
  ComplaintUrgency urgency,
);

/// Asks for the category and urgency of a complaint, starting from [current]:
/// an AI result, an earlier manual one, or null when there is none.
///
/// The categories are loaded when the sheet is shown. Pops once [onConfirm]
/// completes. An [ApiFailure] it throws stays on the sheet with its message,
/// and the chosen values are kept. The sheet holds no request of its own, so
/// the caller's work goes on if the sheet is dismissed while it is in flight.
class ComplaintClassificationSheet extends ConsumerStatefulWidget {
  const ComplaintClassificationSheet({
    super.key,
    required this.current,
    required this.onConfirm,
  });

  final ComplaintClassification? current;
  final ComplaintClassificationConfirm onConfirm;

  @override
  ConsumerState<ComplaintClassificationSheet> createState() =>
      _ComplaintClassificationSheetState();
}

class _ComplaintClassificationSheetState
    extends ConsumerState<ComplaintClassificationSheet> {
  String? _category;
  ComplaintUrgency? _urgency;
  var _saving = false;
  ApiFailure? _failure;

  @override
  void initState() {
    super.initState();
    _category = widget.current?.category;
    _urgency = widget.current?.urgency;
  }

  Future<void> _save(String category, ComplaintUrgency urgency) async {
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await widget.onConfirm(category, urgency);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = failure;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(complaintCategoriesProvider);
    final items = categories.value;
    // A category the API does not offer can be neither shown nor saved.
    final category = items != null && items.contains(_category)
        ? _category
        : null;
    final urgency = _urgency;
    final failure = _failure;
    final categoryError = failure != null && failure.field == 'category'
        ? errorMessageFor(failure)
        : null;
    final formError = failure != null && categoryError == null
        ? errorMessageFor(failure)
        : null;
    final save = category != null && urgency != null && !_saving
        ? () => _save(category, urgency)
        : null;

    final categoryField = categories.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormMessage(errorMessageFor(error)),
          formGap,
          FilledButton.tonal(
            onPressed: () => ref.invalidate(complaintCategoriesProvider),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
      data: (categoryList) => LabeledField(
        label: 'Kategori',
        required: true,
        child: DropdownButtonFormField<String>(
          initialValue: category,
          isExpanded: true,
          decoration: InputDecoration(errorText: categoryError),
          items: [
            for (final item in categoryList)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) => setState(() => _category = value),
        ),
      ),
    );

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
                      'Klasifikasi keluhan',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  formGap,
                  categoryField,
                  formGap,
                  Text('Urgensi (wajib)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  RadioGroup<ComplaintUrgency>(
                    groupValue: urgency,
                    onChanged: (value) => setState(() => _urgency = value),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final value in ComplaintUrgency.values)
                          RadioListTile<ComplaintUrgency>(
                            value: value,
                            title: Text(complaintUrgencyStyles[value]!.label),
                          ),
                      ],
                    ),
                  ),
                  if (formError != null) ...[formGap, FormMessage(formError)],
                  if (widget.current != null) ...[
                    formGap,
                    Text(_correctionNote, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          // Side by side, so the buttons take less height at large text sizes.
          Padding(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: NiscalaSpacing.s),
                Expanded(
                  child: BusyButton(
                    label: 'Simpan',
                    busy: _saving,
                    onPressed: save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
