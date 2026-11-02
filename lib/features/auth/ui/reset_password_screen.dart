import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/link_token.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

const _invalidLink = 'Tautan tidak valid.';
const _linkHelper = 'Tempel tautan atur ulang dari email Anda.';
const _passwordHelper =
    'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa aturan huruf '
    'atau simbol khusus.';
const _mismatch = 'Konfirmasi tidak sama dengan kata sandi baru.';

/// The codes of a link that cannot be used any more. They send the user back
/// to the link step, where a new link can be requested.
const _linkCodes = {
  'PASSWORD_RESET_NOT_FOUND',
  'PASSWORD_RESET_USED',
  'PASSWORD_RESET_EXPIRED',
};

/// Sets a new password from a pasted password-reset link. The link is checked
/// first; the new password is then typed twice. Success does not sign the user
/// in.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _link = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  var _done = false;
  var _linkFailed = false;
  String? _linkError;
  String? _passwordError;
  String? _confirmError;
  String? _banner;

  /// The checked link and the email of its account, once the link is valid.
  ({String token, String email})? _verified;

  @override
  void dispose() {
    _link.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _checkLink() async {
    if (_busy) return;
    final token = tokenFromQueryLink(_link.text);
    if (token == null) {
      setState(() => _linkError = _invalidLink);
      return;
    }
    setState(() {
      _linkError = null;
      _banner = null;
      _linkFailed = false;
      _busy = true;
    });
    try {
      final email = await ref
          .read(authRepositoryProvider)
          .previewPasswordReset(token);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _verified = (token: token, email: email);
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _linkFailed = _linkCodes.contains(failure.code);
        _banner = errorMessageFor(failure);
      });
    }
  }

  Future<void> _submit() async {
    final token = _verified?.token;
    if (_busy || token == null) return;
    final password = _password.text;
    final confirmation = _confirm.text;
    final passwordError = password.isEmpty
        ? 'Kata sandi baru wajib diisi.'
        : newPasswordError(password);
    final confirmError = confirmation.isEmpty
        ? 'Ketik ulang kata sandi baru.'
        : confirmation != password
        ? _mismatch
        : null;
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
          .read(authRepositoryProvider)
          .resetPassword(token: token, newPassword: password);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  /// Shows a failure where it belongs: a dead link goes back to the link step,
  /// a password failure goes on the password field, and anything else is a
  /// banner that keeps the typed values.
  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure);
    final onPassword =
        failure.code == 'PASSWORD_TOO_COMMON' ||
        (failure.code == 'VALIDATION_FAILED' && failure.field == 'newPassword');
    setState(() {
      _busy = false;
      if (_linkCodes.contains(failure.code)) {
        _verified = null;
        _linkFailed = true;
        _passwordError = null;
        _confirmError = null;
        _banner = message;
      } else if (onPassword) {
        _passwordError = message;
        _banner = null;
      } else {
        _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = _verified;
    return AuthPage(
      appBar: DetailAppBar(
        title: 'Atur ulang kata sandi',
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/masuk'),
        ),
      ),
      children: _done
          ? _result(theme)
          : verified == null
          ? _linkStep()
          : _passwordStep(theme, verified.email),
    );
  }

  List<Widget> _linkStep() => [
    if (_banner != null) ...[FormMessage(_banner!), formGap],
    if (_linkFailed) ...[
      OutlinedButton(
        onPressed: () => context.go('/lupa-kata-sandi'),
        child: const Text('Minta Tautan Baru'),
      ),
      formGap,
    ],
    LabeledField(
      label: 'Tautan atur ulang',
      required: true,
      helper: _linkHelper,
      child: TextField(
        controller: _link,
        decoration: InputDecoration(errorText: _linkError),
        keyboardType: TextInputType.url,
        autocorrect: false,
      ),
    ),
    formGap,
    BusyButton(label: 'Lanjut', busy: _busy, onPressed: _checkLink),
  ];

  List<Widget> _passwordStep(ThemeData theme, String email) => [
    if (_banner != null) ...[FormMessage(_banner!), formGap],
    Text('Untuk akun $email', style: theme.textTheme.bodyMedium),
    formGap,
    LabeledField(
      label: 'Kata sandi baru',
      required: true,
      helper: _passwordHelper,
      child: TextField(
        controller: _password,
        decoration: InputDecoration(errorText: _passwordError),
        obscureText: !_showPassword,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        onChanged: (_) => setState(() {}),
      ),
    ),
    PasswordStrengthHint(password: _password.text, name: '', email: email),
    formGap,
    LabeledField(
      label: 'Konfirmasi kata sandi baru',
      required: true,
      child: TextField(
        controller: _confirm,
        decoration: InputDecoration(errorText: _confirmError),
        obscureText: !_showPassword,
        autofillHints: const [AutofillHints.newPassword],
      ),
    ),
    ShowPasswordCheckbox(
      value: _showPassword,
      onChanged: (value) => setState(() => _showPassword = value),
    ),
    formGap,
    BusyButton(label: 'Simpan Kata Sandi', busy: _busy, onPressed: _submit),
  ];

  List<Widget> _result(ThemeData theme) => [
    Semantics(
      header: true,
      child: Text('Kata sandi diperbarui', style: theme.textTheme.titleLarge),
    ),
    const SizedBox(height: 8),
    Text(
      'Semua perangkat yang masuk ke akun ini telah dikeluarkan. Masuk lagi '
      'dengan kata sandi baru Anda.',
      style: theme.textTheme.bodyLarge,
    ),
    formGap,
    FilledButton(
      onPressed: () => context.go('/masuk'),
      child: const Text('Masuk'),
    ),
  ];
}
