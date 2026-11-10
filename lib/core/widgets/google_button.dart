import 'package:flutter/material.dart';

/// The Google sign-in button of a sign-in, sign-up or activation form, and of
/// the re-authentication dialog. Its visible label is its whole spoken label.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.label, required this.onPressed});

  final String label;

  /// Null disables the button while another request is in flight.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
