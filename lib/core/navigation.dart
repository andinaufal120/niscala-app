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
