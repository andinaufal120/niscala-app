import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Notifications of the caller and their push settings. Every method throws an
/// `ApiFailure` when the call fails.
abstract interface class NotificationRepository {
  /// The caller's notifications, newest first, with the unread count.
  Future<NotificationList> list();

  /// Marks one notification read. A notification that is already read stays
  /// read.
  Future<Notification> markRead(String notificationId);

  Future<void> markAllRead();

  /// The push settings, one entry per category of the caller's role.
  Future<NotificationSettings> settings();

  /// Replaces the push settings. [items] must hold each category of the
  /// caller's role once, and the urgency scope only for the new complaint
  /// category.
  Future<NotificationSettings> updateSettings(
    List<NotificationSettingItem> items,
  );

  /// Registers the push token of this device for the current session,
  /// replacing the token registered before.
  Future<void> registerPushToken(String token);
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiNotificationRepository(notifications: NotificationsApi(client));
});

/// The caller's notifications. Invalidate it after a change. Failures are not
/// retried in the background: the screen shows them and the user retries.
final notificationListProvider = FutureProvider<NotificationList>(
  (ref) => ref.watch(notificationRepositoryProvider).list(),
  retry: (_, _) => null,
);

/// The caller's push settings. Invalidate it after a save. Failures are not
/// retried in the background, see [notificationListProvider].
final notificationSettingsProvider = FutureProvider<NotificationSettings>(
  (ref) => ref.watch(notificationRepositoryProvider).settings(),
  retry: (_, _) => null,
);

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({required this.notifications});

  final NotificationsApi notifications;

  @override
  Future<NotificationList> list() => _guard(() async {
    return (await notifications.listNotifications())!;
  });

  @override
  Future<Notification> markRead(String notificationId) => _guard(() async {
    return (await notifications.markNotificationRead(notificationId))!;
  });

  @override
  Future<void> markAllRead() =>
      _guard(() => notifications.markAllNotificationsRead());

  @override
  Future<NotificationSettings> settings() => _guard(() async {
    return (await notifications.getNotificationSettings())!;
  });

  @override
  Future<NotificationSettings> updateSettings(
    List<NotificationSettingItem> items,
  ) => _guard(() async {
    return (await notifications.updateNotificationSettings(
      NotificationSettingsInput(items: items),
    ))!;
  });

  @override
  Future<void> registerPushToken(String token) => _guard(
    () => notifications.registerPushToken(PushTokenInput(token: token)),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
