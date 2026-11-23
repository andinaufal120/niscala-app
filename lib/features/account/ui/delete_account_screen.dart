import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/reauth_dialog.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala_api/api.dart';

const _title = 'Hapus Akun';
const _warning =
    'Penghapusan akun bersifat permanen dan tidak bisa dibatalkan.';
const _outcomeHeading = 'Yang akan terjadi';
const _outcomes = [
  'Profil, email, dan metode masuk dihapus.',
  'Semua perangkat dikeluarkan.',
  'Catatan transaksi dapat disimpan sesuai kewajiban hukum.',
];
const _ownerOutcome =
    'Data properti Anda dihapus permanen 90 hari setelah akun dihapus.';
const _confirmWord = 'HAPUS';
const _confirmLabel = 'Ketik HAPUS untuk melanjutkan';
const _submitLabel = 'Hapus akun saya';

const _ownerLeaseRefusal =
    'Akun belum bisa dihapus karena salah satu properti Anda masih punya sewa '
    'aktif. Akhiri atau hapus sewa itu lebih dulu.';
const _tenantLeaseRefusal =
    'Akun belum bisa dihapus karena Anda masih punya sewa aktif. Minta pemilik '
    'atau pengelola kost mengakhiri sewa Anda lebih dulu.';
const _subscriptionRefusal =
    'Akun belum bisa dihapus karena langganan Google Play Anda masih berjalan '
    'otomatis. Batalkan langganan di Google Play, lalu coba lagi.';

/// Deletes the account of the caller after the user types [_confirmWord]. The
/// account is deleted only by this screen, and a success ends the session.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  var _busy = false;
  String? _banner;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  /// Whether the typed word, without the spaces around it, is [_confirmWord].
  bool get _confirmed => _confirm.text.trim() == _confirmWord;

  Future<void> _submit() async {
    if (_busy || !_confirmed) return;
    setState(() {
      _busy = true;
      _banner = null;
    });
    try {
      final deleted = await _deleteAccount();
      if (!mounted) return;
      if (!deleted) {
        setState(() => _busy = false);
        return;
      }
      await ref
          .read(sessionControllerProvider.notifier)
          .endAfterAccountDeletion();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = _refusalMessage(failure);
      });
    }
  }

  /// Deletes the account. When the API asks for a recent re-authentication, the
  /// user confirms it and the deletion is retried once. Returns false when the
  /// user cancels the confirmation. A failure of the retry is thrown.
  Future<bool> _deleteAccount() async {
    final accounts = ref.read(accountRepositoryProvider);
    try {
      await accounts.deleteMyAccount();
    } on ApiFailure catch (failure) {
      if (failure.code != 'REAUTHENTICATION_REQUIRED') rethrow;
      if (!mounted) return false;
      // The dialog is modal, so the screen is idle while it is open.
      setState(() => _busy = false);
      final confirmed = await showReauthDialog(context, ref);
      if (!confirmed || !mounted) return false;
      setState(() => _busy = true);
      await accounts.deleteMyAccount();
    }
    return true;
  }

  /// The message for a refused deletion. The wording names the refusal for the
  /// person who deletes the account, so it differs from the shared texts.
  String _refusalMessage(ApiFailure failure) => switch (failure.code) {
    'OWNER_HAS_ACTIVE_LEASE' => _ownerLeaseRefusal,
    'TENANT_HAS_ACTIVE_LEASE' => _tenantLeaseRefusal,
    'SUBSCRIPTION_AUTO_RENEWING' => _subscriptionRefusal,
    _ => errorMessageFor(failure),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Loads the account, so that the re-authentication dialog knows whether it
    // has a password.
    ref.watch(myAccountProvider);
    final role = ref.watch(currentRoleProvider);
    final banner = _banner;
    return AuthPage(
      appBar: const DetailAppBar(title: _title),
      children: [
        if (banner != null) ...[FormMessage(banner), formGap],
        Text(_warning, style: theme.textTheme.titleMedium),
        formGap,
        Semantics(
          header: true,
          child: Text(_outcomeHeading, style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        for (final outcome in _outcomes) ...[
          _Bullet(outcome),
          const SizedBox(height: 8),
        ],
        if (role == UserRole.owner) _Bullet(_ownerOutcome),
        formGap,
        LabeledField(
          label: _confirmLabel,
          required: true,
          child: TextField(
            controller: _confirm,
            onChanged: (_) => setState(() {}),
          ),
        ),
        formGap,
        DangerButton(
          label: _submitLabel,
          busy: _busy,
          onPressed: _confirmed && !_busy ? _submit : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(accountTabPath(role)),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

/// One item of the outcome list. The bullet is hidden from TalkBack, so only
/// the text is read.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('•')),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
