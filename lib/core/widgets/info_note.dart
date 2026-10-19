import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// A soft callout: a decorative leading [icon] and the [text] it explains.
class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NiscalaColors.primarySoft,
        borderRadius: BorderRadius.circular(NiscalaRadius.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NiscalaSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 20, color: NiscalaColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: NiscalaColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
