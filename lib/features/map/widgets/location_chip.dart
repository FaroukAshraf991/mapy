import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';
import 'package:mapy/core/utils/responsive.dart';

class LocationChip extends StatelessWidget {
  final String type;
  final IconData icon;
  final String label;
  final bool isSet;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? trailingIcon;

  const LocationChip({
    super.key,
    required this.type,
    required this.icon,
    required this.label,
    required this.isSet,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppConstants.darkBackground;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: context.w(10),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(14), vertical: context.h(8)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(context.r(24)),
              border: Border.all(
                color: isSet
                    ? activeColor.withValues(alpha: 0.4)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(context.r(24)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: isSet
                          ? activeColor
                          : (isDark ? Colors.white38 : Colors.black38),
                      size: context.sp(18)),
                  SizedBox(width: context.w(8)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    SizedBox(width: context.w(4)),
                    Icon(trailingIcon,
                        color: isSet
                            ? activeColor
                            : (isDark ? Colors.white38 : Colors.black38),
                        size: context.sp(16)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
