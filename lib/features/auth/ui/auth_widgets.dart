import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/features/auth/password_strength.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

const maximumPasswordLength = 128;

bool isValidEmail(String email) => _emailPattern.hasMatch(email);

/// The Indonesian error for a sign-up email, or null when it is valid.
String? signUpEmailError(String email) => email.isEmpty
    ? 'Email wajib diisi.'
    : isValidEmail(email)
    ? null
    : 'Format email tidak valid.';

/// The Indonesian error for a new password, or null when its length is allowed.
String? newPasswordError(String password) => password.length < 8
    ? 'Kata sandi minimal 8 karakter.'
    : password.length > maximumPasswordLength
    ? 'Kata sandi maksimal $maximumPasswordLength karakter.'
    : null;

/// The Indonesian error for a confirmation that does not match, or null.
String? confirmPasswordError(String password, String confirmation) =>
    confirmation.isEmpty
    ? 'Ketik ulang kata sandi.'
    : confirmation != password
    ? 'Konfirmasi tidak sama dengan kata sandi.'
    : null;

/// A form page. The [children] scroll above the [footer], which stays pinned
/// to the bottom of the screen. The credential fields share one autofill group.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.appBar, this.footer, required this.children});

  final PreferredSizeWidget? appBar;
  final Widget? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NiscalaSpacing.gutter),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// The strength bars and the Indonesian line under a new-password field. The
/// bars are hidden from TalkBack; the line is announced as it changes.
class PasswordStrengthHint extends StatelessWidget {
  const PasswordStrengthHint({
    super.key,
    required this.password,
    required this.name,
    required this.email,
  });

  final String password;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strength = passwordStrength(password, name: name, email: email);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                            ? _strengthColor(scheme, strength)
                            : scheme.surfaceContainerHighest,
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
            passwordStrengthText(password, name: name, email: email),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
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
