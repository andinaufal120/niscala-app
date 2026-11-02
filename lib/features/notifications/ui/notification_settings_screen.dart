import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/notifications/data/notification_repository.dart';
import 'package:niscala/features/notifications/notification_copy.dart';
import 'package:niscala_api/api.dart';

const _savedMessage = 'Pengaturan disimpan';

/// The push switch of each category of the caller's role, and the urgency
/// scope of the new complaint category. Saving sends the whole list; a failed
/// save keeps the edits on screen.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// The edits, copied from the loaded settings. Null until they load.
  List<NotificationSettingItem>? _draft;

  /// Set while a save is in flight, so a second tap sends nothing.
  var _saving = false;

  /// The result of the last save, until the next one.
  ({String text, bool isError})? _message;

  Future<void> _save(List<NotificationSettingItem> draft) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    final items = [
      for (final item in draft)
        NotificationSettingItem(
          category: item.category,
          pushEnabled: item.pushEnabled,
          urgencyScope: item.category == NotificationCategory.newComplaint
              ? item.urgencyScope
              : null,
        ),
    ];
    try {
      await ref.read(notificationRepositoryProvider).updateSettings(items);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = (text: errorMessageFor(failure), isError: true);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = (text: _savedMessage, isError: false);
    });
    ref.invalidate(notificationSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);
    return Scaffold(
      appBar: const DetailAppBar(title: 'Pengaturan Notifikasi'),
      body: settings.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(notificationSettingsProvider),
        ),
        data: (loaded) {
          final draft = _draft ??= [
            for (final item in loaded.items)
              NotificationSettingItem(
                category: item.category,
                pushEnabled: item.pushEnabled,
                urgencyScope: item.urgencyScope,
              ),
          ];
          return _form(draft);
        },
      ),
    );
  }

  Widget _form(List<NotificationSettingItem> draft) {
    final message = _message;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pengaturan ini hanya mengatur notifikasi push. Notifikasi tetap '
            'muncul di daftar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          formGap,
          for (final item in draft) ...[
            SwitchListTile(
              title: Text(notificationCategoryLabels[item.category]!),
              value: item.pushEnabled,
              onChanged: (value) => setState(() => item.pushEnabled = value),
            ),
            if (item.category == NotificationCategory.newComplaint)
              _UrgencyChoices(
                scope: item.urgencyScope,
                onChanged: (scope) => setState(() => item.urgencyScope = scope),
              ),
          ],
          if (message != null) ...[
            formGap,
            FormMessage(message.text, isError: message.isError),
          ],
          formGap,
          BusyButton(
            label: 'Simpan',
            busy: _saving,
            onPressed: () => _save(draft),
          ),
        ],
      ),
    );
  }
}

/// The urgencies that a new complaint sends a push for, as two choices.
class _UrgencyChoices extends StatelessWidget {
  const _UrgencyChoices({required this.scope, required this.onChanged});

  final NotificationUrgencyScope? scope;
  final ValueChanged<NotificationUrgencyScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: NiscalaSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kirim notifikasi untuk urgensi:',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          RadioGroup<NotificationUrgencyScope>(
            groupValue: scope ?? NotificationUrgencyScope.allUrgencies,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RadioListTile<NotificationUrgencyScope>(
                  value: NotificationUrgencyScope.allUrgencies,
                  title: const Text('Semua urgensi'),
                ),
                RadioListTile<NotificationUrgencyScope>(
                  value: NotificationUrgencyScope.highOnly,
                  title: const Text('Hanya urgensi tinggi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
