import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

const _newPasswordHelper =
    'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa aturan huruf '
    'atau simbol khusus.';
const _mismatch = 'Konfirmasi tidak sama dengan kata sandi baru.';
const _changedNotice = 'Kata sandi diperbarui.';
const _changedAndEndedNotice =
    'Kata sandi diperbarui. Perangkat lain telah dikeluarkan.';
const _offerTitle = 'Kata sandi berhasil diubah';
const _offerMessage =
    'Perangkat lain yang masih masuk ke akun ini bisa dikeluarkan sekarang.';

/// Changes the password of the caller. The new password is typed twice and
/// the two must match; the API checks the current password and the rules of
/// the new one. After a change the user may sign out the other devices.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  String? _currentError;
  String? _nextError;
  String? _confirmError;
  String? _banner;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final current = _current.text;
    final next = _next.text;
    final currentError = current.isEmpty
        ? 'Kata sandi saat ini wajib diisi.'
        : null;
    final nextError = next.isEmpty
        ? 'Kata sandi baru wajib diisi.'
        : newPasswordError(next);
    final confirmError = _confirmationError(next, _confirm.text);
    final valid =
        currentError == null && nextError == null && confirmError == null;
    setState(() {
      _currentError = currentError;
      _nextError = nextError;
      _confirmError = confirmError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      final hasOtherSessions = await ref
          .read(accountRepositoryProvider)
          .changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      if (hasOtherSessions) {
        setState(() => _busy = false);
        await _offerEndOthers();
      } else {
        _leave(_changedNotice);
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  /// Asks whether to sign out the other devices, then returns to the Akun tab
  /// with the matching confirmation. Dismissing the prompt keeps them signed in.
  Future<void> _offerEndOthers() async {
    final ended = await showDialog<bool>(
      context: context,
      builder: (_) => const _EndOthersDialog(),
    );
    if (!mounted) return;
    _leave(ended == true ? _changedAndEndedNotice : _changedNotice);
  }

  /// Shows a failure next to the field it names, or as a message at the form.
  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure);
    final onCurrent = failure.field == 'currentPassword';
    final onNext = failure.field == 'newPassword';
    setState(() {
      _busy = false;
      _currentError = onCurrent ? message : null;
      _nextError = onNext ? message : null;
      _banner = onCurrent || onNext ? null : message;
    });
  }

  void _leave(String notice) =>
      context.go(accountTabPath(ref.read(currentRoleProvider)), extra: notice);

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(meProvider).value;
    return AuthPage(
      appBar: const DetailAppBar(title: 'Ubah kata sandi'),
      // The toggle applies to all three fields, so it is pinned with the submit
      // action rather than placed among the fields.
      footer: ActionFooter(
        primary: BusyButton(
          label: 'Simpan kata sandi',
          busy: _busy,
          onPressed: _submit,
        ),
        // The tile paints its own ink on the nearest Material, not on the
        // footer's coloured box.
        secondary: Material(
          type: MaterialType.transparency,
          child: ShowPasswordCheckbox(
            value: _showPassword,
            onChanged: (value) => setState(() => _showPassword = value),
          ),
        ),
      ),
      children: [
        if (_banner != null) ...[FormMessage(_banner!), formGap],
        LabeledField(
          label: 'Kata sandi saat ini',
          required: true,
          child: TextField(
            controller: _current,
            decoration: InputDecoration(errorText: _currentError),
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.password],
          ),
        ),
        formGap,
        LabeledField(
          label: 'Kata sandi baru',
          required: true,
          helper: _newPasswordHelper,
          child: TextField(
            controller: _next,
            decoration: InputDecoration(errorText: _nextError),
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
        ),
        PasswordStrengthHint(
          password: _next.text,
          name: account?.name ?? '',
          email: account?.email ?? '',
        ),
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
      ],
    );
  }
}

/// The error for a confirmation that is empty or differs from [next], or null.
/// The two are compared as typed, without trimming.
String? _confirmationError(String next, String confirmation) {
  if (confirmation.isEmpty) return 'Ketik ulang kata sandi baru.';
  return confirmation == next ? null : _mismatch;
}

/// Offers to sign out the other devices after a password change. Pops with
/// true once they are all signed out, and with false or by dismissal when the
/// user stays signed in on them.
class _EndOthersDialog extends ConsumerStatefulWidget {
  const _EndOthersDialog();

  @override
  ConsumerState<_EndOthersDialog> createState() => _EndOthersDialogState();
}

class _EndOthersDialogState extends ConsumerState<_EndOthersDialog> {
  var _busy = false;
  String? _failure;

  Future<void> _endOthers() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(accountRepositoryProvider).endOtherSessions();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    ref.invalidate(sessionsProvider);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    return AlertDialog(
      title: const Text(_offerTitle),
      // Large text leaves the content little height, so it scrolls.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(_offerMessage),
          if (failure != null) ...[formGap, FormMessage(failure)],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Tetap masuk'),
        ),
        BusyButton(
          label: 'Keluarkan perangkat lain',
          busy: _busy,
          onPressed: _endOthers,
        ),
      ],
    );
  }
}
