import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/screen_brightness.dart';

/// Shows [child] with the app screen at full brightness, so that a QR code can
/// be scanned in the dark.
///
/// The brightness is raised while this widget is in the tree. It is restored
/// when the widget is removed or the app leaves the foreground, and raised
/// again when the app resumes. A failure to change the brightness is ignored,
/// so the screen still works without it.
class FullBrightness extends ConsumerStatefulWidget {
  const FullBrightness({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FullBrightness> createState() => _FullBrightnessState();
}

class _FullBrightnessState extends ConsumerState<FullBrightness>
    with WidgetsBindingObserver {
  // Read once, so that dispose can restore the brightness without a ref.
  late final ScreenBrightnessControl _brightness;

  // Whether the raised brightness is held and still has to be restored.
  var _held = false;

  @override
  void initState() {
    super.initState();
    _brightness = ref.read(screenBrightnessProvider);
    WidgetsBinding.instance.addObserver(this);
    _raise();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _raise();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _restore();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _raise() {
    if (_held) return;
    _held = true;
    _ignoreFailure(_brightness.raise);
  }

  void _restore() {
    if (!_held) return;
    _held = false;
    _ignoreFailure(_brightness.restore);
  }

  /// Runs [change] and drops any failure, synchronous or asynchronous.
  Future<void> _ignoreFailure(Future<void> Function() change) async {
    try {
      await change();
    } catch (_) {
      // The brightness is a convenience; a platform error must not break the
      // screen that shows the code.
    }
  }
}
