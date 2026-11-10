import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_card_row.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/lease/ui/lease_card.dart';
import 'package:niscala_api/api.dart';

/// Ends the session. The server-side logout is best effort: the device is
/// signed out even when the request fails.
final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    try {
      await AuthApi(ref.read(apiClientProvider)).logout();
    } on Object {
      // The local session is cleared below regardless.
    }
    await ref.read(sessionControllerProvider.notifier).signOut();
  };
});

/// The Akun tab of [role]. Its sub-pages sit under this path.
String accountTabPath(UserRole? role) =>
    role == UserRole.tenant ? '/penyewa/akun' : '/akun';

class AccountScreen extends ConsumerWidget {
  /// [showLease] adds the room and lease card below the profile. Only the
  /// tenant's account tab sets it, so other roles never fetch the lease.
  ///
  /// [notice] is a confirmation shown at the top of the tab, such as the result
  /// of a password change.
  const AccountScreen({super.key, this.showLease = false, this.notice});

  final bool showLease;
  final String? notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The sign-in rows say what the account has, so they wait for the profile.
    final account = ref.watch(meProvider).value;
    // The role of the session decides the rows, so they do not wait for the
    // profile to load.
    final role = ref.watch(currentRoleProvider);
    final acceptsInvitation =
        role == UserRole.manager || role == UserRole.tenant;
    final notice = this.notice;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Akun'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NiscalaSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice != null) ...[
                    FormMessage(notice, isError: false),
                    formGap,
                  ],
                  const _ProfileCard(),
                  const SizedBox(height: NiscalaSpacing.l),
                  if (showLease) ...[
                    const LeaseCard(),
                    const SizedBox(height: NiscalaSpacing.l),
                  ],
                  if (acceptsInvitation) ...[
                    SectionCard(
                      title: 'Undangan',
                      child: ActionCardRow(
                        icon: Icons.mail_outline,
                        title: 'Terima undangan',
                        subtitle: 'Masukkan tautan undangan dari pemilik kost',
                        onTap: () => _openSubPage(context, ref, 'undangan'),
                      ),
                    ),
                    const SizedBox(height: NiscalaSpacing.l),
                  ],
                  ActionCardRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    subtitle: 'Lihat pemberitahuan dan atur notifikasi push',
                    onTap: () => _openSubPage(context, ref, 'notifikasi'),
                  ),
                  const SizedBox(height: NiscalaSpacing.l),
                  SectionCard(
                    title: 'Keamanan',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (account != null)
                          ..._signInRows(context, ref, account),
                        ActionCardRow(
                          icon: Icons.devices_outlined,
                          title: 'Perangkat aktif',
                          subtitle: 'Lihat dan keluarkan perangkat yang masuk',
                          onTap: () => _openSubPage(context, ref, 'perangkat'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logout stays in view below the scrolling content, so it can always
          // be reached without scrolling.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NiscalaSpacing.gutter,
              0,
              NiscalaSpacing.gutter,
              NiscalaSpacing.gutter,
            ),
            child: SizedBox(
              width: double.infinity,
              child: DangerButton(
                label: 'Keluar',
                icon: Icons.logout,
                onPressed: () => ref.read(logoutProvider)(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSubPage(BuildContext context, WidgetRef ref, String subPath) =>
      context.go('${accountTabPath(ref.read(currentRoleProvider))}/$subPath');

  /// The password and Google rows of the Keamanan section. The password is
  /// set or added, and Google is linked, shown with its email, or offered to
  /// link when the account has a password to sign in with.
  List<Widget> _signInRows(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) {
    final googleEmail = account.googleEmail;
    final hasPassword = account.hasPassword;
    return [
      _SecurityRow(
        title: 'Kata sandi',
        status: hasPassword ? 'Diatur' : 'Belum diatur',
        action: hasPassword
            ? _RowAction(
                label: 'Ubah',
                spokenLabel: 'Ubah kata sandi',
                onPressed: () => _openSubPage(context, ref, 'kata-sandi'),
              )
            : _RowAction(
                label: 'Tambah',
                spokenLabel: 'Tambah kata sandi',
                onPressed: () =>
                    _openSubPage(context, ref, 'tambah-kata-sandi'),
              ),
      ),
      formGap,
      _SecurityRow(
        title: 'Google',
        status: googleEmail == null
            ? 'Belum terhubung'
            : 'Terhubung · $googleEmail',
        action: googleEmail == null && hasPassword
            ? _RowAction(
                label: 'Hubungkan',
                spokenLabel: 'Hubungkan Google',
                onPressed: () => _openSubPage(context, ref, 'hubungkan-google'),
              )
            : null,
      ),
      formGap,
    ];
  }
}

/// The name, email and role of the caller, with the initials of the name as
/// an avatar. Its own loading and error states leave the rest of the screen
/// usable.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return SectionCard(
      child: me.when(
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(meProvider),
        ),
        data: (account) => _ProfileDetails(account: account),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        // The initials repeat the name, so TalkBack reads the name only.
        ExcludeSemantics(
          child: CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              _initials(account.name),
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(width: NiscalaSpacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A container keeps the name a node of its own, so TalkBack reads
              // it apart from the email and role.
              Semantics(
                container: true,
                child: Text(account.name, style: theme.textTheme.titleMedium),
              ),
              Text(account.email, style: theme.textTheme.bodyMedium),
              Text(
                _roleLabel(account.role),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row of the Keamanan section: its [title] and [status], with an optional
/// [action] at the end.
class _SecurityRow extends StatelessWidget {
  const _SecurityRow({required this.title, required this.status, this.action});

  final String title;
  final String status;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          // Title and status are read as one item.
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(status, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// The action of a [_SecurityRow]. The visible [label] is short; the
/// [spokenLabel] says what it acts on and starts with the label.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.label,
    required this.spokenLabel,
    required this.onPressed,
  });

  final String label;
  final String spokenLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spokenLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: TextButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// Up to two initials of the words of [name], e.g. "AP" for "Andi Pengguna".
String _initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word[0].toUpperCase())
    .join();

String _roleLabel(UserRole role) => switch (role) {
  UserRole.owner => 'Pemilik Kost',
  UserRole.manager => 'Pengelola Kost',
  UserRole.tenant => 'Penyewa',
  UserRole.admin => 'Admin',
  _ => throw ArgumentError.value(role, 'role', 'Unknown role'),
};
