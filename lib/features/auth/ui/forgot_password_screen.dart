import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

/// Asks for a password-reset link. The confirmation does not repeat the email
/// and does not tell whether the email belongs to an account.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  var _busy = false;
  var _sent = false;
  String? _emailError;
  String? _banner;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final emailError = signUpEmailError(email);
    setState(() {
      _emailError = emailError;
      _banner = null;
      _busy = emailError == null;
    });
    if (emailError != null) return;

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _sent = true;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      final message = errorMessageFor(failure);
      final onEmail =
          failure.code == 'VALIDATION_FAILED' && failure.field == 'email';
      setState(() {
        _busy = false;
        _emailError = onEmail ? message : null;
        _banner = onEmail ? null : message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthPage(
      appBar: DetailAppBar(
        title: 'Lupa kata sandi',
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/masuk'),
        ),
      ),
      children: _sent ? _confirmation(theme) : _form(),
    );
  }

  List<Widget> _form() => [
    if (_banner != null) ...[FormMessage(_banner!), formGap],
    LabeledField(
      label: 'Email',
      required: true,
      child: TextField(
        controller: _email,
        decoration: InputDecoration(errorText: _emailError),
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
    ),
    formGap,
    BusyButton(label: 'Kirim Tautan', busy: _busy, onPressed: _submit),
  ];

  List<Widget> _confirmation(ThemeData theme) => [
    Semantics(
      header: true,
      child: Text('Periksa email Anda', style: theme.textTheme.titleLarge),
    ),
    const SizedBox(height: 8),
    Text(
      'Jika email terdaftar, kami sudah mengirim tautan atur ulang kata '
      'sandi. Tautan berlaku 30 menit.',
      style: theme.textTheme.bodyLarge,
    ),
    formGap,
    FilledButton(
      onPressed: () => context.go('/atur-ulang-kata-sandi'),
      child: const Text('Atur ulang dengan tautan'),
    ),
    const SizedBox(height: 8),
    OutlinedButton(
      onPressed: () => context.go('/masuk'),
      child: const Text('Kembali ke Masuk'),
    ),
  ];
}
