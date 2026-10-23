import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A status shown as text, so it never relies on colour alone. The optional
/// [icon] and the [colors] only reinforce the label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.colors,
    this.icon,
  });

  final String label;
  final BadgeColors colors;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final border = colors.border;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(NiscalaRadius.badge),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: colors.foreground),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
