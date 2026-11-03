import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
import 'package:niscala/features/notifications/notification_copy.dart';
import 'package:niscala_api/api.dart';

const _tenantEmpty =
    'Belum ada notifikasi. Pemberitahuan tentang tagihan dan keluhan Anda '
    'akan muncul di sini.';
const _managementEmpty =
    'Belum ada notifikasi. Pemberitahuan tentang penyewa, pembayaran dan '
    'keluhan kost akan muncul di sini.';

/// The notifications of the caller, newest first, with the unread count and
/// the action that marks them all read. Opening a row shows its detail.
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  /// Set while the request is in flight, so a second tap sends nothing.
  var _markingAll = false;

  /// The message of the last failed "mark all read", until the next attempt.
  String? _markError;

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() {
      _markingAll = true;
      _markError = null;
    });
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _markingAll = false;
        _markError = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _markingAll = false);
    ref.invalidate(notificationListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final base = '${accountTabPath(role)}/notifikasi';
    final notifications = ref.watch(notificationListProvider);
    return Scaffold(
      appBar: DetailAppBar(
        title: 'Notifikasi',
        actions: [
          DetailBarAction.icon(
            icon: Icons.settings_outlined,
            tooltip: 'Pengaturan notifikasi',
            onPressed: () => context.go('$base/pengaturan'),
          ),
        ],
      ),
      body: notifications.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(notificationListProvider),
        ),
        data: (list) =>
            _list(list, forManagement: role != UserRole.tenant, base: base),
      ),
    );
  }

  Widget _list(
    NotificationList list, {
    required bool forManagement,
    required String base,
  }) {
    if (list.items.isEmpty) {
      return EmptyState(
        message: forManagement ? _managementEmpty : _tenantEmpty,
      );
    }
    final markError = _markError;
    return ListView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      children: [
        if (list.unreadCount > 0)
          _UnreadHeader(
            count: list.unreadCount,
            busy: _markingAll,
            onMarkAll: _markAllRead,
          ),
        if (markError != null) ...[formGap, FormMessage(markError)],
        for (final n in list.items) ...[
          _NotificationRow(
            notification: n,
            forManagement: forManagement,
            onTap: () => context.go('$base/${n.id}'),
          ),
          const SizedBox(height: NiscalaSpacing.s),
        ],
      ],
    );
  }
}

class _UnreadHeader extends StatelessWidget {
  const _UnreadHeader({
    required this.count,
    required this.busy,
    required this.onMarkAll,
  });

  final int count;
  final bool busy;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: NiscalaSpacing.s,
      children: [
        Text(
          '$count belum dibaca',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        TextButton(
          onPressed: busy ? null : onMarkAll,
          child: const Text('Tandai semua dibaca'),
        ),
      ],
    );
  }
}

/// One notification: its kind, an unread mark, its title, its line and its
/// date. It is one item for assistive technology, labelled with the same text
/// in reading order, and it opens the notification on tap.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.forManagement,
    required this.onTap,
  });

  final Notification notification;
  final bool forManagement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = notificationText(n, forManagement: forManagement);
    final body = text.body;
    final unread = !n.read;
    final date = formatDate(n.createdAt.toLocal());
    final spoken = [
      if (unread) 'Belum dibaca',
      notificationTypeLabel(n.type),
      text.title,
      ?body,
      date,
    ].join(', ');
    return Semantics(
      button: true,
      label: spoken,
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(NiscalaSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: NiscalaSpacing.s,
                  runSpacing: NiscalaSpacing.xs,
                  children: [
                    if (unread) ...[
                      DecoratedBox(
                        key: const ValueKey('unread-dot'),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      Text(
                        'Belum dibaca',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                    Text(
                      notificationTypeLabel(n.type),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: NiscalaSpacing.xs),
                Text(
                  text.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (body != null) Text(body, style: theme.textTheme.bodyMedium),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
