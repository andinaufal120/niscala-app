import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves the current page the way Kembali does, so the page animates away.
/// [location] is only used when there is no earlier page to return to.
void leavePage(BuildContext context, String location) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(location);
  }
}

/// Leaves the current page for [location] in one navigation, so only the page
/// being left animates out. Calling it again before the router has caught up
/// goes to the same location and does not pop past it.
void leavePageTo(BuildContext context, String location) {
  context.go(location);
}
