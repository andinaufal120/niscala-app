import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// The app bar of a screen that is not a tab root: a bold [title], an optional
/// muted [subtitle] under it, and [actions] at the end.
///
/// A route that can pop shows a back button unless [leading] is given. The
/// title starts at the screen gutter, after the back button slot when there is
/// one. Text wraps, and the bar is as tall as its wrapped text needs and never
/// shorter than 56 dp.
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  /// Replaces the default back button. A [SizedBox] leaves the slot empty.
  final Widget? leading;

  /// A [Scaffold] caps its app bar at this height and gives it exactly this
  /// height, so the height has to be known before the bar is built. It is
  /// measured from the text, the platform width and the platform text scale,
  /// the same values the bar lays out with inside the app's [MediaQuery].
  @override
  Size get preferredSize {
    final platform = WidgetsBinding.instance.platformDispatcher;
    final view = platform.implicitView;
    if (view == null) return const Size.fromHeight(kToolbarHeight);
    return Size.fromHeight(
      _barHeight(
        title: title,
        subtitle: subtitle,
        hasActions: actions?.isNotEmpty ?? false,
        textScaler: TextScaler.linear(platform.textScaleFactor),
        width: view.physicalSize.width / view.devicePixelRatio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final hasActions = actions?.isNotEmpty ?? false;
    final leadingWidget =
        leading ?? (Navigator.canPop(context) ? const BackButton() : null);
    // A SizedBox is an empty slot: it takes no width, so the title starts at
    // the gutter.
    final hasSlot = leadingWidget != null && leadingWidget is! SizedBox;
    final heading = MediaQuery(
      // The app bar clamps the text scale of its title. The bar keeps the
      // app's scale so the text and the toolbar height grow together.
      data: mediaQuery,
      child: Padding(
        padding: EdgeInsets.only(left: hasSlot ? 0 : _gutter),
        child: SizedBox(
          width: _titleWidth(
            width: mediaQuery.size.width,
            hasActions: hasActions,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: textTheme.titleLarge,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: textTheme.bodySmall,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
            ],
          ),
        ),
      ),
    );
    final height = _barHeight(
      title: title,
      subtitle: subtitle,
      hasActions: hasActions,
      textScaler: mediaQuery.textScaler,
      width: mediaQuery.size.width,
    );
    return IconButtonTheme(
      data: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(48)),
        ),
      ),
      child: AppBar(
        leading: leadingWidget,
        leadingWidth: hasSlot ? _leadingWidth : 0,
        title: heading,
        excludeHeaderSemantics: true,
        toolbarHeight: height,
        titleSpacing: 0,
        actionsPadding: const EdgeInsets.only(right: NiscalaSpacing.gutter),
        actions: actions,
      ),
    );
  }
}

/// Title and subtitle styles of the app theme, as the bar lays them out. The
/// subtitle keeps the letter spacing of the Material body small style, which
/// the theme inherits, because that spacing changes where the text wraps.
const _titleStyle = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: NiscalaColors.text,
);
const _subtitleStyle = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: NiscalaColors.textMuted,
  height: 1.5,
  letterSpacing: 0.4,
);

/// The back button slot, the gutter at the start and before the actions, the
/// actions with their gutter, and the padding above and below the title block.
const _leadingWidth = 56.0;
const _gutter = 20.0;
const _actionsWidth = 68.0;
const _verticalPadding = 16.0;

/// The width of the title column. It is the same on every bar, with or without
/// a back button, so a title wraps the same way on each bar and the measured
/// height is the height that is laid out.
double _titleWidth({required double width, required bool hasActions}) => math
    .max(0, width - _leadingWidth - _gutter - (hasActions ? _actionsWidth : 0));

/// The bar height for the wrapped title and subtitle plus padding, and never
/// less than the 56 dp toolbar.
double _barHeight({
  required String title,
  required String? subtitle,
  required bool hasActions,
  required TextScaler textScaler,
  required double width,
}) {
  final textWidth = _titleWidth(width: width, hasActions: hasActions);
  double lines(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: textWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  final text =
      lines(title, _titleStyle) +
      (subtitle == null ? 0 : lines(subtitle, _subtitleStyle));
  return math.max(kToolbarHeight, text + _verticalPadding);
}
