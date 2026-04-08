import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';

/// A slide-up modal bottom sheet with an animated entrance.
/// Content height is driven by the child's intrinsic size and is capped at
/// [context.maxSheetHeight] to prevent oversized sheets on tablets/desktop.
class AnimatedBottomSheet extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? radius;
  final bool isDismissible;
  final bool enableDrag;
  final Color? barrierColor;

  const AnimatedBottomSheet({
    super.key,
    required this.child,
    this.backgroundColor,
    this.radius,
    this.isDismissible = true,
    this.enableDrag = true,
    this.barrierColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    double? radius,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? barrierColor,
    bool fullScreen = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final defaultRadius = fullScreen ? 0.0 : 24.0;
    final maxSheetWidth = context.adaptiveValue(
      mobile: double.infinity,
      tablet: AppConstants.maxSheetWidthTablet,
      desktop: AppConstants.maxSheetWidthDesktop,
    );
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      constraints: maxSheetWidth == double.infinity
          ? null
          : BoxConstraints(maxWidth: maxSheetWidth),
      builder: (context) => AnimatedBottomSheet(
        backgroundColor: backgroundColor ?? defaultBgColor,
        radius: radius ?? defaultRadius,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        child: child,
      ),
    );
  }

  @override
  State<AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<AnimatedBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? 24.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1A1A1A) : Colors.white);
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            child: Container(
              constraints:
                  BoxConstraints(maxHeight: context.maxSheetHeight),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
