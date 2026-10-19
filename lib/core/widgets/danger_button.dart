import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A full-width outlined button with a trash icon, in the danger colour. A null
/// [onPressed] disables it.
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: NiscalaColors.danger,
        side: const BorderSide(color: NiscalaColors.danger),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline),
      label: Text(label),
    );
  }
}
