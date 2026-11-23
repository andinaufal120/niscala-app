import 'package:flutter/widgets.dart';

const _order = [
  AppLifecycleState.resumed,
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];

/// Moves the app to [target] through every state in between, as the platform
/// does: resumed, inactive, hidden, paused, and back the same way.
void moveLifecycleTo(WidgetsBinding binding, AppLifecycleState target) {
  var index = _order.indexOf(
    binding.lifecycleState ?? AppLifecycleState.resumed,
  );
  final end = _order.indexOf(target);
  while (index != end) {
    index += end > index ? 1 : -1;
    binding.handleAppLifecycleStateChanged(_order[index]);
  }
}
