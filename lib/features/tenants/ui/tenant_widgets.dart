import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

/// The account status of a tenant as a text badge.
class TenantStatusBadge extends StatelessWidget {
  const TenantStatusBadge({super.key, required this.status});

  final TenantAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = NiscalaTokens.of(context);
    return status == TenantAccountStatus.active
        ? StatusBadge(label: 'Aktif', colors: tokens.tenantActive)
        : StatusBadge(
            label: 'Belum Diaktifkan',
            colors: tokens.tenantNotActivated,
          );
  }
}
