import 'package:flutter/material.dart';
import 'package:niscala/core/widgets/labeled_field.dart';

/// The error for a link field that is empty or holds no token.
const invitationLinkRequiredMessage =
    'Tempel tautan undangan dari pemilik kost.';

/// The labelled field that takes a pasted invitation link. [error] is shown
/// under the field.
class InvitationLinkField extends StatelessWidget {
  const InvitationLinkField({super.key, required this.controller, this.error});

  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: 'Tautan undangan',
      required: true,
      helper: 'Tempel tautan yang dibagikan pemilik kost.',
      child: TextField(
        controller: controller,
        decoration: InputDecoration(errorText: error),
        keyboardType: TextInputType.url,
        autocorrect: false,
      ),
    );
  }
}
