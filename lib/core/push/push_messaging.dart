import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A push that the user opened, with the two string entries of its data. An
/// entry the push does not carry is null.
class PushOpened {
  const PushOpened({this.notificationId, this.type});

  /// Reads the `notificationId` and `type` entries. Entries that are not
  /// strings are ignored.
  factory PushOpened.fromData(Map<String, Object?> data) => PushOpened(
    notificationId: _stringOf(data['notificationId']),
    type: _stringOf(data['type']),
  );

  final String? notificationId;
  final String? type;
}

String? _stringOf(Object? value) => value is String ? value : null;

/// The push messages of this device: the permission, the token and the pushes
/// that reach the app.
abstract interface class PushMessaging {
  /// Asks the user for permission to show notifications. Returns whether it is
  /// granted.
  Future<bool> requestPermission();

  /// The token of this device, or null when the device has none.
  Future<String?> token();

  /// Emits each new token of this device.
  Stream<String> get onTokenRefresh;

  /// Emits each push that the user opens while the app runs in the background.
  Stream<PushOpened> get onOpened;

  /// The push that the user opened to start the app, or null. It is read once.
  Future<PushOpened?> initialOpened();

  /// Emits each push that arrives while the app is open.
  Stream<void> get onForegroundMessage;
}

/// [PushMessaging] backed by Firebase Cloud Messaging. Firebase must be
/// initialized before any of its members is used.
class FirebasePushMessaging implements PushMessaging {
  @override
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<String?> token() {
    // getToken returns the FCM registration token that the backend sends to.
    // Its replacement, register(), exposes the Installation ID instead.
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  @override
  Stream<PushOpened> get onOpened => FirebaseMessaging.onMessageOpenedApp.map(
    (message) => PushOpened.fromData(message.data),
  );

  @override
  Future<PushOpened?> initialOpened() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : PushOpened.fromData(message.data);
  }

  @override
  Stream<void> get onForegroundMessage => FirebaseMessaging.onMessage;
}

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => FirebasePushMessaging(),
);
