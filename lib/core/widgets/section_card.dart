import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A white card with an optional [title] that is a header for assistive
/// technology. A [trailing] widget sits at the end of the title row. An
/// [emphasis] card has a 2 px primary border.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.emphasis = false,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final trailing = this.trailing;
    return Card(
      shape: emphasis
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NiscalaRadius.card),
              side: const BorderSide(color: NiscalaColors.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(NiscalaSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      container: true,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: NiscalaSpacing.s),
                    trailing,
                  ],
                ],
              ),
              const SizedBox(height: NiscalaSpacing.s),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
