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

class AccountScreen extends ConsumerWidget {
  /// [showLease] adds the room and lease card below the profile. Only the
  /// tenant's account tab sets it, so other roles never fetch the lease.
  const AccountScreen({super.key, this.showLease = false});

  final bool showLease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const _ProfileCard(),
                  const SizedBox(height: NiscalaSpacing.l),
                  if (showLease) ...[
                    const LeaseCard(),
                    const SizedBox(height: NiscalaSpacing.l),
                  ],
                  SectionCard(
                    title: 'Keamanan',
                    child: ActionCardRow(
                      icon: Icons.devices_outlined,
                      title: 'Perangkat aktif',
                      subtitle: 'Lihat dan keluarkan perangkat yang masuk',
                      onTap: () => _openSessions(context, ref),
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

  /// The active devices page sits under the Akun tab of the signed-in role.
  void _openSessions(BuildContext context, WidgetRef ref) {
    final isTenant = ref.read(currentRoleProvider) == UserRole.tenant;
    context.go(isTenant ? '/penyewa/akun/perangkat' : '/akun/perangkat');
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
