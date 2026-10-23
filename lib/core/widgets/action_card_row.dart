import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A tappable card row with a leading icon, a bold [title], a [subtitle] and a
/// chevron. Screen readers get it as one button. A [filled] row is white on the
/// primary colour; otherwise it is dark on white with an outline.
class ActionCardRow extends StatelessWidget {
  const ActionCardRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = filled ? NiscalaColors.surface : NiscalaColors.text;
    final secondary = filled ? NiscalaColors.surface : NiscalaColors.textMuted;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: filled ? NiscalaColors.primary : NiscalaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NiscalaRadius.card),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: NiscalaColors.controlBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(NiscalaSpacing.l),
              child: Row(
                children: [
                  Icon(icon, color: foreground),
                  const SizedBox(width: NiscalaSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: NiscalaSpacing.s),
                  Icon(Icons.chevron_right, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
