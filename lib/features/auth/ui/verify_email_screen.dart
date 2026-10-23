import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

final _codePattern = RegExp(r'^\d{6}$');

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  String? _accountEmail;
  var _verifying = false;
  var _resending = false;
  String? _codeError;
  String? _banner;
  var _resent = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    try {
      final account = await ref.read(authRepositoryProvider).getMyAccount();
      if (mounted) setState(() => _accountEmail = account.email);
    } on ApiFailure {
      // The screen is complete without the address; it says "email Anda".
    }
  }

  Future<void> _verify() async {
    if (_verifying || _resending) return;
    final code = _code.text.trim();
    final valid = _codePattern.hasMatch(code);
    setState(() {
      _codeError = valid ? null : 'Masukkan 6 digit kode.';
      _banner = null;
      _resent = false;
      _verifying = valid;
    });
    if (!valid) return;

    final session = ref.read(sessionControllerProvider.notifier);
    try {
      await ref.read(authRepositoryProvider).confirmEmail(code);
      await session.markEmailVerified();
    } on ApiFailure catch (failure) {
      if (failure.code == 'EMAIL_ALREADY_VERIFIED') {
        await session.markEmailVerified();
        return;
      }
      if (!mounted) return;
      final message = errorMessageFor(failure);
      final onCodeField =
          failure.code == 'VERIFICATION_CODE_INVALID' ||
          failure.code == 'VERIFICATION_CODE_EXPIRED';
      setState(() {
        _verifying = false;
        if (onCodeField) {
          _codeError = message;
        } else {
          _banner = message;
        }
      });
    }
  }

  Future<void> _resend() async {
    if (_verifying || _resending) return;
    setState(() {
      _codeError = null;
      _banner = null;
      _resent = false;
      _resending = true;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) setState(() => _resent = true);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _banner = errorMessageFor(failure));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _verifying || _resending;
    return AuthPage(
      appBar: const DetailAppBar(title: 'Verifikasi email'),
      footer: ActionFooter(
        primary: BusyButton(
          label: 'Verifikasi',
          busy: _verifying,
          onPressed: _verify,
        ),
        secondary: TextButton(
          onPressed: () => ref.read(logoutProvider)(),
          child: const Text('Keluar'),
        ),
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Masukkan kode 6 digit',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyLarge,
            children: [
              const TextSpan(text: 'Kode dikirim ke '),
              TextSpan(
                text: _accountEmail ?? 'email Anda',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '. Kode berlaku 10 menit.'),
            ],
          ),
        ),
        formGap,
        if (_banner != null) ...[FormMessage(_banner!), formGap],
        if (_resent) ...[
          const FormMessage('Kode baru dikirim.', isError: false),
          formGap,
        ],
        LabeledField(
          label: 'Kode verifikasi',
          required: true,
          child: TextField(
            controller: _code,
            decoration: InputDecoration(errorText: _codeError),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('Belum menerima kode?', style: theme.textTheme.bodyMedium),
            OutlinedButton(
              onPressed: busy ? null : _resend,
              child: const Text('Kirim ulang'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tidak menemukan email? Periksa folder spam.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
