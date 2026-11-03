import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/tappable_date_field.dart';
import 'package:niscala/features/rent_bills/data/management_rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala/features/rent_bills/payment_labels.dart';
import 'package:niscala_api/api.dart';

const _confirmRequired = 'Centang bahwa Anda sudah menerima uang tunai.';
const _noPayable = 'Tidak ada tagihan yang menunggu pembayaran.';

/// The field that the API names when it rejects the date received.
const _receivedOnField = 'receivedOn';

/// Records a cash payment of one bill that is unpaid or rejected. The tenant is
/// chosen first, then the bill; a tenant with a single payable bill has it
/// chosen at once. A [billId] given beforehand is chosen as soon as the bills
/// are loaded.
///
/// The bills are reloaded after a conflict, and the screen pops once the
/// payment is recorded.
class CashPaymentScreen extends ConsumerStatefulWidget {
  const CashPaymentScreen({super.key, required this.propertyId, this.billId});

  /// The property of the bills, from the `properti` query parameter. Null when
  /// the link has none, in which case no bills can be asked for.
  final String? propertyId;

  /// The bill chosen beforehand, from the `tagihan` query parameter.
  final String? billId;

  @override
  ConsumerState<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends ConsumerState<CashPaymentScreen> {
  final _receivedOnText = TextEditingController();

  /// The day the money was received. Starts at today and is never later.
  var _receivedOn = _today();
  String? _tenantId;
  String? _billId;
  var _confirmed = false;

  /// Set while the payment is sent, so that a second tap sends nothing.
  var _saving = false;
  String? _banner;
  String? _dateError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _billId = widget.billId;
    _receivedOnText.text = formatDate(_receivedOn);
  }

  @override
  void dispose() {
    _receivedOnText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.propertyId;
    return Scaffold(
      appBar: const DetailAppBar(title: 'Catat Pembayaran Tunai'),
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
          : _payableBills(propertyId),
    );
  }

  Widget _payableBills(String propertyId) {
    final bills = ref.watch(payableRentBillsProvider(propertyId));
    return bills.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
      error: (error, _) => ErrorView(
        message: errorMessageFor(error),
        onRetry: () => ref.invalidate(payableRentBillsProvider(propertyId)),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(message: _noPayable)
          : _content(items, propertyId),
    );
  }

