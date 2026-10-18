import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/password_strength.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

const _maximumPasswordLength = 128;

class RegisterOwnerScreen extends ConsumerStatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  ConsumerState<RegisterOwnerScreen> createState() =>
      _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends ConsumerState<RegisterOwnerScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _banner;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final nameError = name.isEmpty ? 'Nama wajib diisi.' : null;
    final emailError = email.isEmpty
        ? 'Email wajib diisi.'
        : isValidEmail(email)
        ? null
        : 'Format email tidak valid.';
    final passwordError = password.length < 8
        ? 'Kata sandi minimal 8 karakter.'
        : password.length > _maximumPasswordLength
        ? 'Kata sandi maksimal $_maximumPasswordLength karakter.'
        : null;
    final confirmError = _confirm.text.isEmpty
        ? 'Ketik ulang kata sandi.'
        : _confirm.text != password
        ? 'Konfirmasi tidak sama dengan kata sandi.'
        : null;
    final valid =
        nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmError == null;
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .registerOwner(name: name, email: email, password: password);
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  void _showFailure(ApiFailure failure) {
    final message = errorMessage(failure.code);
    final field = switch (failure.code) {
      'EMAIL_ALREADY_REGISTERED' => 'email',
      'PASSWORD_TOO_COMMON' => 'password',
      _ => failure.field,
    };
    setState(() {
      _busy = false;
      switch (field) {
        case 'name':
          _nameError = message;
        case 'email':
          _emailError = message;
        case 'password':
          _passwordError = message;
        default:
          _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = passwordStrength(
      _password.text,
      name: _name.text,
      email: _email.text,
    );
    return AuthPage(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            semanticLabel: 'Kembali ke halaman masuk',
          ),
          onPressed: () => context.go('/masuk'),
        ),
        title: const Text('Daftar sebagai Pemilik Kost'),
      ),
      children: [
        if (_banner != null) ...[AuthMessage(_banner!), formGap],
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: 'Nama lengkap (wajib)',
            errorText: _nameError,
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
        ),
        formGap,
        TextField(
          controller: _email,
          decoration: InputDecoration(
            labelText: 'Email (wajib)',
            helperText:
                'Kode verifikasi dikirim ke email ini. Email juga dipakai '
                'untuk mengatur ulang kata sandi.',
            helperMaxLines: 4,
            errorText: _emailError,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() {}),
        ),
        formGap,
        TextField(
          controller: _password,
          decoration: InputDecoration(
            labelText: 'Kata sandi (wajib)',
            helperText:
                'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa '
                'aturan huruf atau simbol khusus.',
            helperMaxLines: 4,
            errorText: _passwordError,
          ),
          obscureText: !_showPassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Row(
            spacing: 4,
            children: [
              for (var i = 1; i <= 4; i++)
                Expanded(
                  child: SizedBox(
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: strength.index >= i
                            ? _strengthColor(theme.colorScheme, strength)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          liveRegion: true,
          child: Text(
            passwordStrengthText(
              _password.text,
              name: _name.text,
              email: _email.text,
            ),
          ),
        ),
        formGap,
        TextField(
          controller: _confirm,
          decoration: InputDecoration(
            labelText: 'Konfirmasi kata sandi (wajib)',
            errorText: _confirmError,
          ),
          obscureText: !_showPassword,
          autofillHints: const [AutofillHints.newPassword],
        ),
        ShowPasswordCheckbox(
          value: _showPassword,
          onChanged: (value) => setState(() => _showPassword = value),
        ),
        formGap,
        BusyButton(label: 'Daftar', busy: _busy, onPressed: _submit),
      ],
    );
  }
}

Color _strengthColor(ColorScheme scheme, PasswordStrength strength) =>
    switch (strength) {
      PasswordStrength.weak => scheme.error,
      PasswordStrength.fair => scheme.tertiary,
      _ => scheme.primary,
    };
