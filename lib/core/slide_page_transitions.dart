import 'package:flutter/material.dart';

/// Slides a new page in from the right while the page under it moves a little
/// to the left. Popping plays both in reverse. With reduced motion the page is
/// shown at its resting place at once.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  static const _curve = Curves.easeInOutCubicEmphasized;
  static const _enterFrom = Offset(1, 0);
  static const _underMovesTo = Offset(-0.25, 0);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: _curve);
    final under = CurvedAnimation(parent: secondaryAnimation, curve: _curve);
    return SlideTransition(
      position: enter.drive(Tween<Offset>(begin: _enterFrom, end: Offset.zero)),
      child: SlideTransition(
        position: under.drive(
          Tween<Offset>(begin: Offset.zero, end: _underMovesTo),
        ),
        child: child,
      ),
    );
  }
}
