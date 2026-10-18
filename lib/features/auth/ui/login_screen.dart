import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _banner;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    final emailError = email.isEmpty
        ? 'Masukkan email.'
        : isValidEmail(email)
        ? null
        : 'Format email tidak valid.';
    final passwordError = password.isEmpty ? 'Masukkan kata sandi.' : null;
    final valid = emailError == null && passwordError == null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _banner = errorMessage(failure.code);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthPage(
      children: [
        Semantics(
          header: true,
          child: Text('Masuk ke Niscala', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 4),
        Text('Kelola Kost Tanpa Ribet', style: theme.textTheme.bodyLarge),
        formGap,
        if (_banner != null) ...[AuthMessage(_banner!), formGap],
        TextField(
          controller: _email,
          decoration: InputDecoration(
            labelText: 'Email (wajib)',
            errorText: _emailError,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        formGap,
        TextField(
          controller: _password,
          decoration: InputDecoration(
            labelText: 'Kata sandi (wajib)',
            errorText: _passwordError,
          ),
          obscureText: !_showPassword,
          autofillHints: const [AutofillHints.password],
        ),
        ShowPasswordCheckbox(
          value: _showPassword,
          onChanged: (value) => setState(() => _showPassword = value),
        ),
        formGap,
        BusyButton(label: 'Masuk', busy: _busy, onPressed: _submit),
        formGap,
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Pemilik kost baru?'),
            TextButton(
              onPressed: () => context.go('/daftar'),
              child: const Text('Daftar'),
            ),
          ],
        ),
      ],
    );
  }
}
