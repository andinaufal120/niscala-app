import 'package:flutter/material.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/section_card.dart';
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
    return StatusBadge(
      label: _style.label,
      colors: _style.colors(NiscalaTokens.of(context)),
    );
  }
}

/// The three steps of a complaint, from new to done: one bar per step, filled
/// up to the current status, with its label under the bar. Read as one item,
/// "Status: <label>".
class ComplaintStatusSteps extends StatelessWidget {
  const ComplaintStatusSteps({super.key, required this.status});

  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final current = ComplaintStatus.values.indexOf(status);
    return Semantics(
      label: 'Status: ${complaintStatusStyles[status]!.label}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (i, _) in ComplaintStatus.values.indexed) ...[
                if (i > 0) const SizedBox(width: NiscalaSpacing.xs),
                Expanded(
                  child: SizedBox(
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i <= current
                            ? NiscalaColors.primary
                            : NiscalaColors.neutralSoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: NiscalaSpacing.xs),
          Row(
            children: [
              for (final (i, step) in ComplaintStatus.values.indexed) ...[
                if (i > 0) const SizedBox(width: NiscalaSpacing.xs),
                Expanded(
                  child: Text(
                    complaintStatusStyles[step]!.label,
                    style: i == current
                        ? labelStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: NiscalaColors.text,
                          )
                        : labelStyle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The Kategori and Urgensi of a classification side by side, each under its
/// muted label.
class ComplaintClassificationValues extends StatelessWidget {
  const ComplaintClassificationValues({
    super.key,
    required this.classification,
  });

  final ComplaintClassification classification;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LabelledValue(
            label: 'Kategori',
            child: Text(classification.category),
          ),
        ),
        const SizedBox(width: NiscalaSpacing.l),
        Expanded(
          child: _LabelledValue(
            label: 'Urgensi',
            child: ComplaintBadge.urgency(classification.urgency),
          ),
        ),
      ],
    );
  }
}

/// A note about AI output: a divider, then [text] in small muted type.
class AiDisclaimerNote extends StatelessWidget {
  const AiDisclaimerNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: NiscalaSpacing.s),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LabelledValue extends StatelessWidget {
  const _LabelledValue({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: NiscalaSpacing.xs),
        child,
      ],
    );
  }
}

/// Each status change as its label and date, with the handling note under it
/// when the change has one, in a card titled Riwayat status.
class ComplaintStatusHistory extends StatelessWidget {
  const ComplaintStatusHistory({super.key, required this.changes});

  final List<ComplaintStatusChange> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Riwayat status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      ),
    );
  }
}
