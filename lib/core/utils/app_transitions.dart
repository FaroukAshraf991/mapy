import 'package:flutter/material.dart';
class AppTransitions {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve defaultReverseCurve = Curves.easeInCubic;
  static Widget fadeSlideTransition(
      {required Widget child,
      required Animation<double> animation,
      Curve curve = defaultCurve,
      Offset beginOffset = const Offset(0.0, 0.05)}) {
    return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animation,
            curve: Interval(0.0, 0.6, curve: Curves.easeOut))),
        child: SlideTransition(
            position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation,
                    curve: curve,
                    reverseCurve: defaultReverseCurve)),
            child: child));
  }
  static Widget scaleTransition(
      {required Widget child,
      required Animation<double> animation,
      Curve curve = defaultCurve,
      double beginScale = 0.92}) {
    return ScaleTransition(
        scale: Tween<double>(begin: beginScale, end: 1.0).animate(
            CurvedAnimation(
                parent: animation,
                curve: curve,
                reverseCurve: defaultReverseCurve)),
        child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                    parent: animation,
                    curve: Interval(0.0, 0.6, curve: Curves.easeOut))),
            child: child));
  }
  static Widget slideFromRight(
      {required Widget child, required Animation<double> animation}) {
    return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: animation,
                curve: defaultCurve,
                reverseCurve: defaultReverseCurve)),
        child: FadeTransition(opacity: animation, child: child));
  }
  static Widget slideFromBottom(
      {required Widget child,
      required Animation<double> animation,
      double beginOffset = 0.15}) {
    return SlideTransition(
        position:
            Tween<Offset>(begin: Offset(0.0, beginOffset), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation,
                    curve: defaultCurve,
                    reverseCurve: defaultReverseCurve)),
        child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                    parent: animation,
                    curve: Interval(0.0, 0.5, curve: Curves.easeOut))),
            child: child));
  }
}
class AnimatedVisibilityWidget extends StatefulWidget {
  final Widget child;
  final bool visible;
  final Duration duration, delay;
  final Curve curve;
  final Offset slideBeginOffset;
  const AnimatedVisibilityWidget(
      {super.key,
      required this.child,
      required this.visible,
      this.duration = const Duration(milliseconds: 300),
      this.delay = Duration.zero,
      this.curve = Curves.easeOutCubic,
      this.slideBeginOffset = const Offset(0.0, 0.1)});
  @override
  State<AnimatedVisibilityWidget> createState() =>
      _AnimatedVisibilityWidgetState();
}
class _AnimatedVisibilityWidgetState extends State<AnimatedVisibilityWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _slideAnimation =
        Tween<Offset>(begin: widget.slideBeginOffset, end: Offset.zero)
            .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.visible) _startAnimation();
  }
  void _startAnimation() {
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }
  @override
  void didUpdateWidget(AnimatedVisibilityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible)
        _startAnimation();
      else
        _controller.reverse();
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
                offset: _slideAnimation.value, child: child)),
        child: widget.child);
  }
}
class StaggeredListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration, itemDelay;
  final Curve curve;
  final double itemOffset;
  const StaggeredListAnimation(
      {super.key,
      required this.children,
      this.itemDuration = const Duration(milliseconds: 400),
      this.itemDelay = const Duration(milliseconds: 50),
      this.curve = Curves.easeOutCubic,
      this.itemOffset = 30.0});
  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}
class _StaggeredListAnimationState extends State<StaggeredListAnimation> {
  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
            widget.children.length,
            (index) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: widget.itemDuration,
                curve: widget.curve,
                builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                        offset: Offset(0.0, widget.itemOffset * (1 - value)),
                        child: child)),
                child: widget.children[index])));
  }
}
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale, maxScale;
  const PulseAnimation(
      {super.key,
      required this.child,
      this.duration = const Duration(milliseconds: 1000),
      this.minScale = 0.95,
      this.maxScale = 1.05});
  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}
class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
            begin: widget.minScale, end: widget.maxScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scaleAnimation, child: widget.child);
}
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor, highlightColor;
  final Duration duration;
  const ShimmerEffect(
      {super.key,
      required this.child,
      this.baseColor = const Color(0xFFEEEEEE),
      this.highlightColor = const Color(0xFFF5F5F5),
      this.duration = const Duration(milliseconds: 1500)});
  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}
class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.baseColor,
                      widget.highlightColor,
                      widget.baseColor
                    ],
                    stops: [0.0, 0.5, 1.0],
                    transform: _SlidingGradientTransform(_animation.value))
                .createShader(bounds),
            child: child),
        child: widget.child);
  }
}
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
}
