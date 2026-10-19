import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

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
  appBar: AppBar(title: const Text('Ubah Properti')),
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
      final reauthenticated = await _askForPassword();
      if (!reauthenticated || !mounted) return;
      setState(() => _busy = true);
      failure = await _attempt(input);
    }
    if (!mounted) return;
    if (failure == null) {
      _finish();
    } else {
      _showFailure(failure);
    }
  }

  /// Sends the add or the edit. Returns the failure, or null on success.
  Future<ApiFailure?> _attempt(PropertyInput input) async {
    final repo = ref.read(propertyRepositoryProvider);
    final id = widget.propertyId;
    try {
      if (id == null) {
        await repo.create(input);
      } else {
        await repo.update(id, input);
      }
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }

  void _finish() {
    final id = widget.propertyId;
    ref.invalidate(propertyListProvider);
    if (id != null) ref.invalidate(propertyDetailProvider(id));
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

  /// Resolves to true once the password dialog has re-authenticated the user.
  Future<bool> _askForPassword() async {
    final reauthenticate = ref
        .read(propertyRepositoryProvider)
        .reauthenticateWithPassword;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ReauthDialog(reauthenticate: reauthenticate),
    );
    return confirmed ?? false;
  }

  void _showFailure(ApiFailure failure) {
    final message = errorMessage(failure.code);
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
    final isEdit = widget.propertyId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Ubah Properti' : 'Tambah Properti')),
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
                  SectionCard(
                    title: 'Rekening untuk transfer sewa (opsional)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _bankHelper,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        formGap,
                        LabeledField(
                          label: 'Nama bank',
                          child: TextField(
                            controller: _bankName,
                            decoration: InputDecoration(
                              errorText: _bankNameError,
                            ),
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
                            decoration: InputDecoration(
                              errorText: _holderError,
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
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

/// Asks for the password again. Pops true once it is accepted, false when the
/// user cancels. A wrong password keeps the dialog open with the message.
class _ReauthDialog extends StatefulWidget {
  const _ReauthDialog({required this.reauthenticate});

  final Future<void> Function(String password) reauthenticate;

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _password = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  String? _passwordError;
  String? _banner;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _passwordError = null;
      _banner = null;
      _busy = true;
    });
    try {
      await widget.reauthenticate(password);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessage(failure.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Konfirmasi kata sandi'),
      content: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Masukkan kata sandi Anda untuk melanjutkan.'),
            if (_banner != null) ...[formGap, FormMessage(_banner!)],
            formGap,
            LabeledField(
              label: 'Kata sandi',
              required: true,
              child: TextField(
                controller: _password,
                decoration: InputDecoration(errorText: _passwordError),
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.password],
              ),
            ),
            ShowPasswordCheckbox(
              value: _showPassword,
              onChanged: (value) => setState(() => _showPassword = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }
}
