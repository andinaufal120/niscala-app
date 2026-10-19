import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

/// The app bar title of a tenant screen: the screen name, and the property name
/// under it when the property has loaded.
class TenantTitle extends StatelessWidget {
  const TenantTitle({super.key, required this.title, this.propertyName});

  final String title;
  final String? propertyName;

  @override
  Widget build(BuildContext context) {
    final name = propertyName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (name != null)
          Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

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
