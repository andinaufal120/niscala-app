import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala/features/rent_bills/data/rent_bill_repository.dart';
import 'package:niscala_api/api.dart';

const _maxBytes = 5 * 1024 * 1024;
const _chooseFirst = 'Pilih bukti transfer terlebih dahulu.';
const _sentMessage = 'Bukti transfer terkirim.';
const _typeInvalid = ApiFailure(code: 'RECEIPT_TYPE_INVALID');
const _tooLarge = ApiFailure(code: 'RECEIPT_TOO_LARGE');

/// Codes of a failed upload that belong next to the file; any other failure
/// is shown in a banner.
const _fileFailures = {'RECEIPT_TYPE_INVALID', 'RECEIPT_TOO_LARGE'};

/// Sends the transfer receipt of one bill. A bill that cannot be uploaded to
/// only shows the amount and tells the tenant to pay cash.
class UploadReceiptScreen extends ConsumerStatefulWidget {
  const UploadReceiptScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<UploadReceiptScreen> createState() =>
      _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends ConsumerState<UploadReceiptScreen> {
  ReceiptFile? _file;
  String? _fileError;
  String? _banner;
  var _busy = false;

  /// Set when the API says the bill changed, so the list is stale.
  var _stale = false;

  Future<void> _pick(ReceiptSource source) async {
    final file = await ref.read(receiptPickerProvider).pick(source);
    if (file == null || !mounted) return;
    final failure = receiptMediaType(file.bytes) == null
        ? _typeInvalid
        : file.bytes.length > _maxBytes
        ? _tooLarge
        : null;
    setState(() {
      _file = failure == null ? file : null;
      _fileError = failure == null ? null : errorMessageFor(failure);
    });
  }

  Future<void> _submit() async {
    final file = _file;
    if (_busy) return;
    if (file == null) {
      setState(() => _fileError = _chooseFirst);
      return;
    }
    setState(() {
      _busy = true;
      _banner = null;
      _fileError = null;
    });
    try {
      await ref
          .read(rentBillRepositoryProvider)
          .uploadReceipt(widget.billId, file);
      if (!mounted) return;
      ref.invalidate(activeRentBillsProvider);
      ref.invalidate(rentBillDetailProvider(widget.billId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_sentMessage)));
      context.go('/penyewa/pembayaran');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      final message = errorMessageFor(failure);
      setState(() {
        _busy = false;
        _stale = failure.statusCode == 409;
        if (failure.field == 'file' || _fileFailures.contains(failure.code)) {
          _fileError = message;
        } else {
          _banner = message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = ref.watch(rentBillDetailProvider(widget.billId));
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _stale) ref.invalidate(activeRentBillsProvider);
      },
      child: Scaffold(
        appBar: const DetailAppBar(title: 'Unggah Bukti'),
        body: bill.when(
          skipLoadingOnReload: true,
          loading: () => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
          ),
          error: (error, _) => ErrorView(
            message: errorMessageFor(error),
            onRetry: () =>
                ref.invalidate(rentBillDetailProvider(widget.billId)),
          ),
          data: _details,
        ),
      ),
    );
  }

  Widget _details(RentBill bill) {
    final account = bill.bankAccount;
    final theme = Theme.of(context);
    final canUpload = bill.canUploadReceipt && account != null;
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_banner != null) ...[FormMessage(_banner!), formGap],
          SectionCard(
            title: 'Tagihan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatRupiah(bill.amount),
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  '${formatDate(bill.periodStart)} - '
                  '${formatDate(bill.periodEnd)}',
                ),
                Text(
                  'Jatuh tempo ${formatDate(bill.dueDate)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (canUpload)
                  _CopyButton(label: 'Salin jumlah', text: '${bill.amount}'),
              ],
            ),
          ),
          formGap,
          if (account == null || !bill.canUploadReceipt)
            const Text(
              'Transfer tidak tersedia untuk tagihan ini. '
              'Bayar tunai ke pengelola kost.',
            )
          else ...[
            SectionCard(
              title: 'Rekening tujuan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.bankName, style: theme.textTheme.titleMedium),
                  Text(account.accountNumber),
                  Text(account.accountHolderName),
                  _CopyButton(
                    label: 'Salin nomor rekening',
                    text: account.accountNumber,
                  ),
                ],
              ),
            ),
            formGap,
            SectionCard(
              title: 'Bukti transfer',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ReceiptSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Ambil dari kamera'),
                  ),
                  const SizedBox(height: NiscalaSpacing.s),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _pick(ReceiptSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pilih dari galeri'),
                  ),
                  if (_file != null) ...[
                    const SizedBox(height: NiscalaSpacing.s),
                    Text(_file!.name),
                  ],
                  if (_fileError != null) ...[
                    const SizedBox(height: NiscalaSpacing.s),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _fileError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
    return Column(
      children: [
        Expanded(child: body),
        if (canUpload)
          ActionFooter(
            primary: BusyButton(
              label: 'Kirim Bukti',
              busy: _busy,
              onPressed: _submit,
            ),
          ),
      ],
    );
  }
}

/// A button that puts [text] on the clipboard.
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Clipboard.setData(ClipboardData(text: text)),
      icon: const Icon(Icons.copy_outlined),
      label: Text(label),
    );
  }
}
