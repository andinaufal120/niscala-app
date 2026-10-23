import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

/// A length or an area without its unit, with a decimal comma and at most two
/// decimals, e.g. "3,5", "4" or "14,7".
String formatMeasure(num value) {
  final rounded = (value * 100).round() / 100;
  final text = rounded.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return text.replaceAll('.', ',');
}

/// Length and width in metres, e.g. "3,5 × 4 m".
String formatDimensions(num lengthM, num widthM) =>
    '${formatMeasure(lengthM)} × ${formatMeasure(widthM)} m';

/// The occupancy of a room as a text badge.
class OccupancyBadge extends StatelessWidget {
  const OccupancyBadge({super.key, required this.occupancy});

  final Occupancy occupancy;

  @override
  Widget build(BuildContext context) {
    final tokens = NiscalaTokens.of(context);
    return occupancy == Occupancy.occupied
        ? StatusBadge(label: 'Terisi', colors: tokens.roomOccupied)
        : StatusBadge(label: 'Kosong', colors: tokens.roomVacant);
  }
}
