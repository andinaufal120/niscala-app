import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/failure_dialog.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/user_accounts/data/user_account_repository.dart';
import 'package:niscala/features/user_accounts/status_labels.dart';
import 'package:niscala_api/api.dart';

/// One account with its login details and what it is linked to. The only
/// action is Ubah, which opens the edit form of the account.
class UserAccountDetailScreen extends ConsumerWidget {
  const UserAccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(userAccountDetailProvider(accountId));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Rincian Akun'),
      body: account.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(userAccountDetailProvider(accountId)),
        ),
        data: (account) => _Details(account: account),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = account.role;
    final showsProperties = role == UserRole.owner || role == UserRole.manager;
    // Until the signed-in account is known, the delete action stays hidden, so
    // an admin never sees it on their own account.
    final signedInId = ref.watch(meProvider).value?.id;
    final canDelete =
        account.status != UserAccountStatus.deleted &&
        signedInId != null &&
        account.id != signedInId;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(child: _Identity(account: account)),
          formGap,
          SectionCard(
            title: 'Akun',
            child: _AccountDetails(account: account),
          ),
          if (showsProperties) ...[
            formGap,
            SectionCard(
              title: 'Properti',
              child: _Properties(account: account),
            ),
          ],
          if (role == UserRole.owner || role == UserRole.tenant) ...[
            formGap,
            SectionCard(
              title: 'Sewa',
              child: _Lease(account: account),
            ),
          ],
          // A deleted account cannot be changed, so it offers no edit.
          if (account.status != UserAccountStatus.deleted) ...[
            formGap,
            OutlinedButton(
              onPressed: () => context.go('/admin/${account.id}/ubah'),
              child: const Text('Ubah'),
            ),
          ],
          if (canDelete) ...[
            const SizedBox(height: 8),
            _DeleteAccountButton(account: account),
          ],
        ],
      ),
    );
  }
}

/// Deletes the account after confirmation. The button is disabled while the
/// request is in flight.
///
/// On success the account detail is reloaded and the list of accounts opens. On
/// failure the message is shown in a dialog; an account that is gone or already
/// deleted is reloaded, so the detail shows its current state.
class _DeleteAccountButton extends ConsumerStatefulWidget {
  const _DeleteAccountButton({required this.account});

  final UserAccount account;

  @override
  ConsumerState<_DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<_DeleteAccountButton> {
  var _busy = false;

  Future<void> _delete() async {
    final account = widget.account;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus ${account.name}?',
      message: '${account.email}. Hapus akun ini? Semua sesinya akan diakhiri.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(userAccountRepositoryProvider).delete(account.id);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (failure.code == 'USER_ACCOUNT_DELETED' ||
          failure.code == 'USER_ACCOUNT_NOT_FOUND') {
        ref.invalidate(userAccountDetailProvider(account.id));
      }
      await showFailureDialog(
        context,
        title: 'Akun belum bisa dihapus',
        message: errorMessageFor(failure),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(userAccountDetailProvider(account.id));
    ref.invalidate(userAccountListProvider);
    leavePageTo(context, '/admin');
  }

  @override
  Widget build(BuildContext context) =>
      DangerButton(label: 'Hapus Akun', onPressed: _busy ? null : _delete);
}

/// The name, email, role and status of the account.
class _Identity extends StatelessWidget {
  const _Identity({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(account.name, style: theme.textTheme.headlineSmall),
        ),
        Text(account.email),
        formGap,
        Wrap(
          spacing: NiscalaSpacing.s,
          runSpacing: NiscalaSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              userRoleLabels[account.role]!,
              style: theme.textTheme.labelLarge,
            ),
            UserAccountStatusBadge(account.status),
          ],
        ),
      ],
    );
  }
}

/// When the account was registered and last signed in, how it signs in, and
/// the email change that waits for confirmation.
class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) {
    final lastLogin = account.lastLoginAt;
    final pendingEmail = account.pendingEmail;
    final pendingExpiresAt = account.pendingEmailExpiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'Terdaftar',
          child: Text(formatDate(account.registeredAt.toLocal())),
        ),
        _Field(
          label: 'Terakhir masuk',
          child: Text(
            lastLogin == null
                ? 'Belum pernah masuk'
                : formatDate(lastLogin.toLocal()),
          ),
        ),
        _Field(
          label: 'Metode masuk',
          child: account.loginMethods.isEmpty
              ? const Text('Tidak ada')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final method in account.loginMethods)
                      Text(_loginMethodLabel(method)),
                  ],
                ),
        ),
        if (pendingEmail != null) ...[
          _Field(
            label: 'Email baru menunggu konfirmasi',
            child: Text(pendingEmail),
          ),
          if (pendingExpiresAt != null)
            _Field(
              label: 'Tautan berlaku sampai',
              child: Text(formatDate(pendingExpiresAt.toLocal())),
            ),
        ],
      ],
    );
  }
}

/// The properties an Owner owns or a Manager is assigned to.
class _Properties extends StatelessWidget {
  const _Properties({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) {
    final properties = account.properties;
    if (properties.isEmpty) return const Text('Belum ada properti.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final property in properties)
          Padding(
            padding: const EdgeInsets.only(bottom: NiscalaSpacing.s),
            child: Text(property.name),
          ),
      ],
    );
  }
}

/// The number of active leases of an Owner or Tenant, and for a Tenant the
/// property, room and lease end of each tenancy, in the order the API gives.
class _Lease extends StatelessWidget {
  const _Lease({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tenancy in account.tenancies) ...[
          _Field(label: 'Properti', child: Text(tenancy.propertyName)),
          _Field(label: 'Kamar', child: Text(tenancy.roomNumber)),
          if (tenancy.leaseEndDate case final leaseEnd?)
            _Field(
              label: 'Berakhir pada',
              // A lease end is a calendar date, so its day is not shifted.
              child: Text(formatDate(leaseEnd)),
            ),
        ],
        _Field(
          label: 'Masa sewa aktif',
          child: Text('${account.activeLeaseCount}'),
        ),
      ],
    );
  }
}

/// A label with its value below it. The value wraps, so long text never
/// overflows.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NiscalaSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          child,
        ],
      ),
    );
  }
}

String _loginMethodLabel(LoginMethod method) =>
    method == LoginMethod.google ? 'Google' : 'Kata sandi';
