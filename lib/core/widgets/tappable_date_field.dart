import 'package:flutter/material.dart';
import 'package:niscala/core/widgets/labeled_field.dart';

/// A labelled date field that is filled by a date picker rather than typing.
///
/// The field shows the text of [controller] and is read-only. [onTap] runs on a
/// tap and also on the tap action of a screen reader or Switch Access, so the
/// picker opens without a pointer. [errorText] is shown under the field and
/// read with it. [required] is passed to the [LabeledField] label.
class TappableDateField extends StatelessWidget {
  const TappableDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.onTap,
    this.required,
    this.errorText,
  });

  final String label;
  final bool? required;
  final TextEditingController controller;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      required: required,
      child: Semantics(
        onTap: onTap,
        child: TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(errorText: errorText),
        ),
      ),
    );
  }
}
