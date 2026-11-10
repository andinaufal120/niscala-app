import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/google_button.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

/// Shown for a Google account that has no Niscala account yet. The password
/// wording would suggest a mistyped password.
const _googleAccountNotRegistered =
    'Akun Google ini belum terdaftar. Daftar atau aktifkan akun lewat tautan '
    'undangan dulu.';

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
      // A validation failure on the email or the password is shown next to
      // that field. Any other failure is shown in the banner.
      final field = failure.code == 'VALIDATION_FAILED' ? failure.field : null;
      final message = errorMessageFor(failure);
      setState(() {
        _emailError = field == 'email' ? message : null;
        _passwordError = field == 'password' ? message : null;
        _banner = field == 'email' || field == 'password' ? null : message;
        _busy = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() {
      _banner = null;
      _busy = true;
    });
    try {
      final idToken = await ref.read(googleIdentityProvider).idToken();
      if (idToken == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final session = await ref
          .read(authRepositoryProvider)
          .loginWithGoogle(idToken);
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _banner = _googleLoginMessage(error);
        _busy = false;
      });
    }
  }

  /// The banner text for a failed Google sign-in.
  String _googleLoginMessage(Object error) =>
      error is ApiFailure && error.code == 'INVALID_CREDENTIALS'
      ? _googleAccountNotRegistered
      : errorMessageFor(error);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(NiscalaSpacing.gutter),
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: _LogoTile(),
                          ),
                          formGap,
                          Semantics(
                            header: true,
                            child: Text(
                              'Masuk ke Niscala',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelola Kost Tanpa Ribet',
                            style: theme.textTheme.bodyLarge,
                          ),
                          formGap,
                          if (_banner != null) ...[
                            FormMessage(_banner!),
                            formGap,
                          ],
                          GoogleButton(
                            label: 'Masuk dengan Google',
                            onPressed: _busy ? null : _signInWithGoogle,
                          ),
                          formGap,
                          const EmailDivider(),
                          formGap,
                          LabeledField(
                            label: 'Email',
                            required: true,
                            child: TextField(
                              controller: _email,
                              decoration: InputDecoration(
                                errorText: _emailError,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                            ),
                          ),
                          formGap,
                          LabeledField(
                            label: 'Kata sandi',
                            required: true,
                            child: TextField(
                              controller: _password,
                              decoration: InputDecoration(
                                errorText: _passwordError,
                              ),
                              obscureText: !_showPassword,
                              autofillHints: const [AutofillHints.password],
                            ),
                          ),
                          ShowPasswordCheckbox(
                            value: _showPassword,
                            onChanged: (value) =>
                                setState(() => _showPassword = value),
                          ),
                          formGap,
                          BusyButton(
                            label: 'Masuk',
                            busy: _busy,
                            onPressed: _submit,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => context.go('/lupa-kata-sandi'),
                              child: const Text('Lupa kata sandi?'),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          const SizedBox(height: 8),
                          DefaultTextStyle(
                            style: theme.textTheme.bodySmall!,
                            textAlign: TextAlign.center,
                            child: const Text(
                              'Penyewa dan pengelola kost mengaktifkan akun '
                              'lewat tautan undangan dari pemilik kost.',
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/aktivasi'),
                            child: const Text(
                              'Aktifkan dengan tautan undangan',
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.go('/konfirmasi-email-baru'),
                            child: const Text('Konfirmasi email baru'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app icon shown above the heading, hidden from assistive technology.
class _LogoTile extends StatelessWidget {
  const _LogoTile();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset('assets/icon/niscala_icon.png', width: 56, height: 56),
    );
  }
}
