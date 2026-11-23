import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// The brightness of the app screen. It changes the brightness of this app's
/// window only, never the system brightness setting.
abstract interface class ScreenBrightnessControl {
  /// Sets the app screen to full brightness.
  Future<void> raise();

  /// Gives the app screen back its own brightness, as it was before [raise].
  Future<void> restore();
}

/// [ScreenBrightnessControl] backed by the screen_brightness plugin. The
/// plugin changes the brightness of the app window only; the system setting
/// stays as the user left it.
class PluginScreenBrightness implements ScreenBrightnessControl {
  @override
  Future<void> raise() =>
      ScreenBrightness.instance.setApplicationScreenBrightness(1.0);

  @override
  Future<void> restore() =>
      ScreenBrightness.instance.resetApplicationScreenBrightness();
}

final screenBrightnessProvider = Provider<ScreenBrightnessControl>(
  (ref) => PluginScreenBrightness(),
);
