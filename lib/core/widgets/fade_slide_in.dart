import 'package:flutter/material.dart';

/// A gentle fade + upward-slide entrance, with an optional [delay] so a
/// list of these staggers in one after another instead of popping in as a
/// block. Used anywhere a screen's first paint should feel less abrupt —
/// dashboard tiles, terms sections, list items on first load.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps [children] with [FadeSlideIn], staggering each by [stagger] —
/// the common case of animating a list/grid's initial items in.
class StaggeredFadeSlideIn extends StatelessWidget {
  const StaggeredFadeSlideIn({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 60),
  });

  final List<Widget> children;
  final Duration stagger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          FadeSlideIn(delay: stagger * i, child: children[i]),
      ],
    );
  }
}