  /// The tenants of [items] while no tenant is chosen, otherwise the bills of
  /// the chosen tenant and the form for the chosen bill.
  Widget _content(List<RentBillSummary> items, String propertyId) {
    final preselected = items.where((bill) => bill.id == _billId);
    final tenantId =
        _tenantId ?? (preselected.isEmpty ? null : preselected.first.tenant.id);
    final tenantBills = [
      for (final bill in items)
        if (bill.tenant.id == tenantId) bill,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_banner != null) ...[FormMessage(_banner!), formGap],
          if (tenantBills.isEmpty)
            ..._tenantRows(items)
          else
            ..._billRows(tenantBills, propertyId),
        ],
      ),
    );
  }

  /// One row for each tenant, in the order the API returns their bills.
  List<Widget> _tenantRows(List<RentBillSummary> items) {
    final firstBills = <String, RentBillSummary>{};
    for (final bill in items) {
      firstBills.putIfAbsent(bill.tenant.id, () => bill);
    }
    return [
      for (final bill in firstBills.values) ...[
        _TenantRow(
          bill: bill,
          onTap: () => setState(() {
            _tenantId = bill.tenant.id;
            _billId = null;
          }),
        ),
        const SizedBox(height: NiscalaSpacing.s),
      ],
    ];
  }

  /// The bills of the chosen tenant, and the form once one bill is chosen. A
  /// tenant with a single bill has that bill chosen.
  List<Widget> _billRows(List<RentBillSummary> tenantBills, String propertyId) {
    final tenant = tenantBills.first;
    RentBillSummary? chosen;
    for (final bill in tenantBills) {
      if (bill.id == _billId) chosen = bill;
    }
    if (chosen == null && tenantBills.length == 1) chosen = tenantBills.single;
    return [
      Semantics(
        header: true,
        child: Text(
          tenant.tenant.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      Text('Kamar ${tenant.room.number}'),
      const SizedBox(height: NiscalaSpacing.s),
      for (final bill in tenantBills) ...[
        _BillRow(
          bill: bill,
          selected: bill.id == chosen?.id,
          onTap: () => setState(() => _billId = bill.id),
        ),
        const SizedBox(height: NiscalaSpacing.s),
      ],
      if (chosen != null) ...[
        const SizedBox(height: NiscalaSpacing.m),
        ..._form(chosen.id, propertyId),
      ],
    ];
  }

  List<Widget> _form(String billId, String propertyId) => [
    TappableDateField(
      label: 'Tanggal diterima',
      required: true,
      controller: _receivedOnText,
      onTap: _pickDate,
      errorText: _dateError,
    ),
    formGap,
    CheckboxListTile(
      value: _confirmed,
      onChanged: (value) => setState(() => _confirmed = value ?? false),
      title: const Text('Saya sudah menerima uang tunai'),
      controlAffinity: ListTileControlAffinity.leading,
    ),
    if (_confirmError != null) ...[FormMessage(_confirmError!), formGap],
    BusyButton(
      label: 'Simpan Pembayaran',
      busy: _saving,
      onPressed: () => _submit(billId, propertyId),
    ),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: DateTime(2000),
      lastDate: _today(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _receivedOn = picked;
      _receivedOnText.text = formatDate(picked);
    });
  }

  /// Records the payment of [billId]. A failure on the date is shown on the
  /// date field, any other on a banner; the form keeps what was entered. A
  /// conflict also reloads the bills, so the list shows what is still payable.
  Future<void> _submit(String billId, String propertyId) async {
    if (_saving) return;
    if (!_confirmed) {
      setState(() => _confirmError = _confirmRequired);
      return;
    }
    setState(() {
      _saving = true;
      _banner = null;
      _dateError = null;
      _confirmError = null;
    });
    try {
      await ref
          .read(managementRentBillRepositoryProvider)
          .recordCashPayment(billId, _receivedOn);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      final message = errorMessageFor(failure);
      setState(() {
        _saving = false;
        if (failure.field == _receivedOnField) {
          _dateError = message;
        } else {
          _banner = message;
        }
      });
      if (failure.statusCode == 409) {
        ref.invalidate(payableRentBillsProvider(propertyId));
      }
      return;
    }
    if (!mounted) return;
    ref.invalidate(rentBillDetailProvider(billId));
    ref.invalidate(tenantRentBillsProvider);
    ref.invalidate(awaitingVerificationProvider);
    ref.invalidate(paymentOverviewProvider);
    ref.invalidate(payableRentBillsProvider(propertyId));
    context.pop();
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// A tenant of the property, with the room. Chooses the tenant.
class _TenantRow extends StatelessWidget {
  const _TenantRow({required this.bill, required this.onTap});

  /// Any bill of the tenant, which gives the name and the room.
  final RentBillSummary bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: onTap,
          title: Text(bill.tenant.name),
          subtitle: Text('Kamar ${bill.room.number}'),
        ),
      ),
    );
  }
}

/// One bill of the chosen tenant. Chooses the bill; [selected] shows which one
/// is chosen.
class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.bill,
    required this.selected,
    required this.onTap,
  });

  final RentBillSummary bill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: MergeSemantics(
        child: ListTile(
          selected: selected,
          onTap: onTap,
          title: Text(
            formatRupiah(bill.amount),
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDate(bill.periodStart)} - '
                '${formatDate(bill.periodEnd)}',
              ),
              Text(
                'Jatuh tempo ${formatDate(bill.dueDate)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: NiscalaSpacing.xs),
              PaymentBadge(bill.payment.status),
            ],
          ),
        ),
      ),
    );
  }
}
