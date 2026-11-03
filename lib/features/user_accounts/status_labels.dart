import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

/// The Indonesian text of each account status.
const userAccountStatusLabels = {
  UserAccountStatus.active: 'Aktif',
  UserAccountStatus.inactive: 'Nonaktif',
  UserAccountStatus.deleted: 'Dihapus',
};

/// The Indonesian text of each role.
const userRoleLabels = {
  UserRole.owner: 'Pemilik',
  UserRole.tenant: 'Penyewa',
  UserRole.manager: 'Pengelola',
  UserRole.admin: 'Admin',
};

/// An account status as a text badge. Each status has its own icon, so the
/// status is not shown by colour alone.
class UserAccountStatusBadge extends StatelessWidget {
  const UserAccountStatusBadge(this.status, {super.key});

  final UserAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = NiscalaTokens.of(context);
    final (colors, icon) = switch (status) {
      UserAccountStatus.active => (
        tokens.tenantActive,
        Icons.check_circle_outline,
      ),
      UserAccountStatus.inactive => (
        tokens.tenantNotActivated,
        Icons.pause_circle_outline,
      ),
      UserAccountStatus.deleted => (
        tokens.accountDeleted,
        Icons.delete_outline,
      ),
      _ => throw ArgumentError.value(status, 'status', 'Unknown status'),
    };
    return StatusBadge(
      label: userAccountStatusLabels[status]!,
      colors: colors,
      icon: icon,
    );
  }
}
