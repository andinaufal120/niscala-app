import 'package:flutter/material.dart';

enum StatusTone { success, warning, danger, info, neutral }

/// A status shown as text, so it never relies on colour alone. The optional
/// [icon] and the tone's colour only reinforce the label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      StatusTone.success => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      StatusTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      StatusTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      StatusTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurface),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
