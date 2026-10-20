import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niscala/core/tokens.dart';

/// The app bar of a screen that is not a tab root: a bold [title], an optional
/// muted [subtitle] under it, and [actions] at the end.
///
/// The leading slot is always reserved, so the title sits at the same x with
/// or without a back button. A route that can pop shows a back button unless
/// [leading] is given. Text wraps, and the bar is as tall as its wrapped text
/// needs and never shorter than 56 dp.
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

  /// Replaces the default back button. An empty widget leaves the slot empty.
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
    final heading = MediaQuery(
      // The app bar clamps the text scale of its title. The bar keeps the
      // app's scale so the text and the toolbar height grow together.
      data: mediaQuery,
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
    );
    final height = _barHeight(
      title: title,
      subtitle: subtitle,
      hasActions: actions?.isNotEmpty ?? false,
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
        leading:
            leading ??
            (Navigator.canPop(context)
                ? const BackButton()
                : const SizedBox.shrink()),
        title: heading,
        excludeHeaderSemantics: true,
        toolbarHeight: height,
        actionsPadding: const EdgeInsets.only(right: NiscalaSpacing.gutter),
        actions: actions,
      ),
    );
  }
}

/// Title and subtitle styles of the app theme, as the bar lays them out.
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
);

/// The width of the leading slot, and of the space after the title: the
/// actions with their gutter, or just the gutter.
const _leadingWidth = 56.0;
const _actionsWidth = 68.0;
const _gutter = 20.0;

/// The bar height for the wrapped title and subtitle, and never less than the
/// 56 dp toolbar.
double _barHeight({
  required String title,
  required String? subtitle,
  required bool hasActions,
  required TextScaler textScaler,
  required double width,
}) {
  final textWidth =
      width - _leadingWidth - (hasActions ? _actionsWidth : _gutter);
  double lines(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: math.max(textWidth, 0));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  final text =
      lines(title, _titleStyle) +
      (subtitle == null ? 0 : lines(subtitle, _subtitleStyle));
  return math.max(
    math.max(kToolbarHeight, textScaler.scale(kToolbarHeight)),
    text,
  );
}
