import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/utils/responsive.dart';

class FloatingMessage {
  static void show(BuildContext context, String message,
      {bool isError = true, Duration duration = const Duration(seconds: 3)}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + context.h(20),
        left: context.w(16),
        right: context.w(16),
        child: SlideUpFloatingMessage(
          message: message,
          isError: isError,
          isDark: isDark,
          onDismiss: () => overlayEntry.remove(),
          duration: duration,
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, isError: false);
  }
}

class SlideUpFloatingMessage extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final VoidCallback onDismiss;
  final Duration duration;

  const SlideUpFloatingMessage({
    super.key,
    required this.message,
    required this.isError,
    required this.isDark,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<SlideUpFloatingMessage> createState() => _SlideUpFloatingMessageState();
}

class _SlideUpFloatingMessageState extends State<SlideUpFloatingMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(Duration(milliseconds: widget.duration.inMilliseconds + 300),
        () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError ? Colors.redAccent : Colors.green;

    return GestureDetector(
      onTap: () {
        _controller.reverse().then((_) => widget.onDismiss());
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.r(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(20), vertical: context.h(16)),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.black.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(context.r(16)),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: context.w(20),
                        offset: Offset(0, context.h(8)),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.w(8)),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: color,
                          size: context.sp(24),
                        ),
                      ),
                      SizedBox(width: context.w(14)),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color:
                                widget.isDark ? Colors.white : Colors.black87,
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
