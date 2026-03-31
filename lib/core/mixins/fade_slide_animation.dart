import 'package:flutter/material.dart';

/// A mixin that provides fade and slide animations for screens.
/// Use with SingleTickerProviderStateMixin.
mixin FadeSlideAnimation<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController animController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;

  /// Override to customize animation duration.
  Duration get animationDuration => const Duration(milliseconds: 1200);

  void initFadeSlideAnimation() {
    animController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeOutCubic),
    );
    animController.forward();
  }

  void disposeFadeSlideAnimation() {
    animController.dispose();
  }
}
