import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';

/// An action at the end of a [DetailAppBar]. A null [onPressed] disables it.
///
/// The bar sizes each action before it is built, and the title is laid out in
/// the width that is left, so an action is drawn at exactly the width it was
/// measured at.
sealed class DetailBarAction {
  const DetailBarAction({required this.onPressed});

  /// A text button. It is at least 48 dp wide and grows with its label.
  const factory DetailBarAction.text({
    required String label,
    required VoidCallback? onPressed,
  }) = _TextAction;

  /// A 48 dp square icon button. [tooltip] is what assistive technology reads.
  const factory DetailBarAction.icon({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) = _IconAction;

  final VoidCallback? onPressed;

  /// The width the action is drawn at, for the given text scale.
  double width(TextScaler textScaler);

  Widget build();
}

const _actionTextStyle = TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

final class _TextAction extends DetailBarAction {
  const _TextAction({required this.label, required super.onPressed});

  final String label;

  @override
  double width(TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _actionTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final width = painter.width + 2 * _textActionPadding;
    painter.dispose();
    return math.max(_minTarget, width);
  }

  @override
  Widget build() => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      textStyle: _actionTextStyle,
      padding: const EdgeInsets.symmetric(horizontal: _textActionPadding),
    ),
    child: Text(label),
  );
}

final class _IconAction extends DetailBarAction {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required super.onPressed,
  });

  final IconData icon;
  final String tooltip;

  @override
  double width(TextScaler textScaler) => _minTarget;

  @override
  Widget build() =>
      IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed);
}

/// The app bar of a screen that is not a tab root: a bold title, an optional
/// muted [subtitle] under it, and [actions] at the end.
///
/// A route that can pop shows a back button when [showBack] is true, unless
/// [leading] is given, which replaces it. The space for that button is kept
/// whether or not the route can pop, so a bar has the same title width with or
/// without one. The text wraps, and the bar is as tall as its wrapped text needs
/// and never shorter than 56 dp.
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<DetailBarAction>? actions;

  /// Whether a route that can pop shows the back button. Ignored when [leading]
  /// is given.
  final bool showBack;

  /// Replaces the back button. It is laid out at its own width, and at least
  /// 48 dp wide. The height of the bar is measured for a leading of 48 dp, so a
  /// wider leading leaves less room for the title.
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
    final textScaler = TextScaler.linear(platform.textScaleFactor);
    return Size.fromHeight(
      _barHeight(
        title: title,
        subtitle: subtitle,
        reserveSlot: showBack || leading != null,
        actionsWidth: _actionsWidth(actions ?? const [], textScaler),
        textScaler: textScaler,
        width: view.physicalSize.width / view.devicePixelRatio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler;
    final subtitle = this.subtitle;
    final actions = this.actions ?? const <DetailBarAction>[];
    final hasActions = actions.isNotEmpty;
    final leadingWidget =
        leading ??
        (showBack && Navigator.canPop(context) ? const BackButton() : null);
    final heading = MediaQuery(
      // The app bar clamps the text scale of its title. The bar keeps the
      // app's scale so the text and the toolbar height grow together.
      data: mediaQuery,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingWidget != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _slotWidth),
              child: leadingWidget,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: leadingWidget == null ? _gutter : 0,
                // The space of a back button that is not shown stays empty.
                right:
                    (hasActions ? 0 : _gutter) +
                    (leadingWidget == null && showBack ? _slotWidth : 0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: detailTitleStyle,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: detailSubtitleStyle,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final height = _barHeight(
      title: title,
      subtitle: subtitle,
      reserveSlot: showBack || leading != null,
      actionsWidth: _actionsWidth(actions, textScaler),
      textScaler: textScaler,
      width: mediaQuery.size.width,
    );
    return IconButtonTheme(
      data: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(_minTarget)),
        ),
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        title: heading,
        excludeHeaderSemantics: true,
        toolbarHeight: height,
        titleSpacing: 0,
        actionsPadding: const EdgeInsets.only(right: NiscalaSpacing.gutter),
        actions: [
          for (final action in actions)
            SizedBox(width: action.width(textScaler), child: action.build()),
        ],
      ),
    );
  }
}

const _minTarget = 48.0;
const _slotWidth = 48.0;
const _gutter = 20.0;
const _textActionPadding = 12.0;
const _verticalPadding = 16.0;

double _actionsWidth(List<DetailBarAction> actions, TextScaler textScaler) =>
    actions.fold(0, (sum, action) => sum + action.width(textScaler));

/// The width of the title column: the bar width less the gutters, the back
/// button slot when [reserveSlot] is set, and the actions.
double _titleWidth({
  required double width,
  required bool reserveSlot,
  required double actionsWidth,
}) => math.max(
  0,
  width - _gutter - (reserveSlot ? _slotWidth : 0) - _gutter - actionsWidth,
);

/// The bar height for the wrapped title and subtitle plus padding, and never
/// less than the 56 dp toolbar.
double _barHeight({
  required String title,
  required String? subtitle,
  required bool reserveSlot,
  required double actionsWidth,
  required TextScaler textScaler,
  required double width,
}) {
  final textWidth = _titleWidth(
    width: width,
    reserveSlot: reserveSlot,
    actionsWidth: actionsWidth,
  );
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
      lines(title, detailTitleStyle) +
      (subtitle == null ? 0 : lines(subtitle, detailSubtitleStyle));
  return math.max(kToolbarHeight, text + _verticalPadding);
}
