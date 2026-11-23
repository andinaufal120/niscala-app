import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/google_button.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';

/// Asks the signed-in user to confirm their identity. Resolves to true once the
/// user has re-authenticated, and to false when they cancel. An account without
/// a password confirms with Google; while the account is not known, the
/// password dialog is shown.
Future<bool> showReauthDialog(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(accountRepositoryProvider);
  final hasPassword = ref.read(myAccountProvider).value?.hasPassword ?? true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => hasPassword
        ? _ReauthDialog(reauthenticate: repository.reauthenticateWithPassword)
        : _GoogleReauthDialog(
            identity: ref.read(googleIdentityProvider),
            reauthenticate: repository.reauthenticateWithGoogle,
          ),
  );
  return confirmed ?? false;
}

/// Confirms the user with a Google account. Pops true once it is accepted, false
/// when the user cancels. A failure keeps the dialog open with its message.
class _GoogleReauthDialog extends StatefulWidget {
  const _GoogleReauthDialog({
    required this.identity,
    required this.reauthenticate,
  });

  final GoogleIdentity identity;
  final Future<void> Function(String idToken) reauthenticate;

  @override
  State<_GoogleReauthDialog> createState() => _GoogleReauthDialogState();
}

class _GoogleReauthDialogState extends State<_GoogleReauthDialog> {
  var _busy = false;
  String? _banner;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _banner = null;
      _busy = true;
    });
    try {
      final idToken = await widget.identity.idToken();
      if (idToken == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await widget.reauthenticate(idToken);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessageFor(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Konfirmasi akun'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pilih akun Google Anda untuk melanjutkan.'),
          if (_banner != null) ...[formGap, FormMessage(_banner!)],
          formGap,
          GoogleButton(
            label: 'Lanjutkan dengan Google',
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
      ],
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
        _banner = errorMessageFor(failure);
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
