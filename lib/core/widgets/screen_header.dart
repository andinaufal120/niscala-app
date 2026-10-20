import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// The white header of a tab root: a bold title that is also the page title
/// for assistive technology, an optional muted [subtitle] and an optional
/// trailing [action].
///
/// The title is top-aligned and keeps the same top and left edge at every
/// text scale. The header always reserves one subtitle line and at least a
/// 48 dp action, so its height and the title position stay the same whether
/// or not a subtitle or an action is given. Text wraps and grows the header
/// when it needs more room. The action is centred against the title and
/// subtitle block.
///
/// An [action] keeps its space when [actionVisible] is false. A hidden action
/// is laid out but not painted, not tappable and not announced.
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
    final subtitleStyle = textTheme.bodySmall?.copyWith(fontSize: 13);
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: textTheme.headlineSmall),
                        ),
                        // Without a subtitle, an empty line of the same height
                        // keeps the header as tall as one with a subtitle.
                        if (subtitle != null)
                          Text(subtitle, style: subtitleStyle)
                        else
                          RichText(
                            text: TextSpan(
                              text: ' ',
                              style: DefaultTextStyle.of(context).style
                                  .merge(subtitleStyle),
                            ),
                            textScaler: MediaQuery.textScalerOf(context),
                          ),
                      ],
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: NiscalaSpacing.m),
                    Align(
                      widthFactor: 1,
                      child: Visibility(
                        visible: actionVisible,
                        maintainSize: true,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainInteractivity: false,
                        maintainSemantics: false,
                        child: action,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
