import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// Filter chips on one line that scrolls sideways when they do not fit.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key, required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, chip) in chips.indexed) ...[
            if (index > 0) const SizedBox(width: NiscalaSpacing.s),
            chip,
          ],
        ],
      ),
    );
  }
}
