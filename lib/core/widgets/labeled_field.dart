import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A form field with its label above it. The field's semantics node carries
/// the full label, and the visible label is excluded from semantics, so a
/// screen reader reads it once. Tapping the label focuses the field.
///
/// [required] adds "(wajib)" when true and "(opsional)" when false; null adds
/// no marker. The [helper] text is shown under the field and read with it.
/// The [child] is a field without its own label.
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required,
    this.helper,
  });

  final String label;
  final bool? required;
  final String? helper;
  final Widget child;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  final _fieldScope = FocusNode(
    debugLabel: 'LabeledField',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _fieldScope.dispose();
    super.dispose();
  }

  void _focusField() {
    for (final node in _fieldScope.descendants) {
      if (node.canRequestFocus) {
        node.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marker = switch (widget.required) {
      true => ' (wajib)',
      false => ' (opsional)',
      null => null,
    };
    final base = Theme.of(context).textTheme.titleSmall!;
    final helper = widget.helper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusField,
            child: Text.rich(
              TextSpan(
                text: widget.label,
                style: base,
                children: [
                  if (marker != null)
                    TextSpan(
                      text: marker,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: NiscalaColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        MergeSemantics(
          child: Semantics(
            label: '${widget.label}${marker ?? ''}',
            hint: helper,
            child: Focus(
              focusNode: _fieldScope,
              includeSemantics: false,
              child: widget.child,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(helper, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ],
    );
  }
}
