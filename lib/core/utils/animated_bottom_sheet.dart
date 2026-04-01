import 'package:flutter/material.dart';
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
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
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
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius),
                ),
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
class DraggableBottomSheet extends StatefulWidget {
  final Widget child;
  final Widget? dragHandle;
  final double minSize;
  final double maxSize;
  final double initialSize;
  final Color? backgroundColor;
  final bool snap;
  const DraggableBottomSheet({
    super.key,
    required this.child,
    this.dragHandle,
    this.minSize = 0.25,
    this.maxSize = 0.9,
    this.initialSize = 0.5,
    this.backgroundColor,
    this.snap = true,
  });
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Widget? dragHandle,
    double minSize = 0.25,
    double maxSize = 0.9,
    double initialSize = 0.5,
    Color? backgroundColor,
    bool snap = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => DraggableBottomSheet(
        dragHandle: dragHandle,
        minSize: minSize,
        maxSize: maxSize,
        initialSize: initialSize,
        backgroundColor: backgroundColor ?? defaultBgColor,
        snap: snap,
        child: child,
      ),
    );
  }
  @override
  State<DraggableBottomSheet> createState() => _DraggableBottomSheetState();
}
class _DraggableBottomSheetState extends State<DraggableBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _currentSize;
  @override
  void initState() {
    super.initState();
    _currentSize = widget.initialSize;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1A1A1A) : Colors.white);
    return AnimatedContainer(
      duration: widget.snap ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOutCubic,
      child: Container(
        height: screenHeight * _currentSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            if (widget.dragHandle != null) widget.dragHandle!,
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
