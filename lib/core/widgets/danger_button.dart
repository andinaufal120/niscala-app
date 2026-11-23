import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A full-width outlined button in the danger colour. It shows [icon], a trash
/// icon by default. A null [onPressed] disables it.
///
/// While [busy] it is disabled and shows progress in place of the icon.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: NiscalaColors.danger,
        side: const BorderSide(color: NiscalaColors.danger),
      ),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Memproses',
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
