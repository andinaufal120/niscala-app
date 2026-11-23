import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/reauth_dialog.dart';
import 'package:niscala/core/widgets/version_conflict.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

const _bankGroup = 'Rekening untuk transfer sewa (opsional)';
const _bankHelper =
    'Ditampilkan kepada penyewa properti ini saat membayar dengan transfer. '
    'Tanpa rekening, penyewa hanya bisa membayar tunai. Isi ketiga kolom, atau '
    'kosongkan semuanya.';
const _bankRequired = 'Wajib diisi jika rekening diisi.';

/// Adds a property when [propertyId] is null, and edits the property with that
/// id otherwise.
class PropertyFormScreen extends ConsumerWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  final String? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = propertyId;
    if (id == null) {
      return const _PropertyForm(propertyId: null, property: null);
    }
    return ref
        .watch(propertyDetailProvider(id))
        .when(
          skipLoadingOnReload: true,
          loading: () => _editPage(
            const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
            ),
          ),
          error: (error, _) => _editPage(
            ErrorView(
              message: errorMessageFor(error),
              onRetry: () => ref.invalidate(propertyDetailProvider(id)),
            ),
          ),
          data: (property) => _PropertyForm(propertyId: id, property: property),
        );
  }
}

Scaffold _editPage(Widget body) => Scaffold(
  appBar: const DetailAppBar(title: 'Ubah Properti'),
  body: body,
);

class _PropertyForm extends ConsumerStatefulWidget {
  const _PropertyForm({required this.propertyId, required this.property});

  final String? propertyId;
  final Property? property;

  @override
  ConsumerState<_PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends ConsumerState<_PropertyForm> {
  late final _name = TextEditingController(text: widget.property?.name);
  late final _address = TextEditingController(text: widget.property?.address);
  late final _bankName = TextEditingController(
    text: widget.property?.bankAccount?.bankName,
  );
  late final _accountNumber = TextEditingController(
    text: widget.property?.bankAccount?.accountNumber,
  );
  late final _holder = TextEditingController(
    text: widget.property?.bankAccount?.accountHolderName,
  );
  var _busy = false;
  String? _nameError;
  String? _addressError;
  String? _bankNameError;
  String? _accountNumberError;
  String? _holderError;
  String? _banner;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    final address = _address.text.trim();
    final bankName = _bankName.text.trim();
    final accountNumber = _accountNumber.text.trim();
    final holder = _holder.text.trim();
    final hasBank = [bankName, accountNumber, holder].any((v) => v.isNotEmpty);
    String? bankError(String value) =>
        hasBank && value.isEmpty ? _bankRequired : null;

    final nameError = name.isEmpty ? 'Nama properti wajib diisi.' : null;
    final addressError = address.isEmpty ? 'Alamat wajib diisi.' : null;
    final bankNameError = bankError(bankName);
    final accountNumberError = bankError(accountNumber);
    final holderError = bankError(holder);
    final valid = [
      nameError,
      addressError,
      bankNameError,
      accountNumberError,
      holderError,
    ].every((error) => error == null);
    setState(() {
      _nameError = nameError;
      _addressError = addressError;
      _bankNameError = bankNameError;
      _accountNumberError = accountNumberError;
      _holderError = holderError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    final input = PropertyInput(
      name: name,
      address: address,
      bankAccount: hasBank
          ? BankAccount(
              bankName: bankName,
              accountNumber: accountNumber,
              accountHolderName: holder,
            )
          : null,
    );
    var failure = await _attempt(input);
    if (failure?.code == 'REAUTHENTICATION_REQUIRED') {
      // The button is idle while the dialog waits for the password, so it
      // does not spin behind the dialog.
      if (mounted) setState(() => _busy = false);
      final reauthenticated = await showReauthDialog(context, ref);
      if (!reauthenticated || !mounted) return;
      setState(() => _busy = true);
      failure = await _attempt(input);
    }
    if (!mounted) return;
    if (failure == null) {
      _finish();
    } else if (isVersionConflict(failure)) {
      _refresh();
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      showVersionConflict(messenger, failure);
    } else {
      _showFailure(failure);
    }
  }

  /// Sends the add or the edit. Returns the failure, or null on success. An
  /// edit sends the version of the property it was loaded with.
  Future<ApiFailure?> _attempt(PropertyInput input) async {
    final repo = ref.read(propertyRepositoryProvider);
    final property = widget.property;
    try {
      if (property == null) {
        await repo.create(input);
      } else {
        await repo.update(property.id, input, version: property.version);
      }
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }

  void _refresh() {
    final id = widget.propertyId;
    ref.invalidate(propertyListProvider);
    if (id != null) ref.invalidate(propertyDetailProvider(id));
  }

  void _finish() {
    final id = widget.propertyId;
    _refresh();
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          id == null ? 'Properti ditambahkan' : 'Perubahan tersimpan',
        ),
      ),
    );
  }

  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure);
    setState(() {
      _busy = false;
      switch (failure.field) {
        case 'name':
          _nameError = message;
        case 'address':
          _addressError = message;
        case 'bankAccount.bankName':
          _bankNameError = message;
        case 'bankAccount.accountNumber':
          _accountNumberError = message;
        case 'bankAccount.accountHolderName':
          _holderError = message;
        default:
          _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loads the signed-in account, so that a re-authentication knows whether
    // the account has a password.
    ref.watch(myAccountProvider);
    final isEdit = widget.propertyId != null;
    return Scaffold(
      appBar: DetailAppBar(title: isEdit ? 'Ubah Properti' : 'Tambah Properti'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NiscalaSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_banner != null) ...[FormMessage(_banner!), formGap],
                  LabeledField(
                    label: 'Nama properti',
                    required: true,
                    child: TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Kos Melati',
                        errorText: _nameError,
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  formGap,
                  LabeledField(
                    label: 'Alamat',
                    required: true,
                    child: TextField(
                      controller: _address,
                      decoration: InputDecoration(
                        hintText: 'Jalan, nomor, kelurahan, kota',
                        errorText: _addressError,
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  formGap,
                  Semantics(
                    header: true,
                    container: true,
                    child: Text(
                      _bankGroup,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: NiscalaSpacing.s),
                  Text(
                    _bankHelper,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  formGap,
                  LabeledField(
                    label: 'Nama bank',
                    child: TextField(
                      controller: _bankName,
                      decoration: InputDecoration(errorText: _bankNameError),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  formGap,
                  LabeledField(
                    label: 'Nomor rekening',
                    child: TextField(
                      controller: _accountNumber,
                      decoration: InputDecoration(
                        errorText: _accountNumberError,
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  formGap,
                  LabeledField(
                    label: 'Nama pemilik rekening',
                    child: TextField(
                      controller: _holder,
                      decoration: InputDecoration(errorText: _holderError),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ActionFooter(
            primary: BusyButton(
              label: isEdit ? 'Simpan Perubahan' : 'Simpan Properti',
              busy: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
