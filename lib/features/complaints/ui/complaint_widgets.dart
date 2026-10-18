import 'package:flutter/material.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/complaints/complaint_labels.dart';
import 'package:niscala_api/api.dart';

/// A complaint status, urgency or classification state as a text badge.
class ComplaintBadge extends StatelessWidget {
  ComplaintBadge.status(ComplaintStatus status, {super.key})
    : _style = complaintStatusStyles[status]!;

  ComplaintBadge.urgency(ComplaintUrgency urgency, {super.key})
    : _style = complaintUrgencyStyles[urgency]!;

  ComplaintBadge.classification(ComplaintClassificationState state, {super.key})
    : _style = complaintClassificationStyles[state]!;

  final ComplaintBadgeStyle _style;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: _style.label, tone: _style.tone);
  }
}

/// A titled block of a complaint screen. The title is a header for assistive
/// technology.
class ComplaintSectionHeader extends StatelessWidget {
  const ComplaintSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// Each status change as its label and date, with the handling note under it
/// when the change has one.
class ComplaintStatusHistory extends StatelessWidget {
  const ComplaintStatusHistory({super.key, required this.changes});

  final List<ComplaintStatusChange> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ComplaintSectionHeader('Riwayat status'),
        const SizedBox(height: 4),
        for (final change in changes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${complaintStatusStyles[change.status]!.label} · '
                  '${formatDate(change.changedAt.toLocal())}',
                  style: theme.textTheme.labelLarge,
                ),
                if (change.handlingNote != null) Text(change.handlingNote!),
              ],
            ),
          ),
      ],
    );
  }
}
