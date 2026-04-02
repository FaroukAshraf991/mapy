import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class AnimatedSwapPins extends StatefulWidget {
  final Widget startPin;
  final Widget endPin;
  final bool isSwapped;
  final Animation<double> animation;

  const AnimatedSwapPins({
    super.key,
    required this.startPin,
    required this.endPin,
    required this.isSwapped,
    required this.animation,
  });

  @override
  State<AnimatedSwapPins> createState() => _AnimatedSwapPinsState();
}

class _AnimatedSwapPinsState extends State<AnimatedSwapPins>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedSwapPins oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSwapped != widget.isSwapped) {
      _controller.forward(from: 0.0);
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
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Start pin
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _animation.value,
                child: widget.isSwapped ? widget.endPin : widget.startPin,
              ),
            ),
            // End pin
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _animation.value,
                child: widget.isSwapped ? widget.startPin : widget.endPin,
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedPinSwap extends StatefulWidget {
  final Widget child;
  final bool shouldAnimate;
  final Duration duration;
  final Curve curve;

  const AnimatedPinSwap({
    super.key,
    required this.child,
    this.shouldAnimate = true,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  State<AnimatedPinSwap> createState() => _AnimatedPinSwapState();
}

class _AnimatedPinSwapState extends State<AnimatedPinSwap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.shouldAnimate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedPinSwap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shouldAnimate != widget.shouldAnimate &&
        widget.shouldAnimate) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
