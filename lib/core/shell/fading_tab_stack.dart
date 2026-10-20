import 'package:flutter/material.dart';

const _fadeDuration = Duration(milliseconds: 200);

/// The branches of a tab shell, cross-faded when the tab changes. Every branch
/// stays built, so its state survives a switch. With reduced motion the switch
/// is instant.
class FadingTabStack extends StatefulWidget {
  const FadingTabStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadingTabStack> createState() => _FadingTabStackState();
}

class _FadingTabStackState extends State<FadingTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: _fadeDuration,
    value: 1,
  );

  /// The tab that is fading out after a switch. Null when nothing is fading.
  int? _leaving;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FadingTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = 1;
      _leaving = null;
      return;
    }
    _leaving = oldWidget.index;
    _fade.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _leaving = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index && i != _leaving,
            child: FadeTransition(
              opacity: i == widget.index
                  ? _fade
                  : i == _leaving
                  ? ReverseAnimation(_fade)
                  : kAlwaysDismissedAnimation,
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}
