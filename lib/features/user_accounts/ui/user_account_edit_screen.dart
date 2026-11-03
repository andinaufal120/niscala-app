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
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala/features/user_accounts/data/user_account_repository.dart';
import 'package:niscala_api/api.dart';

const _nameRequired = 'Nama wajib diisi.';
const _emailNote =
    'Email baru berlaku setelah tautan yang dikirim ke alamat itu '
    'dikonfirmasi.';

/// Edits the name, email and status of the account [accountId]. The form is
/// prefilled from the account; saving goes back to its detail.
class UserAccountEditScreen extends ConsumerWidget {
  const UserAccountEditScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(userAccountDetailProvider(accountId));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Ubah Akun'),
      body: account.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(userAccountDetailProvider(accountId)),
        ),
        data: (account) => _EditForm(accountId: accountId, account: account),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.accountId, required this.account});

  final String accountId;
  final UserAccount account;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  late EditableAccountStatus _status;

  var _busy = false;
  String? _nameError;
  String? _emailError;
  String? _banner;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name.text = account.name;
    _email.text = account.email;
    _status = account.status == UserAccountStatus.active
        ? EditableAccountStatus.active
        : EditableAccountStatus.inactive;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final nameError = name.isEmpty ? _nameRequired : null;
    final emailError = signUpEmailError(email);
    final valid = nameError == null && emailError == null;
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      await ref
          .read(userAccountRepositoryProvider)
          .update(
            widget.accountId,
            UserAccountInput(name: name, email: email, status: _status),
          );
    } on ApiFailure catch (failure) {
      if (mounted) _showFailure(failure);
      return;
    }
    if (!mounted) return;
    ref.invalidate(userAccountDetailProvider(widget.accountId));
    ref.invalidate(userAccountListProvider);
    context.go('/admin/${widget.accountId}');
  }

  /// Shows a failure next to the field it belongs to, or as a banner that keeps
  /// what the user typed.
  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure);
    final field = failure.field;
    final onName = failure.code == 'VALIDATION_FAILED' && field == 'name';
    final onEmail =
        failure.code == 'EMAIL_ALREADY_REGISTERED' ||
        (failure.code == 'VALIDATION_FAILED' && field == 'email');
    setState(() {
      _busy = false;
      _nameError = onName ? message : null;
      _emailError = onEmail ? message : null;
      _banner = onName || onEmail ? null : message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_banner != null) ...[FormMessage(_banner!), formGap],
                LabeledField(
                  label: 'Nama lengkap',
                  required: true,
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(errorText: _nameError),
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Email',
                  required: true,
                  helper: _emailNote,
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(errorText: _emailError),
                  ),
                ),
                formGap,
                Semantics(
                  header: true,
                  child: Text('Status akun', style: theme.textTheme.titleSmall),
                ),
                RadioGroup<EditableAccountStatus>(
                  groupValue: _status,
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<EditableAccountStatus>(
                        value: EditableAccountStatus.active,
                        title: Text('Aktif'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<EditableAccountStatus>(
                        value: EditableAccountStatus.inactive,
                        title: Text('Nonaktif'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ActionFooter(
          primary: BusyButton(label: 'Simpan', busy: _busy, onPressed: _submit),
        ),
      ],
    );
  }
}
