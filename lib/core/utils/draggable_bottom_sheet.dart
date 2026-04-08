import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';

/// A bottom sheet whose height the user can drag between [minSize] and
/// [maxSize] fractions of the screen. Height is capped by
/// [context.maxSheetHeight] so the sheet never becomes oversized on tablets
/// or desktop screens.
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
    final maxSheetWidth = context.adaptiveValue(
      mobile: double.infinity,
      tablet: AppConstants.maxSheetWidthTablet,
      desktop: AppConstants.maxSheetWidthDesktop,
    );
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: maxSheetWidth == double.infinity
          ? null
          : BoxConstraints(maxWidth: maxSheetWidth),
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
    final double effectiveHeight =
        (screenHeight * _currentSize).clamp(0.0, context.maxSheetHeight);

    return AnimatedContainer(
      duration:
          widget.snap ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOutCubic,
      child: Container(
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
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
