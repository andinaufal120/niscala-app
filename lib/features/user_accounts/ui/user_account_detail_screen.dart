import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/user_accounts/data/user_account_repository.dart';
import 'package:niscala/features/user_accounts/status_labels.dart';
import 'package:niscala_api/api.dart';

/// One account with its login details and what it is linked to. An Admin
/// only reads accounts, so the screen has no actions.
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

class _Details extends StatelessWidget {
  const _Details({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) {
    final role = account.role;
    final showsProperties = role == UserRole.owner || role == UserRole.manager;
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
        ],
      ),
    );
  }
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

/// The number of active leases of an Owner or Tenant, and for a Tenant with a
/// tenancy its property, room and lease end.
class _Lease extends StatelessWidget {
  const _Lease({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context) {
    final tenancy = account.tenancy;
    final leaseEnd = tenancy?.leaseEndDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tenancy != null) ...[
          _Field(label: 'Properti', child: Text(tenancy.propertyName)),
          _Field(label: 'Kamar', child: Text(tenancy.roomNumber)),
          if (leaseEnd != null)
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
