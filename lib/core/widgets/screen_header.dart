import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// The white header of a tab root: a bold title that is also the page title
/// for assistive technology, an optional muted [subtitle] and an optional
/// trailing [action].
///
/// Text wraps. The header is never shorter than a 48 dp action, and an
/// [action] keeps its space when [actionVisible] is false, so the height and
/// the title position stay the same whether or not the action shows. A hidden
/// action is laid out but not painted, not tappable and not announced.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actionVisible = true,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final bool actionVisible;

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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
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
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(fontSize: 13),
                        ),
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: NiscalaSpacing.m),
                  Visibility(
                    visible: actionVisible,
                    maintainSize: true,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainInteractivity: false,
                    maintainSemantics: false,
                    child: action,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
