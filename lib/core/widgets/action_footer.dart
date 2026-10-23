import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// The white footer pinned under a screen, with a divider on top, a [primary]
/// action and an optional [secondary] one below it.
class ActionFooter extends StatelessWidget {
  const ActionFooter({super.key, required this.primary, this.secondary});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final secondary = this.secondary;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NiscalaColors.surface,
        border: Border(top: BorderSide(color: NiscalaColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NiscalaSpacing.gutter,
            NiscalaSpacing.m,
            NiscalaSpacing.gutter,
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              if (secondary != null) ...[
                const SizedBox(height: NiscalaSpacing.s),
                secondary,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
