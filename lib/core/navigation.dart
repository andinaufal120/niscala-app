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

/// Leaves the current page and the pages above [location], each with its own
/// pop animation, so the page that was opened last slides out first. When the
/// pages below cannot be popped down to [location], goes there instead.
void leavePageTo(BuildContext context, String location) {
  final router = GoRouter.of(context);
  while (router.routerDelegate.state.uri.path != location && context.canPop()) {
    context.pop();
  }
  if (router.routerDelegate.state.uri.path != location) {
    context.go(location);
  }
}
