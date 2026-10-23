import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A white card with an optional [title] that is a header for assistive
/// technology. An [emphasis] card has a 2 px primary border.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.emphasis = false,
  });

  final Widget child;
  final String? title;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
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
              Semantics(
                header: true,
                container: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
