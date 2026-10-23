import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// The white header of a tab root: a bold title that is also the page title
/// for assistive technology, an optional muted [subtitle] and an optional
/// trailing [action].
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final action = this.action;
    return ColoredBox(
      color: NiscalaColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NiscalaSpacing.gutter,
            NiscalaSpacing.l,
            NiscalaSpacing.gutter,
            NiscalaSpacing.m,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: textTheme.headlineSmall),
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: NiscalaSpacing.m),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
