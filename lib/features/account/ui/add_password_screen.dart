import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/google_button.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala_api/api.dart';

const _title = 'Tambah kata sandi';
const _introHeading = 'Konfirmasi dulu bahwa ini Anda';
const _googleLabel = 'Lanjutkan dengan Google';
const _passwordLabel = 'Kata sandi';
const _confirmLabel = 'Konfirmasi kata sandi';
const _submitLabel = 'Simpan kata sandi';
const _doneHeading = 'Kata sandi ditambahkan';
const _backToAccount = 'Kembali ke Akun';
const _emptyPassword = 'Kata sandi wajib diisi.';

/// The codes that send the user back to choose the Google account again.
const _googleCodes = {'GOOGLE_ACCOUNT_MISMATCH', 'GOOGLE_TOKEN_INVALID'};

enum _Step { intro, form, done }

/// Gives an account that signs in with Google only a local password. The user
/// first confirms the Google account it is linked to, then chooses the
/// password, which is sent once. The screen shows the result in place.
class AddPasswordScreen extends ConsumerStatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  ConsumerState<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends ConsumerState<AddPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// The ID token of the confirmed Google account. Null until one is chosen.
  String? _googleIdToken;
  var _added = false;
  var _busy = false;
  var _showPassword = false;
  String? _passwordError;
  String? _confirmError;
  String? _banner;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  _Step get _step => _added
      ? _Step.done
      : _googleIdToken == null
      ? _Step.intro
      : _Step.form;

  /// Asks Google for the account to confirm. Cancelling changes nothing; a
  /// failure is shown on the intro.
  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _banner = null;
    });
    try {
      final idToken = await ref.read(googleIdentityProvider).idToken();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _googleIdToken = idToken;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessageFor(error);
      });
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final password = _password.text;
    final passwordError = password.isEmpty
        ? _emptyPassword
        : newPasswordError(password);
    final confirmError = confirmPasswordError(password, _confirm.text);
    final valid = passwordError == null && confirmError == null;
    setState(() {
      _passwordError = passwordError;
      _confirmError = confirmError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      await ref
          .read(accountRepositoryProvider)
          .addLocalPassword(googleIdToken: _googleIdToken!, password: password);
      if (!mounted) return;
      ref.invalidate(meProvider);
      setState(() {
        _busy = false;
        _added = true;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  /// Shows a failure on the password field it names, or as a message at the
  /// form. A Google failure sends the user back to the Google step, where its
  /// message is shown.
  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure);
    final onPassword = failure.field == 'password';
    setState(() {
      _busy = false;
      _passwordError = onPassword ? message : null;
      _banner = onPassword ? null : message;
      if (_googleCodes.contains(failure.code)) _googleIdToken = null;
    });
  }

  void _leave() => context.go(accountTabPath(ref.read(currentRoleProvider)));

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(meProvider).value;
    final step = _step;
    final banner = _banner;
    return AuthPage(
      appBar: const DetailAppBar(title: _title),
      footer: step == _Step.form ? _formFooter() : null,
      children: [
        if (banner != null) ...[FormMessage(banner), formGap],
        ...switch (step) {
          _Step.intro => _introChildren(context, account),
          _Step.form => _formChildren(account),
          _Step.done => _doneChildren(),
        },
      ],
    );
  }

  List<Widget> _introChildren(BuildContext context, Account? account) {
    final theme = Theme.of(context);
    final email = account?.googleEmail;
    return [
      Semantics(
        header: true,
        child: Text(_introHeading, style: theme.textTheme.titleMedium),
      ),
      const SizedBox(height: 4),
      Text(
        'Pilih akun Google untuk memastikan ini Anda sebelum membuat kata '
        'sandi.',
        style: theme.textTheme.bodyMedium,
      ),
      if (email != null) ...[
        const SizedBox(height: 4),
        Text('Akun Google: $email', style: theme.textTheme.bodyMedium),
      ],
      formGap,
      GoogleButton(
        label: _googleLabel,
        onPressed: _busy ? null : _continueWithGoogle,
      ),
    ];
  }

  ActionFooter _formFooter() => ActionFooter(
    primary: BusyButton(label: _submitLabel, busy: _busy, onPressed: _submit),
    // The tile paints its own ink on the nearest Material, not on the footer's
    // coloured box.
    secondary: Material(
      type: MaterialType.transparency,
      child: ShowPasswordCheckbox(
        value: _showPassword,
        onChanged: (value) => setState(() => _showPassword = value),
      ),
    ),
  );

  List<Widget> _formChildren(Account? account) => [
    LabeledField(
      label: _passwordLabel,
      required: true,
      helper: newPasswordHelper,
      child: TextField(
        controller: _password,
        decoration: InputDecoration(errorText: _passwordError),
        obscureText: !_showPassword,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        onChanged: (_) => setState(() {}),
      ),
    ),
    PasswordStrengthHint(
      password: _password.text,
      name: account?.name ?? '',
      email: account?.email ?? '',
    ),
    formGap,
    LabeledField(
      label: _confirmLabel,
      required: true,
      child: TextField(
        controller: _confirm,
        decoration: InputDecoration(errorText: _confirmError),
        obscureText: !_showPassword,
        autofillHints: const [AutofillHints.newPassword],
      ),
    ),
  ];

  List<Widget> _doneChildren() => [
    const FormMessage(_doneHeading, isError: false),
    formGap,
    const Text('Sekarang Anda bisa masuk dengan email dan kata sandi.'),
    formGap,
    FilledButton(onPressed: _leave, child: const Text(_backToAccount)),
  ];
}
