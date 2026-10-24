import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/screen_header.dart';
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
  /// [showLease] adds the room and lease card above the logout button. Only the
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
                  if (showLease) ...[
                    const LeaseCard(),
                    const SizedBox(height: NiscalaSpacing.l),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: DangerButton(
                      label: 'Keluar',
                      icon: Icons.logout,
                      onPressed: () => ref.read(logoutProvider)(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
