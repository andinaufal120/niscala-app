import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/filter_chip_row.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

/// The payment status of every tenant of one property on one day. The filter
/// works on the loaded list and never sends a request.
class PaymentOverviewScreen extends ConsumerStatefulWidget {
  const PaymentOverviewScreen({super.key});

  @override
  ConsumerState<PaymentOverviewScreen> createState() =>
      _PaymentOverviewScreenState();
}

class _PaymentOverviewScreenState extends ConsumerState<PaymentOverviewScreen> {
  /// The property the user chose. Null means the first property.
  String? _propertyId;

  /// The calendar day the bills cover.
  var _date = _today();

  /// Whether only the tenants whose bill is not paid are listed.
  var _unpaidOnly = true;

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertyListProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Pembayaran'),
          Expanded(
            child: properties.when(
              skipLoadingOnReload: true,
              loading: _loading,
              error: (error, _) => ErrorView(
                message: errorMessageFor(error),
                onRetry: () => ref.invalidate(propertyListProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    message: 'Belum ada properti. Tambahkan properti terlebih dahulu.',
                  );
                }
                final property = list.firstWhere(
                  (p) => p.id == _propertyId,
                  orElse: () => list.first,
                );
                return _overview(list, property);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The property chooser, date control and entries above the tenants of
  /// [property]. The header and the list scroll together, so every entry stays
  /// reachable at large text sizes.
  Widget _overview(List<PropertySummary> properties, PropertySummary property) {
    final theme = Theme.of(context);
    final request = (propertyId: property.id, date: _date);
    final overview = ref.watch(paymentOverviewProvider(request));
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              NiscalaSpacing.gutter,
              NiscalaSpacing.s,
              NiscalaSpacing.gutter,
              NiscalaSpacing.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Properti', style: theme.textTheme.labelMedium),
                const SizedBox(height: NiscalaSpacing.xs),
                OutlinedButton(
                  onPressed: () => _chooseProperty(properties, property),
                  child: Text(property.name),
                ),
                const SizedBox(height: NiscalaSpacing.m),
                ExcludeSemantics(
                  child: Text('Tanggal', style: theme.textTheme.labelMedium),
                ),
                const SizedBox(height: NiscalaSpacing.xs),
                // The visible text is the date alone, so the spoken label starts
                // with it, as the label-in-name rule asks.
                Semantics(
                  button: true,
                  label: '${formatDate(_date)}, Tanggal',
                  onTap: _pickDate,
                  child: ExcludeSemantics(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(formatDate(_date)),
                    ),
                  ),
                ),
                const SizedBox(height: NiscalaSpacing.m),
                FilterChipRow(
                  chips: [
                    ChoiceChip(
                      label: const Text('Belum lunas'),
                      selected: _unpaidOnly,
                      onSelected: (_) => setState(() => _unpaidOnly = true),
                    ),
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: !_unpaidOnly,
                      onSelected: (_) => setState(() => _unpaidOnly = false),
                    ),
                  ],
                ),
                const SizedBox(height: NiscalaSpacing.s),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/pembayaran/verifikasi?properti=${property.id}',
                  ),
                  child: const Text('Menunggu Verifikasi'),
                ),
                const SizedBox(height: NiscalaSpacing.s),
                OutlinedButton(
                  onPressed: () =>
                      context.push('/pembayaran/tunai?properti=${property.id}'),
                  child: const Text('Catat Pembayaran Tunai'),
                ),
                const SizedBox(height: NiscalaSpacing.s),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/pembayaran/risiko?properti=${property.id}',
                  ),
                  child: const Text('Risiko Pembayaran'),
                ),
              ],
            ),
          ),
        ),
        overview.when(
          skipLoadingOnReload: true,
          loading: () => _fill(_loading()),
          error: (error, _) => _fill(
            ErrorView(
              message: errorMessageFor(error),
              onRetry: () => ref.invalidate(paymentOverviewProvider(request)),
            ),
          ),
          data: (payments) => _rows(payments.items, property.id),
        ),
      ],
    );
  }

  Widget _rows(List<PaymentOverviewItem> items, String propertyId) {
    if (items.isEmpty) {
      return _fill(
        const EmptyState(message: 'Belum ada penyewa di properti ini.'),
      );
    }
    final shown = [
      for (final item in items)
        if (!_unpaidOnly || _isUnpaid(item)) item,
    ];
    if (shown.isEmpty) {
      return _fill(
        const EmptyState(
          message: 'Tidak ada tagihan yang belum lunas pada tanggal ini.',
        ),
      );
    }
    // Every row is built, not only those near the viewport, so each one can be
    // reached at large text sizes.
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NiscalaSpacing.gutter,
          NiscalaSpacing.xs,
          NiscalaSpacing.gutter,
          NiscalaSpacing.gutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in shown) ...[
              _PaymentRow(item: item, propertyId: propertyId),
              const SizedBox(height: NiscalaSpacing.s),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _chooseProperty(
    List<PropertySummary> properties,
    PropertySummary current,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(NiscalaSpacing.l),
              child: Semantics(
                header: true,
                child: Text(
                  'Pilih properti',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
            ),
            for (final property in properties)
              ListTile(
                title: Text(property.name),
                selected: property.id == current.id,
                onTap: () => Navigator.of(sheetContext).pop(property.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _propertyId = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }
}

Widget _loading() =>
    const Center(child: CircularProgressIndicator(semanticsLabel: 'Memuat'));

/// A sliver that fills the rest of the scrolling area with [child], for the
/// states that take the place of the list.
Widget _fill(Widget child) =>
    SliverFillRemaining(hasScrollBody: false, child: child);

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Whether the tenant has a bill and the bill is not paid.
bool _isUnpaid(PaymentOverviewItem item) {
  final bill = item.bill;
  return bill != null && bill.payment.status != PaymentStatus.paid;
}

/// One tenant: the room, the bill of the day and its status, or a note when
/// the tenant has no bill on the day. Opens the tenant's payment history.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.item, required this.propertyId});

  final PaymentOverviewItem item;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bill = item.bill;
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.push(
            '/pembayaran/penyewa/${item.tenant.id}?properti=$propertyId',
          ),
          title: Text(item.tenant.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kamar ${item.room.number}'),
              const SizedBox(height: NiscalaSpacing.xs),
              if (bill == null)
                const Text('Tidak ada tagihan pada tanggal ini')
              else
                Wrap(
                  spacing: NiscalaSpacing.s,
                  runSpacing: NiscalaSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatRupiah(bill.amount),
                      style: theme.textTheme.titleMedium,
                    ),
                    PaymentBadge(bill.payment.status),
                  ],
                ),
              if (bill != null && bill.daysOverdue > 0)
                Text(
                  '${bill.daysOverdue} hari terlambat',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
