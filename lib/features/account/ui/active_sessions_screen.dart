import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala_api/api.dart';

const _retention =
    'Perangkat keluar otomatis jika tidak dipakai selama 90 hari. '
    'Sesi juga berakhir paling lama 1 tahun setelah masuk.';
const _noOthers = 'Tidak ada perangkat lain yang masuk ke akun ini.';
const _bulkLabel = 'Keluarkan semua perangkat lain';

/// The devices of the caller. The current device is listed apart and has no
/// end action. Each other device can be ended, or all of them at once.
class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  ConsumerState<ActiveSessionsScreen> createState() =>
      _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends ConsumerState<ActiveSessionsScreen> {
  /// The result of the last ending, kept on screen until the next action.
  String? _announcement;
  String? _failure;

  Future<void> _endOne(Session session) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluarkan ${session.deviceName}?',
      message: 'Perangkat ini akan keluar dari akun Anda.',
      confirmLabel: 'Keluarkan',
    );
    if (!confirmed || !mounted) return;
    await _end(
      () => ref.read(accountRepositoryProvider).endSession(session.id),
      announcement: 'Perangkat dikeluarkan.',
    );
  }

  Future<void> _endOthers() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluarkan semua perangkat lain?',
      message: 'Semua perangkat lain akan keluar. Perangkat ini tetap masuk.',
      confirmLabel: 'Keluarkan semua',
    );
    if (!confirmed || !mounted) return;
    await _end(
      () => ref.read(accountRepositoryProvider).endOtherSessions(),
      announcement: 'Perangkat lain dikeluarkan.',
    );
  }

  Future<void> _end(
    Future<void> Function() call, {
    required String announcement,
  }) async {
    try {
      await call();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _announcement = null;
        _failure = errorMessageFor(failure);
      });
      // The device was already gone, so the list on screen is out of date.
      if (failure.code == 'SESSION_NOT_FOUND') {
        ref.invalidate(sessionsProvider);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _failure = null;
      _announcement = announcement;
    });
    ref.invalidate(sessionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: const DetailAppBar(title: 'Perangkat aktif'),
      body: sessions.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(sessionsProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(List<Session> devices) {
    final current = devices.where((s) => s.isCurrent);
    final others = devices.where((s) => !s.isCurrent).toList();
    final failure = _failure;
    final announcement = _announcement;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_retention, style: Theme.of(context).textTheme.bodySmall),
          if (failure != null) ...[formGap, FormMessage(failure)],
          if (announcement != null) ...[
            formGap,
            FormMessage(announcement, isError: false),
          ],
          formGap,
          SectionCard(
            title: 'Perangkat ini',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final session in current) _DeviceRow(session: session),
              ],
            ),
          ),
          formGap,
          SectionCard(
            title: 'Perangkat lain · ${others.length}',
            child: others.isEmpty
                ? const EmptyState(message: _noOthers)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, session) in others.indexed) ...[
                        if (index > 0) const SizedBox(height: NiscalaSpacing.l),
                        _DeviceRow(
                          session: session,
                          onEnd: () => _endOne(session),
                        ),
                      ],
                      if (others.length >= 2) ...[
                        formGap,
                        DangerButton(
                          label: _bulkLabel,
                          icon: Icons.logout,
                          onPressed: _endOthers,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// One device: its name, platform, login method and last activity, with an
/// end button when [onEnd] is given.
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.session, this.onEnd});

  final Session session;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onEnd = this.onEnd;
    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.isCurrent) ...[
                  StatusBadge(
                    label: 'Aktif sekarang',
                    colors: NiscalaTokens.of(context).tenantActive,
                  ),
                  const SizedBox(height: NiscalaSpacing.xs),
                ],
                Text(session.deviceName, style: theme.textTheme.titleMedium),
                Text(
                  '${session.platform} · masuk dengan '
                  '${_loginLabel(session.loginMethod)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Terakhir aktif '
                  '${formatDate(session.lastActiveAt.toLocal())}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (onEnd != null) ...[
          const SizedBox(width: NiscalaSpacing.m),
          OutlinedButton(
            onPressed: onEnd,
            style: OutlinedButton.styleFrom(
              foregroundColor: NiscalaColors.danger,
              side: const BorderSide(color: NiscalaColors.danger),
            ),
            child: Text(
              'Keluarkan',
              semanticsLabel: 'Keluarkan ${session.deviceName}',
            ),
          ),
        ],
      ],
    );
  }
}

String _loginLabel(LoginMethod method) => switch (method) {
  LoginMethod.google => 'Google',
  LoginMethod.password => 'kata sandi',
  _ => throw ArgumentError.value(method, 'method', 'Unknown login method'),
};
