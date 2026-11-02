import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

/// The payment pattern of each tenant of one property, in the order the API
/// returns them. The values are shown as the API has them.
class PaymentPatternScreen extends ConsumerWidget {
  const PaymentPatternScreen({super.key, required this.propertyId});

  /// The property the patterns belong to, from the `properti` query parameter.
  /// Null when the link has none, in which case no patterns can be asked for.
  final String? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyId = this.propertyId;
    return Scaffold(
      appBar: const DetailAppBar(title: 'Risiko Pembayaran'),
      body: propertyId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(NiscalaSpacing.gutter),
                child: Text(
                  'Properti tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          : _Cards(propertyId: propertyId),
    );
  }
}

class _Cards extends ConsumerWidget {
  const _Cards({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(paymentPatternsProvider(propertyId));
    return patterns.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
      error: (error, _) => ErrorView(
        message: errorMessageFor(error),
        onRetry: () => ref.invalidate(paymentPatternsProvider(propertyId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            message: 'Belum ada penyewa dengan sewa aktif.',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(NiscalaSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final pattern in items) ...[
                _PatternCard(pattern: pattern),
                const SizedBox(height: NiscalaSpacing.s),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One tenant: the name, the at-risk flag, the room, the facts of the pattern
/// and the summary. The card is read as one item.
class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final PaymentPattern pattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NiscalaSpacing.gutter),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: NiscalaSpacing.s,
                runSpacing: NiscalaSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(pattern.tenant.name, style: theme.textTheme.titleMedium),
                  if (pattern.atRisk)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // No label: the text next to it already says Berisiko.
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: NiscalaSpacing.xs),
                        Text(
                          'Berisiko',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: NiscalaSpacing.xs),
              Text('Kamar ${pattern.room.number}'),
              Text(
                'Tepat waktu ${pattern.onTimeCount} dari '
                '${pattern.countedBillCount} tagihan',
              ),
              Text('Rata-rata terlambat ${pattern.averageDaysLate} hari'),
              Text('Tunggakan ${formatRupiah(pattern.arrears)}'),
              const SizedBox(height: NiscalaSpacing.s),
              _summary(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// The summary with its AI disclaimer. A withheld summary is replaced by the
  /// subscription note, even when the response still carries its text.
  Widget _summary(ThemeData theme) {
    if (pattern.summaryWithheld) {
      return const Text('Ringkasan AI memerlukan langganan aktif.');
    }
    final summary = pattern.summary;
    if (summary == null) {
      return const Text('Ringkasan belum tersedia');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary),
        const SizedBox(height: NiscalaSpacing.xs),
        Text(
          'Ringkasan dibuat dengan AI dan bisa keliru.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
