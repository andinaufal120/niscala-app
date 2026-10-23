import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A full-width outlined button in the danger colour. It shows [icon], a trash
/// icon by default. A null [onPressed] disables it.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: NiscalaColors.danger,
        side: const BorderSide(color: NiscalaColors.danger),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
